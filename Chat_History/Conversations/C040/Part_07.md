# Campaign QA and strategy expansion

## Part 07

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_06.md) · [Next](Part_08.md)

<a id="c040-m02317"></a>

### C040-M02317

**ChatGPT** · 2026-05-26T10:58:09.563827-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02317 -->
Yes — code-first is the better workflow here.

The image generation path is slow because it bundles several steps into one hosted operation: loading CSVs, rendering high-DPI charts, composing the collage, saving artifacts, uploading files, and then displaying links. That is fine for final delivery, but it is inefficient for iterative chart design. The scatter especially needs iteration because the first version is visually congested and we need to decide the analytical framing before rendering again.

For this project, the better process is:

```text
1. Discuss and lock the chart story.
2. Generate Python code only.
3. You run it locally against the final campaign CSVs.
4. We refine the code/spec chart by chart.
5. Only after the designs are stable do you render final PNG/SVG assets.
```

The scatter chart is powerful, but it needs a cleaner design. Section 15 is the right data source because it is explicitly the archive-wide strategy frontier / executive comparison layer that turns completed strategy runs into tradeoff evidence for README and campaign storytelling. fileciteturn41file3 The challenge is that all 39 runs are not one simple two-dimensional scatter story: they span multiple Module 1 scenario families, strategy families, and comparison purposes. If we plot all 39 points with labels, colors, bubble sizes, and legend entries, it becomes crowded quickly.

Why the current scatter feels congested:

```text
1. Too many points are shown for a hero README chart.
2. Too many labels compete for space.
3. Multiple scenario families are mixed into one plane.
4. Bubble size adds meaning but also visual clutter.
5. Frontier_position_type has many categories, creating a busy legend.
6. Some strategies are only comparable within their Module 1 scenario / population group.
```

What makes the scatter powerful when cleaned up:

```text
X-axis = simulated offer exposure rate
    How much access / positive offer exposure the strategy creates.

Y-axis = approved EL per approved dollar
    How much approved Expected Loss density the strategy carries.

Bubble size = total approved amount
    How much approved exposure the strategy produces.

Color = strategy posture or frontier type
    What kind of strategy tradeoff the run represents.
```

That lets the reader immediately see:

```text
Growth strategies move toward more access / more exposure.
Risk-discipline strategies move toward lower approved EL density but lower access.
Affordability strategies can reduce exposure without behaving like pure risk tightening.
Option C strategies show counteroffer-management posture rather than simple approve/decline movement.
```

To make it efficient, we should produce a **standalone Python script** with a few switches:

```text
CHART_MODE = "preview" or "final"
SCATTER_SCOPE = "SC01_only" or "all_campaign"
LABEL_MODE = "selected_runs_only"
OUTPUT_FORMAT = "png" or "svg"
```

For previews, the script should use:

```text
lower DPI
smaller figure size
no collage composition
limited labels
one chart at a time
```

For final README assets, it should use:

```text
higher DPI
polished title/subtitle
selected labels
saved PNG and/or SVG
```

For the strategy frontier scatter specifically, I recommend we start with this design:

```text
Scope:
    SC01 only for the first README hero scatter.

Why:
    SC01 compares multiple strategies on the same BASELINE_V2 population.
    That makes the frontier easier to explain and less analytically mixed.

Label only:
    M2-01 Baseline
    M2-02 Tighter Risk
    M2-03 Growth
    M2-04 Affordability
    M2-05 Selective Counteroffer
    M2-37 Aggressive Counteroffer

Show all SC01 points as dots, but only label those six.
```

That should produce a much cleaner chart than plotting all 39 labeled points. A second appendix chart can show all 39 runs later.

For code generation, I would make the Python script read the final CSVs directly:

```text
15.7A → strategy frontier scatter
17.15 → selected baseline-relative deltas
17.17 → Option C split
17.20 → optional acceptance badge / caption text
```

The efficient next step is to lock the first chart spec — the frontier scatter — then generate Python code for that chart only, without rendering it here.
<!-- END_MESSAGE C040-M02317 -->


---

<a id="c040-m02319"></a>

### C040-M02319

**Andrew** · 2026-05-26T11:19:02.261000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02319 -->
let's lock down the first chart spec.
<!-- END_MESSAGE C040-M02319 -->


---

<a id="c040-m02322"></a>

### C040-M02322

**ChatGPT** · 2026-05-26T11:24:43.012473-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02322 -->
## Locked first-chart spec: Strategy Frontier Scatter

### Working title

**Strategy Frontier: Access vs Approved Expected-Loss Density**

Suggested subtitle:

**Baseline population only — same synthetic applicants, different governed strategy postures**

This is the right first chart because it visually supports the main Module 2 thesis: credit strategy is not a score cutoff; it is a governed tradeoff among access, approval exposure, affordability, counteroffers, risk profile, approved Expected Loss, product controls, and evidence readiness. Module 2’s own executive framing is built around making those tradeoffs visible in a controlled synthetic environment, and Section 15 is explicitly the archive-wide “strategy control tower” for interpreting those tradeoffs. fileciteturn41file2 fileciteturn41file3

---

# 1. Chart purpose

This chart should answer:

> **How do representative Module 2 strategies move the portfolio between access and approved risk density on the same synthetic applicant population?**

The reader should immediately see:

```text
Baseline = reference point
Tighter risk = lower access, lower approved EL density
Growth = higher access, higher approved EL density / exposure tradeoff
Affordability = lower access with mixed risk-efficiency behavior
Counteroffer strategies = different access / risk positions driven by governed feasibility routing
```

The chart is powerful because it turns a 39-run SQL campaign into a strategy frontier. It does not ask the reader to inspect dozens of QA files. It shows the portfolio design problem in one picture.

---

# 2. Data source

Use:

```text
15.7A — Executive-ready strategy frontier summary
```

Specifically:

```text
module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_15.7A_QA_executive_ready_strategy_frontier_summary_review_output_campaign.csv
```

This is the right source because Section 15 is designed to summarize archived strategy slices into an executive frontier view across offer exposure, approved amount, approved Expected Loss, affordability, risk profile, counteroffer behavior, manual review, decline rate, product behavior, score-band behavior, and reason-code movement. fileciteturn41file3

---

# 3. Scope

Use a **baseline-population frontier**, not the full 39-run campaign scatter.

Filter to:

```text
module1_scenario_name = BASELINE_V2
population_id = BASE_POPULATION_V1
```

This keeps the chart analytically clean because the strategies are being compared on the same Module 1 population. That is consistent with the project’s matched-comparison discipline: strategy movement should be interpreted as downstream Module 2 strategy movement, not source-population drift. fileciteturn41file31

This should include the representative baseline-population strategy set:

```text
M2-01 — Baseline
M2-02 — Tighter Synthetic Risk
M2-03 — Growth Oriented
M2-04 — Tighter Affordability
M2-05 — Selective Counteroffer Feasibility
M2-06 — Product Guardrails
M2-07 — Manual Review Reduction
M2-37 — Aggressive Counteroffer Expansion
```

Important note: M2-37 belongs to the Option C aggressive expansion addendum, but it is still useful in this scatter because it is applied to the same `BASELINE_V2 / BASE_POPULATION_V1` population. The chart title should say **baseline population**, not only “SC01,” to avoid implying it is limited to one showcase family.

---

# 4. Axes

## X-axis

```text
simulated_offer_exposure_rate
```

Plain-English label:

```text
Simulated Offer Exposure Rate
```

Interpretation:

```text
Higher = more applicants receive positive simulated offer exposure through APPROVE or COUNTEROFFER.
```

Format:

```text
percentage
```

## Y-axis

```text
approved_el_per_approved_dollar
```

Plain-English label:

```text
Approved EL per Approved Dollar
```

Interpretation:

```text
Higher = the approved exposure book carries more approved Expected Loss per approved dollar.
```

Format:

```text
percentage
```

This y-axis is better than total approved Expected Loss for the scatter because it measures **risk density**, not just size. A growth strategy can increase total approved Expected Loss simply because it approves more exposure; approved EL per approved dollar shows whether the approved book itself became denser with expected loss.

---

# 5. Marker encoding

## Marker position

```text
x = simulated_offer_exposure_rate
y = approved_el_per_approved_dollar
```

## Marker size

Use:

```text
total_approved_amount
```

Plain-English interpretation:

```text
Bigger point = larger approved exposure book.
```

Keep the bubble sizes restrained. This should not look like a bubble chart that overwhelms the x/y tradeoff. Bubble size is a secondary cue.

Recommended scaling:

```text
Minimum bubble size: small but visible
Maximum bubble size: no more than ~3x minimum visual footprint
```

## Marker grouping

Use `frontier_position_type` or simplified strategy family.

For README readability, I would simplify to these groups:

```text
Baseline Reference
Risk Discipline
Growth
Affordability / Mixed
Counteroffer Management
Product Guardrail
Review Burden
```

The raw `frontier_position_type` can still be used in the code, but the legend should be readable.

---

# 6. Baseline reference lines

This is the most important design choice.

Draw a thin vertical line at M2-01’s:

```text
simulated_offer_exposure_rate
```

Draw a thin horizontal line at M2-01’s:

```text
approved_el_per_approved_dollar
```

This turns the chart into four intuitive quadrants:

```text
Upper right:
    Higher access, higher EL density
    Growth tradeoff zone

Lower left:
    Lower access, lower EL density
    Risk-discipline / conservative zone

Upper left:
    Lower access, higher EL density
    Mixed / constrained tradeoff zone

Lower right:
    Higher access, lower EL density
    Frontier sweet spot if achieved
```

This makes the chart much easier to read than a plain scatter. The baseline becomes the reference anchor, and every challenger can be understood relative to it.

---

# 7. Labels

Label all points in the baseline-population subset, because the filtered chart should only have around eight points.

Use short labels:

```text
M2-01 Baseline
M2-02 Tighter Risk
M2-03 Growth
M2-04 Affordability
M2-05 Selective CO
M2-06 Product Guardrails
M2-07 Review Reduction
M2-37 Aggressive CO
```

Do **not** label with full strategy names inside the plot. Full strategy names are too long. Put full names in the README caption or nearby table.

---

# 8. Recommended visual annotations

Use only two or three annotations.

### Annotation 1 — Baseline

```text
Baseline reference
```

Pointing to M2-01.

### Annotation 2 — Tighter risk

```text
Lower access, cleaner approved risk density
```

Pointing to M2-02.

### Annotation 3 — Growth

```text
More access, larger approved exposure tradeoff
```

Pointing to M2-03.

Avoid annotating every point. The chart should feel executive-readable, not like a dense QA plot.

---

# 9. Chart caption

Use this below the chart in the README:

```text
Each point is an archived Module 2 strategy run applied to the same BASELINE_V2 synthetic applicant population. The x-axis shows simulated positive offer exposure; the y-axis shows approved Expected Loss per approved dollar. Bubble size represents total approved amount. The baseline crosshair makes each challenger’s access / risk-density tradeoff visible.
```

Optional shorter caption:

```text
The frontier shows how strategy posture changes the approved book: tighter risk lowers access and approved EL density, growth expands access and exposure, and counteroffer strategies create governed middle paths.
```

---

# 10. What not to do

Do **not** plot all 39 campaign rows in the README hero scatter. That creates the congestion we saw.

Do **not** label every all-campaign point.

Do **not** mix scenario families without explaining the scope.

Do **not** use total approved Expected Loss as the y-axis for this first chart. It overweights strategy size and makes growth look worse simply because it approves more exposure. Use risk density first; total approved Expected Loss can appear in the second chart.

Do **not** use a 3D chart or too many encodings. This should stay simple.

---

# 11. Final locked spec

```text
Chart name:
    Strategy Frontier Scatter

README title:
    Strategy Frontier: Access vs Approved Expected-Loss Density

Data source:
    Final campaign 15.7A executive frontier summary

Filter:
    module1_scenario_name = BASELINE_V2
    population_id = BASE_POPULATION_V1

Rows:
    M2-01, M2-02, M2-03, M2-04, M2-05, M2-06, M2-07, M2-37

X-axis:
    simulated_offer_exposure_rate

Y-axis:
    approved_el_per_approved_dollar

Marker size:
    total_approved_amount

Marker group:
    simplified strategy family or frontier_position_type

Reference lines:
    vertical line at M2-01 simulated_offer_exposure_rate
    horizontal line at M2-01 approved_el_per_approved_dollar

Labels:
    short module2_run_id + short strategy label for all filtered points

Annotations:
    baseline reference
    tighter risk tradeoff
    growth tradeoff

Output:
    standalone PNG and SVG
    later reused as the left panel of the 3-chart README collage
```

This is the version I would lock for the first README chart.
<!-- END_MESSAGE C040-M02322 -->


---

<a id="c040-m02323"></a>

### C040-M02323

**Andrew** · 2026-05-26T11:27:44.858000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02323 -->
I agree.  Let's create python code to produce that first readme chart.
<!-- END_MESSAGE C040-M02323 -->


---

<a id="c040-m02326"></a>

### C040-M02326

**ChatGPT** · 2026-05-26T11:33:26.372260-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02326 -->
Yes. Below is a standalone Python script for the **first locked README chart** only: the baseline-population strategy frontier scatter.

It reads the final campaign `15.7A` CSV, filters to `BASELINE_V2 / BASE_POPULATION_V1`, plots the representative strategy frontier, adds the M2-01 baseline crosshair, labels the eight baseline-population strategies, and saves both PNG and SVG.

This chart is grounded in Section 15’s role as the archive-wide strategy frontier control tower, which summarizes completed strategy runs into executive-ready tradeoff evidence across offer exposure, approved amount, approved Expected Loss, affordability, risk profile, counteroffer behavior, and reason-code movement. fileciteturn41file3

```python
"""
Module 2 README Chart 1
Strategy Frontier Scatter: Access vs Approved Expected-Loss Density

Purpose:
    Produce a clean README-ready scatter chart showing how representative
    Module 2 strategies move the same BASELINE_V2 / BASE_POPULATION_V1
    synthetic applicant population across access and approved Expected Loss density.

Data source:
    Final campaign Section 15.7A CSV:
    module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_15.7A_QA_executive_ready_strategy_frontier_summary_review_output_campaign.csv

Chart design:
    X-axis:
        simulated_offer_exposure_rate

    Y-axis:
        approved_el_per_approved_dollar

    Bubble size:
        total_approved_amount

    Reference lines:
        M2-01 baseline simulated_offer_exposure_rate
        M2-01 baseline approved_el_per_approved_dollar

    Labels:
        M2-01, M2-02, M2-03, M2-04, M2-05, M2-06, M2-07, M2-37

Authoring note:
    This script uses matplotlib only and avoids seaborn.
"""

from __future__ import annotations

from pathlib import Path
import textwrap

import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.ticker as mtick


# =============================================================================
# 1. USER SETTINGS
# =============================================================================

INPUT_CSV = Path(
    "module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_"
    "15.7A_QA_executive_ready_strategy_frontier_summary_review_output_campaign.csv"
)

OUTPUT_DIR = Path("assets")
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

OUTPUT_PNG = OUTPUT_DIR / "module2_strategy_frontier_scatter_baseline_population.png"
OUTPUT_SVG = OUTPUT_DIR / "module2_strategy_frontier_scatter_baseline_population.svg"

TARGET_MODULE1_SCENARIO_NAME = "BASELINE_V2"
TARGET_POPULATION_ID = "BASE_POPULATION_V1"

REPRESENTATIVE_RUN_ORDER = [
    "M2-01",
    "M2-02",
    "M2-03",
    "M2-04",
    "M2-05",
    "M2-06",
    "M2-07",
    "M2-37",
]

SHORT_LABELS = {
    "M2-01": "M2-01\nBaseline",
    "M2-02": "M2-02\nTighter Risk",
    "M2-03": "M2-03\nGrowth",
    "M2-04": "M2-04\nAffordability",
    "M2-05": "M2-05\nSelective CO",
    "M2-06": "M2-06\nProduct\nGuardrails",
    "M2-07": "M2-07\nReview\nReduction",
    "M2-37": "M2-37\nAggressive CO",
}

# Manual label offsets in points. These can be tuned after first render.
LABEL_OFFSETS = {
    "M2-01": (-42, 12),
    "M2-02": (-58, -26),
    "M2-03": (14, 14),
    "M2-04": (-62, 12),
    "M2-05": (-62, -30),
    "M2-06": (12, -30),
    "M2-07": (12, 12),
    "M2-37": (12, 16),
}

STRATEGY_FAMILY_DISPLAY = {
    "M2-01": "Baseline Reference",
    "M2-02": "Risk Discipline",
    "M2-03": "Growth",
    "M2-04": "Affordability / Mixed",
    "M2-05": "Counteroffer Management",
    "M2-06": "Product Guardrail",
    "M2-07": "Review Burden",
    "M2-37": "Counteroffer Management",
}


# =============================================================================
# 2. HELPER FUNCTIONS
# =============================================================================

def require_columns(df: pd.DataFrame, required_columns: list[str]) -> None:
    """Raise a clear error if the input CSV is missing required columns."""
    missing = [col for col in required_columns if col not in df.columns]
    if missing:
        raise ValueError(
            "Input CSV is missing required column(s): "
            + ", ".join(missing)
            + "\n\nAvailable columns:\n"
            + "\n".join(df.columns)
        )


def choose_metric_column(df: pd.DataFrame, preferred: str, fallback: str | None = None) -> str:
    """
    Choose a metric column with an optional fallback.

    Useful because older outputs may still carry legacy approved_expected_loss_rate,
    while refined outputs should use approved_el_per_approved_dollar.
    """
    if preferred in df.columns:
        return preferred
    if fallback and fallback in df.columns:
        return fallback
    raise ValueError(
        f"Could not find preferred column '{preferred}'"
        + (f" or fallback column '{fallback}'." if fallback else ".")
    )


def normalize_bubble_size(series: pd.Series, min_size: float = 260, max_size: float = 900) -> pd.Series:
    """
    Convert approved amount into restrained bubble sizes.

    Bubble size is a secondary cue, so the range is intentionally modest.
    """
    min_val = series.min()
    max_val = series.max()

    if pd.isna(min_val) or pd.isna(max_val):
        raise ValueError("Bubble-size source contains only null values.")

    if max_val == min_val:
        return pd.Series([0.5 * (min_size + max_size)] * len(series), index=series.index)

    return min_size + ((series - min_val) / (max_val - min_val)) * (max_size - min_size)


def clean_family_name(raw: str) -> str:
    """Readable fallback for frontier position labels."""
    return str(raw).replace("_", " ").title()


# =============================================================================
# 3. LOAD AND PREPARE DATA
# =============================================================================

df = pd.read_csv(INPUT_CSV)

y_col = choose_metric_column(
    df,
    preferred="approved_el_per_approved_dollar",
    fallback="approved_expected_loss_rate",
)

required = [
    "module2_run_id",
    "strategy_name",
    "module1_scenario_name",
    "population_id",
    "simulated_offer_exposure_rate",
    y_col,
    "total_approved_amount",
]

require_columns(df, required)

if "frontier_position_type" not in df.columns:
    df["frontier_position_type"] = "UNCLASSIFIED_FRONTIER_POINT"

plot_df = df[
    (df["module1_scenario_name"] == TARGET_MODULE1_SCENARIO_NAME)
    & (df["population_id"] == TARGET_POPULATION_ID)
    & (df["module2_run_id"].isin(REPRESENTATIVE_RUN_ORDER))
].copy()

if plot_df.empty:
    raise ValueError(
        "No rows found for the selected baseline-population filter. "
        f"Expected module1_scenario_name={TARGET_MODULE1_SCENARIO_NAME} "
        f"and population_id={TARGET_POPULATION_ID}."
    )

missing_runs = sorted(set(REPRESENTATIVE_RUN_ORDER) - set(plot_df["module2_run_id"]))
if missing_runs:
    raise ValueError(
        "The baseline-population chart is missing expected representative run(s): "
        + ", ".join(missing_runs)
    )

plot_df["run_order"] = plot_df["module2_run_id"].map(
    {run_id: idx for idx, run_id in enumerate(REPRESENTATIVE_RUN_ORDER)}
)
plot_df = plot_df.sort_values("run_order")

plot_df["strategy_family_display"] = plot_df["module2_run_id"].map(STRATEGY_FAMILY_DISPLAY)
plot_df["strategy_family_display"] = plot_df["strategy_family_display"].fillna(
    plot_df["frontier_position_type"].map(clean_family_name)
)

plot_df["short_label"] = plot_df["module2_run_id"].map(SHORT_LABELS).fillna(plot_df["module2_run_id"])
plot_df["bubble_size"] = normalize_bubble_size(plot_df["total_approved_amount"])

baseline = plot_df.loc[plot_df["module2_run_id"] == "M2-01"].iloc[0]
baseline_x = baseline["simulated_offer_exposure_rate"]
baseline_y = baseline[y_col]


# =============================================================================
# 4. BUILD CHART
# =============================================================================

fig, ax = plt.subplots(figsize=(10.5, 6.4), dpi=160)

# Plot each simplified family as its own scatter layer. Matplotlib default cycle
# handles the colors without hardcoding specific color values.
for family, group in plot_df.groupby("strategy_family_display", sort=False):
    ax.scatter(
        group["simulated_offer_exposure_rate"],
        group[y_col],
        s=group["bubble_size"],
        alpha=0.76,
        edgecolors="black",
        linewidths=0.7,
        label=family,
    )

# Baseline crosshair.
ax.axvline(baseline_x, linestyle="--", linewidth=1.0, alpha=0.65)
ax.axhline(baseline_y, linestyle="--", linewidth=1.0, alpha=0.65)

# Labels.
for _, row in plot_df.iterrows():
    run_id = row["module2_run_id"]
    offset = LABEL_OFFSETS.get(run_id, (8, 8))

    ax.annotate(
        row["short_label"],
        xy=(row["simulated_offer_exposure_rate"], row[y_col]),
        xytext=offset,
        textcoords="offset points",
        fontsize=8.5,
        ha="center",
        va="center",
        arrowprops={
            "arrowstyle": "-",
            "linewidth": 0.6,
            "alpha": 0.7,
            "shrinkA": 0,
            "shrinkB": 5,
        },
    )

# Strategic annotations.
ax.annotate(
    "Baseline reference",
    xy=(baseline_x, baseline_y),
    xytext=(-95, 48),
    textcoords="offset points",
    fontsize=9,
    arrowprops={"arrowstyle": "->", "linewidth": 0.8},
)

risk_row = plot_df.loc[plot_df["module2_run_id"] == "M2-02"].iloc[0]
ax.annotate(
    "Lower access,\ncleaner risk density",
    xy=(risk_row["simulated_offer_exposure_rate"], risk_row[y_col]),
    xytext=(-110, -68),
    textcoords="offset points",
    fontsize=9,
    arrowprops={"arrowstyle": "->", "linewidth": 0.8},
)

growth_row = plot_df.loc[plot_df["module2_run_id"] == "M2-03"].iloc[0]
ax.annotate(
    "More access,\nlarger exposure tradeoff",
    xy=(growth_row["simulated_offer_exposure_rate"], growth_row[y_col]),
    xytext=(35, 44),
    textcoords="offset points",
    fontsize=9,
    arrowprops={"arrowstyle": "->", "linewidth": 0.8},
)

# Axis formatting.
ax.set_title(
    "Strategy Frontier: Access vs Approved Expected-Loss Density",
    fontsize=15,
    fontweight="bold",
    pad=16,
)

ax.text(
    0.5,
    1.015,
    "Baseline population only — same synthetic applicants, different governed strategy postures",
    transform=ax.transAxes,
    ha="center",
    va="bottom",
    fontsize=10,
)

ax.set_xlabel("Simulated Offer Exposure Rate", fontsize=11)
ax.set_ylabel("Approved EL per Approved Dollar", fontsize=11)

ax.xaxis.set_major_formatter(mtick.PercentFormatter(xmax=1.0))
ax.yaxis.set_major_formatter(mtick.PercentFormatter(xmax=1.0))

# Add a small margin around points.
x_pad = max(0.005, (plot_df["simulated_offer_exposure_rate"].max() - plot_df["simulated_offer_exposure_rate"].min()) * 0.18)
y_pad = max(0.0002, (plot_df[y_col].max() - plot_df[y_col].min()) * 0.22)

ax.set_xlim(plot_df["simulated_offer_exposure_rate"].min() - x_pad, plot_df["simulated_offer_exposure_rate"].max() + x_pad)
ax.set_ylim(plot_df[y_col].min() - y_pad, plot_df[y_col].max() + y_pad)

ax.grid(True, linewidth=0.45, alpha=0.35)

legend = ax.legend(
    title="Strategy posture",
    loc="best",
    fontsize=8,
    title_fontsize=9,
    frameon=True,
)

# Bubble-size explanation.
caption = (
    "Bubble size represents total approved amount. "
    "Dashed lines mark M2-01 baseline access and approved-EL density."
)
wrapped_caption = "\n".join(textwrap.wrap(caption, width=120))

fig.text(
    0.5,
    0.015,
    wrapped_caption,
    ha="center",
    va="bottom",
    fontsize=8.5,
)

fig.tight_layout(rect=[0.03, 0.06, 0.98, 0.96])


# =============================================================================
# 5. SAVE OUTPUTS
# =============================================================================

fig.savefig(OUTPUT_PNG, bbox_inches="tight")
fig.savefig(OUTPUT_SVG, bbox_inches="tight")
plt.close(fig)

print(f"Saved PNG: {OUTPUT_PNG}")
print(f"Saved SVG: {OUTPUT_SVG}")

# Optional: print chart data for quick sanity review.
display_cols = [
    "module2_run_id",
    "strategy_name",
    "simulated_offer_exposure_rate",
    y_col,
    "total_approved_amount",
    "strategy_family_display",
]

print("\nChart data used:")
print(plot_df[display_cols].to_string(index=False))
```

For the README, I would place this chart immediately after the Module 2 thesis statement. Suggested caption:

```text
Each point is an archived Module 2 strategy run applied to the same BASELINE_V2 synthetic applicant population. The x-axis shows simulated positive offer exposure; the y-axis shows approved Expected Loss per approved dollar. Bubble size represents total approved amount. The baseline crosshair makes each challenger’s access / risk-density tradeoff visible.
```
<!-- END_MESSAGE C040-M02326 -->


---

<a id="c040-m02327"></a>

### C040-M02327

**Andrew** · 2026-05-26T11:38:08.591000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02327 -->
thank you. within the python code, can you hardcode the values from our 15.7A that we need? here is 15.7A again.
<!-- END_MESSAGE C040-M02327 -->


**Attachments in export:** `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_15.7A_QA_executive_ready_strategy_frontier_summary_review_output_campaign(2).csv`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c040-m02332"></a>

### C040-M02332

**ChatGPT** · 2026-05-26T11:46:52.210544-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02332 -->
Yes. Below is the same chart script, but with the needed **15.7A values hardcoded** into the Python code. It no longer depends on reading the CSV.

I kept only the fields needed for the first README scatter:

```text
module2_run_id
short label
strategy posture
simulated_offer_exposure_rate
approved_el_per_approved_dollar
total_approved_amount
```

These are the Section 15 frontier fields we need for the chart. Section 15 is the archive-wide strategy frontier view, which is why it is the right evidence source for this visualization. fileciteturn41file3

```python
"""
Module 2 README Chart 1
Strategy Frontier Scatter: Access vs Approved Expected-Loss Density

This version uses hardcoded final-campaign Section 15.7A values.

Chart thesis:
    Same synthetic applicant population.
    Different governed Module 2 strategy postures.
    Visible access / risk-density / exposure tradeoffs.

Data scope:
    module1_scenario_name = BASELINE_V2
    population_id = BASE_POPULATION_V1

Output:
    assets/module2_strategy_frontier_scatter_baseline_population.png
    assets/module2_strategy_frontier_scatter_baseline_population.svg
"""

from __future__ import annotations

from pathlib import Path
import textwrap

import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.ticker as mtick


# =============================================================================
# 1. OUTPUT SETTINGS
# =============================================================================

OUTPUT_DIR = Path("assets")
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

OUTPUT_PNG = OUTPUT_DIR / "module2_strategy_frontier_scatter_baseline_population.png"
OUTPUT_SVG = OUTPUT_DIR / "module2_strategy_frontier_scatter_baseline_population.svg"


# =============================================================================
# 2. HARDCODED SECTION 15.7A FRONTIER DATA
# =============================================================================

FRONTIER_DATA = [
    {
        "module2_run_id": "M2-01",
        "short_label": "M2-01\nBaseline",
        "strategy_posture": "Baseline Reference",
        "strategy_name": "BASELINE_STRATEGY",
        "module1_scenario_name": "BASELINE_V2",
        "population_id": "BASE_POPULATION_V1",
        "simulated_offer_exposure_rate": 0.595240,
        "approved_el_per_approved_dollar": 0.0152985203377187,
        "total_approved_amount": 3827278124.10,
    },
    {
        "module2_run_id": "M2-02",
        "short_label": "M2-02\nTighter Risk",
        "strategy_posture": "Risk Discipline",
        "strategy_name": "TIGHTER_SYNTHETIC_RISK_STRATEGY",
        "module1_scenario_name": "BASELINE_V2",
        "population_id": "BASE_POPULATION_V1",
        "simulated_offer_exposure_rate": 0.570760,
        "approved_el_per_approved_dollar": 0.0139552919132960,
        "total_approved_amount": 3677999148.76,
    },
    {
        "module2_run_id": "M2-03",
        "short_label": "M2-03\nGrowth",
        "strategy_posture": "Growth",
        "strategy_name": "GROWTH_ORIENTED_STRATEGY",
        "module1_scenario_name": "BASELINE_V2",
        "population_id": "BASE_POPULATION_V1",
        "simulated_offer_exposure_rate": 0.622500,
        "approved_el_per_approved_dollar": 0.0165351528346220,
        "total_approved_amount": 4065698262.08,
    },
    {
        "module2_run_id": "M2-04",
        "short_label": "M2-04\nAffordability",
        "strategy_posture": "Affordability / Mixed",
        "strategy_name": "TIGHTER_AFFORDABILITY_STRATEGY",
        "module1_scenario_name": "BASELINE_V2",
        "population_id": "BASE_POPULATION_V1",
        "simulated_offer_exposure_rate": 0.565520,
        "approved_el_per_approved_dollar": 0.0154141022464799,
        "total_approved_amount": 3569433393.72,
    },
    {
        "module2_run_id": "M2-05",
        "short_label": "M2-05\nSelective CO",
        "strategy_posture": "Counteroffer Management",
        "strategy_name": "SELECTIVE_COUNTEROFFER_FEASIBILITY_STRATEGY",
        "module1_scenario_name": "BASELINE_V2",
        "population_id": "BASE_POPULATION_V1",
        "simulated_offer_exposure_rate": 0.525820,
        "approved_el_per_approved_dollar": 0.0145871986070696,
        "total_approved_amount": 3463854014.82,
    },
    {
        "module2_run_id": "M2-06",
        "short_label": "M2-06\nProduct\nGuardrails",
        "strategy_posture": "Product Guardrail",
        "strategy_name": "PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY",
        "module1_scenario_name": "BASELINE_V2",
        "population_id": "BASE_POPULATION_V1",
        "simulated_offer_exposure_rate": 0.512600,
        "approved_el_per_approved_dollar": 0.0145885274000267,
        "total_approved_amount": 3716432230.48,
    },
    {
        "module2_run_id": "M2-07",
        "short_label": "M2-07\nReview\nReduction",
        "strategy_posture": "Review Burden",
        "strategy_name": "MANUAL_REVIEW_REDUCTION_STRATEGY",
        "module1_scenario_name": "BASELINE_V2",
        "population_id": "BASE_POPULATION_V1",
        "simulated_offer_exposure_rate": 0.595240,
        "approved_el_per_approved_dollar": 0.0152985203377187,
        "total_approved_amount": 3827278124.10,
    },
    {
        "module2_run_id": "M2-37",
        "short_label": "M2-37\nAggressive CO",
        "strategy_posture": "Counteroffer Management",
        "strategy_name": "AGGRESSIVE_COUNTEROFFER_EXPANSION_STRATEGY",
        "module1_scenario_name": "BASELINE_V2",
        "population_id": "BASE_POPULATION_V1",
        "simulated_offer_exposure_rate": 0.607020,
        "approved_el_per_approved_dollar": 0.0149365120481094,
        "total_approved_amount": 3639742514.82,
    },
]


# =============================================================================
# 3. LABEL AND LAYOUT SETTINGS
# =============================================================================

RUN_ORDER = [
    "M2-01",
    "M2-02",
    "M2-03",
    "M2-04",
    "M2-05",
    "M2-06",
    "M2-07",
    "M2-37",
]

# Manual label offsets in points. Tune these after first local render if needed.
LABEL_OFFSETS = {
    "M2-01": (-42, 14),
    "M2-02": (-58, -30),
    "M2-03": (18, 16),
    "M2-04": (-64, 12),
    "M2-05": (-62, -32),
    "M2-06": (18, -34),
    "M2-07": (18, 18),
    "M2-37": (22, 18),
}


# =============================================================================
# 4. HELPER FUNCTIONS
# =============================================================================

def normalize_bubble_size(
    series: pd.Series,
    min_size: float = 280,
    max_size: float = 900,
) -> pd.Series:
    """
    Convert total approved amount into restrained marker sizes.

    Bubble size is intentionally a secondary cue. The chart should mainly read
    as access versus approved Expected-Loss density.
    """
    min_val = series.min()
    max_val = series.max()

    if max_val == min_val:
        return pd.Series([0.5 * (min_size + max_size)] * len(series), index=series.index)

    return min_size + ((series - min_val) / (max_val - min_val)) * (max_size - min_size)


def approved_amount_billions(value: float) -> str:
    """Format approved amount for optional sanity-print output."""
    return f"${value / 1_000_000_000:.2f}B"


# =============================================================================
# 5. PREPARE DATA
# =============================================================================

plot_df = pd.DataFrame(FRONTIER_DATA)

plot_df["run_order"] = plot_df["module2_run_id"].map(
    {run_id: idx for idx, run_id in enumerate(RUN_ORDER)}
)

plot_df = plot_df.sort_values("run_order").reset_index(drop=True)

plot_df["bubble_size"] = normalize_bubble_size(plot_df["total_approved_amount"])

baseline = plot_df.loc[plot_df["module2_run_id"] == "M2-01"].iloc[0]
baseline_x = baseline["simulated_offer_exposure_rate"]
baseline_y = baseline["approved_el_per_approved_dollar"]


# =============================================================================
# 6. BUILD CHART
# =============================================================================

fig, ax = plt.subplots(figsize=(10.5, 6.4), dpi=160)

# Plot by simplified strategy posture. Matplotlib's default color cycle is used.
for posture, group in plot_df.groupby("strategy_posture", sort=False):
    ax.scatter(
        group["simulated_offer_exposure_rate"],
        group["approved_el_per_approved_dollar"],
        s=group["bubble_size"],
        alpha=0.78,
        label=posture,
    )

# Baseline crosshair.
ax.axvline(baseline_x, linestyle="--", linewidth=1.0, alpha=0.65)
ax.axhline(baseline_y, linestyle="--", linewidth=1.0, alpha=0.65)

# Point labels.
for _, row in plot_df.iterrows():
    run_id = row["module2_run_id"]
    offset = LABEL_OFFSETS.get(run_id, (8, 8))

    ax.annotate(
        row["short_label"],
        xy=(row["simulated_offer_exposure_rate"], row["approved_el_per_approved_dollar"]),
        xytext=offset,
        textcoords="offset points",
        fontsize=8.5,
        ha="center",
        va="center",
        arrowprops={
            "arrowstyle": "-",
            "linewidth": 0.6,
            "alpha": 0.70,
            "shrinkA": 0,
            "shrinkB": 5,
        },
    )

# A few high-value annotations only.
ax.annotate(
    "Baseline\nreference",
    xy=(baseline_x, baseline_y),
    xytext=(-95, 48),
    textcoords="offset points",
    fontsize=9,
    arrowprops={"arrowstyle": "->", "linewidth": 0.8},
)

risk_row = plot_df.loc[plot_df["module2_run_id"] == "M2-02"].iloc[0]
ax.annotate(
    "Lower access,\ncleaner risk density",
    xy=(risk_row["simulated_offer_exposure_rate"], risk_row["approved_el_per_approved_dollar"]),
    xytext=(-112, -68),
    textcoords="offset points",
    fontsize=9,
    arrowprops={"arrowstyle": "->", "linewidth": 0.8},
)

growth_row = plot_df.loc[plot_df["module2_run_id"] == "M2-03"].iloc[0]
ax.annotate(
    "More access,\nlarger exposure tradeoff",
    xy=(growth_row["simulated_offer_exposure_rate"], growth_row["approved_el_per_approved_dollar"]),
    xytext=(38, 44),
    textcoords="offset points",
    fontsize=9,
    arrowprops={"arrowstyle": "->", "linewidth": 0.8},
)

# Titles.
ax.set_title(
    "Strategy Frontier: Access vs Approved Expected-Loss Density",
    fontsize=15,
    fontweight="bold",
    pad=16,
)

ax.text(
    0.5,
    1.015,
    "Baseline population only — same synthetic applicants, different governed strategy postures",
    transform=ax.transAxes,
    ha="center",
    va="bottom",
    fontsize=10,
)

# Axes.
ax.set_xlabel("Simulated Offer Exposure Rate", fontsize=11)
ax.set_ylabel("Approved EL per Approved Dollar", fontsize=11)

ax.xaxis.set_major_formatter(mtick.PercentFormatter(xmax=1.0))
ax.yaxis.set_major_formatter(mtick.PercentFormatter(xmax=1.0))

# Add a small margin around points.
x_pad = max(
    0.005,
    (plot_df["simulated_offer_exposure_rate"].max() - plot_df["simulated_offer_exposure_rate"].min()) * 0.18,
)

y_pad = max(
    0.0002,
    (plot_df["approved_el_per_approved_dollar"].max() - plot_df["approved_el_per_approved_dollar"].min()) * 0.22,
)

ax.set_xlim(
    plot_df["simulated_offer_exposure_rate"].min() - x_pad,
    plot_df["simulated_offer_exposure_rate"].max() + x_pad,
)

ax.set_ylim(
    plot_df["approved_el_per_approved_dollar"].min() - y_pad,
    plot_df["approved_el_per_approved_dollar"].max() + y_pad,
)

ax.grid(True, linewidth=0.45, alpha=0.35)

ax.legend(
    title="Strategy posture",
    loc="best",
    fontsize=8,
    title_fontsize=9,
    frameon=True,
)

caption = (
    "Bubble size represents total approved amount. "
    "Dashed lines mark M2-01 baseline access and approved-EL density."
)

fig.text(
    0.5,
    0.015,
    "\n".join(textwrap.wrap(caption, width=120)),
    ha="center",
    va="bottom",
    fontsize=8.5,
)

fig.tight_layout(rect=[0.03, 0.06, 0.98, 0.96])


# =============================================================================
# 7. SAVE OUTPUTS
# =============================================================================

fig.savefig(OUTPUT_PNG, bbox_inches="tight")
fig.savefig(OUTPUT_SVG, bbox_inches="tight")
plt.close(fig)

print(f"Saved PNG: {OUTPUT_PNG}")
print(f"Saved SVG: {OUTPUT_SVG}")

print("\nChart data used:")
for _, row in plot_df.iterrows():
    print(
        f"{row['module2_run_id']:>5} | "
        f"{row['strategy_posture']:<24} | "
        f"Offer exposure: {row['simulated_offer_exposure_rate']:.2%} | "
        f"Approved EL / approved $: {row['approved_el_per_approved_dollar']:.2%} | "
        f"Approved amount: {approved_amount_billions(row['total_approved_amount'])}"
    )
```

This version is more README-stable because the chart will not change unless you deliberately edit the hardcoded evidence values.
<!-- END_MESSAGE C040-M02332 -->


---

<a id="c040-m02334"></a>

### C040-M02334

**Andrew** · 2026-05-26T12:08:18.262000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02334 -->
Is there a benefit to show manual review reduction in this chart, since it is exactly equal to baseline?  also take a look at the output.  is there a reason some bubbles are bigger vs smaller? and some of the descriptive text overlaps.  otherwise this is looking great!
<!-- END_MESSAGE C040-M02334 -->


**Attachments in export:** `module2_strategy_frontier_scatter_baseline_population.png`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c040-m02336"></a>

### C040-M02336

**ChatGPT** · 2026-05-26T12:12:44.148254-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02336 -->
Yes — the chart is close, but I would make three refinements before using it in the README.

## 1. I would remove M2-07 from this scatter

There is not much benefit to showing **Manual Review Reduction** on this specific chart because it sits exactly on top of the baseline:

```text
M2-01 Baseline:
    simulated_offer_exposure_rate = 59.524%
    approved_el_per_approved_dollar = 1.5299%

M2-07 Review Reduction:
    simulated_offer_exposure_rate = 59.524%
    approved_el_per_approved_dollar = 1.5299%
```

That does **not** mean M2-07 has no strategic effect. It means its effect is not visible on this chart’s two dimensions. M2-07 is an **operational burden / final-resolution strategy**, not an access-versus-approved-risk-density strategy. It changes manual-review handling, failed-counteroffer resolution, and no-offer posture, but it does not materially change the approved positive-offer book. For this scatter, it creates overlap and distracts from the frontier story.

I would handle M2-07 elsewhere with a better chart:

```text
Manual Review Burden Chart:
    x-axis: manual_review_rate
    y-axis: decline_rate
    highlight: M2-01 vs M2-07
```

or:

```text
Decision Outcome Mix:
    stacked bars for APPROVE / COUNTEROFFER / MANUAL_REVIEW / DECLINE
```

For the README hero scatter, I would keep:

```text
M2-01 Baseline
M2-02 Tighter Risk
M2-03 Growth
M2-04 Affordability
M2-05 Selective CO
M2-06 Product Guardrails
M2-37 Aggressive CO
```

That gives you seven points, no exact duplicate, and a cleaner frontier.

## 2. Bubble size means total approved amount

Yes — the bubble sizes are intentional. They represent:

```text
total_approved_amount
```

So a bigger bubble means the strategy produced a larger approved exposure book.

That is useful because the scatter otherwise only shows:

```text
x-axis = access / positive offer exposure
y-axis = approved Expected Loss density
```

Bubble size adds the third business dimension:

```text
approved exposure scale
```

For example:

```text
M2-03 Growth
    larger bubble because it expands approved amount

M2-05 Selective CO
    smaller bubble because it reduces approved amount / access

M2-02 Tighter Risk
    lower y-position because approved EL density improves
```

That said, the bubble-size range is a little too visually dominant right now. I would keep bubble size, but compress the range. In the code, change:

```python
min_size=280,
max_size=900,
```

to something like:

```python
min_size=260,
max_size=620,
```

That keeps the approved-amount cue without making the chart feel like a bubble-size story.

## 3. The overlapping text is fixable

The main overlap / crowding issues are:

```text
M2-01 and M2-07 overlap exactly.
M2-05 and M2-06 labels crowd each other.
The top-right growth annotation is too close to the plot boundary.
The lower M2-02 annotation is clipped by the x-axis / caption area.
The legend takes a lot of plot space.
```

The cleanest improvements:

```text
1. Remove M2-07 from this chart.
2. Move the legend outside the plot or remove it entirely.
3. Compress bubble sizes.
4. Replace long arrow annotations with short quadrant callouts.
5. Increase bottom margin.
6. Move M2-02 annotation inside the plot area instead of below it.
```

My recommended design change: keep point labels, but remove most arrows. The points are already labeled. The chart only needs one or two callouts.

## Recommended code edits

### Remove M2-07

Change:

```python
FRONTIER_DATA = [
    ...
    {
        "module2_run_id": "M2-07",
        ...
    },
    ...
]
```

Remove the entire M2-07 dictionary.

Then change:

```python
RUN_ORDER = [
    "M2-01",
    "M2-02",
    "M2-03",
    "M2-04",
    "M2-05",
    "M2-06",
    "M2-07",
    "M2-37",
]
```

to:

```python
RUN_ORDER = [
    "M2-01",
    "M2-02",
    "M2-03",
    "M2-04",
    "M2-05",
    "M2-06",
    "M2-37",
]
```

And remove the M2-07 offset:

```python
"M2-07": (18, 18),
```

### Compress bubble sizes

Change:

```python
min_size: float = 280,
max_size: float = 900,
```

to:

```python
min_size: float = 260,
max_size: float = 620,
```

### Use cleaner label offsets

Use this updated offset block:

```python
LABEL_OFFSETS = {
    "M2-01": (-48, 18),
    "M2-02": (-58, 22),
    "M2-03": (42, 2),
    "M2-04": (-58, 16),
    "M2-05": (-66, -26),
    "M2-06": (46, -28),
    "M2-37": (62, -4),
}
```

This should reduce the M2-05 / M2-06 collision and keep M2-02 from being clipped.

### Move the legend outside the plot

Replace:

```python
ax.legend(
    title="Strategy posture",
    loc="best",
    fontsize=8,
    title_fontsize=9,
    frameon=True,
)
```

with:

```python
ax.legend(
    title="Strategy posture",
    loc="center left",
    bbox_to_anchor=(1.02, 0.5),
    fontsize=8,
    title_fontsize=9,
    frameon=True,
)
```

Then change:

```python
fig.tight_layout(rect=[0.03, 0.06, 0.98, 0.96])
```

to:

```python
fig.tight_layout(rect=[0.03, 0.08, 0.82, 0.94])
```

That gives the legend its own right-side space.

### Replace the three arrow annotations with two cleaner callouts

I would remove these blocks:

```python
ax.annotate("Baseline\nreference", ...)
ax.annotate("Lower access,\ncleaner risk density", ...)
ax.annotate("More access,\nlarger exposure tradeoff", ...)
```

and replace with static text boxes:

```python
ax.text(
    0.02,
    0.04,
    "Lower access,\ncleaner approved-risk density",
    transform=ax.transAxes,
    fontsize=9,
    va="bottom",
    ha="left",
    bbox={"boxstyle": "round,pad=0.35", "facecolor": "white", "alpha": 0.85},
)

ax.text(
    0.98,
    0.96,
    "Higher access,\nhigher approved-risk density",
    transform=ax.transAxes,
    fontsize=9,
    va="top",
    ha="right",
    bbox={"boxstyle": "round,pad=0.35", "facecolor": "white", "alpha": 0.85},
)
```

This avoids arrows crossing labels and lets the baseline crosshair do the explanation.

## Revised README interpretation

The chart should tell this story:

```text
M2-01 is the baseline anchor.
M2-02 moves down and left: lower access, cleaner approved-risk density.
M2-03 moves up and right: more access, higher approved-risk density.
M2-04 moves left but not clearly down: affordability discipline is not the same as risk discipline.
M2-05 and M2-06 move left/down: selective counteroffer and product guardrails constrain access while improving approved-risk density.
M2-37 moves right/down: aggressive counteroffer expansion increases access relative to baseline while improving approved-risk density, making it an especially interesting governed counteroffer strategy.
```

That last point is powerful. M2-37 being to the **right and below** the baseline crosshair is visually interesting because it suggests a governed counteroffer path that can improve access without worsening approved EL density. That is exactly the kind of insight this chart is meant to surface.

So yes: remove M2-07 from this chart, keep bubble size but compress it, move the legend outside, and simplify annotations.
<!-- END_MESSAGE C040-M02336 -->


---

<a id="c040-m02338"></a>

### C040-M02338

**Andrew** · 2026-05-26T12:21:01.371000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02338 -->
give me updated python code in a full copy paste with those edits incorporated.
<!-- END_MESSAGE C040-M02338 -->


---

<a id="c040-m02340"></a>

### C040-M02340

**ChatGPT** · 2026-05-26T12:24:50.527686-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02340 -->
Below is the updated full-copy Python script with the refinements incorporated:

```python
"""
Module 2 README Chart 1
Strategy Frontier Scatter: Access vs Approved Expected-Loss Density

This version uses hardcoded final-campaign Section 15.7A values.

Chart thesis:
    Same synthetic applicant population.
    Different governed Module 2 strategy postures.
    Visible access / risk-density / approved-exposure tradeoffs.

Data scope:
    module1_scenario_name = BASELINE_V2
    population_id = BASE_POPULATION_V1

Key design choices:
    1. M2-07 Manual Review Reduction is intentionally excluded because it sits
       exactly on top of M2-01 on this chart's two dimensions:
           simulated_offer_exposure_rate
           approved_el_per_approved_dollar

       M2-07 is better shown in an operational-burden chart, such as
       manual_review_rate vs decline_rate or a decision outcome mix chart.

    2. Bubble size represents total approved amount, but the size range is
       compressed so the chart remains primarily about the access / risk-density
       frontier.

    3. Baseline crosshair lines are retained so every challenger can be read
       relative to M2-01.

    4. Legend is moved outside the plot to reduce congestion.

    5. Long arrow annotations are replaced with simple quadrant-style callouts.

Output:
    assets/module2_strategy_frontier_scatter_baseline_population.png
    assets/module2_strategy_frontier_scatter_baseline_population.svg
"""

from __future__ import annotations

from pathlib import Path
import textwrap

import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.ticker as mtick


# =============================================================================
# 1. OUTPUT SETTINGS
# =============================================================================

OUTPUT_DIR = Path("assets")
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

OUTPUT_PNG = OUTPUT_DIR / "module2_strategy_frontier_scatter_baseline_population.png"
OUTPUT_SVG = OUTPUT_DIR / "module2_strategy_frontier_scatter_baseline_population.svg"


# =============================================================================
# 2. HARDCODED SECTION 15.7A FRONTIER DATA
# =============================================================================

FRONTIER_DATA = [
    {
        "module2_run_id": "M2-01",
        "short_label": "M2-01\nBaseline",
        "strategy_posture": "Baseline Reference",
        "strategy_name": "BASELINE_STRATEGY",
        "module1_scenario_name": "BASELINE_V2",
        "population_id": "BASE_POPULATION_V1",
        "simulated_offer_exposure_rate": 0.595240,
        "approved_el_per_approved_dollar": 0.0152985203377187,
        "total_approved_amount": 3827278124.10,
    },
    {
        "module2_run_id": "M2-02",
        "short_label": "M2-02\nTighter Risk",
        "strategy_posture": "Risk Discipline",
        "strategy_name": "TIGHTER_SYNTHETIC_RISK_STRATEGY",
        "module1_scenario_name": "BASELINE_V2",
        "population_id": "BASE_POPULATION_V1",
        "simulated_offer_exposure_rate": 0.570760,
        "approved_el_per_approved_dollar": 0.0139552919132960,
        "total_approved_amount": 3677999148.76,
    },
    {
        "module2_run_id": "M2-03",
        "short_label": "M2-03\nGrowth",
        "strategy_posture": "Growth",
        "strategy_name": "GROWTH_ORIENTED_STRATEGY",
        "module1_scenario_name": "BASELINE_V2",
        "population_id": "BASE_POPULATION_V1",
        "simulated_offer_exposure_rate": 0.622500,
        "approved_el_per_approved_dollar": 0.0165351528346220,
        "total_approved_amount": 4065698262.08,
    },
    {
        "module2_run_id": "M2-04",
        "short_label": "M2-04\nAffordability",
        "strategy_posture": "Affordability / Mixed",
        "strategy_name": "TIGHTER_AFFORDABILITY_STRATEGY",
        "module1_scenario_name": "BASELINE_V2",
        "population_id": "BASE_POPULATION_V1",
        "simulated_offer_exposure_rate": 0.565520,
        "approved_el_per_approved_dollar": 0.0154141022464799,
        "total_approved_amount": 3569433393.72,
    },
    {
        "module2_run_id": "M2-05",
        "short_label": "M2-05\nSelective CO",
        "strategy_posture": "Counteroffer Management",
        "strategy_name": "SELECTIVE_COUNTEROFFER_FEASIBILITY_STRATEGY",
        "module1_scenario_name": "BASELINE_V2",
        "population_id": "BASE_POPULATION_V1",
        "simulated_offer_exposure_rate": 0.525820,
        "approved_el_per_approved_dollar": 0.0145871986070696,
        "total_approved_amount": 3463854014.82,
    },
    {
        "module2_run_id": "M2-06",
        "short_label": "M2-06\nProduct\nGuardrails",
        "strategy_posture": "Product Guardrail",
        "strategy_name": "PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY",
        "module1_scenario_name": "BASELINE_V2",
        "population_id": "BASE_POPULATION_V1",
        "simulated_offer_exposure_rate": 0.512600,
        "approved_el_per_approved_dollar": 0.0145885274000267,
        "total_approved_amount": 3716432230.48,
    },
    {
        "module2_run_id": "M2-37",
        "short_label": "M2-37\nAggressive CO",
        "strategy_posture": "Counteroffer Management",
        "strategy_name": "AGGRESSIVE_COUNTEROFFER_EXPANSION_STRATEGY",
        "module1_scenario_name": "BASELINE_V2",
        "population_id": "BASE_POPULATION_V1",
        "simulated_offer_exposure_rate": 0.607020,
        "approved_el_per_approved_dollar": 0.0149365120481094,
        "total_approved_amount": 3639742514.82,
    },
]


# =============================================================================
# 3. LABEL AND LAYOUT SETTINGS
# =============================================================================

RUN_ORDER = [
    "M2-01",
    "M2-02",
    "M2-03",
    "M2-04",
    "M2-05",
    "M2-06",
    "M2-37",
]

# Manual label offsets in points. Tune these locally if you want slightly
# different label positions after rendering.
LABEL_OFFSETS = {
    "M2-01": (-48, 18),
    "M2-02": (-58, 22),
    "M2-03": (42, 2),
    "M2-04": (-58, 16),
    "M2-05": (-66, -26),
    "M2-06": (46, -28),
    "M2-37": (62, -4),
}


# =============================================================================
# 4. HELPER FUNCTIONS
# =============================================================================

def normalize_bubble_size(
    series: pd.Series,
    min_size: float = 260,
    max_size: float = 620,
) -> pd.Series:
    """
    Convert total approved amount into restrained marker sizes.

    Bubble size is intentionally a secondary cue. The chart should mainly read
    as access versus approved Expected-Loss density.
    """
    min_val = series.min()
    max_val = series.max()

    if max_val == min_val:
        return pd.Series(
            [0.5 * (min_size + max_size)] * len(series),
            index=series.index,
        )

    return min_size + ((series - min_val) / (max_val - min_val)) * (max_size - min_size)


def approved_amount_billions(value: float) -> str:
    """Format approved amount for sanity-print output."""
    return f"${value / 1_000_000_000:.2f}B"


# =============================================================================
# 5. PREPARE DATA
# =============================================================================

plot_df = pd.DataFrame(FRONTIER_DATA)

plot_df["run_order"] = plot_df["module2_run_id"].map(
    {run_id: idx for idx, run_id in enumerate(RUN_ORDER)}
)

plot_df = plot_df.sort_values("run_order").reset_index(drop=True)

plot_df["bubble_size"] = normalize_bubble_size(plot_df["total_approved_amount"])

baseline = plot_df.loc[plot_df["module2_run_id"] == "M2-01"].iloc[0]
baseline_x = baseline["simulated_offer_exposure_rate"]
baseline_y = baseline["approved_el_per_approved_dollar"]


# =============================================================================
# 6. BUILD CHART
# =============================================================================

fig, ax = plt.subplots(figsize=(10.8, 6.4), dpi=160)

# Plot by simplified strategy posture. Matplotlib's default color cycle is used.
for posture, group in plot_df.groupby("strategy_posture", sort=False):
    ax.scatter(
        group["simulated_offer_exposure_rate"],
        group["approved_el_per_approved_dollar"],
        s=group["bubble_size"],
        alpha=0.78,
        label=posture,
    )

# Baseline crosshair.
ax.axvline(baseline_x, linestyle="--", linewidth=1.0, alpha=0.65)
ax.axhline(baseline_y, linestyle="--", linewidth=1.0, alpha=0.65)

# Point labels.
for _, row in plot_df.iterrows():
    run_id = row["module2_run_id"]
    offset = LABEL_OFFSETS.get(run_id, (8, 8))

    ax.annotate(
        row["short_label"],
        xy=(
            row["simulated_offer_exposure_rate"],
            row["approved_el_per_approved_dollar"],
        ),
        xytext=offset,
        textcoords="offset points",
        fontsize=8.5,
        ha="center",
        va="center",
        arrowprops={
            "arrowstyle": "-",
            "linewidth": 0.6,
            "alpha": 0.70,
            "shrinkA": 0,
            "shrinkB": 5,
        },
    )

# Quadrant-style callouts. These avoid long crossing arrows and keep the chart cleaner.
ax.text(
    0.02,
    0.04,
    "Lower access,\ncleaner approved-risk density",
    transform=ax.transAxes,
    fontsize=9,
    va="bottom",
    ha="left",
    bbox={
        "boxstyle": "round,pad=0.35",
        "facecolor": "white",
        "alpha": 0.85,
    },
)

ax.text(
    0.98,
    0.96,
    "Higher access,\nhigher approved-risk density",
    transform=ax.transAxes,
    fontsize=9,
    va="top",
    ha="right",
    bbox={
        "boxstyle": "round,pad=0.35",
        "facecolor": "white",
        "alpha": 0.85,
    },
)

# Titles.
ax.set_title(
    "Strategy Frontier: Access vs Approved Expected-Loss Density",
    fontsize=15,
    fontweight="bold",
    pad=16,
)

ax.text(
    0.5,
    1.015,
    "Baseline population only — same synthetic applicants, different governed strategy postures",
    transform=ax.transAxes,
    ha="center",
    va="bottom",
    fontsize=10,
)

# Axes.
ax.set_xlabel("Simulated Offer Exposure Rate", fontsize=11)
ax.set_ylabel("Approved EL per Approved Dollar", fontsize=11)

ax.xaxis.set_major_formatter(mtick.PercentFormatter(xmax=1.0))
ax.yaxis.set_major_formatter(mtick.PercentFormatter(xmax=1.0))

# Add a small margin around points.
x_pad = max(
    0.005,
    (
        plot_df["simulated_offer_exposure_rate"].max()
        - plot_df["simulated_offer_exposure_rate"].min()
    )
    * 0.18,
)

y_pad = max(
    0.0002,
    (
        plot_df["approved_el_per_approved_dollar"].max()
        - plot_df["approved_el_per_approved_dollar"].min()
    )
    * 0.22,
)

ax.set_xlim(
    plot_df["simulated_offer_exposure_rate"].min() - x_pad,
    plot_df["simulated_offer_exposure_rate"].max() + x_pad,
)

ax.set_ylim(
    plot_df["approved_el_per_approved_dollar"].min() - y_pad,
    plot_df["approved_el_per_approved_dollar"].max() + y_pad,
)

ax.grid(True, linewidth=0.45, alpha=0.35)

# Legend outside the plotting area to reduce congestion.
ax.legend(
    title="Strategy posture",
    loc="center left",
    bbox_to_anchor=(1.02, 0.5),
    fontsize=8,
    title_fontsize=9,
    frameon=True,
)

caption = (
    "Bubble size represents total approved amount. "
    "Dashed lines mark M2-01 baseline access and approved-EL density."
)

fig.text(
    0.5,
    0.015,
    "\n".join(textwrap.wrap(caption, width=120)),
    ha="center",
    va="bottom",
    fontsize=8.5,
)

# Right margin leaves room for the outside legend.
fig.tight_layout(rect=[0.03, 0.08, 0.82, 0.94])


# =============================================================================
# 7. SAVE OUTPUTS
# =============================================================================

fig.savefig(OUTPUT_PNG, bbox_inches="tight")
fig.savefig(OUTPUT_SVG, bbox_inches="tight")
plt.close(fig)

print(f"Saved PNG: {OUTPUT_PNG}")
print(f"Saved SVG: {OUTPUT_SVG}")

print("\nChart data used:")
for _, row in plot_df.iterrows():
    print(
        f"{row['module2_run_id']:>5} | "
        f"{row['strategy_posture']:<24} | "
        f"Offer exposure: {row['simulated_offer_exposure_rate']:.2%} | "
        f"Approved EL / approved $: {row['approved_el_per_approved_dollar']:.2%} | "
        f"Approved amount: {approved_amount_billions(row['total_approved_amount'])}"
    )
```

One README interpretation note I’d use with this version:

```text
Manual Review Reduction is intentionally not shown because it overlaps the baseline on access and approved-EL density. Its impact is operational — reducing review burden / changing final resolution — so it belongs in a separate decision-outcome or review-burden chart.
```
<!-- END_MESSAGE C040-M02340 -->


---

<a id="c040-m02342"></a>

### C040-M02342

**Andrew** · 2026-05-26T12:49:53.331000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02342 -->
put M2-06 Product Guardrails text above its brown dot.  Put M2-05 Selected CO text below its purple dot.  put M2-02 Tighter Risk text above its orange dot.  Move M2-4 Affordability and M2-01 Baseline text 5-10 degrees clockwise so they move just slightly move northeast.  Put M2-37 Aggressive CO text 10-15 degrees clockwise so it moves slightly southeast. Put M2-03 Growth text below its green dot.  Also, I understand now that bubble size means total_approved_amount but the chart doesn't necessarily say that.  I wonder if we can use the empty space below or above the legend to add some clarity.  provide back full updated python copy paste.
<!-- END_MESSAGE C040-M02342 -->


---

<a id="c040-m02343"></a>

### C040-M02343

**Andrew** · 2026-05-26T12:53:28.840000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02343 -->
why are you generating an image.  we are doing this in python!  update python code to: put M2-06 Product Guardrails text above its brown dot. Put M2-05 Selected CO text below its purple dot. put M2-02 Tighter Risk text above its orange dot. Move M2-4 Affordability and M2-01 Baseline text 5-10 degrees clockwise so they move just slightly move northeast. Put M2-37 Aggressive CO text 10-15 degrees clockwise so it moves slightly southeast. Put M2-03 Growth text below its green dot. Also, I understand now that bubble size means total_approved_amount but the chart doesn't necessarily say that. I wonder if we can use the empty space below or above the legend to add some clarity. provide back full updated python copy paste.
<!-- END_MESSAGE C040-M02343 -->


---

<a id="c040-m02345"></a>

### C040-M02345

**ChatGPT** · 2026-05-26T12:58:46.176254-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02345 -->
Below is the full updated Python copy-paste with your requested label-position changes and a right-side explanatory note clarifying that bubble size represents `total_approved_amount`.

```python
"""
Module 2 README Chart 1
Strategy Frontier Scatter: Access vs Approved Expected-Loss Density

This version uses hardcoded final-campaign Section 15.7A values.

Chart thesis:
    Same synthetic applicant population.
    Different governed Module 2 strategy postures.
    Visible access / risk-density / approved-exposure tradeoffs.

Data scope:
    module1_scenario_name = BASELINE_V2
    population_id = BASE_POPULATION_V1

Key design choices:
    1. M2-07 Manual Review Reduction is intentionally excluded because it sits
       exactly on top of M2-01 on this chart's two dimensions:
           simulated_offer_exposure_rate
           approved_el_per_approved_dollar

       M2-07 is better shown in an operational-burden chart, such as
       manual_review_rate vs decline_rate or a decision outcome mix chart.

    2. Bubble size represents total approved amount, but the size range is
       compressed so the chart remains primarily about the access / risk-density
       frontier.

    3. Baseline crosshair lines are retained so every challenger can be read
       relative to M2-01.

    4. Legend and bubble-size explanation are placed outside the plot area to
       reduce congestion.

    5. Long arrow annotations are replaced with simple quadrant-style callouts.

Output:
    assets/module2_strategy_frontier_scatter_baseline_population.png
    assets/module2_strategy_frontier_scatter_baseline_population.svg
"""

from __future__ import annotations

from pathlib import Path
import textwrap

import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.ticker as mtick


# =============================================================================
# 1. OUTPUT SETTINGS
# =============================================================================

OUTPUT_DIR = Path("assets")
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

OUTPUT_PNG = OUTPUT_DIR / "module2_strategy_frontier_scatter_baseline_population.png"
OUTPUT_SVG = OUTPUT_DIR / "module2_strategy_frontier_scatter_baseline_population.svg"


# =============================================================================
# 2. HARDCODED SECTION 15.7A FRONTIER DATA
# =============================================================================

FRONTIER_DATA = [
    {
        "module2_run_id": "M2-01",
        "short_label": "M2-01\nBaseline",
        "strategy_posture": "Baseline Reference",
        "strategy_name": "BASELINE_STRATEGY",
        "module1_scenario_name": "BASELINE_V2",
        "population_id": "BASE_POPULATION_V1",
        "simulated_offer_exposure_rate": 0.595240,
        "approved_el_per_approved_dollar": 0.0152985203377187,
        "total_approved_amount": 3827278124.10,
    },
    {
        "module2_run_id": "M2-02",
        "short_label": "M2-02\nTighter Risk",
        "strategy_posture": "Risk Discipline",
        "strategy_name": "TIGHTER_SYNTHETIC_RISK_STRATEGY",
        "module1_scenario_name": "BASELINE_V2",
        "population_id": "BASE_POPULATION_V1",
        "simulated_offer_exposure_rate": 0.570760,
        "approved_el_per_approved_dollar": 0.0139552919132960,
        "total_approved_amount": 3677999148.76,
    },
    {
        "module2_run_id": "M2-03",
        "short_label": "M2-03\nGrowth",
        "strategy_posture": "Growth",
        "strategy_name": "GROWTH_ORIENTED_STRATEGY",
        "module1_scenario_name": "BASELINE_V2",
        "population_id": "BASE_POPULATION_V1",
        "simulated_offer_exposure_rate": 0.622500,
        "approved_el_per_approved_dollar": 0.0165351528346220,
        "total_approved_amount": 4065698262.08,
    },
    {
        "module2_run_id": "M2-04",
        "short_label": "M2-04\nAffordability",
        "strategy_posture": "Affordability / Mixed",
        "strategy_name": "TIGHTER_AFFORDABILITY_STRATEGY",
        "module1_scenario_name": "BASELINE_V2",
        "population_id": "BASE_POPULATION_V1",
        "simulated_offer_exposure_rate": 0.565520,
        "approved_el_per_approved_dollar": 0.0154141022464799,
        "total_approved_amount": 3569433393.72,
    },
    {
        "module2_run_id": "M2-05",
        "short_label": "M2-05\nSelective CO",
        "strategy_posture": "Counteroffer Management",
        "strategy_name": "SELECTIVE_COUNTEROFFER_FEASIBILITY_STRATEGY",
        "module1_scenario_name": "BASELINE_V2",
        "population_id": "BASE_POPULATION_V1",
        "simulated_offer_exposure_rate": 0.525820,
        "approved_el_per_approved_dollar": 0.0145871986070696,
        "total_approved_amount": 3463854014.82,
    },
    {
        "module2_run_id": "M2-06",
        "short_label": "M2-06\nProduct\nGuardrails",
        "strategy_posture": "Product Guardrail",
        "strategy_name": "PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY",
        "module1_scenario_name": "BASELINE_V2",
        "population_id": "BASE_POPULATION_V1",
        "simulated_offer_exposure_rate": 0.512600,
        "approved_el_per_approved_dollar": 0.0145885274000267,
        "total_approved_amount": 3716432230.48,
    },
    {
        "module2_run_id": "M2-37",
        "short_label": "M2-37\nAggressive CO",
        "strategy_posture": "Counteroffer Management",
        "strategy_name": "AGGRESSIVE_COUNTEROFFER_EXPANSION_STRATEGY",
        "module1_scenario_name": "BASELINE_V2",
        "population_id": "BASE_POPULATION_V1",
        "simulated_offer_exposure_rate": 0.607020,
        "approved_el_per_approved_dollar": 0.0149365120481094,
        "total_approved_amount": 3639742514.82,
    },
]


# =============================================================================
# 3. LABEL AND LAYOUT SETTINGS
# =============================================================================

RUN_ORDER = [
    "M2-01",
    "M2-02",
    "M2-03",
    "M2-04",
    "M2-05",
    "M2-06",
    "M2-37",
]

# Manual label offsets in points.
#
# User-directed layout:
#   M2-06 Product Guardrails: above its dot.
#   M2-05 Selective CO: below its dot.
#   M2-02 Tighter Risk: above its dot.
#   M2-04 Affordability: slightly northeast.
#   M2-01 Baseline: slightly northeast.
#   M2-37 Aggressive CO: slightly southeast.
#   M2-03 Growth: below its dot.
LABEL_OFFSETS = {
    "M2-01": (34, 22),
    "M2-02": (0, 38),
    "M2-03": (0, -42),
    "M2-04": (38, 24),
    "M2-05": (0, -42),
    "M2-06": (0, 42),
    "M2-37": (70, -22),
}


# =============================================================================
# 4. HELPER FUNCTIONS
# =============================================================================

def normalize_bubble_size(
    series: pd.Series,
    min_size: float = 260,
    max_size: float = 620,
) -> pd.Series:
    """
    Convert total approved amount into restrained marker sizes.

    Bubble size is intentionally a secondary cue. The chart should mainly read
    as access versus approved Expected-Loss density.
    """
    min_val = series.min()
    max_val = series.max()

    if max_val == min_val:
        return pd.Series(
            [0.5 * (min_size + max_size)] * len(series),
            index=series.index,
        )

    return min_size + ((series - min_val) / (max_val - min_val)) * (max_size - min_size)


def approved_amount_billions(value: float) -> str:
    """Format approved amount for sanity-print output."""
    return f"${value / 1_000_000_000:.2f}B"


# =============================================================================
# 5. PREPARE DATA
# =============================================================================

plot_df = pd.DataFrame(FRONTIER_DATA)

plot_df["run_order"] = plot_df["module2_run_id"].map(
    {run_id: idx for idx, run_id in enumerate(RUN_ORDER)}
)

plot_df = plot_df.sort_values("run_order").reset_index(drop=True)

plot_df["bubble_size"] = normalize_bubble_size(plot_df["total_approved_amount"])

baseline = plot_df.loc[plot_df["module2_run_id"] == "M2-01"].iloc[0]
baseline_x = baseline["simulated_offer_exposure_rate"]
baseline_y = baseline["approved_el_per_approved_dollar"]


# =============================================================================
# 6. BUILD CHART
# =============================================================================

fig, ax = plt.subplots(figsize=(11.2, 6.5), dpi=160)

# Plot by simplified strategy posture. Matplotlib's default color cycle is used.
for posture, group in plot_df.groupby("strategy_posture", sort=False):
    ax.scatter(
        group["simulated_offer_exposure_rate"],
        group["approved_el_per_approved_dollar"],
        s=group["bubble_size"],
        alpha=0.78,
        label=posture,
    )

# Baseline crosshair.
ax.axvline(baseline_x, linestyle="--", linewidth=1.0, alpha=0.65)
ax.axhline(baseline_y, linestyle="--", linewidth=1.0, alpha=0.65)

# Point labels.
for _, row in plot_df.iterrows():
    run_id = row["module2_run_id"]
    offset = LABEL_OFFSETS.get(run_id, (8, 8))

    ax.annotate(
        row["short_label"],
        xy=(
            row["simulated_offer_exposure_rate"],
            row["approved_el_per_approved_dollar"],
        ),
        xytext=offset,
        textcoords="offset points",
        fontsize=8.5,
        ha="center",
        va="center",
        arrowprops={
            "arrowstyle": "-",
            "linewidth": 0.6,
            "alpha": 0.70,
            "shrinkA": 0,
            "shrinkB": 5,
        },
    )

# Quadrant-style callouts.
# Placed away from the labeled points to avoid overlap.
ax.text(
    0.02,
    0.04,
    "Lower access,\ncleaner approved-risk density",
    transform=ax.transAxes,
    fontsize=9,
    va="bottom",
    ha="left",
    bbox={
        "boxstyle": "round,pad=0.35",
        "alpha": 0.85,
    },
)

ax.text(
    0.66,
    0.96,
    "Higher access,\nhigher approved-risk density",
    transform=ax.transAxes,
    fontsize=9,
    va="top",
    ha="left",
    bbox={
        "boxstyle": "round,pad=0.35",
        "alpha": 0.85,
    },
)

# Titles.
ax.set_title(
    "Strategy Frontier: Access vs Approved Expected-Loss Density",
    fontsize=15,
    fontweight="bold",
    pad=16,
)

ax.text(
    0.5,
    1.015,
    "Baseline population only — same synthetic applicants, different governed strategy postures",
    transform=ax.transAxes,
    ha="center",
    va="bottom",
    fontsize=10,
)

# Axes.
ax.set_xlabel("Simulated Offer Exposure Rate", fontsize=11)
ax.set_ylabel("Approved EL per Approved Dollar", fontsize=11)

ax.xaxis.set_major_formatter(mtick.PercentFormatter(xmax=1.0))
ax.yaxis.set_major_formatter(mtick.PercentFormatter(xmax=1.0))

# Add a small margin around points.
x_pad = max(
    0.005,
    (
        plot_df["simulated_offer_exposure_rate"].max()
        - plot_df["simulated_offer_exposure_rate"].min()
    )
    * 0.18,
)

y_pad = max(
    0.0002,
    (
        plot_df["approved_el_per_approved_dollar"].max()
        - plot_df["approved_el_per_approved_dollar"].min()
    )
    * 0.22,
)

ax.set_xlim(
    plot_df["simulated_offer_exposure_rate"].min() - x_pad,
    plot_df["simulated_offer_exposure_rate"].max() + x_pad,
)

ax.set_ylim(
    plot_df["approved_el_per_approved_dollar"].min() - y_pad,
    plot_df["approved_el_per_approved_dollar"].max() + y_pad,
)

ax.grid(True, linewidth=0.45, alpha=0.35)

# Strategy legend outside the plotting area.
ax.legend(
    title="Strategy posture",
    loc="center left",
    bbox_to_anchor=(1.02, 0.62),
    fontsize=8,
    title_fontsize=9,
    frameon=True,
)

# Bubble-size explanation in the open space under the legend.
ax.text(
    1.02,
    0.26,
    "Bubble size\n= total approved amount\n\nLarger circle\n= larger approved book",
    transform=ax.transAxes,
    fontsize=8.5,
    va="top",
    ha="left",
    bbox={
        "boxstyle": "round,pad=0.45",
        "alpha": 0.85,
    },
)

caption = (
    "Dashed lines mark M2-01 baseline access and approved-EL density. "
    "Bubble size represents total approved amount."
)

fig.text(
    0.5,
    0.015,
    "\n".join(textwrap.wrap(caption, width=120)),
    ha="center",
    va="bottom",
    fontsize=8.5,
)

# Right margin leaves room for the outside legend and bubble-size explanation.
fig.tight_layout(rect=[0.03, 0.08, 0.78, 0.94])


# =============================================================================
# 7. SAVE OUTPUTS
# =============================================================================

fig.savefig(OUTPUT_PNG, bbox_inches="tight")
fig.savefig(OUTPUT_SVG, bbox_inches="tight")
plt.close(fig)

print(f"Saved PNG: {OUTPUT_PNG}")
print(f"Saved SVG: {OUTPUT_SVG}")

print("\nChart data used:")
for _, row in plot_df.iterrows():
    print(
        f"{row['module2_run_id']:>5} | "
        f"{row['strategy_posture']:<24} | "
        f"Offer exposure: {row['simulated_offer_exposure_rate']:.2%} | "
        f"Approved EL / approved $: {row['approved_el_per_approved_dollar']:.2%} | "
        f"Approved amount: {approved_amount_billions(row['total_approved_amount'])}"
    )
```
<!-- END_MESSAGE C040-M02345 -->


---

<a id="c040-m02347"></a>

### C040-M02347

**Andrew** · 2026-05-26T13:08:52.646000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02347 -->
very close! I love the new design.  only remaining changes to python code (do not provide image - only full updated python code). 1) Add total_approved_amount to the text descriptions - for example.  change M2-01 Baseline text to M2-01 Baseline $3.83B ; 2) Adjust M2-37 Aggressive CO text to be more below and to the right of its purple dot.  It is currently overlapping the chart box outline.  
<!-- END_MESSAGE C040-M02347 -->


---

<a id="c040-m02350"></a>

### C040-M02350

**ChatGPT** · 2026-05-26T13:13:32.900956-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02350 -->
```python
"""
Module 2 README Chart 1
Strategy Frontier Scatter: Access vs Approved Expected-Loss Density

This version uses hardcoded final-campaign Section 15.7A values.

Chart thesis:
    Same synthetic applicant population.
    Different governed Module 2 strategy postures.
    Visible access / risk-density / approved-exposure tradeoffs.

Data scope:
    module1_scenario_name = BASELINE_V2
    population_id = BASE_POPULATION_V1

Key design choices:
    1. M2-07 Manual Review Reduction is intentionally excluded because it sits
       exactly on top of M2-01 on this chart's two dimensions:
           simulated_offer_exposure_rate
           approved_el_per_approved_dollar

       M2-07 is better shown in an operational-burden chart, such as
       manual_review_rate vs decline_rate or a decision outcome mix chart.

    2. Bubble size represents total approved amount, but the size range is
       compressed so the chart remains primarily about the access / risk-density
       frontier.

    3. Total approved amount is also printed directly in each point label so the
       bubble-size encoding is immediately understandable.

    4. Baseline crosshair lines are retained so every challenger can be read
       relative to M2-01.

    5. Legend and bubble-size explanation are placed outside the plot area to
       reduce congestion.

    6. Long arrow annotations are replaced with simple quadrant-style callouts.

Output:
    assets/module2_strategy_frontier_scatter_baseline_population.png
    assets/module2_strategy_frontier_scatter_baseline_population.svg
"""

from __future__ import annotations

from pathlib import Path
import textwrap

import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.ticker as mtick


# =============================================================================
# 1. OUTPUT SETTINGS
# =============================================================================

OUTPUT_DIR = Path("assets")
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

OUTPUT_PNG = OUTPUT_DIR / "module2_strategy_frontier_scatter_baseline_population.png"
OUTPUT_SVG = OUTPUT_DIR / "module2_strategy_frontier_scatter_baseline_population.svg"


# =============================================================================
# 2. HARDCODED SECTION 15.7A FRONTIER DATA
# =============================================================================

FRONTIER_DATA = [
    {
        "module2_run_id": "M2-01",
        "base_label": "M2-01\nBaseline",
        "strategy_posture": "Baseline Reference",
        "strategy_name": "BASELINE_STRATEGY",
        "module1_scenario_name": "BASELINE_V2",
        "population_id": "BASE_POPULATION_V1",
        "simulated_offer_exposure_rate": 0.595240,
        "approved_el_per_approved_dollar": 0.0152985203377187,
        "total_approved_amount": 3827278124.10,
    },
    {
        "module2_run_id": "M2-02",
        "base_label": "M2-02\nTighter Risk",
        "strategy_posture": "Risk Discipline",
        "strategy_name": "TIGHTER_SYNTHETIC_RISK_STRATEGY",
        "module1_scenario_name": "BASELINE_V2",
        "population_id": "BASE_POPULATION_V1",
        "simulated_offer_exposure_rate": 0.570760,
        "approved_el_per_approved_dollar": 0.0139552919132960,
        "total_approved_amount": 3677999148.76,
    },
    {
        "module2_run_id": "M2-03",
        "base_label": "M2-03\nGrowth",
        "strategy_posture": "Growth",
        "strategy_name": "GROWTH_ORIENTED_STRATEGY",
        "module1_scenario_name": "BASELINE_V2",
        "population_id": "BASE_POPULATION_V1",
        "simulated_offer_exposure_rate": 0.622500,
        "approved_el_per_approved_dollar": 0.0165351528346220,
        "total_approved_amount": 4065698262.08,
    },
    {
        "module2_run_id": "M2-04",
        "base_label": "M2-04\nAffordability",
        "strategy_posture": "Affordability / Mixed",
        "strategy_name": "TIGHTER_AFFORDABILITY_STRATEGY",
        "module1_scenario_name": "BASELINE_V2",
        "population_id": "BASE_POPULATION_V1",
        "simulated_offer_exposure_rate": 0.565520,
        "approved_el_per_approved_dollar": 0.0154141022464799,
        "total_approved_amount": 3569433393.72,
    },
    {
        "module2_run_id": "M2-05",
        "base_label": "M2-05\nSelective CO",
        "strategy_posture": "Counteroffer Management",
        "strategy_name": "SELECTIVE_COUNTEROFFER_FEASIBILITY_STRATEGY",
        "module1_scenario_name": "BASELINE_V2",
        "population_id": "BASE_POPULATION_V1",
        "simulated_offer_exposure_rate": 0.525820,
        "approved_el_per_approved_dollar": 0.0145871986070696,
        "total_approved_amount": 3463854014.82,
    },
    {
        "module2_run_id": "M2-06",
        "base_label": "M2-06\nProduct\nGuardrails",
        "strategy_posture": "Product Guardrail",
        "strategy_name": "PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY",
        "module1_scenario_name": "BASELINE_V2",
        "population_id": "BASE_POPULATION_V1",
        "simulated_offer_exposure_rate": 0.512600,
        "approved_el_per_approved_dollar": 0.0145885274000267,
        "total_approved_amount": 3716432230.48,
    },
    {
        "module2_run_id": "M2-37",
        "base_label": "M2-37\nAggressive CO",
        "strategy_posture": "Counteroffer Management",
        "strategy_name": "AGGRESSIVE_COUNTEROFFER_EXPANSION_STRATEGY",
        "module1_scenario_name": "BASELINE_V2",
        "population_id": "BASE_POPULATION_V1",
        "simulated_offer_exposure_rate": 0.607020,
        "approved_el_per_approved_dollar": 0.0149365120481094,
        "total_approved_amount": 3639742514.82,
    },
]


# =============================================================================
# 3. LABEL AND LAYOUT SETTINGS
# =============================================================================

RUN_ORDER = [
    "M2-01",
    "M2-02",
    "M2-03",
    "M2-04",
    "M2-05",
    "M2-06",
    "M2-37",
]

# Manual label positions.
#
# User-directed layout:
#   M2-06 Product Guardrails: above its dot.
#   M2-05 Selective CO: below its dot.
#   M2-02 Tighter Risk: above its dot.
#   M2-04 Affordability: slightly northeast.
#   M2-01 Baseline: slightly northeast.
#   M2-37 Aggressive CO: more below and to the right of its dot.
#   M2-03 Growth: below its dot.
#
# NOTE:
#   These offsets are in display points, not data units.
LABEL_STYLES = {
    "M2-01": {"offset": (38, 28), "ha": "center", "va": "center"},
    "M2-02": {"offset": (0, 54), "ha": "center", "va": "center"},
    "M2-03": {"offset": (0, -58), "ha": "center", "va": "center"},
    "M2-04": {"offset": (42, 30), "ha": "center", "va": "center"},
    "M2-05": {"offset": (0, -52), "ha": "center", "va": "center"},
    "M2-06": {"offset": (0, 56), "ha": "center", "va": "center"},
    "M2-37": {"offset": (42, -48), "ha": "left", "va": "top"},
}


# =============================================================================
# 4. HELPER FUNCTIONS
# =============================================================================

def normalize_bubble_size(
    series: pd.Series,
    min_size: float = 260,
    max_size: float = 620,
) -> pd.Series:
    """
    Convert total approved amount into restrained marker sizes.

    Bubble size is intentionally a secondary cue. The chart should mainly read
    as access versus approved Expected-Loss density.
    """
    min_val = series.min()
    max_val = series.max()

    if max_val == min_val:
        return pd.Series(
            [0.5 * (min_size + max_size)] * len(series),
            index=series.index,
        )

    return min_size + ((series - min_val) / (max_val - min_val)) * (max_size - min_size)


def approved_amount_billions(value: float) -> str:
    """Format approved amount for labels and sanity-print output."""
    return f"${value / 1_000_000_000:.2f}B"


# =============================================================================
# 5. PREPARE DATA
# =============================================================================

plot_df = pd.DataFrame(FRONTIER_DATA)

plot_df["run_order"] = plot_df["module2_run_id"].map(
    {run_id: idx for idx, run_id in enumerate(RUN_ORDER)}
)

plot_df = plot_df.sort_values("run_order").reset_index(drop=True)

plot_df["approved_amount_label"] = plot_df["total_approved_amount"].apply(approved_amount_billions)

plot_df["chart_label"] = (
    plot_df["base_label"]
    + "\n"
    + plot_df["approved_amount_label"]
)

plot_df["bubble_size"] = normalize_bubble_size(plot_df["total_approved_amount"])

baseline = plot_df.loc[plot_df["module2_run_id"] == "M2-01"].iloc[0]
baseline_x = baseline["simulated_offer_exposure_rate"]
baseline_y = baseline["approved_el_per_approved_dollar"]


# =============================================================================
# 6. BUILD CHART
# =============================================================================

fig, ax = plt.subplots(figsize=(11.2, 6.5), dpi=160)

# Plot by simplified strategy posture. Matplotlib's default color cycle is used.
for posture, group in plot_df.groupby("strategy_posture", sort=False):
    ax.scatter(
        group["simulated_offer_exposure_rate"],
        group["approved_el_per_approved_dollar"],
        s=group["bubble_size"],
        alpha=0.78,
        label=posture,
    )

# Baseline crosshair.
ax.axvline(baseline_x, linestyle="--", linewidth=1.0, alpha=0.65)
ax.axhline(baseline_y, linestyle="--", linewidth=1.0, alpha=0.65)

# Point labels.
for _, row in plot_df.iterrows():
    run_id = row["module2_run_id"]
    style = LABEL_STYLES.get(
        run_id,
        {"offset": (8, 8), "ha": "center", "va": "center"},
    )

    ax.annotate(
        row["chart_label"],
        xy=(
            row["simulated_offer_exposure_rate"],
            row["approved_el_per_approved_dollar"],
        ),
        xytext=style["offset"],
        textcoords="offset points",
        fontsize=8.3,
        ha=style["ha"],
        va=style["va"],
        arrowprops={
            "arrowstyle": "-",
            "linewidth": 0.6,
            "alpha": 0.70,
            "shrinkA": 0,
            "shrinkB": 5,
        },
    )

# Quadrant-style callouts.
# Placed away from the labeled points to avoid overlap.
ax.text(
    0.02,
    0.04,
    "Lower access,\ncleaner approved-risk density",
    transform=ax.transAxes,
    fontsize=9,
    va="bottom",
    ha="left",
    bbox={
        "boxstyle": "round,pad=0.35",
        "alpha": 0.85,
    },
)

ax.text(
    0.66,
    0.96,
    "Higher access,\nhigher approved-risk density",
    transform=ax.transAxes,
    fontsize=9,
    va="top",
    ha="left",
    bbox={
        "boxstyle": "round,pad=0.35",
        "alpha": 0.85,
    },
)

# Titles.
ax.set_title(
    "Strategy Frontier: Access vs Approved Expected-Loss Density",
    fontsize=15,
    fontweight="bold",
    pad=16,
)

ax.text(
    0.5,
    1.015,
    "Baseline population only — same synthetic applicants, different governed strategy postures",
    transform=ax.transAxes,
    ha="center",
    va="bottom",
    fontsize=10,
)

# Axes.
ax.set_xlabel("Simulated Offer Exposure Rate", fontsize=11)
ax.set_ylabel("Approved EL per Approved Dollar", fontsize=11)

ax.xaxis.set_major_formatter(mtick.PercentFormatter(xmax=1.0))
ax.yaxis.set_major_formatter(mtick.PercentFormatter(xmax=1.0))

# Add margin around points.
# The right-side margin is slightly widened so M2-37 can sit below/right without
# crowding the chart border.
x_range = (
    plot_df["simulated_offer_exposure_rate"].max()
    - plot_df["simulated_offer_exposure_rate"].min()
)

y_range = (
    plot_df["approved_el_per_approved_dollar"].max()
    - plot_df["approved_el_per_approved_dollar"].min()
)

x_pad_left = max(0.005, x_range * 0.18)
x_pad_right = max(0.008, x_range * 0.24)

y_pad = max(0.0002, y_range * 0.24)

ax.set_xlim(
    plot_df["simulated_offer_exposure_rate"].min() - x_pad_left,
    plot_df["simulated_offer_exposure_rate"].max() + x_pad_right,
)

ax.set_ylim(
    plot_df["approved_el_per_approved_dollar"].min() - y_pad,
    plot_df["approved_el_per_approved_dollar"].max() + y_pad,
)

ax.grid(True, linewidth=0.45, alpha=0.35)

# Strategy legend outside the plotting area.
ax.legend(
    title="Strategy posture",
    loc="center left",
    bbox_to_anchor=(1.02, 0.62),
    fontsize=8,
    title_fontsize=9,
    frameon=True,
)

# Bubble-size explanation in the open space under the legend.
ax.text(
    1.02,
    0.26,
    "Bubble size\n= total approved amount\n\nLarger circle\n= larger approved book\n\nDollar value is also\nshown in each label.",
    transform=ax.transAxes,
    fontsize=8.5,
    va="top",
    ha="left",
    bbox={
        "boxstyle": "round,pad=0.45",
        "alpha": 0.85,
    },
)

caption = (
    "Dashed lines mark M2-01 baseline access and approved-EL density. "
    "Bubble size and point-label dollar values represent total approved amount."
)

fig.text(
    0.5,
    0.015,
    "\n".join(textwrap.wrap(caption, width=120)),
    ha="center",
    va="bottom",
    fontsize=8.5,
)

# Right margin leaves room for the outside legend and bubble-size explanation.
fig.tight_layout(rect=[0.03, 0.08, 0.78, 0.94])


# =============================================================================
# 7. SAVE OUTPUTS
# =============================================================================

fig.savefig(OUTPUT_PNG, bbox_inches="tight")
fig.savefig(OUTPUT_SVG, bbox_inches="tight")
plt.close(fig)

print(f"Saved PNG: {OUTPUT_PNG}")
print(f"Saved SVG: {OUTPUT_SVG}")

print("\nChart data used:")
for _, row in plot_df.iterrows():
    print(
        f"{row['module2_run_id']:>5} | "
        f"{row['strategy_posture']:<24} | "
        f"Offer exposure: {row['simulated_offer_exposure_rate']:.2%} | "
        f"Approved EL / approved $: {row['approved_el_per_approved_dollar']:.2%} | "
        f"Approved amount: {approved_amount_billions(row['total_approved_amount'])}"
    )
```
<!-- END_MESSAGE C040-M02350 -->


---

<a id="c040-m02351"></a>

### C040-M02351

**Andrew** · 2026-05-26T13:19:26.406000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02351 -->
update python code (full copy paste) to bring the M2...text descriptions significantly closer to their bubbles.  make sure the bubble that says "higher access, higher approved-risk density" does not overlap the baseline reference X axis dotted line and the chart outline.  
<!-- END_MESSAGE C040-M02351 -->


---

<a id="c040-m02354"></a>

### C040-M02354

**ChatGPT** · 2026-05-26T13:25:07.476043-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02354 -->
Here is the full updated Python code with the label offsets pulled closer to the bubbles, M2-37 moved lower/right with extra axis breathing room, and the upper-right callout moved away from the baseline crosshair and chart outline.

```python
"""
Module 2 README Chart 1
Strategy Frontier Scatter: Access vs Approved Expected-Loss Density

This version uses hardcoded final-campaign Section 15.7A values.

Chart thesis:
    Same synthetic applicant population.
    Different governed Module 2 strategy postures.
    Visible access / risk-density / approved-exposure tradeoffs.

Data scope:
    module1_scenario_name = BASELINE_V2
    population_id = BASE_POPULATION_V1

Key design choices:
    1. M2-07 Manual Review Reduction is intentionally excluded because it sits
       exactly on top of M2-01 on this chart's two dimensions:
           simulated_offer_exposure_rate
           approved_el_per_approved_dollar

       M2-07 is better shown in an operational-burden chart, such as
       manual_review_rate vs decline_rate or a decision outcome mix chart.

    2. Bubble size represents total approved amount, but the size range is
       compressed so the chart remains primarily about the access / risk-density
       frontier.

    3. Total approved amount is also printed directly in each point label so the
       bubble-size encoding is immediately understandable.

    4. Baseline crosshair lines are retained so every challenger can be read
       relative to M2-01.

    5. Legend and bubble-size explanation are placed outside the plot area to
       reduce congestion.

    6. Long arrow annotations are replaced with simple quadrant-style callouts.

Output:
    assets/module2_strategy_frontier_scatter_baseline_population.png
    assets/module2_strategy_frontier_scatter_baseline_population.svg
"""

from __future__ import annotations

from pathlib import Path
import textwrap

import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.ticker as mtick


# =============================================================================
# 1. OUTPUT SETTINGS
# =============================================================================

OUTPUT_DIR = Path("assets")
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

OUTPUT_PNG = OUTPUT_DIR / "module2_strategy_frontier_scatter_baseline_population.png"
OUTPUT_SVG = OUTPUT_DIR / "module2_strategy_frontier_scatter_baseline_population.svg"


# =============================================================================
# 2. HARDCODED SECTION 15.7A FRONTIER DATA
# =============================================================================

FRONTIER_DATA = [
    {
        "module2_run_id": "M2-01",
        "base_label": "M2-01\nBaseline",
        "strategy_posture": "Baseline Reference",
        "strategy_name": "BASELINE_STRATEGY",
        "module1_scenario_name": "BASELINE_V2",
        "population_id": "BASE_POPULATION_V1",
        "simulated_offer_exposure_rate": 0.595240,
        "approved_el_per_approved_dollar": 0.0152985203377187,
        "total_approved_amount": 3827278124.10,
    },
    {
        "module2_run_id": "M2-02",
        "base_label": "M2-02\nTighter Risk",
        "strategy_posture": "Risk Discipline",
        "strategy_name": "TIGHTER_SYNTHETIC_RISK_STRATEGY",
        "module1_scenario_name": "BASELINE_V2",
        "population_id": "BASE_POPULATION_V1",
        "simulated_offer_exposure_rate": 0.570760,
        "approved_el_per_approved_dollar": 0.0139552919132960,
        "total_approved_amount": 3677999148.76,
    },
    {
        "module2_run_id": "M2-03",
        "base_label": "M2-03\nGrowth",
        "strategy_posture": "Growth",
        "strategy_name": "GROWTH_ORIENTED_STRATEGY",
        "module1_scenario_name": "BASELINE_V2",
        "population_id": "BASE_POPULATION_V1",
        "simulated_offer_exposure_rate": 0.622500,
        "approved_el_per_approved_dollar": 0.0165351528346220,
        "total_approved_amount": 4065698262.08,
    },
    {
        "module2_run_id": "M2-04",
        "base_label": "M2-04\nAffordability",
        "strategy_posture": "Affordability / Mixed",
        "strategy_name": "TIGHTER_AFFORDABILITY_STRATEGY",
        "module1_scenario_name": "BASELINE_V2",
        "population_id": "BASE_POPULATION_V1",
        "simulated_offer_exposure_rate": 0.565520,
        "approved_el_per_approved_dollar": 0.0154141022464799,
        "total_approved_amount": 3569433393.72,
    },
    {
        "module2_run_id": "M2-05",
        "base_label": "M2-05\nSelective CO",
        "strategy_posture": "Counteroffer Management",
        "strategy_name": "SELECTIVE_COUNTEROFFER_FEASIBILITY_STRATEGY",
        "module1_scenario_name": "BASELINE_V2",
        "population_id": "BASE_POPULATION_V1",
        "simulated_offer_exposure_rate": 0.525820,
        "approved_el_per_approved_dollar": 0.0145871986070696,
        "total_approved_amount": 3463854014.82,
    },
    {
        "module2_run_id": "M2-06",
        "base_label": "M2-06\nProduct\nGuardrails",
        "strategy_posture": "Product Guardrail",
        "strategy_name": "PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY",
        "module1_scenario_name": "BASELINE_V2",
        "population_id": "BASE_POPULATION_V1",
        "simulated_offer_exposure_rate": 0.512600,
        "approved_el_per_approved_dollar": 0.0145885274000267,
        "total_approved_amount": 3716432230.48,
    },
    {
        "module2_run_id": "M2-37",
        "base_label": "M2-37\nAggressive CO",
        "strategy_posture": "Counteroffer Management",
        "strategy_name": "AGGRESSIVE_COUNTEROFFER_EXPANSION_STRATEGY",
        "module1_scenario_name": "BASELINE_V2",
        "population_id": "BASE_POPULATION_V1",
        "simulated_offer_exposure_rate": 0.607020,
        "approved_el_per_approved_dollar": 0.0149365120481094,
        "total_approved_amount": 3639742514.82,
    },
]


# =============================================================================
# 3. LABEL AND LAYOUT SETTINGS
# =============================================================================

RUN_ORDER = [
    "M2-01",
    "M2-02",
    "M2-03",
    "M2-04",
    "M2-05",
    "M2-06",
    "M2-37",
]

# Manual label positions.
#
# User-directed layout:
#   M2-06 Product Guardrails: above its dot.
#   M2-05 Selective CO: below its dot.
#   M2-02 Tighter Risk: above its dot.
#   M2-04 Affordability: slightly northeast.
#   M2-01 Baseline: slightly northeast.
#   M2-37 Aggressive CO: below and to the right of its dot, but pulled away from the chart outline.
#   M2-03 Growth: below its dot.
#
# NOTE:
#   These offsets are in display points, not data units.
#   Values were tightened so labels sit significantly closer to the bubbles.
LABEL_STYLES = {
    "M2-01": {"offset": (20, 15), "ha": "center", "va": "center"},
    "M2-02": {"offset": (0, 30), "ha": "center", "va": "center"},
    "M2-03": {"offset": (0, -34), "ha": "center", "va": "center"},
    "M2-04": {"offset": (24, 17), "ha": "center", "va": "center"},
    "M2-05": {"offset": (0, -30), "ha": "center", "va": "center"},
    "M2-06": {"offset": (0, 32), "ha": "center", "va": "center"},
    "M2-37": {"offset": (26, -34), "ha": "left", "va": "top"},
}


# =============================================================================
# 4. HELPER FUNCTIONS
# =============================================================================

def normalize_bubble_size(
    series: pd.Series,
    min_size: float = 260,
    max_size: float = 620,
) -> pd.Series:
    """
    Convert total approved amount into restrained marker sizes.

    Bubble size is intentionally a secondary cue. The chart should mainly read
    as access versus approved Expected-Loss density.
    """
    min_val = series.min()
    max_val = series.max()

    if max_val == min_val:
        return pd.Series(
            [0.5 * (min_size + max_size)] * len(series),
            index=series.index,
        )

    return min_size + ((series - min_val) / (max_val - min_val)) * (max_size - min_size)


def approved_amount_billions(value: float) -> str:
    """Format approved amount for labels and sanity-print output."""
    return f"${value / 1_000_000_000:.2f}B"


# =============================================================================
# 5. PREPARE DATA
# =============================================================================

plot_df = pd.DataFrame(FRONTIER_DATA)

plot_df["run_order"] = plot_df["module2_run_id"].map(
    {run_id: idx for idx, run_id in enumerate(RUN_ORDER)}
)

plot_df = plot_df.sort_values("run_order").reset_index(drop=True)

plot_df["approved_amount_label"] = plot_df["total_approved_amount"].apply(approved_amount_billions)

plot_df["chart_label"] = (
    plot_df["base_label"]
    + "\n"
    + plot_df["approved_amount_label"]
)

plot_df["bubble_size"] = normalize_bubble_size(plot_df["total_approved_amount"])

baseline = plot_df.loc[plot_df["module2_run_id"] == "M2-01"].iloc[0]
baseline_x = baseline["simulated_offer_exposure_rate"]
baseline_y = baseline["approved_el_per_approved_dollar"]


# =============================================================================
# 6. BUILD CHART
# =============================================================================

fig, ax = plt.subplots(figsize=(11.2, 6.5), dpi=160)

# Plot by simplified strategy posture. Matplotlib's default color cycle is used.
for posture, group in plot_df.groupby("strategy_posture", sort=False):
    ax.scatter(
        group["simulated_offer_exposure_rate"],
        group["approved_el_per_approved_dollar"],
        s=group["bubble_size"],
        alpha=0.78,
        label=posture,
    )

# Baseline crosshair.
ax.axvline(baseline_x, linestyle="--", linewidth=1.0, alpha=0.65)
ax.axhline(baseline_y, linestyle="--", linewidth=1.0, alpha=0.65)

# Point labels.
for _, row in plot_df.iterrows():
    run_id = row["module2_run_id"]
    style = LABEL_STYLES.get(
        run_id,
        {"offset": (8, 8), "ha": "center", "va": "center"},
    )

    ax.annotate(
        row["chart_label"],
        xy=(
            row["simulated_offer_exposure_rate"],
            row["approved_el_per_approved_dollar"],
        ),
        xytext=style["offset"],
        textcoords="offset points",
        fontsize=8.3,
        ha=style["ha"],
        va=style["va"],
        arrowprops={
            "arrowstyle": "-",
            "linewidth": 0.6,
            "alpha": 0.70,
            "shrinkA": 0,
            "shrinkB": 5,
        },
    )

# Quadrant-style callouts.
# The upper-right callout is intentionally moved away from:
#   1. the baseline vertical dotted reference line,
#   2. the horizontal baseline dotted reference line,
#   3. the top/right chart outline.
ax.text(
    0.02,
    0.04,
    "Lower access,\ncleaner approved-risk density",
    transform=ax.transAxes,
    fontsize=9,
    va="bottom",
    ha="left",
    bbox={
        "boxstyle": "round,pad=0.35",
        "alpha": 0.85,
    },
)

ax.text(
    0.73,
    0.86,
    "Higher access,\nhigher approved-risk density",
    transform=ax.transAxes,
    fontsize=9,
    va="top",
    ha="left",
    bbox={
        "boxstyle": "round,pad=0.35",
        "alpha": 0.85,
    },
)

# Titles.
ax.set_title(
    "Strategy Frontier: Access vs Approved Expected-Loss Density",
    fontsize=15,
    fontweight="bold",
    pad=16,
)

ax.text(
    0.5,
    1.015,
    "Baseline population only — same synthetic applicants, different governed strategy postures",
    transform=ax.transAxes,
    ha="center",
    va="bottom",
    fontsize=10,
)

# Axes.
ax.set_xlabel("Simulated Offer Exposure Rate", fontsize=11)
ax.set_ylabel("Approved EL per Approved Dollar", fontsize=11)

ax.xaxis.set_major_formatter(mtick.PercentFormatter(xmax=1.0))
ax.yaxis.set_major_formatter(mtick.PercentFormatter(xmax=1.0))

# Add margin around points.
# Extra right-side margin keeps M2-37's label away from the plot outline while
# allowing it to remain below/right of the bubble.
x_range = (
    plot_df["simulated_offer_exposure_rate"].max()
    - plot_df["simulated_offer_exposure_rate"].min()
)

y_range = (
    plot_df["approved_el_per_approved_dollar"].max()
    - plot_df["approved_el_per_approved_dollar"].min()
)

x_pad_left = max(0.005, x_range * 0.18)
x_pad_right = max(0.014, x_range * 0.36)

y_pad_bottom = max(0.0002, y_range * 0.26)
y_pad_top = max(0.0002, y_range * 0.24)

ax.set_xlim(
    plot_df["simulated_offer_exposure_rate"].min() - x_pad_left,
    plot_df["simulated_offer_exposure_rate"].max() + x_pad_right,
)

ax.set_ylim(
    plot_df["approved_el_per_approved_dollar"].min() - y_pad_bottom,
    plot_df["approved_el_per_approved_dollar"].max() + y_pad_top,
)

ax.grid(True, linewidth=0.45, alpha=0.35)

# Strategy legend outside the plotting area.
ax.legend(
    title="Strategy posture",
    loc="center left",
    bbox_to_anchor=(1.02, 0.62),
    fontsize=8,
    title_fontsize=9,
    frameon=True,
)

# Bubble-size explanation in the open space under the legend.
ax.text(
    1.02,
    0.26,
    "Bubble size\n= total approved amount\n\nLarger circle\n= larger approved book\n\nDollar value is also\nshown in each label.",
    transform=ax.transAxes,
    fontsize=8.5,
    va="top",
    ha="left",
    bbox={
        "boxstyle": "round,pad=0.45",
        "alpha": 0.85,
    },
)

caption = (
    "Dashed lines mark M2-01 baseline access and approved-EL density. "
    "Bubble size and point-label dollar values represent total approved amount."
)

fig.text(
    0.5,
    0.015,
    "\n".join(textwrap.wrap(caption, width=120)),
    ha="center",
    va="bottom",
    fontsize=8.5,
)

# Right margin leaves room for the outside legend and bubble-size explanation.
fig.tight_layout(rect=[0.03, 0.08, 0.78, 0.94])


# =============================================================================
# 7. SAVE OUTPUTS
# =============================================================================

fig.savefig(OUTPUT_PNG, bbox_inches="tight")
fig.savefig(OUTPUT_SVG, bbox_inches="tight")
plt.close(fig)

print(f"Saved PNG: {OUTPUT_PNG}")
print(f"Saved SVG: {OUTPUT_SVG}")

print("\nChart data used:")
for _, row in plot_df.iterrows():
    print(
        f"{row['module2_run_id']:>5} | "
        f"{row['strategy_posture']:<24} | "
        f"Offer exposure: {row['simulated_offer_exposure_rate']:.2%} | "
        f"Approved EL / approved $: {row['approved_el_per_approved_dollar']:.2%} | "
        f"Approved amount: {approved_amount_billions(row['total_approved_amount'])}"
    )
```
<!-- END_MESSAGE C040-M02354 -->


---

<a id="c040-m02355"></a>

### C040-M02355

**Andrew** · 2026-05-26T13:43:53.465000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02355 -->
evaluate this final image and the black vs white background.  here was the python code used.
<!-- END_MESSAGE C040-M02355 -->


**Attachments in export:** `Pasted text(225).txt`, `module2_strategy_frontier_scatter_baseline_population (6).png`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c040-m02359"></a>

### C040-M02359

**ChatGPT** · 2026-05-26T13:49:03.194864-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02359 -->
The chart is now strong enough to use as a README hero candidate. The dark version gives it a polished “strategy control tower” feel, and the current layout finally reads like an intentional frontier graphic rather than a QA plot.

## What is working well

The **baseline crosshair** is the most important design element. It turns the scatter from “points on a chart” into a strategic interpretation frame: every challenger is now visually relative to M2-01.

The labels with approved-dollar values are a big improvement. The reader no longer has to infer what bubble size means, and the right-side note reinforces the encoding without overcrowding the plot.

The most compelling visual insight is very clear:

```text
M2-02 moves lower-left:
    lower access, cleaner approved-risk density

M2-03 moves upper-right:
    higher access, higher approved-risk density

M2-37 moves right and below baseline:
    more access than baseline, but lower approved EL density
```

That last point is especially powerful. M2-37 visually supports the governed-counteroffer story: aggressive counteroffer expansion is not simply “more risk.” It can expand offer exposure while preserving or improving approved EL density.

## Black background vs white background

For a **GitHub README hero image**, the black background works well if you intend this to be a visual centerpiece. It looks more premium, more dashboard-like, and more distinctive than a standard white matplotlib chart. It also makes the colored strategy bubbles and blue callout boxes stand out.

The downside is that GitHub README pages usually sit on a white/light page unless the viewer uses dark mode. A large black rectangle can feel heavier than the rest of the README, especially if the surrounding document is text-heavy. It also makes small text slightly more vulnerable to compression or mobile scaling.

A **white-background version** would feel more like a board-ready validation artifact or technical appendix. It would probably integrate better into a longer README and into a 3-chart collage if the other two charts are also light. It would also be easier to print, screenshot, or reuse in a PDF.

My recommendation:

```text
Use the dark version as the main README hero if this chart appears large and standalone.

Use a white version if this chart becomes one panel inside a 3-chart collage.

Keep both:
    dark = GitHub hero / LinkedIn visual
    white = documentation / appendix / validation-summary visual
```

Given this exact image, I would use the **dark version** for a standalone README hero. If we later build the full 3-chart collage, I would decide whether all three charts should use this same dark visual system. Mixed dark/light panels in one collage will look inconsistent.

## Remaining visual refinements I would make

There are only a few minor polish items left.

First, the title is excellent but very large. It works in this full-size image, but on GitHub mobile or a narrow README column it may dominate. I would either keep it as-is for a full-width hero or reduce it by 1–2 points if this will be part of a collage.

Second, the top-right callout is now placed well. It no longer collides with the baseline crosshair or the chart outline. It is close to M2-03, but that is acceptable because it explains the quadrant M2-03 occupies.

Third, the right-side legend and bubble-size note are effective. The note is worth keeping because it makes the chart self-contained. The wording is good:

```text
Bubble size = total approved amount
Larger circle = larger approved book
Dollar value is also shown in each label.
```

That solves the earlier ambiguity.

Fourth, M2-05 and M2-06 are readable now, but they remain the tightest cluster. That is not a problem; it actually helps tell the story that selective counteroffer and product guardrails sit in a similar lower-access / lower-risk-density zone.

## Interpretation quality

This chart now tells a sophisticated story quickly:

```text
M2-01 Baseline:
    anchor strategy

M2-02 Tighter Risk:
    conservative risk-discipline move

M2-03 Growth:
    access-expansion tradeoff

M2-04 Affordability:
    lower-access but not pure risk-density improvement

M2-05 Selective CO:
    conservative counteroffer-management posture

M2-06 Product Guardrails:
    targeted product-policy constraint posture

M2-37 Aggressive CO:
    governed counteroffer expansion with better approved-risk density than baseline
```

That is exactly the kind of frontier insight a README needs. It visually proves that the module is not just assigning outcomes; it is comparing governed strategy postures across access, approved exposure, and approved risk density.

## Final recommendation

I would treat this dark-background version as **near-final**. For the README, I would use it with a caption like:

```text
Each point is an archived Module 2 strategy run applied to the same BASELINE_V2 synthetic applicant population. The x-axis shows simulated positive offer exposure; the y-axis shows approved Expected Loss per approved dollar; bubble size and point labels show total approved amount. The baseline crosshair makes each challenger’s access / risk-density tradeoff visible.
```

For the next step, I would save this as the standalone hero chart and then build the second chart — the baseline-relative delta bars — using the same dark theme so the eventual collage feels cohesive.
<!-- END_MESSAGE C040-M02359 -->


---

<a id="c040-m02360"></a>

### C040-M02360

**Andrew** · 2026-05-26T14:03:02.947000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02360 -->
let's focus on the baseline-relative delta bars chart next.  lets use the same python based approach.  first, before we get to the code, let's lock down - what are we trying to say/demonstrate with this chart and is it a value add versus our strategy frontier scatter chart?
<!-- END_MESSAGE C040-M02360 -->


---

<a id="c040-m02366"></a>

### C040-M02366

**ChatGPT** · 2026-05-26T14:08:34.138328-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02366 -->
Yes — the baseline-relative delta bars chart is a real value add **if we make it a magnitude chart rather than another frontier-position chart**.

The scatter chart answers:

> **Where does each strategy sit on the access vs approved-risk-density frontier?**

The delta bar chart should answer:

> **How much did each selected challenger move the portfolio relative to baseline, and in which direction?**

That distinction matters. Section 15 is explicitly the archive-wide strategy frontier view: it summarizes how completed strategy slices trade off across offer exposure, approved amount, approved Expected Loss, affordability, counteroffer behavior, manual-review burden, decline rate, product behavior, score-band behavior, and reason-code movement. fileciteturn45file4 The scatter uses that frontier idea visually; the delta bar chart should quantify the movement behind the visual.

## What this chart should demonstrate

The chart should make the champion/challenger tradeoff concrete:

```text
M2-02 Tighter Risk:
    less access
    lower approved exposure
    lower approved Expected Loss

M2-03 Growth:
    more access
    higher approved exposure
    higher approved Expected Loss

M2-04 Affordability:
    less access
    lower approved exposure
    lower approved Expected Loss, but not necessarily a pure risk-density win

M2-05 Selective Counteroffer:
    more conservative counteroffer-management posture
    lower access / lower approved exposure

M2-06 Product Guardrails:
    targeted policy constraint
    lower access, but not identical to broad selective-counteroffer tightening

M2-37 Aggressive Counteroffer:
    very interesting because it can increase offer exposure while still reducing approved exposure / risk density through governed counteroffer treatment
```

That last point is where the chart adds the most value. In the scatter, M2-37 appears to the right of baseline and below baseline on approved-EL density. The delta bars can explain **how**: more applicants may receive positive offer exposure, but the governed counteroffer path can still reduce approved dollars or approved Expected Loss. That is a more nuanced story than “more access means more risk.”

## Why it is not redundant with the scatter

The scatter is intuitive but approximate. It uses position and bubble size. It is excellent for the “strategy frontier” concept, but it does not make exact magnitude obvious.

The delta bar chart adds three things:

```text
1. Direction:
   Did the strategy move access, exposure, and Expected Loss up or down?

2. Magnitude:
   Was the movement small, moderate, or material?

3. Tradeoff shape:
   Did access and approved dollars move together, or did counteroffer treatment decouple them?
```

That third point is the most important. A strategy can increase offer exposure while reducing approved amount if it shifts more applicants into smaller governed counteroffers. The scatter hints at that; the delta chart proves it.

## Recommended chart title

```text
Baseline-Relative Tradeoffs: Access, Exposure, and Expected Loss
```

Subtitle:

```text
Selected challengers vs M2-01 baseline on the same synthetic applicant population
```

## Recommended source

Use:

```text
17.15 — Baseline × challenger delta summary for active comparison groups
```

That is better than 15.7A for this specific chart because the chart is explicitly about **baseline-relative deltas**. Section 13/17 comparison logic is designed around matched archived baseline/challenger comparisons on the same Module 1 scenario and population, with source-field consistency checks so deltas can be interpreted as Module 2 strategy movement rather than population drift. fileciteturn45file32

15.7A remains the right source for the scatter because it is the executive strategy frontier summary. 17.15 is the better source for the delta chart because it is comparison-framed.

## Recommended selected strategies

Use the same representative strategy set as the scatter, excluding baseline:

```text
M2-02 — Tighter Risk
M2-03 — Growth
M2-04 — Affordability
M2-05 — Selective CO
M2-06 — Product Guardrails
M2-37 — Aggressive CO
```

Do not include M2-07 here. Like the scatter, this chart is not the best place for Manual Review Reduction. Its story is operational burden and outcome resolution, not primarily access / exposure / Expected Loss magnitude. M2-07 belongs in an outcome-mix or review-burden chart.

## Recommended metrics

Use exactly three metric panels:

```text
1. Δ Offer Exposure Rate
   delta_simulated_offer_exposure_rate
   Unit: percentage points

2. Δ Total Approved Amount
   delta_total_approved_amount
   Unit: $ millions

3. Δ Total Approved Expected Loss
   delta_total_approved_expected_loss_amount
   Unit: $ millions
```

This keeps the chart focused on the README phrase:

> access, exposure, and Expected Loss

I would **not** include approved EL per approved dollar in this chart. The scatter already handles approved-risk density. If we add a fourth metric, the chart becomes busy and starts repeating the first chart’s purpose.

## Recommended visual design

Use a three-panel horizontal bar chart:

```text
Rows:
    selected challenger strategies

Columns:
    Panel 1: Δ Offer Exposure Rate
    Panel 2: Δ Total Approved Amount
    Panel 3: Δ Total Approved Expected Loss
```

Each panel should have a vertical zero line:

```text
left of zero = reduction vs baseline
right of zero = increase vs baseline
```

This will make the tradeoffs instantly readable.

Example interpretation:

```text
M2-02:
    left / left / left
    = less access, less approved amount, less approved EL

M2-03:
    right / right / right
    = more access, more approved amount, more approved EL

M2-37:
    potentially right on access but left on approved amount / approved EL
    = governed counteroffer expansion, not uncontrolled exposure expansion
```

That is the chart’s strongest insight.

## Dark vs white background

Since the scatter is now dark and polished, I would keep this second chart in the same dark visual language. If the charts eventually become a 3-panel README collage, visual consistency matters.

So:

```text
Use dark background.
Use the same title style.
Use the same font scale.
Use the same strategy labels.
Use the same short run names.
```

## Recommended chart caption

```text
Each bar shows challenger movement relative to the matched M2-01 baseline. The chart separates access, approved exposure, and approved Expected Loss so the reader can see whether a strategy expands offers, expands dollars, reduces loss, or changes the relationship between offer exposure and approved exposure.
```

Shorter README caption:

```text
Baseline-relative deltas show that strategy movement is multidimensional: growth expands access and exposure, risk tightening reduces loss, and governed counteroffer expansion can increase offer exposure without simply expanding approved dollars.
```

## Final locked concept

```text
Chart 2:
    Baseline-Relative Tradeoff Bars

Purpose:
    Quantify how selected challengers moved access, approved exposure, and approved Expected Loss
    relative to M2-01.

Source:
    17.15 baseline × challenger delta summary

Rows:
    M2-02 Tighter Risk
    M2-03 Growth
    M2-04 Affordability
    M2-05 Selective CO
    M2-06 Product Guardrails
    M2-37 Aggressive CO

Panels:
    Δ Offer Exposure Rate, percentage points
    Δ Total Approved Amount, $M
    Δ Total Approved Expected Loss, $M

Main message:
    No strategy wins universally. Each strategy moves access, exposure, and loss differently.
    The most interesting strategies are those that decouple access from approved exposure or
    approved Expected Loss.
```

This chart is worth building. It will make the scatter’s frontier story more concrete and give the README a stronger executive tradeoff narrative.
<!-- END_MESSAGE C040-M02366 -->


---

<a id="c040-m02367"></a>

### C040-M02367

**Andrew** · 2026-05-26T14:12:18.751000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02367 -->
Let's build the python code.  Here is the 17.15 data (hardcode values) + the prior python code from the strategy frontier scatter (for alignment)
<!-- END_MESSAGE C040-M02367 -->


**Attachments in export:** `Pasted text(226).txt`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.15_QA_baseline_x_challenger_delta_summary_for_active_comparison_groups_campaign(2).csv`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c040-m02372"></a>

### C040-M02372

**ChatGPT** · 2026-05-26T14:21:44.969972-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02372 -->
Below is a full-copy Python script for the **Baseline-Relative Delta Bars** chart. It uses hardcoded values from your final campaign 17.15 output and follows the same dark README style as the strategy frontier scatter.

```python
"""
Module 2 README Chart 2
Baseline-Relative Tradeoffs: Access, Exposure, and Expected Loss

This version uses hardcoded final-campaign Section 17.15 values.

Chart thesis:
    The strategy frontier scatter shows where selected strategies sit.
    This delta chart shows how much selected challengers moved the portfolio
    relative to the matched M2-01 baseline.

Data source:
    Final campaign Section 17.15:
    Baseline × challenger delta summary for active comparison groups.

Data scope:
    Selected representative challengers on BASELINE_V2 / BASE_POPULATION_V1:
        M2-02 Tighter Risk
        M2-03 Growth
        M2-04 Affordability
        M2-05 Selective Counteroffer
        M2-06 Product Guardrails
        M2-37 Aggressive Counteroffer

Metrics:
    1. Delta simulated offer exposure rate, shown in percentage points.
    2. Delta total approved amount, shown in $ millions.
    3. Delta total approved Expected Loss, shown in $ millions.

Interpretation:
    Bars left of zero = reduction versus M2-01 baseline.
    Bars right of zero = increase versus M2-01 baseline.

Output:
    assets/module2_baseline_relative_tradeoff_bars.png
    assets/module2_baseline_relative_tradeoff_bars.svg
"""

from __future__ import annotations

from pathlib import Path
import textwrap

import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.ticker as mtick


# =============================================================================
# 1. OUTPUT SETTINGS
# =============================================================================

OUTPUT_DIR = Path("assets")
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

OUTPUT_PNG = OUTPUT_DIR / "module2_baseline_relative_tradeoff_bars.png"
OUTPUT_SVG = OUTPUT_DIR / "module2_baseline_relative_tradeoff_bars.svg"


# =============================================================================
# 2. HARDCODED SECTION 17.15 BASELINE-RELATIVE DELTA DATA
# =============================================================================

DELTA_DATA = [
    {
        "comparison_group_id": "CG01",
        "challenger_module2_run_id": "M2-02",
        "base_label": "M2-02\nTighter Risk",
        "strategy_posture": "Risk Discipline",
        "comparison_set_name": "Baseline vs Tighter Synthetic Risk",
        "challenger_strategy_name": "TIGHTER_SYNTHETIC_RISK_STRATEGY",
        "module1_scenario_name": "BASELINE_V2",
        "population_id": "BASE_POPULATION_V1",
        "delta_simulated_offer_exposure_rate": -0.02448,
        "delta_total_approved_amount": -149278975.34,
        "delta_total_approved_expected_loss_amount": -7224140.44185,
    },
    {
        "comparison_group_id": "CG02",
        "challenger_module2_run_id": "M2-03",
        "base_label": "M2-03\nGrowth",
        "strategy_posture": "Growth",
        "comparison_set_name": "Baseline vs Growth Oriented",
        "challenger_strategy_name": "GROWTH_ORIENTED_STRATEGY",
        "module1_scenario_name": "BASELINE_V2",
        "population_id": "BASE_POPULATION_V1",
        "delta_simulated_offer_exposure_rate": 0.02726,
        "delta_total_approved_amount": 238420137.98,
        "delta_total_approved_expected_loss_amount": 8675249.92330,
    },
    {
        "comparison_group_id": "CG03",
        "challenger_module2_run_id": "M2-04",
        "base_label": "M2-04\nAffordability",
        "strategy_posture": "Affordability / Mixed",
        "comparison_set_name": "Baseline vs Tighter Affordability",
        "challenger_strategy_name": "TIGHTER_AFFORDABILITY_STRATEGY",
        "module1_scenario_name": "BASELINE_V2",
        "population_id": "BASE_POPULATION_V1",
        "delta_simulated_offer_exposure_rate": -0.02972,
        "delta_total_approved_amount": -257844730.38,
        "delta_total_approved_expected_loss_amount": -3532080.92685,
    },
    {
        "comparison_group_id": "CG04",
        "challenger_module2_run_id": "M2-05",
        "base_label": "M2-05\nSelective CO",
        "strategy_posture": "Counteroffer Management",
        "comparison_set_name": "Baseline vs Selective Counteroffer Feasibility",
        "challenger_strategy_name": "SELECTIVE_COUNTEROFFER_FEASIBILITY_STRATEGY",
        "module1_scenario_name": "BASELINE_V2",
        "population_id": "BASE_POPULATION_V1",
        "delta_simulated_offer_exposure_rate": -0.06942,
        "delta_total_approved_amount": -363424109.28,
        "delta_total_approved_expected_loss_amount": -8023765.759575,
    },
    {
        "comparison_group_id": "CG05",
        "challenger_module2_run_id": "M2-06",
        "base_label": "M2-06\nProduct Guardrails",
        "strategy_posture": "Product Guardrail",
        "comparison_set_name": "Baseline vs Product Guardrails",
        "challenger_strategy_name": "PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY",
        "module1_scenario_name": "BASELINE_V2",
        "population_id": "BASE_POPULATION_V1",
        "delta_simulated_offer_exposure_rate": -0.08264,
        "delta_total_approved_amount": -110845893.62,
        "delta_total_approved_expected_loss_amount": -4334418.79495,
    },
    {
        "comparison_group_id": "CG18",
        "challenger_module2_run_id": "M2-37",
        "base_label": "M2-37\nAggressive CO",
        "strategy_posture": "Counteroffer Management",
        "comparison_set_name": "Baseline vs Aggressive Counteroffer Expansion",
        "challenger_strategy_name": "AGGRESSIVE_COUNTEROFFER_EXPANSION_STRATEGY",
        "module1_scenario_name": "BASELINE_V2",
        "population_id": "BASE_POPULATION_V1",
        "delta_simulated_offer_exposure_rate": 0.01178,
        "delta_total_approved_amount": -187535609.28,
        "delta_total_approved_expected_loss_amount": -4186634.295025,
    },
]


# =============================================================================
# 3. CHART STYLE SETTINGS
# =============================================================================

RUN_ORDER = [
    "M2-02",
    "M2-03",
    "M2-04",
    "M2-05",
    "M2-06",
    "M2-37",
]

# Explicit dark styling for README consistency with the strategy frontier scatter.
FIG_FACE = "black"
AX_FACE = "black"
TEXT_COLOR = "white"
GRID_COLOR = "white"
ZERO_LINE_COLOR = "white"

# Sign colors are intentionally simple:
#   positive movement = expansion / increase
#   negative movement = reduction / decrease
POSITIVE_BAR_COLOR = "#74add1"
NEGATIVE_BAR_COLOR = "#f46d43"

# Highlight color for M2-37 annotation.
CALLOUT_BOX_COLOR = "#4f8fc4"


# =============================================================================
# 4. HELPER FUNCTIONS
# =============================================================================

def dollars_to_millions(value: float) -> float:
    """Convert dollars to millions."""
    return value / 1_000_000.0


def format_pp(value: float) -> str:
    """Format a percentage-point value."""
    return f"{value:+.1f} pp"


def format_millions(value: float) -> str:
    """Format a dollar-value-in-millions label."""
    sign = "+" if value >= 0 else "-"
    return f"{sign}${abs(value):.0f}M"


def symmetric_xlim(values: pd.Series, pad_ratio: float = 0.18, minimum: float = 1.0) -> tuple[float, float]:
    """
    Build symmetric x-axis limits around zero so positive and negative movement
    is visually comparable within each panel.
    """
    max_abs = max(abs(values.min()), abs(values.max()), minimum)
    max_abs = max_abs * (1 + pad_ratio)
    return -max_abs, max_abs


def annotate_bars(
    ax: plt.Axes,
    values: pd.Series,
    y_positions: list[int],
    formatter,
    text_color: str = TEXT_COLOR,
) -> None:
    """Add compact labels at the end of each horizontal bar."""
    x_min, x_max = ax.get_xlim()
    x_range = x_max - x_min

    for y, value in zip(y_positions, values):
        label = formatter(value)

        if value >= 0:
            x_text = value + x_range * 0.018
            ha = "left"
        else:
            x_text = value - x_range * 0.018
            ha = "right"

        ax.text(
            x_text,
            y,
            label,
            va="center",
            ha=ha,
            fontsize=8.5,
            color=text_color,
        )


def style_axis(ax: plt.Axes) -> None:
    """Apply shared dark chart styling."""
    ax.set_facecolor(AX_FACE)
    ax.tick_params(colors=TEXT_COLOR, labelsize=9)
    ax.xaxis.label.set_color(TEXT_COLOR)
    ax.yaxis.label.set_color(TEXT_COLOR)
    ax.title.set_color(TEXT_COLOR)

    for spine in ax.spines.values():
        spine.set_color(TEXT_COLOR)
        spine.set_linewidth(0.8)

    ax.grid(
        True,
        axis="x",
        linewidth=0.45,
        alpha=0.28,
        color=GRID_COLOR,
    )

    ax.axvline(
        0,
        color=ZERO_LINE_COLOR,
        linewidth=1.0,
        alpha=0.85,
    )


# =============================================================================
# 5. PREPARE DATA
# =============================================================================

plot_df = pd.DataFrame(DELTA_DATA)

plot_df["run_order"] = plot_df["challenger_module2_run_id"].map(
    {run_id: idx for idx, run_id in enumerate(RUN_ORDER)}
)

plot_df = plot_df.sort_values("run_order").reset_index(drop=True)

plot_df["delta_offer_exposure_pp"] = (
    plot_df["delta_simulated_offer_exposure_rate"] * 100.0
)

plot_df["delta_total_approved_amount_m"] = plot_df["delta_total_approved_amount"].apply(
    dollars_to_millions
)

plot_df["delta_total_approved_el_m"] = plot_df[
    "delta_total_approved_expected_loss_amount"
].apply(dollars_to_millions)

plot_df["bar_color_access"] = plot_df["delta_offer_exposure_pp"].apply(
    lambda v: POSITIVE_BAR_COLOR if v >= 0 else NEGATIVE_BAR_COLOR
)

plot_df["bar_color_amount"] = plot_df["delta_total_approved_amount_m"].apply(
    lambda v: POSITIVE_BAR_COLOR if v >= 0 else NEGATIVE_BAR_COLOR
)

plot_df["bar_color_el"] = plot_df["delta_total_approved_el_m"].apply(
    lambda v: POSITIVE_BAR_COLOR if v >= 0 else NEGATIVE_BAR_COLOR
)


# =============================================================================
# 6. BUILD CHART
# =============================================================================

fig, axes = plt.subplots(
    nrows=1,
    ncols=3,
    figsize=(15.5, 7.0),
    dpi=160,
    sharey=True,
)

fig.patch.set_facecolor(FIG_FACE)

y_positions = list(range(len(plot_df)))
y_labels = plot_df["base_label"].tolist()

panel_specs = [
    {
        "ax": axes[0],
        "values": plot_df["delta_offer_exposure_pp"],
        "colors": plot_df["bar_color_access"],
        "title": "Offer Exposure",
        "xlabel": "Δ vs baseline (percentage points)",
        "formatter": format_pp,
        "minimum_xlim": 3.0,
    },
    {
        "ax": axes[1],
        "values": plot_df["delta_total_approved_amount_m"],
        "colors": plot_df["bar_color_amount"],
        "title": "Approved Amount",
        "xlabel": "Δ vs baseline ($ millions)",
        "formatter": format_millions,
        "minimum_xlim": 100.0,
    },
    {
        "ax": axes[2],
        "values": plot_df["delta_total_approved_el_m"],
        "colors": plot_df["bar_color_el"],
        "title": "Approved Expected Loss",
        "xlabel": "Δ vs baseline ($ millions)",
        "formatter": lambda v: f"{'+' if v >= 0 else '-'}${abs(v):.1f}M",
        "minimum_xlim": 2.0,
    },
]

for spec in panel_specs:
    ax = spec["ax"]
    values = spec["values"]

    ax.barh(
        y_positions,
        values,
        color=spec["colors"],
        alpha=0.88,
        height=0.62,
    )

    style_axis(ax)

    ax.set_title(
        spec["title"],
        fontsize=12,
        fontweight="bold",
        pad=12,
        color=TEXT_COLOR,
    )

    ax.set_xlabel(
        spec["xlabel"],
        fontsize=9.5,
        color=TEXT_COLOR,
        labelpad=8,
    )

    ax.set_xlim(
        *symmetric_xlim(
            values,
            pad_ratio=0.24,
            minimum=spec["minimum_xlim"],
        )
    )

    annotate_bars(
        ax=ax,
        values=values,
        y_positions=y_positions,
        formatter=spec["formatter"],
    )

# Y-axis labels only on first panel.
axes[0].set_yticks(y_positions)
axes[0].set_yticklabels(y_labels, color=TEXT_COLOR, fontsize=9.5)

for ax in axes[1:]:
    ax.tick_params(axis="y", left=False, labelleft=False)

# Keep M2-02 at the top.
axes[0].invert_yaxis()

# X-axis formatting.
axes[0].xaxis.set_major_formatter(mtick.FormatStrFormatter("%.1f"))
axes[1].xaxis.set_major_formatter(mtick.FormatStrFormatter("%.0f"))
axes[2].xaxis.set_major_formatter(mtick.FormatStrFormatter("%.1f"))

# Main title and subtitle.
fig.suptitle(
    "Baseline-Relative Tradeoffs: Access, Exposure, and Expected Loss",
    fontsize=20,
    fontweight="bold",
    color=TEXT_COLOR,
    y=0.975,
)

fig.text(
    0.5,
    0.925,
    "Selected challengers vs M2-01 baseline on the same BASELINE_V2 synthetic applicant population",
    ha="center",
    va="center",
    fontsize=11,
    color=TEXT_COLOR,
)

# Small direction note.
fig.text(
    0.5,
    0.885,
    "Left of zero = reduction vs baseline     |     Right of zero = increase vs baseline",
    ha="center",
    va="center",
    fontsize=9.5,
    color=TEXT_COLOR,
    bbox={
        "boxstyle": "round,pad=0.35",
        "facecolor": CALLOUT_BOX_COLOR,
        "edgecolor": CALLOUT_BOX_COLOR,
        "alpha": 0.88,
    },
)

# Key insight note.
fig.text(
    0.5,
    0.055,
    "\n".join(
        textwrap.wrap(
            "Read across each row: risk tightening reduces access, approved dollars, and approved Expected Loss; "
            "growth expands all three; aggressive counteroffer expansion is especially interesting because it increases "
            "offer exposure while reducing approved dollars and approved Expected Loss.",
            width=145,
        )
    ),
    ha="center",
    va="center",
    fontsize=9.2,
    color=TEXT_COLOR,
)

# Leave space for title, subtitle, note, and caption.
fig.tight_layout(rect=[0.04, 0.10, 0.98, 0.84])


# =============================================================================
# 7. SAVE OUTPUTS
# =============================================================================

fig.savefig(
    OUTPUT_PNG,
    bbox_inches="tight",
    facecolor=fig.get_facecolor(),
)

fig.savefig(
    OUTPUT_SVG,
    bbox_inches="tight",
    facecolor=fig.get_facecolor(),
)

plt.close(fig)

print(f"Saved PNG: {OUTPUT_PNG}")
print(f"Saved SVG: {OUTPUT_SVG}")

print("\nChart data used:")
for _, row in plot_df.iterrows():
    print(
        f"{row['challenger_module2_run_id']:>5} | "
        f"{row['strategy_posture']:<24} | "
        f"Access Δ: {format_pp(row['delta_offer_exposure_pp'])} | "
        f"Approved amount Δ: {format_millions(row['delta_total_approved_amount_m'])} | "
        f"Approved EL Δ: "
        f"{'+' if row['delta_total_approved_el_m'] >= 0 else '-'}"
        f"${abs(row['delta_total_approved_el_m']):.1f}M"
    )
```
<!-- END_MESSAGE C040-M02372 -->


---

<a id="c040-m02374"></a>

### C040-M02374

**Andrew** · 2026-05-26T14:37:47.396000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02374 -->
update python (full copy paste) based on this feedback: I really like this but I preferred it to be all in one chart like you had in this original. what I would like vs the original is our updated style/titles, the reach across interpretation notes, the left of zero/right of zero guidance, and the numerical values (e.g. -2.4pp, -$149M, -$7.2M).
<!-- END_MESSAGE C040-M02374 -->


**Attachments in export:** `module2_baseline_relative_delta_bars(1).png`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c040-m02375"></a>

### C040-M02375

**Andrew** · 2026-05-26T15:11:26.817000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02375 -->
I want this exactly, but minus the gemini logo and fading at the bottom. preferably using python to produce.
<!-- END_MESSAGE C040-M02375 -->


**Attachments in export:** `Gemini_Generated_Image_x2jblcx2jblcx2jb.png`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_06.md) · [Next](Part_08.md)
