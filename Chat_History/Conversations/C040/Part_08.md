# Campaign QA and strategy expansion

## Part 08

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_07.md) · [Next](Part_09.md)

<a id="c040-m02376"></a>

### C040-M02376

**Andrew** · 2026-05-26T15:39:54.994000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02376 -->
i have finished the second chart.  let's lock down the criteria for the third chart - you called it earlier the option_c_counteroffer_split.  it needs to have value added versus our first two charts and needs to answer interesting aspects of our campaign and project.
<!-- END_MESSAGE C040-M02376 -->


---

<a id="c040-m02379"></a>

### C040-M02379

**ChatGPT** · 2026-05-26T15:45:06.944132-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02379 -->
Yes — the third chart should **not** be another access / exposure / Expected Loss chart. The first two charts already cover that:

```text
Chart 1:
    Where strategies sit on access vs approved-risk-density frontier.

Chart 2:
    How selected challengers move access, approved dollars, and approved Expected Loss vs baseline.
```

The third chart should answer a different and more architectural question:

> **What did the Option C counteroffer split actually do, and did aggressive expansion remain governed?**

That is the value-add.

Module 2 explicitly treats credit strategy as a governed tradeoff system, including selective versus aggressive counteroffer posture, counteroffer feasibility, reason-code transparency, parameter traceability, and post-campaign evidence readiness. fileciteturn47file4 The Option C design is specifically a split between `SELECTIVE_COUNTEROFFER_FEASIBILITY_STRATEGY` and `AGGRESSIVE_COUNTEROFFER_EXPANSION_STRATEGY`, where aggressive expansion routes more severe requested-structure cases into governed feasibility testing rather than bypassing policy controls. fileciteturn47file55

## Third chart thesis

**Option C is not “approve more.” It is “route more cases into governed counteroffer feasibility.”**

The chart should demonstrate:

```text
Selective feasibility:
    preserves conservative treatment
    produces zero aggressive override rows

Aggressive expansion:
    creates aggressive override rows
    resolves many into final counteroffers
    sends some to manual review
    produces zero final aggressive override declines in the observed campaign
```

That is a materially different story from the first two charts. It proves the system has **decision-path governance**, not just portfolio metric movement.

---

# Locked chart concept

## Chart title

```text
Option C Counteroffer Governance
Selective Feasibility vs Aggressive Expansion
```

## Subtitle

```text
Aggressive expansion routes more severe requested-structure cases into governed feasibility testing
```

## Source

Use:

```text
17.17 — Option C counteroffer strategy split effect check
```

This is the right source because the chart is not a generic frontier metric. It is specifically about the active comparison groups where the challenger is either:

```text
SELECTIVE_COUNTEROFFER_FEASIBILITY_STRATEGY
AGGRESSIVE_COUNTEROFFER_EXPANSION_STRATEGY
```

Section 15 can summarize Option C frontier posture, but the third README chart should use the campaign-level Option C effect check because it directly evaluates the selective/aggressive strategy split.

---

# What the chart should answer

## Question 1 — Did selective feasibility create aggressive override rows?

Expected visual answer:

```text
No.
M2-05, M2-18, and M2-29 all show 0 aggressive override rows.
```

This shows selective feasibility is not aggressive expansion under a different name.

## Question 2 — Did aggressive expansion create governed override volume?

Expected visual answer:

```text
Yes.
M2-37, M2-38, and M2-39 produce aggressive override rows.
```

Approximate known values:

```text
M2-37 BASELINE_V2:
    aggressive override rows = 4,614

M2-38 NEAR_PRIME_EXPANSION_MIX:
    aggressive override rows = 4,380

M2-39 HIGH_BALANCE_APPETITE:
    aggressive override rows = 8,892
```

## Question 3 — Where did those aggressive override rows resolve?

Expected visual answer:

```text
Mostly final counteroffer.
Some manual review.
Zero final aggressive override decline rows.
```

Known outcome mix:

```text
M2-37:
    final counteroffer = 4,067
    final manual review = 547
    final decline = 0

M2-38:
    final counteroffer = 3,699
    final manual review = 681
    final decline = 0

M2-39:
    final counteroffer = 7,081
    final manual review = 1,811
    final decline = 0
```

This is the governance story: aggressive expansion does not simply grant approvals. It routes into feasibility and final resolution.

## Question 4 — Which scenario creates the most Option C pressure?

Expected visual answer:

```text
HIGH_BALANCE_APPETITE creates the largest aggressive override population.
```

M2-39 is the standout:

```text
8,892 aggressive override rows
7,081 final counteroffers
1,811 final manual reviews
```

That is an interesting campaign insight because it shows that exposure-intensity context changes the size and friction of the counteroffer expansion opportunity.

---

# Recommended chart type

Use a **stacked bar chart**, grouped by scenario family.

## X-axis grouping

Three scenario groups:

```text
BASELINE_V2
NEAR_PRIME_EXPANSION_MIX
HIGH_BALANCE_APPETITE
```

Each group has two bars:

```text
Selective
Aggressive
```

Specific run mapping:

```text
BASELINE_V2:
    M2-05 Selective
    M2-37 Aggressive

NEAR_PRIME_EXPANSION_MIX:
    M2-18 Selective
    M2-38 Aggressive

HIGH_BALANCE_APPETITE:
    M2-29 Selective
    M2-39 Aggressive
```

## Y-axis

```text
Aggressive Override Rows
```

## Stack segments

```text
Final Counteroffer
Final Manual Review
Final Decline
```

Since final decline is zero in the observed campaign, it can either appear in the legend with no visible bar or be mentioned in an annotation.

I would keep it in the legend because “zero final decline” is part of the governance proof.

---

# What to label

Each bar should show total aggressive override rows:

```text
Selective bars:
    0 override rows

Aggressive bars:
    4,614
    4,380
    8,892
```

Inside or near each aggressive bar, add final outcome mix:

```text
M2-37:
    88% CO / 12% MR

M2-38:
    84% CO / 16% MR

M2-39:
    80% CO / 20% MR
```

Rounded values are fine. The point is not exact decimal precision; the point is the governed split.

---

# Why this chart adds value

The first two charts show **portfolio movement**.

This third chart shows **strategy mechanics**.

It answers:

```text
Did aggressive counteroffer expansion bypass controls?
    No.

Did it create a controlled path into reduced-exposure offers?
    Yes.

Did selective feasibility behave differently from aggressive expansion?
    Yes.

Did higher-balance context create more aggressive override pressure?
    Yes.

Were aggressive override rows explainable by final outcome?
    Yes.
```

That makes it a **governance and architecture chart**, not just a performance chart.

---

# Recommended interpretation note

Use this as the README caption:

```text
Selective feasibility preserves conservative counteroffer treatment and produces no aggressive override rows. Aggressive expansion routes additional severe requested-structure cases into governed feasibility testing, where most become final counteroffers and the remainder move to manual review. This shows counteroffer expansion as controlled feasibility routing, not approval bypass.
```

A shorter caption:

```text
Option C shows that counteroffer expansion is governed routing: selective strategies produce zero aggressive overrides, while aggressive strategies route additional cases into final counteroffer or manual review outcomes.
```

---

# Suggested visual callouts

Use only two callouts.

## Left / selective side

```text
Selective feasibility:
0 aggressive override rows
```

## Right / aggressive side

```text
Aggressive expansion:
governed feasibility routing,
not approval bypass
```

Optional callout above M2-39:

```text
High-balance appetite creates the largest override population
```

---

# What not to include

Do **not** include approved amount, approved Expected Loss, or offer exposure in this chart. Those are already covered by Charts 1 and 2.

Do **not** include all 39 runs.

Do **not** include all ordinary counteroffer candidates. That would blur the focus. Ordinary counteroffer candidacy is important, but this chart should stay focused on the formal Option C selective/aggressive split.

Do **not** make it a percent-only chart. We need absolute row volume because M2-39’s higher aggressive override volume is part of the story.

---

# Final locked third-chart spec

```text
Chart name:
    Option C Counteroffer Split

Title:
    Option C Counteroffer Governance

Subtitle:
    Selective feasibility vs aggressive expansion across matched scenario contexts

Source:
    Final campaign 17.17 Option C counteroffer strategy split effect check

Rows / bars:
    M2-05 Selective — BASELINE_V2
    M2-37 Aggressive — BASELINE_V2
    M2-18 Selective — NEAR_PRIME_EXPANSION_MIX
    M2-38 Aggressive — NEAR_PRIME_EXPANSION_MIX
    M2-29 Selective — HIGH_BALANCE_APPETITE
    M2-39 Aggressive — HIGH_BALANCE_APPETITE

Y-axis:
    Aggressive Override Rows

Stack:
    aggressive_override_final_counteroffer_rows
    aggressive_override_final_manual_review_rows
    aggressive_override_final_decline_rows

Labels:
    total aggressive override rows
    final outcome mix for aggressive bars
    “0 override rows” for selective bars

Primary message:
    Selective feasibility preserves conservative treatment.
    Aggressive expansion creates governed counteroffer feasibility routing.
    High-balance appetite produces the largest override population.
```

This should be the third chart. It complements the first two cleanly: frontier position, baseline-relative movement, then decision-path governance.
<!-- END_MESSAGE C040-M02379 -->


---

<a id="c040-m02381"></a>

### C040-M02381

**Andrew** · 2026-05-26T15:47:26.287000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02381 -->
please produce the python code for the third chart. i approve this third chart structure.
<!-- END_MESSAGE C040-M02381 -->


---

<a id="c040-m02383"></a>

### C040-M02383

**ChatGPT** · 2026-05-26T15:53:32.738768-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02383 -->
The script below reflects the locked Option C framing: selective feasibility preserves conservative treatment, while aggressive expansion routes more severe requested-structure cases into governed counteroffer feasibility testing rather than bypassing controls. fileciteturn47file4turn47file55

```python
"""
Module 2 README Chart 3
Option C Counteroffer Governance: Selective Feasibility vs Aggressive Expansion

This version uses hardcoded final-campaign Section 17.17 values.

Chart thesis:
    Option C is not "approve more."
    It is governed counteroffer feasibility routing.

    Selective feasibility:
        preserves conservative treatment
        produces zero aggressive override rows

    Aggressive expansion:
        routes additional severe requested-structure cases into governed feasibility testing
        resolves many to final counteroffer
        sends some to manual review
        produces zero final aggressive override declines in the observed campaign

Data source:
    Final campaign Section 17.17:
    Option C counteroffer strategy split effect check.

Rows / bars:
    BASELINE_V2:
        M2-05 Selective
        M2-37 Aggressive

    NEAR_PRIME_EXPANSION_MIX:
        M2-18 Selective
        M2-38 Aggressive

    HIGH_BALANCE_APPETITE:
        M2-29 Selective
        M2-39 Aggressive

Y-axis:
    Aggressive Override Rows

Stack:
    aggressive_override_final_counteroffer_rows
    aggressive_override_final_manual_review_rows
    aggressive_override_final_decline_rows

Output:
    assets/module2_option_c_counteroffer_governance.png
    assets/module2_option_c_counteroffer_governance.svg
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

OUTPUT_PNG = OUTPUT_DIR / "module2_option_c_counteroffer_governance.png"
OUTPUT_SVG = OUTPUT_DIR / "module2_option_c_counteroffer_governance.svg"


# =============================================================================
# 2. HARDCODED SECTION 17.17 OPTION C EFFECT DATA
# =============================================================================

OPTION_C_DATA = [
    {
        "module2_run_id": "M2-05",
        "strategy_variant": "Selective",
        "scenario_label": "BASELINE_V2",
        "scenario_short_label": "Baseline\nPopulation",
        "strategy_name": "SELECTIVE_COUNTEROFFER_FEASIBILITY_STRATEGY",
        "aggressive_override_rows": 0,
        "aggressive_override_final_counteroffer_rows": 0,
        "aggressive_override_final_manual_review_rows": 0,
        "aggressive_override_final_decline_rows": 0,
    },
    {
        "module2_run_id": "M2-37",
        "strategy_variant": "Aggressive",
        "scenario_label": "BASELINE_V2",
        "scenario_short_label": "Baseline\nPopulation",
        "strategy_name": "AGGRESSIVE_COUNTEROFFER_EXPANSION_STRATEGY",
        "aggressive_override_rows": 4614,
        "aggressive_override_final_counteroffer_rows": 4067,
        "aggressive_override_final_manual_review_rows": 547,
        "aggressive_override_final_decline_rows": 0,
    },
    {
        "module2_run_id": "M2-18",
        "strategy_variant": "Selective",
        "scenario_label": "NEAR_PRIME_EXPANSION_MIX",
        "scenario_short_label": "Near-Prime\nExpansion",
        "strategy_name": "SELECTIVE_COUNTEROFFER_FEASIBILITY_STRATEGY",
        "aggressive_override_rows": 0,
        "aggressive_override_final_counteroffer_rows": 0,
        "aggressive_override_final_manual_review_rows": 0,
        "aggressive_override_final_decline_rows": 0,
    },
    {
        "module2_run_id": "M2-38",
        "strategy_variant": "Aggressive",
        "scenario_label": "NEAR_PRIME_EXPANSION_MIX",
        "scenario_short_label": "Near-Prime\nExpansion",
        "strategy_name": "AGGRESSIVE_COUNTEROFFER_EXPANSION_STRATEGY",
        "aggressive_override_rows": 4380,
        "aggressive_override_final_counteroffer_rows": 3699,
        "aggressive_override_final_manual_review_rows": 681,
        "aggressive_override_final_decline_rows": 0,
    },
    {
        "module2_run_id": "M2-29",
        "strategy_variant": "Selective",
        "scenario_label": "HIGH_BALANCE_APPETITE",
        "scenario_short_label": "High-Balance\nAppetite",
        "strategy_name": "SELECTIVE_COUNTEROFFER_FEASIBILITY_STRATEGY",
        "aggressive_override_rows": 0,
        "aggressive_override_final_counteroffer_rows": 0,
        "aggressive_override_final_manual_review_rows": 0,
        "aggressive_override_final_decline_rows": 0,
    },
    {
        "module2_run_id": "M2-39",
        "strategy_variant": "Aggressive",
        "scenario_label": "HIGH_BALANCE_APPETITE",
        "scenario_short_label": "High-Balance\nAppetite",
        "strategy_name": "AGGRESSIVE_COUNTEROFFER_EXPANSION_STRATEGY",
        "aggressive_override_rows": 8892,
        "aggressive_override_final_counteroffer_rows": 7081,
        "aggressive_override_final_manual_review_rows": 1811,
        "aggressive_override_final_decline_rows": 0,
    },
]


# =============================================================================
# 3. CHART STYLE SETTINGS
# =============================================================================

RUN_ORDER = [
    "M2-05",
    "M2-37",
    "M2-18",
    "M2-38",
    "M2-29",
    "M2-39",
]

# X positions leave visual space between scenario pairs.
X_POSITIONS = {
    "M2-05": 0.0,
    "M2-37": 0.9,
    "M2-18": 2.2,
    "M2-38": 3.1,
    "M2-29": 4.4,
    "M2-39": 5.3,
}

SCENARIO_GROUP_CENTERS = {
    "Baseline\nPopulation": 0.45,
    "Near-Prime\nExpansion": 2.65,
    "High-Balance\nAppetite": 4.85,
}

SCENARIO_SEPARATOR_X = [1.55, 3.75]

BAR_WIDTH = 0.64

# Dark theme to align with the first two README charts.
FIG_FACE = "black"
AX_FACE = "black"
TEXT_COLOR = "white"
GRID_COLOR = "white"
ZERO_LINE_COLOR = "white"

# Explicit chart colors.
FINAL_COUNTEROFFER_COLOR = "#2ca02c"
FINAL_MANUAL_REVIEW_COLOR = "#f0a62e"
FINAL_DECLINE_COLOR = "#d95f5f"
SELECTIVE_MARKER_COLOR = "#8fbcd4"
CALLOUT_BOX_COLOR = "#4f8fc4"


# =============================================================================
# 4. HELPER FUNCTIONS
# =============================================================================

def format_count(value: float | int) -> str:
    """Format row counts with commas."""
    return f"{int(value):,}"


def pct(part: float | int, total: float | int) -> float:
    """Safe percentage helper."""
    if total == 0:
        return 0.0
    return 100.0 * float(part) / float(total)


def style_axis(ax: plt.Axes) -> None:
    """Apply shared dark chart styling."""
    ax.set_facecolor(AX_FACE)
    ax.tick_params(colors=TEXT_COLOR, labelsize=9)
    ax.xaxis.label.set_color(TEXT_COLOR)
    ax.yaxis.label.set_color(TEXT_COLOR)
    ax.title.set_color(TEXT_COLOR)

    for spine in ax.spines.values():
        spine.set_color(TEXT_COLOR)
        spine.set_linewidth(0.9)

    ax.grid(
        True,
        axis="y",
        linewidth=0.45,
        alpha=0.28,
        color=GRID_COLOR,
    )

    ax.axhline(
        0,
        color=ZERO_LINE_COLOR,
        linewidth=1.0,
        alpha=0.85,
    )


# =============================================================================
# 5. PREPARE DATA
# =============================================================================

plot_df = pd.DataFrame(OPTION_C_DATA)

plot_df["run_order"] = plot_df["module2_run_id"].map(
    {run_id: idx for idx, run_id in enumerate(RUN_ORDER)}
)

plot_df["x"] = plot_df["module2_run_id"].map(X_POSITIONS)

plot_df = plot_df.sort_values("run_order").reset_index(drop=True)

plot_df["counteroffer_share"] = plot_df.apply(
    lambda r: pct(
        r["aggressive_override_final_counteroffer_rows"],
        r["aggressive_override_rows"],
    ),
    axis=1,
)

plot_df["manual_review_share"] = plot_df.apply(
    lambda r: pct(
        r["aggressive_override_final_manual_review_rows"],
        r["aggressive_override_rows"],
    ),
    axis=1,
)

plot_df["decline_share"] = plot_df.apply(
    lambda r: pct(
        r["aggressive_override_final_decline_rows"],
        r["aggressive_override_rows"],
    ),
    axis=1,
)

selective_df = plot_df.loc[plot_df["strategy_variant"] == "Selective"].copy()
aggressive_df = plot_df.loc[plot_df["strategy_variant"] == "Aggressive"].copy()


# =============================================================================
# 6. BUILD CHART
# =============================================================================

fig, ax = plt.subplots(figsize=(13.2, 7.2), dpi=160)
fig.patch.set_facecolor(FIG_FACE)

style_axis(ax)

# -----------------------------------------------------------------------------
# Selective feasibility bars / markers
# -----------------------------------------------------------------------------
# Selective bars are intentionally zero-height. We still plot markers and labels
# so the reader sees that the zero result is evidence, not missing data.
ax.scatter(
    selective_df["x"],
    selective_df["aggressive_override_rows"],
    s=80,
    marker="o",
    facecolors=AX_FACE,
    edgecolors=SELECTIVE_MARKER_COLOR,
    linewidths=1.8,
    label="Selective feasibility: 0 aggressive overrides",
    zorder=5,
)

for _, row in selective_df.iterrows():
    ax.text(
        row["x"],
        260,
        f"{row['module2_run_id']}\nSelective\n0 override rows",
        ha="center",
        va="bottom",
        fontsize=8.8,
        color=TEXT_COLOR,
    )

# -----------------------------------------------------------------------------
# Aggressive expansion stacked bars
# -----------------------------------------------------------------------------
ax.bar(
    aggressive_df["x"],
    aggressive_df["aggressive_override_final_counteroffer_rows"],
    width=BAR_WIDTH,
    color=FINAL_COUNTEROFFER_COLOR,
    alpha=0.90,
    label="Final counteroffer",
)

ax.bar(
    aggressive_df["x"],
    aggressive_df["aggressive_override_final_manual_review_rows"],
    width=BAR_WIDTH,
    bottom=aggressive_df["aggressive_override_final_counteroffer_rows"],
    color=FINAL_MANUAL_REVIEW_COLOR,
    alpha=0.92,
    label="Final manual review",
)

ax.bar(
    aggressive_df["x"],
    aggressive_df["aggressive_override_final_decline_rows"],
    width=BAR_WIDTH,
    bottom=(
        aggressive_df["aggressive_override_final_counteroffer_rows"]
        + aggressive_df["aggressive_override_final_manual_review_rows"]
    ),
    color=FINAL_DECLINE_COLOR,
    alpha=0.92,
    label="Final decline",
)

# -----------------------------------------------------------------------------
# Aggressive bar labels
# -----------------------------------------------------------------------------
for _, row in aggressive_df.iterrows():
    x = row["x"]
    total = row["aggressive_override_rows"]
    co = row["aggressive_override_final_counteroffer_rows"]
    mr = row["aggressive_override_final_manual_review_rows"]
    de = row["aggressive_override_final_decline_rows"]

    co_share = row["counteroffer_share"]
    mr_share = row["manual_review_share"]

    # Total label above each aggressive bar.
    ax.text(
        x,
        total + 320,
        f"{row['module2_run_id']}\nAggressive\n{format_count(total)} override rows",
        ha="center",
        va="bottom",
        fontsize=8.8,
        color=TEXT_COLOR,
        fontweight="bold",
    )

    # Counteroffer segment label.
    if co > 0:
        ax.text(
            x,
            co / 2,
            f"{format_count(co)}\nCO\n{co_share:.0f}%",
            ha="center",
            va="center",
            fontsize=8.3,
            color=TEXT_COLOR,
            fontweight="bold",
        )

    # Manual-review segment label.
    if mr > 0:
        ax.text(
            x,
            co + mr / 2,
            f"{format_count(mr)}\nMR\n{mr_share:.0f}%",
            ha="center",
            va="center",
            fontsize=8.0,
            color="black",
            fontweight="bold",
        )

    # Decline segment is zero in this campaign, but keep logic for completeness.
    if de > 0:
        ax.text(
            x,
            co + mr + de / 2,
            f"{format_count(de)}\nDecline",
            ha="center",
            va="center",
            fontsize=8.0,
            color=TEXT_COLOR,
            fontweight="bold",
        )

# -----------------------------------------------------------------------------
# Scenario group labels and separators
# -----------------------------------------------------------------------------
for sep_x in SCENARIO_SEPARATOR_X:
    ax.axvline(
        sep_x,
        color=TEXT_COLOR,
        linewidth=0.8,
        alpha=0.28,
        linestyle="--",
    )

for scenario_short_label, group_center in SCENARIO_GROUP_CENTERS.items():
    ax.text(
        group_center,
        -0.105,
        scenario_short_label,
        transform=ax.get_xaxis_transform(),
        ha="center",
        va="top",
        fontsize=9.2,
        color=TEXT_COLOR,
        fontweight="bold",
    )

# -----------------------------------------------------------------------------
# Callouts
# -----------------------------------------------------------------------------
ax.text(
    0.02,
    0.92,
    "Selective feasibility:\n0 aggressive override rows",
    transform=ax.transAxes,
    fontsize=9.4,
    va="top",
    ha="left",
    color=TEXT_COLOR,
    bbox={
        "boxstyle": "round,pad=0.45",
        "facecolor": CALLOUT_BOX_COLOR,
        "edgecolor": CALLOUT_BOX_COLOR,
        "alpha": 0.88,
    },
)

ax.text(
    0.57,
    0.92,
    "Aggressive expansion:\ngoverned feasibility routing,\nnot approval bypass",
    transform=ax.transAxes,
    fontsize=9.4,
    va="top",
    ha="left",
    color=TEXT_COLOR,
    bbox={
        "boxstyle": "round,pad=0.45",
        "facecolor": CALLOUT_BOX_COLOR,
        "edgecolor": CALLOUT_BOX_COLOR,
        "alpha": 0.88,
    },
)

# Highlight M2-39 as the largest pressure point.
m2_39 = aggressive_df.loc[aggressive_df["module2_run_id"] == "M2-39"].iloc[0]
ax.annotate(
    "Largest override\npopulation",
    xy=(m2_39["x"], m2_39["aggressive_override_rows"]),
    xytext=(34, 30),
    textcoords="offset points",
    fontsize=9,
    color=TEXT_COLOR,
    arrowprops={
        "arrowstyle": "->",
        "linewidth": 0.9,
        "color": TEXT_COLOR,
        "alpha": 0.85,
    },
    bbox={
        "boxstyle": "round,pad=0.30",
        "facecolor": AX_FACE,
        "edgecolor": TEXT_COLOR,
        "alpha": 0.80,
    },
)

# -----------------------------------------------------------------------------
# Titles and axes
# -----------------------------------------------------------------------------
ax.set_title(
    "Option C Counteroffer Governance",
    fontsize=20,
    fontweight="bold",
    color=TEXT_COLOR,
    pad=22,
)

fig.text(
    0.5,
    0.925,
    "Selective feasibility vs aggressive expansion across matched scenario contexts",
    ha="center",
    va="center",
    fontsize=11.2,
    color=TEXT_COLOR,
)

fig.text(
    0.5,
    0.885,
    "Stacked bars show where aggressive override rows resolved: final counteroffer, manual review, or decline",
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

ax.set_ylabel(
    "Aggressive Override Rows",
    fontsize=11,
    color=TEXT_COLOR,
)

ax.set_xlabel(
    "Option C Strategy Pair by Scenario Context",
    fontsize=10.5,
    color=TEXT_COLOR,
    labelpad=40,
)

# Bar-level x tick labels.
ax.set_xticks(plot_df["x"])
ax.set_xticklabels(
    [
        f"{row['module2_run_id']}\n{row['strategy_variant']}"
        for _, row in plot_df.iterrows()
    ],
    color=TEXT_COLOR,
    fontsize=8.8,
)

# Y-axis formatting.
ax.yaxis.set_major_formatter(mtick.StrMethodFormatter("{x:,.0f}"))

y_max = max(plot_df["aggressive_override_rows"]) * 1.22
ax.set_ylim(0, y_max)

# X-axis limits with enough room for side callout and M2-39 annotation.
ax.set_xlim(-0.65, 6.15)

# Legend.
legend = ax.legend(
    loc="upper left",
    bbox_to_anchor=(1.02, 0.88),
    fontsize=8.5,
    frameon=True,
    title="Final outcome path",
    title_fontsize=9,
)

legend.get_frame().set_facecolor(AX_FACE)
legend.get_frame().set_edgecolor(TEXT_COLOR)
for text in legend.get_texts():
    text.set_color(TEXT_COLOR)
legend.get_title().set_color(TEXT_COLOR)

# Right-side interpretation note.
ax.text(
    1.02,
    0.44,
    "Readout:\n\n"
    "Selective runs preserve\n"
    "review-oriented treatment.\n\n"
    "Aggressive runs route\n"
    "additional severe requested-\n"
    "structure cases into\n"
    "counteroffer feasibility.\n\n"
    "Observed final decline rows:\n"
    "0",
    transform=ax.transAxes,
    fontsize=8.5,
    va="top",
    ha="left",
    color=TEXT_COLOR,
    bbox={
        "boxstyle": "round,pad=0.50",
        "facecolor": CALLOUT_BOX_COLOR,
        "edgecolor": CALLOUT_BOX_COLOR,
        "alpha": 0.88,
    },
)

# Footer caption.
caption = (
    "Selective feasibility produces zero aggressive override rows. "
    "Aggressive expansion creates governed override volume that resolves mostly to final counteroffer "
    "and partly to manual review, with zero final aggressive override declines observed in this campaign."
)

fig.text(
    0.5,
    0.035,
    "\n".join(textwrap.wrap(caption, width=150)),
    ha="center",
    va="center",
    fontsize=9.2,
    color=TEXT_COLOR,
)

# Layout room:
#   right side for legend / readout
#   bottom for scenario labels and caption
fig.tight_layout(rect=[0.04, 0.12, 0.80, 0.84])


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
        f"{row['module2_run_id']:>5} | "
        f"{row['scenario_label']:<28} | "
        f"{row['strategy_variant']:<10} | "
        f"Override rows: {format_count(row['aggressive_override_rows']):>6} | "
        f"Final CO: {format_count(row['aggressive_override_final_counteroffer_rows']):>6} | "
        f"Final MR: {format_count(row['aggressive_override_final_manual_review_rows']):>5} | "
        f"Final Decline: {format_count(row['aggressive_override_final_decline_rows']):>3}"
    )
```
<!-- END_MESSAGE C040-M02383 -->


---

<a id="c040-m02385"></a>

### C040-M02385

**Andrew** · 2026-05-26T16:03:27.391000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02385 -->
this is very good, especially for a first pass.  but, what is the point of the final decline (when there are zero) or the M2-05/M2-18/M2-29 (when there are zero)? what did change in M2-05/M2-18/M2-29 and are we missing an opportunity to illustrate that as well?
<!-- END_MESSAGE C040-M02385 -->


---

<a id="c040-m02389"></a>

### C040-M02389

**ChatGPT** · 2026-05-26T16:09:43.594545-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02389 -->
Yes — you are exactly right to question it. The first-pass chart proves the aggressive side well, but it underuses the selective side.

The current third chart answers:

> “When aggressive overrides occur, where do they resolve?”

That is useful, but it only tells half the Option C story. It makes M2-05 / M2-18 / M2-29 look like “nothing happened,” when the real selective-feasibility story is:

> **Selective feasibility did not create aggressive override rows; instead, it preserved conservative treatment by reducing counteroffer exposure and shifting more cases to manual review.**

That is very different from “zero effect.”

## What final decline adds

The `final decline = 0` result is valuable as a **governance proof**, but it is not visually useful as a stacked bar segment because it is zero everywhere.

I would not allocate chart space to a visible “final decline” stack. Instead, I would show it as a badge or callout:

```text
Observed aggressive override final declines: 0
```

That preserves the important message:

> Aggressive expansion did not produce a hidden decline bucket or uncontrolled failed-path behavior.

But it keeps the chart focused on the actual nonzero movement: final counteroffers and manual reviews.

## What the selective runs actually changed

The selective runs did not create aggressive override rows, but they materially changed the ordinary counteroffer posture.

From the 17.17 campaign output:

```text
M2-05 — Baseline population selective feasibility
    ordinary counteroffer candidate rows: -2,532
    ordinary candidate rate: -5.06pp
    counteroffer rate: -4.30pp
    manual review rate: +6.94pp
    simulated offer exposure rate: -6.94pp
    approved amount: -$363M
    approved Expected Loss: -$8.0M

M2-18 — Near-prime expansion selective feasibility
    ordinary counteroffer candidate rows: -2,610
    ordinary candidate rate: -5.22pp
    counteroffer rate: -4.28pp
    manual review rate: +6.25pp
    simulated offer exposure rate: -6.25pp
    approved amount: -$378M
    approved Expected Loss: -$10.2M

M2-29 — High-balance appetite selective feasibility
    ordinary counteroffer candidate rows: -778
    ordinary candidate rate: -1.56pp
    counteroffer rate: -0.72pp
    manual review rate: +2.85pp
    simulated offer exposure rate: -2.85pp
    approved amount: -$323M
    approved Expected Loss: -$6.4M
```

That is a strong story. Selective feasibility is not inactive. It is **conservative counteroffer governance**:

```text
fewer ordinary counteroffer candidates
lower counteroffer rate
higher manual review rate
lower offer exposure
lower approved amount
lower approved Expected Loss
zero aggressive override rows
```

That is worth visualizing.

## What the aggressive runs added

The aggressive runs inherit the same ordinary counteroffer candidate reduction, but then add aggressive override routing:

```text
M2-37 — Baseline population aggressive expansion
    aggressive override rows: 4,614
    final counteroffer: 4,067
    final manual review: 547
    final decline: 0
    counteroffer rate: +3.82pp
    manual review rate: -1.18pp
    offer exposure rate: +1.18pp
    approved amount: -$188M
    approved Expected Loss: -$4.2M

M2-38 — Near-prime expansion aggressive expansion
    aggressive override rows: 4,380
    final counteroffer: 3,699
    final manual review: 681
    final decline: 0
    counteroffer rate: +3.10pp
    manual review rate: -1.13pp
    offer exposure rate: +1.13pp
    approved amount: -$220M
    approved Expected Loss: -$5.9M

M2-39 — High-balance appetite aggressive expansion
    aggressive override rows: 8,892
    final counteroffer: 7,081
    final manual review: 1,811
    final decline: 0
    counteroffer rate: +13.43pp
    manual review rate: -11.30pp
    offer exposure rate: +11.30pp
    approved amount: +$62M
    approved Expected Loss: +$0.7M
```

M2-39 is especially interesting because high-balance appetite creates the largest aggressive override opportunity. That is a real scenario-context insight, not just an Option C mechanics detail.

## Better third-chart objective

I would revise the third-chart thesis from:

> “Aggressive override rows resolve to counteroffer or manual review.”

to:

> **“Option C splits counteroffer governance into two different operating modes: selective feasibility reduces counteroffer exposure and preserves review discipline, while aggressive expansion routes additional severe requested-structure cases into governed feasibility testing.”**

That is a much stronger chart.

## Recommended revised chart structure

I would make the third chart a **two-panel Option C governance chart**.

### Panel A — Selective feasibility effect

Title:

```text
Selective Feasibility: Conservative Counteroffer Treatment
```

Visual:

```text
Diverging horizontal bars by scenario
```

Rows:

```text
Baseline population — M2-05
Near-prime expansion — M2-18
High-balance appetite — M2-29
```

Bars:

```text
Δ Counteroffer Rate
Δ Manual Review Rate
```

Optional third bar:

```text
Δ Offer Exposure Rate
```

Message:

```text
Selective feasibility reduces counteroffer / offer exposure and increases manual review.
It does not create aggressive override rows.
```

This shows what changed in M2-05 / M2-18 / M2-29.

### Panel B — Aggressive expansion outcome routing

Title:

```text
Aggressive Expansion: Governed Feasibility Routing
```

Visual:

```text
Stacked bars by scenario
```

Rows or x-axis bars:

```text
M2-37 Baseline population
M2-38 Near-prime expansion
M2-39 High-balance appetite
```

Stack:

```text
Final counteroffer rows
Final manual review rows
```

Not a stack:

```text
Final decline rows = 0
```

Show final decline as a callout:

```text
Observed aggressive override final declines: 0
```

Message:

```text
Aggressive expansion creates override volume, mostly resolving to final counteroffer,
with the remaining cases going to manual review.
```

This preserves the best part of the first-pass chart but eliminates the visual dead space from zero selective bars and zero decline segments.

## Why this is a value add versus charts 1 and 2

Chart 1 says:

```text
Where each strategy sits on the access / approved-risk-density frontier.
```

Chart 2 says:

```text
How selected strategies move access, approved dollars, and approved Expected Loss versus baseline.
```

The revised Chart 3 says:

```text
How the counteroffer mechanism works.
```

That is different and valuable. It explains the architecture behind the frontier movement:

```text
Selective feasibility:
    conservative treatment
    fewer counteroffers
    more manual review
    zero aggressive overrides

Aggressive expansion:
    additional governed feasibility routing
    more final counteroffers
    some manual review
    zero final aggressive override declines
```

This aligns directly with the Module 2 design principle that strategy outcomes are not black-box labels; they emerge through a transparent chain of strategy controls, rule triggers, ordinary vs aggressive counteroffer path evidence, exposure treatment, final outcome resolution, reason codes, archive comparison, and evidence capture. fileciteturn47file4

## My recommendation

Do **not** keep the current third chart as only stacked aggressive override bars.

Use the revised two-panel version:

```text
Left panel:
    Selective feasibility effect
    Δ counteroffer rate and Δ manual review rate

Right panel:
    Aggressive expansion override outcomes
    final counteroffer rows and final manual review rows

Callout:
    Aggressive override final declines observed: 0
```

That will make the third chart much more compelling because it answers both sides of Option C:

> **What did selective feasibility do?**  
> It preserved conservative treatment and shifted more cases to review.

> **What did aggressive expansion do?**  
> It created governed override routing into counteroffer feasibility, mostly resolving to final counteroffers.

That is the fuller and more interesting story.
<!-- END_MESSAGE C040-M02389 -->


---

<a id="c040-m02390"></a>

### C040-M02390

**Andrew** · 2026-05-26T16:13:56.019000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02390 -->
I like that.  please update python code to tell that more complete story.
<!-- END_MESSAGE C040-M02390 -->


---

<a id="c040-m02392"></a>

### C040-M02392

**ChatGPT** · 2026-05-26T16:18:51.093279-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02392 -->
This version tells the fuller Option C story: selective feasibility is not “nothing happened”; it is conservative counteroffer treatment, while aggressive expansion creates governed feasibility routing rather than approval bypass. fileciteturn47file55

```python
"""
Module 2 README Chart 3
Option C Counteroffer Governance: Selective Feasibility vs Aggressive Expansion

This version uses hardcoded final-campaign Section 17.17 values.

Chart thesis:
    Option C is not "approve more."
    It is governed counteroffer feasibility routing.

    Selective feasibility:
        preserves conservative treatment
        reduces counteroffer / offer exposure
        increases manual review
        produces zero aggressive override rows

    Aggressive expansion:
        routes additional severe requested-structure cases into governed feasibility testing
        resolves many to final counteroffer
        sends some to manual review
        produces zero final aggressive override declines in the observed campaign

Data source:
    Final campaign Section 17.17:
    Option C counteroffer strategy split effect check.

Chart structure:
    Left panel:
        Selective feasibility effect
        Delta counteroffer rate, manual-review rate, and offer-exposure rate vs baseline

    Right panel:
        Aggressive expansion outcome routing
        Aggressive override rows stacked by final counteroffer and final manual review

Output:
    assets/module2_option_c_counteroffer_governance_complete_story.png
    assets/module2_option_c_counteroffer_governance_complete_story.svg
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

OUTPUT_PNG = OUTPUT_DIR / "module2_option_c_counteroffer_governance_complete_story.png"
OUTPUT_SVG = OUTPUT_DIR / "module2_option_c_counteroffer_governance_complete_story.svg"


# =============================================================================
# 2. HARDCODED SECTION 17.17 OPTION C EFFECT DATA
# =============================================================================

SELECTIVE_DATA = [
    {
        "module2_run_id": "M2-05",
        "scenario_label": "BASELINE_V2",
        "scenario_short_label": "Baseline\nPopulation",
        "strategy_name": "SELECTIVE_COUNTEROFFER_FEASIBILITY_STRATEGY",
        "aggressive_override_rows": 0,
        "delta_counteroffer_rate_pp": -4.30,
        "delta_manual_review_rate_pp": 6.94,
        "delta_offer_exposure_rate_pp": -6.94,
        "delta_ordinary_counteroffer_candidate_rows": -2532,
        "delta_ordinary_counteroffer_candidate_rate_pp": -5.06,
        "delta_total_approved_amount_m": -363.4,
        "delta_total_approved_expected_loss_m": -8.0,
    },
    {
        "module2_run_id": "M2-18",
        "scenario_label": "NEAR_PRIME_EXPANSION_MIX",
        "scenario_short_label": "Near-Prime\nExpansion",
        "strategy_name": "SELECTIVE_COUNTEROFFER_FEASIBILITY_STRATEGY",
        "aggressive_override_rows": 0,
        "delta_counteroffer_rate_pp": -4.28,
        "delta_manual_review_rate_pp": 6.25,
        "delta_offer_exposure_rate_pp": -6.25,
        "delta_ordinary_counteroffer_candidate_rows": -2610,
        "delta_ordinary_counteroffer_candidate_rate_pp": -5.22,
        "delta_total_approved_amount_m": -378.0,
        "delta_total_approved_expected_loss_m": -10.2,
    },
    {
        "module2_run_id": "M2-29",
        "scenario_label": "HIGH_BALANCE_APPETITE",
        "scenario_short_label": "High-Balance\nAppetite",
        "strategy_name": "SELECTIVE_COUNTEROFFER_FEASIBILITY_STRATEGY",
        "aggressive_override_rows": 0,
        "delta_counteroffer_rate_pp": -0.72,
        "delta_manual_review_rate_pp": 2.85,
        "delta_offer_exposure_rate_pp": -2.85,
        "delta_ordinary_counteroffer_candidate_rows": -778,
        "delta_ordinary_counteroffer_candidate_rate_pp": -1.56,
        "delta_total_approved_amount_m": -323.0,
        "delta_total_approved_expected_loss_m": -6.4,
    },
]

AGGRESSIVE_DATA = [
    {
        "module2_run_id": "M2-37",
        "scenario_label": "BASELINE_V2",
        "scenario_short_label": "Baseline\nPopulation",
        "strategy_name": "AGGRESSIVE_COUNTEROFFER_EXPANSION_STRATEGY",
        "aggressive_override_rows": 4614,
        "aggressive_override_final_counteroffer_rows": 4067,
        "aggressive_override_final_manual_review_rows": 547,
        "aggressive_override_final_decline_rows": 0,
        "delta_counteroffer_rate_pp": 3.82,
        "delta_manual_review_rate_pp": -1.18,
        "delta_offer_exposure_rate_pp": 1.18,
        "delta_total_approved_amount_m": -187.5,
        "delta_total_approved_expected_loss_m": -4.2,
    },
    {
        "module2_run_id": "M2-38",
        "scenario_label": "NEAR_PRIME_EXPANSION_MIX",
        "scenario_short_label": "Near-Prime\nExpansion",
        "strategy_name": "AGGRESSIVE_COUNTEROFFER_EXPANSION_STRATEGY",
        "aggressive_override_rows": 4380,
        "aggressive_override_final_counteroffer_rows": 3699,
        "aggressive_override_final_manual_review_rows": 681,
        "aggressive_override_final_decline_rows": 0,
        "delta_counteroffer_rate_pp": 3.10,
        "delta_manual_review_rate_pp": -1.13,
        "delta_offer_exposure_rate_pp": 1.13,
        "delta_total_approved_amount_m": -220.0,
        "delta_total_approved_expected_loss_m": -5.9,
    },
    {
        "module2_run_id": "M2-39",
        "scenario_label": "HIGH_BALANCE_APPETITE",
        "scenario_short_label": "High-Balance\nAppetite",
        "strategy_name": "AGGRESSIVE_COUNTEROFFER_EXPANSION_STRATEGY",
        "aggressive_override_rows": 8892,
        "aggressive_override_final_counteroffer_rows": 7081,
        "aggressive_override_final_manual_review_rows": 1811,
        "aggressive_override_final_decline_rows": 0,
        "delta_counteroffer_rate_pp": 13.43,
        "delta_manual_review_rate_pp": -11.30,
        "delta_offer_exposure_rate_pp": 11.30,
        "delta_total_approved_amount_m": 62.0,
        "delta_total_approved_expected_loss_m": 0.7,
    },
]


# =============================================================================
# 3. CHART STYLE SETTINGS
# =============================================================================

# Dark theme to align with the first two README charts.
FIG_FACE = "black"
AX_FACE = "black"
TEXT_COLOR = "white"
GRID_COLOR = "white"
ZERO_LINE_COLOR = "white"

# Colors chosen for consistent interpretation:
#   blue  = offer exposure
#   orange = manual review / review path
#   green = counteroffer / final counteroffer path
#   red = decline, used only as zero-decline badge text / possible future stack
OFFER_EXPOSURE_COLOR = "#2f84c4"
COUNTEROFFER_DELTA_COLOR = "#2ca02c"
MANUAL_REVIEW_DELTA_COLOR = "#f0a62e"

FINAL_COUNTEROFFER_COLOR = "#2ca02c"
FINAL_MANUAL_REVIEW_COLOR = "#f0a62e"
FINAL_DECLINE_COLOR = "#d95f5f"

CALLOUT_BOX_COLOR = "#4f8fc4"

BAR_ALPHA = 0.90


# =============================================================================
# 4. HELPER FUNCTIONS
# =============================================================================

def format_count(value: float | int) -> str:
    """Format row counts with commas."""
    return f"{int(value):,}"


def format_pp(value: float | int) -> str:
    """Format percentage-point movement."""
    sign = "+" if value >= 0 else "-"
    return f"{sign}{abs(value):.1f}pp"


def format_millions(value: float | int) -> str:
    """Format dollar movement in millions."""
    sign = "+" if value >= 0 else "-"
    return f"{sign}${abs(value):.0f}M"


def pct(part: float | int, total: float | int) -> float:
    """Safe percentage helper."""
    if total == 0:
        return 0.0
    return 100.0 * float(part) / float(total)


def style_dark_axis(ax: plt.Axes) -> None:
    """Apply shared dark chart styling."""
    ax.set_facecolor(AX_FACE)
    ax.tick_params(colors=TEXT_COLOR, labelsize=9)
    ax.xaxis.label.set_color(TEXT_COLOR)
    ax.yaxis.label.set_color(TEXT_COLOR)
    ax.title.set_color(TEXT_COLOR)

    for spine in ax.spines.values():
        spine.set_color(TEXT_COLOR)
        spine.set_linewidth(0.9)

    ax.grid(
        True,
        linewidth=0.45,
        alpha=0.28,
        color=GRID_COLOR,
    )


def add_bar_end_labels(
    ax: plt.Axes,
    values: pd.Series,
    y_positions: list[float],
    labels: list[str],
    x_offset_ratio: float = 0.018,
    fontsize: float = 8.2,
) -> None:
    """Add value labels at the end of horizontal bars."""
    x_min, x_max = ax.get_xlim()
    x_range = x_max - x_min

    for value, y, label in zip(values, y_positions, labels):
        if value >= 0:
            x_text = value + x_range * x_offset_ratio
            ha = "left"
        else:
            x_text = value - x_range * x_offset_ratio
            ha = "right"

        ax.text(
            x_text,
            y,
            label,
            va="center",
            ha=ha,
            fontsize=fontsize,
            color=TEXT_COLOR,
        )


# =============================================================================
# 5. PREPARE DATA
# =============================================================================

selective_df = pd.DataFrame(SELECTIVE_DATA)
aggressive_df = pd.DataFrame(AGGRESSIVE_DATA)

selective_df["display_label"] = (
    selective_df["scenario_short_label"]
    + "\n"
    + selective_df["module2_run_id"]
)

aggressive_df["display_label"] = (
    aggressive_df["scenario_short_label"]
    + "\n"
    + aggressive_df["module2_run_id"]
)

aggressive_df["counteroffer_share"] = aggressive_df.apply(
    lambda r: pct(
        r["aggressive_override_final_counteroffer_rows"],
        r["aggressive_override_rows"],
    ),
    axis=1,
)

aggressive_df["manual_review_share"] = aggressive_df.apply(
    lambda r: pct(
        r["aggressive_override_final_manual_review_rows"],
        r["aggressive_override_rows"],
    ),
    axis=1,
)

aggressive_df["decline_share"] = aggressive_df.apply(
    lambda r: pct(
        r["aggressive_override_final_decline_rows"],
        r["aggressive_override_rows"],
    ),
    axis=1,
)


# =============================================================================
# 6. BUILD CHART
# =============================================================================

fig = plt.figure(figsize=(16.0, 8.3), dpi=160)
fig.patch.set_facecolor(FIG_FACE)

grid = fig.add_gridspec(
    nrows=1,
    ncols=2,
    width_ratios=[1.10, 1.05],
    wspace=0.22,
)

ax_left = fig.add_subplot(grid[0, 0])
ax_right = fig.add_subplot(grid[0, 1])

style_dark_axis(ax_left)
style_dark_axis(ax_right)


# =============================================================================
# 6A. LEFT PANEL — SELECTIVE FEASIBILITY EFFECT
# =============================================================================

y_base = list(range(len(selective_df)))
bar_h = 0.22

metric_specs = [
    {
        "label": "Counteroffer Δ",
        "column": "delta_counteroffer_rate_pp",
        "color": COUNTEROFFER_DELTA_COLOR,
        "offset": -bar_h,
        "suffix": " CO",
    },
    {
        "label": "Manual review Δ",
        "column": "delta_manual_review_rate_pp",
        "color": MANUAL_REVIEW_DELTA_COLOR,
        "offset": 0.0,
        "suffix": " review",
    },
    {
        "label": "Offer exposure Δ",
        "column": "delta_offer_exposure_rate_pp",
        "color": OFFER_EXPOSURE_COLOR,
        "offset": bar_h,
        "suffix": " offer",
    },
]

for spec in metric_specs:
    y_positions = [y + spec["offset"] for y in y_base]
    values = selective_df[spec["column"]]

    ax_left.barh(
        y_positions,
        values,
        height=bar_h * 0.88,
        color=spec["color"],
        alpha=BAR_ALPHA,
        label=spec["label"],
    )

# Zero line.
ax_left.axvline(
    0,
    color=ZERO_LINE_COLOR,
    linewidth=1.1,
    alpha=0.88,
)

# Labels for bars.
for spec in metric_specs:
    y_positions = [y + spec["offset"] for y in y_base]
    values = selective_df[spec["column"]]
    labels = [
        f"{format_pp(value)}{spec['suffix']}"
        for value in values
    ]
    add_bar_end_labels(
        ax=ax_left,
        values=values,
        y_positions=y_positions,
        labels=labels,
        fontsize=7.8,
    )

# Y-axis scenario labels.
ax_left.set_yticks(y_base)
ax_left.set_yticklabels(
    selective_df["display_label"],
    color=TEXT_COLOR,
    fontsize=9.0,
)

ax_left.invert_yaxis()

# Symmetric x-axis.
ax_left.set_xlim(-8.5, 8.5)

ax_left.set_title(
    "Selective Feasibility:\nConservative Counteroffer Treatment",
    fontsize=13.5,
    fontweight="bold",
    color=TEXT_COLOR,
    pad=14,
)

ax_left.set_xlabel(
    "Change vs matched baseline (percentage points)",
    fontsize=9.5,
    color=TEXT_COLOR,
    labelpad=10,
)

ax_left.xaxis.set_major_formatter(mtick.FormatStrFormatter("%.0f"))

# Panel interpretation note.
ax_left.text(
    0.02,
    0.04,
    "Selective runs:\n"
    "0 aggressive override rows\n\n"
    "Effect shown here:\n"
    "fewer counteroffers,\n"
    "more manual review,\n"
    "lower offer exposure",
    transform=ax_left.transAxes,
    fontsize=8.5,
    va="bottom",
    ha="left",
    color=TEXT_COLOR,
    bbox={
        "boxstyle": "round,pad=0.45",
        "facecolor": CALLOUT_BOX_COLOR,
        "edgecolor": CALLOUT_BOX_COLOR,
        "alpha": 0.88,
    },
)

# Add compact approved economics note, but keep it secondary.
selective_econ_note = (
    "Approved $ and EL also fell:\n"
    "M2-05: -$363M / -$8.0M EL\n"
    "M2-18: -$378M / -$10.2M EL\n"
    "M2-29: -$323M / -$6.4M EL"
)

ax_left.text(
    0.98,
    0.04,
    selective_econ_note,
    transform=ax_left.transAxes,
    fontsize=7.9,
    va="bottom",
    ha="right",
    color=TEXT_COLOR,
    bbox={
        "boxstyle": "round,pad=0.42",
        "facecolor": AX_FACE,
        "edgecolor": TEXT_COLOR,
        "alpha": 0.78,
    },
)

legend_left = ax_left.legend(
    loc="upper right",
    fontsize=8.0,
    frameon=True,
    title="Selective movement",
    title_fontsize=8.5,
)

legend_left.get_frame().set_facecolor(AX_FACE)
legend_left.get_frame().set_edgecolor(TEXT_COLOR)
for text in legend_left.get_texts():
    text.set_color(TEXT_COLOR)
legend_left.get_title().set_color(TEXT_COLOR)


# =============================================================================
# 6B. RIGHT PANEL — AGGRESSIVE EXPANSION OUTCOME ROUTING
# =============================================================================

x_positions = list(range(len(aggressive_df)))
bar_width = 0.58

co = aggressive_df["aggressive_override_final_counteroffer_rows"]
mr = aggressive_df["aggressive_override_final_manual_review_rows"]
decline = aggressive_df["aggressive_override_final_decline_rows"]

ax_right.bar(
    x_positions,
    co,
    width=bar_width,
    color=FINAL_COUNTEROFFER_COLOR,
    alpha=0.92,
    label="Final counteroffer",
)

ax_right.bar(
    x_positions,
    mr,
    width=bar_width,
    bottom=co,
    color=FINAL_MANUAL_REVIEW_COLOR,
    alpha=0.94,
    label="Final manual review",
)

# Decline is zero in this campaign. Keep the data logic, but do not create a visually empty
# legend-driven segment unless future data has positive rows.
if decline.sum() > 0:
    ax_right.bar(
        x_positions,
        decline,
        width=bar_width,
        bottom=co + mr,
        color=FINAL_DECLINE_COLOR,
        alpha=0.94,
        label="Final decline",
    )

# Bar labels and segment shares.
for x, (_, row) in zip(x_positions, aggressive_df.iterrows()):
    total = row["aggressive_override_rows"]
    co_count = row["aggressive_override_final_counteroffer_rows"]
    mr_count = row["aggressive_override_final_manual_review_rows"]

    co_share = row["counteroffer_share"]
    mr_share = row["manual_review_share"]

    # Total override rows above bar.
    ax_right.text(
        x,
        total + 360,
        f"{row['module2_run_id']}\n{format_count(total)} override rows",
        ha="center",
        va="bottom",
        fontsize=8.6,
        color=TEXT_COLOR,
        fontweight="bold",
    )

    # Counteroffer segment label.
    ax_right.text(
        x,
        co_count / 2,
        f"{format_count(co_count)}\nCO\n{co_share:.0f}%",
        ha="center",
        va="center",
        fontsize=8.2,
        color=TEXT_COLOR,
        fontweight="bold",
    )

    # Manual review segment label.
    ax_right.text(
        x,
        co_count + (mr_count / 2),
        f"{format_count(mr_count)}\nMR\n{mr_share:.0f}%",
        ha="center",
        va="center",
        fontsize=8.0,
        color="black",
        fontweight="bold",
    )

# Axes and labels.
ax_right.set_title(
    "Aggressive Expansion:\nGoverned Feasibility Routing",
    fontsize=13.5,
    fontweight="bold",
    color=TEXT_COLOR,
    pad=14,
)

ax_right.set_ylabel(
    "Aggressive Override Rows",
    fontsize=9.8,
    color=TEXT_COLOR,
)

ax_right.set_xticks(x_positions)
ax_right.set_xticklabels(
    aggressive_df["display_label"],
    color=TEXT_COLOR,
    fontsize=9.0,
)

ax_right.yaxis.set_major_formatter(mtick.StrMethodFormatter("{x:,.0f}"))

y_max = max(aggressive_df["aggressive_override_rows"]) * 1.23
ax_right.set_ylim(0, y_max)

# Interpretation note.
ax_right.text(
    0.02,
    0.94,
    "Aggressive runs:\n"
    "additional severe requested-\n"
    "structure cases enter\n"
    "counteroffer feasibility",
    transform=ax_right.transAxes,
    fontsize=8.5,
    va="top",
    ha="left",
    color=TEXT_COLOR,
    bbox={
        "boxstyle": "round,pad=0.45",
        "facecolor": CALLOUT_BOX_COLOR,
        "edgecolor": CALLOUT_BOX_COLOR,
        "alpha": 0.88,
    },
)

# Zero-decline badge.
ax_right.text(
    0.98,
    0.08,
    "Observed final aggressive\noverride declines: 0",
    transform=ax_right.transAxes,
    fontsize=8.8,
    va="bottom",
    ha="right",
    color=TEXT_COLOR,
    bbox={
        "boxstyle": "round,pad=0.45",
        "facecolor": CALLOUT_BOX_COLOR,
        "edgecolor": CALLOUT_BOX_COLOR,
        "alpha": 0.88,
    },
)

# M2-39 callout.
m2_39_idx = aggressive_df.index[aggressive_df["module2_run_id"] == "M2-39"][0]
m2_39_x = x_positions[list(aggressive_df.index).index(m2_39_idx)]
m2_39_total = aggressive_df.loc[m2_39_idx, "aggressive_override_rows"]

ax_right.annotate(
    "Largest override\npopulation",
    xy=(m2_39_x, m2_39_total),
    xytext=(-65, 38),
    textcoords="offset points",
    fontsize=8.6,
    color=TEXT_COLOR,
    arrowprops={
        "arrowstyle": "->",
        "linewidth": 0.9,
        "color": TEXT_COLOR,
        "alpha": 0.86,
    },
    bbox={
        "boxstyle": "round,pad=0.32",
        "facecolor": AX_FACE,
        "edgecolor": TEXT_COLOR,
        "alpha": 0.80,
    },
)

legend_right = ax_right.legend(
    loc="upper right",
    fontsize=8.2,
    frameon=True,
    title="Aggressive final path",
    title_fontsize=8.7,
)

legend_right.get_frame().set_facecolor(AX_FACE)
legend_right.get_frame().set_edgecolor(TEXT_COLOR)
for text in legend_right.get_texts():
    text.set_color(TEXT_COLOR)
legend_right.get_title().set_color(TEXT_COLOR)


# =============================================================================
# 6C. GLOBAL TITLES AND CAPTION
# =============================================================================

fig.suptitle(
    "Option C Counteroffer Governance",
    fontsize=20,
    fontweight="bold",
    color=TEXT_COLOR,
    y=0.972,
)

fig.text(
    0.5,
    0.928,
    "Selective feasibility preserves review discipline; aggressive expansion creates governed counteroffer-routing volume",
    ha="center",
    va="center",
    fontsize=11.0,
    color=TEXT_COLOR,
)

fig.text(
    0.5,
    0.888,
    "Left panel = what changed in selective runs     |     Right panel = where aggressive override rows resolved",
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

caption = (
    "Option C separates two counteroffer operating modes: selective feasibility reduces ordinary "
    "counteroffer exposure and preserves review-oriented handling, while aggressive expansion routes "
    "additional severe requested-structure cases into governed feasibility testing. Aggressive override "
    "rows resolved mostly to final counteroffer, partly to manual review, and never to final decline in this campaign."
)

fig.text(
    0.5,
    0.035,
    "\n".join(textwrap.wrap(caption, width=165)),
    ha="center",
    va="center",
    fontsize=9.0,
    color=TEXT_COLOR,
)

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

print("\nSelective feasibility data used:")
for _, row in selective_df.iterrows():
    print(
        f"{row['module2_run_id']:>5} | "
        f"{row['scenario_label']:<28} | "
        f"CO Δ: {format_pp(row['delta_counteroffer_rate_pp']):>7} | "
        f"MR Δ: {format_pp(row['delta_manual_review_rate_pp']):>7} | "
        f"Offer Δ: {format_pp(row['delta_offer_exposure_rate_pp']):>7} | "
        f"Aggressive overrides: {format_count(row['aggressive_override_rows'])}"
    )

print("\nAggressive expansion data used:")
for _, row in aggressive_df.iterrows():
    print(
        f"{row['module2_run_id']:>5} | "
        f"{row['scenario_label']:<28} | "
        f"Override rows: {format_count(row['aggressive_override_rows']):>6} | "
        f"Final CO: {format_count(row['aggressive_override_final_counteroffer_rows']):>6} | "
        f"Final MR: {format_count(row['aggressive_override_final_manual_review_rows']):>5} | "
        f"Final Decline: {format_count(row['aggressive_override_final_decline_rows']):>3}"
    )
```
<!-- END_MESSAGE C040-M02392 -->


---

<a id="c040-m02394"></a>

### C040-M02394

**Andrew** · 2026-05-26T19:25:43.273000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02394 -->
how is this for an overall read me image?  
<!-- END_MESSAGE C040-M02394 -->


**Attachments in export:** `executive_dashboard_preview_final.png`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c040-m02396"></a>

### C040-M02396

**ChatGPT** · 2026-05-26T19:29:29.520592-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02396 -->
This is **very strong** as an overall README image. It now reads like an executive dashboard rather than a set of disconnected charts, and it communicates the project’s core claim well:

> Module 2 is not a simple approval / decline rules engine; it is a governed strategy simulation framework showing access, exposure, Expected Loss, counteroffer posture, and decision-path governance.

That aligns directly with the Module 2 architecture: the module is designed to make credit-strategy tradeoffs visible across access, approval rate, counteroffers, manual review, affordability, approved exposure, Expected Loss, product guardrails, explanation-code transparency, parameter traceability, and post-campaign evidence readiness. fileciteturn47file4

## What works especially well

The **top-left frontier scatter** is the best conceptual anchor. It says, “Here is the strategy landscape.” The baseline crosshair makes the story immediately interpretable, and M2-37’s position is especially interesting: it visually suggests that governed aggressive counteroffer expansion can increase offer exposure while still improving approved-risk density versus baseline.

The **top-right delta bar chart** is a strong companion because it quantifies what the scatter only implies. It adds magnitude: M2-02 reduces access / dollars / EL, M2-03 expands all three, and M2-37 has the nuanced “more access, lower approved dollars / EL” pattern. That is a real value-add versus the scatter.

The **bottom Option C section** is now much better than a simple stacked bar chart. The left-center selective panel answers “what changed when aggressive overrides were zero,” and the right panel answers “where aggressive override rows resolved.” That makes the Option C story architecture-driven, not just metric-driven.

The whole dashboard also supports Section 15’s purpose well: Section 15 is the archive-wide strategy control tower that turns many completed strategy runs into a frontier view for executive interpretation, README evidence, and campaign storytelling. fileciteturn47file5

## Best aspects of the current design

The dark background works. It gives the image a premium “control tower” feel, and the charts now look visually consistent. For a GitHub README, this will stand out much more than a standard white matplotlib image.

The overall hierarchy is clear:

```text
Top row:
    portfolio frontier + baseline-relative tradeoffs

Bottom row:
    counteroffer mechanism / Option C governance

Left narrative box:
    executive interpretation
```

That is a strong layout. It moves from **portfolio strategy** to **mechanism design**, which is exactly the story you want.

## Important corrections before finalizing

### 1. Change “approved capital” to “approved exposure” or “approved amount”

The bottom-left operational summary says something like “approved capital fell…” That is the only wording I would treat as a real issue.

Module 2 does **not** calculate capital. It calculates simulated approved exposure / approved amount and approved Expected Loss. Capital, profitability, yield, margin, and funding-cost concepts are explicitly outside Module 2 and belong to future Module 3 economics work. fileciteturn47file4

Use one of these instead:

```text
approved exposure fell
```

or:

```text
approved amount fell
```

Suggested replacement:

```text
Selective feasibility optimizes policy discipline, reducing counteroffer exposure and shifting borderline cases directly into manual review workflows. Approved exposure fell by roughly $350M per matched selective scenario while approved Expected Loss also declined.
```

If you want to refer to all three selective runs together, use:

```text
Approved exposure fell by roughly $1.06B across the three selective comparisons.
```

because:

```text
M2-05: -$363M
M2-18: -$378M
M2-29: -$323M
Total ≈ -$1.06B
```

### 2. Fix the legend / unit wording in the top-right chart

The top-right legend says:

```text
Approved $ Δ (%)
Approved EL Δ (%)
```

but the labels on the bars show dollar amounts:

```text
-$149M
+$238M
-$7.2M
+$8.7M
```

That creates a unit mismatch. The bar lengths may be scaled as percent-of-baseline while the labels show dollar values, which is fine, but the chart needs to say that clearly.

Best legend wording:

```text
Access Δ (pp)
Approved $ Δ (% baseline; label=$M)
Approved EL Δ (% baseline; label=$M)
```

Or, if you want simpler legend labels:

```text
Access Δ (pp)
Approved $ movement
Approved EL movement
```

Then keep the x-axis note:

```text
access = percentage points; $ and EL = % of baseline; labels show dollar movement
```

That removes ambiguity.

### 3. Consider shortening the bottom-left paragraph

The operational summary is good, but it is dense. In a README image, dense paragraph text can become hard to read after GitHub scales the image down.

I would convert the summary into 3–4 tighter lines:

```text
Operational Summary

Selective feasibility:
• reduces counteroffer / offer exposure
• shifts borderline cases to manual review
• lowers approved exposure and approved EL

Aggressive expansion:
• routes severe requested structures through feasibility safeguards
• resolves 80–88% to final counteroffer
• sends the remainder to manual review
• observed final aggressive override declines: 0
```

This will be easier to read and stronger visually.

## Small visual polish suggestions

The main title is strong, but long. I would consider adding **Module 2** explicitly:

```text
MODULE 2 — CREDIT POLICY STRATEGY & DECISION OUTCOME SIMULATION ENGINE
```

or:

```text
ENTERPRISE CREDIT DECISIONING STRATEGY SIMULATOR — MODULE 2
```

Then use a subtitle:

```text
Credit Policy Strategy & Decision Outcome Simulation Engine
```

That will make the module identity clearer without making the title feel like a single very long sentence.

The bottom-center title says:

```text
Selective Feasibility: Conservative Risk Handling
```

I would make it more precise:

```text
Selective Feasibility: Conservative Counteroffer Treatment
```

or:

```text
Selective Feasibility: Review-Oriented Counteroffer Treatment
```

“Risk handling” is directionally fine, but the chart is really about counteroffer routing and manual-review treatment.

The bottom-right title is excellent:

```text
Aggressive Expansion: Governed Volume Routing
```

That is exactly the story.

## README usage recommendation

I would absolutely use this as the **main README executive dashboard image**, but I would also include the three individual charts below it or link them as separate assets. This image is excellent as a full-width dashboard, but readers on smaller screens may want enlarged individual views.

Recommended README pattern:

```markdown
![Module 2 Executive Strategy Dashboard](assets/module2_executive_dashboard.png)

The completed Module 2 campaign evaluated 39 governed strategy runs across 20 matched comparison groups and 1.95M archived strategy rows. The dashboard summarizes the campaign frontier, baseline-relative tradeoffs, and Option C counteroffer governance mechanics.
```

Then include:

```markdown
[Open full-size dashboard](assets/module2_executive_dashboard.png)
```

I would export this at high resolution, ideally at least:

```text
2400px wide minimum
3200px wide preferred
```

because the image contains many labels.

## Final verdict

```text
README dashboard status: near-final / strong

Keep:
    dark theme
    three-zone structure
    frontier scatter
    baseline-relative delta chart
    Option C split narrative
    approved-dollar labels
    executive dashboard framing

Fix before final:
    replace “approved capital” with “approved exposure” or “approved amount”
    clarify top-right chart units / legend
    optionally shorten bottom-left summary
    optionally rename “Conservative Risk Handling” to “Conservative Counteroffer Treatment”
```

This is a compelling portfolio image. It shows the system is not just a SQL script; it is a governed strategy simulation platform with frontier analysis, matched challenger comparison, and decision-path governance.
<!-- END_MESSAGE C040-M02396 -->


---

<a id="c040-m02398"></a>

### C040-M02398

**Andrew** · 2026-05-26T19:44:37.124000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02398 -->
regarding main title, this is for the entire portfolio readme, not just module 2.  However, I thought the longer title was appropriate.  Thoughts?
<!-- END_MESSAGE C040-M02398 -->


---

<a id="c040-m02401"></a>

### C040-M02401

**ChatGPT** · 2026-05-26T19:48:33.808024-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02401 -->
I agree with your instinct that a **longer, enterprise-style title is appropriate** for the full portfolio README. This project is not a small SQL demo; it is a multi-module governed simulation system. A more substantial title helps signal that immediately.

That said, I would slightly adjust the current title.

Current image title:

```text
ENTERPRISE CREDIT POLICY STRATEGY & DECISION OUTCOME SIMULATION ENGINE
```

This is strong, but it reads more like the **Module 2 engine title** than the full portfolio umbrella. Module 2 is specifically the credit policy strategy and decision outcome layer: it consumes Module 1 outputs, applies strategy and product-policy controls, assigns simulated outcomes, calculates approved exposure economics, supports archive-backed comparison, summarizes frontier tradeoffs, captures evidence, and supports post-campaign acceptance. fileciteturn47file4

For the **entire portfolio**, I would lead with the broader project name:

```text
ENTERPRISE CREDIT DECISIONING STRATEGY SIMULATOR
```

That is cleaner as the umbrella because it covers both:

```text
Module 1:
    Synthetic Application & Risk Modeling Engine

Module 2:
    Credit Policy Strategy & Decision Outcome Simulation Engine
```

Module 1 establishes the synthetic application / risk foundation and is explicitly positioned as a governed, portfolio-scale simulation framework for pre-production strategy testing without PII. fileciteturn47file88 Module 2 then applies downstream policy strategy, decision outcomes, exposure treatment, counteroffer governance, evidence capture, and campaign acceptance. fileciteturn47file4

## My preferred README dashboard title hierarchy

For the image itself, I would use:

```text
ENTERPRISE CREDIT DECISIONING STRATEGY SIMULATOR
```

Then a subtitle directly underneath:

```text
Synthetic Application & Risk Modeling → Credit Policy Strategy → Decision Outcome Simulation
```

Then, if you want a smaller dashboard-specific label:

```text
Module 2 Campaign Dashboard: Strategy Frontier, Baseline Tradeoffs, and Counteroffer Governance
```

That gives you the best of both worlds: the top line represents the full portfolio, while the subtitle explains that this specific dashboard visual is showcasing Module 2 campaign results.

## Why I would not use only the current title for the full README

The current title is polished, but:

```text
ENTERPRISE CREDIT POLICY STRATEGY & DECISION OUTCOME SIMULATION ENGINE
```

somewhat skips over the fact that Module 1 exists and is foundational. It makes the portfolio sound like it begins at policy strategy, when your full system actually begins with synthetic application generation, product structure, affordability, estimated-risk proxy, and Expected Loss before downstream strategy simulation.

That matters because one of the project’s strongest portfolio-level claims is:

```text
Module 1 builds the governed synthetic population and risk foundation.
Module 2 applies governed credit strategy and decision outcome simulation.
Together they form an enterprise credit decisioning strategy simulator.
```

## Best final title options

### Option 1 — cleanest and strongest

```text
ENTERPRISE CREDIT DECISIONING STRATEGY SIMULATOR
```

Subtitle:

```text
Synthetic Application, Risk Modeling, Credit Policy Strategy & Decision Outcome Simulation
```

This is my favorite.

### Option 2 — more technical / architecture-forward

```text
ENTERPRISE CREDIT DECISIONING STRATEGY SIMULATOR
```

Subtitle:

```text
Synthetic Risk Foundation → Policy Strategy Simulation → Governed Decision Outcomes
```

This is more narrative and visually elegant.

### Option 3 — closest to your current title

```text
ENTERPRISE CREDIT DECISIONING STRATEGY & OUTCOME SIMULATION ENGINE
```

Subtitle:

```text
Portfolio-scale synthetic risk, policy strategy, counteroffer governance, and campaign acceptance
```

This preserves the long-title feel but makes it broader than Module 2.

## My recommendation

Use this for the full README hero/dashboard:

```text
ENTERPRISE CREDIT DECISIONING STRATEGY SIMULATOR
Synthetic Application & Risk Modeling → Credit Policy Strategy → Decision Outcome Simulation
```

Then keep the dashboard section title or caption as:

```text
Module 2 Campaign Dashboard: Strategy Frontier, Baseline Tradeoffs, and Counteroffer Governance
```

That title system is more accurate, more complete, and still appropriately “enterprise-grade.”
<!-- END_MESSAGE C040-M02401 -->


---

<a id="c040-m02402"></a>

### C040-M02402

**Andrew** · 2026-05-26T20:08:41.234000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02402 -->
updated module 2 read me collage attached.  we can decide if we want to make a module 1 collage.  i think that would also add value to the read me.
<!-- END_MESSAGE C040-M02402 -->


**Attachments in export:** `module2_executive_dashboard_preview.png`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c040-m02403"></a>

### C040-M02403

**Andrew** · 2026-05-26T20:20:02.260000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02403 -->
please review and approve final module 2 read me collage.  do not generate anything.  i am simply asking for feedback.  also, let me know (again don't generate anything) whether it would be good to also create a module 1 collage as well.
<!-- END_MESSAGE C040-M02403 -->


**Attachments in export:** `module2_executive_dashboard_preview(1).png`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c040-m02406"></a>

### C040-M02406

**ChatGPT** · 2026-05-26T20:24:50.417798-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02406 -->
## Final Module 2 README collage verdict

**Approved.** This is a strong final Module 2 README image.

It now reads like an executive dashboard rather than a set of exploratory plots. The image successfully communicates the main Module 2 thesis: credit strategy is not a simple score cutoff; it is a governed tradeoff across access, approval exposure, Expected Loss, counteroffer posture, review burden, and strategy controls. That aligns well with the documented Module 2 purpose as a governed synthetic strategy simulation layer that applies strategy/product controls, assigns outcomes, calculates approved exposure economics, supports archive-backed comparison, captures evidence, and supports final campaign acceptance. fileciteturn47file4

## What works especially well

The **top-left frontier scatter** is the best anchor. It immediately shows the strategy landscape and gives the reader a conceptual map: baseline, tighter risk, growth, affordability, product guardrails, selective counteroffer, and aggressive counteroffer. The baseline crosshair is essential and should stay.

The **top-right baseline-relative tradeoff chart** adds the magnitude story. It explains how the selected challengers moved access, approved dollars, and approved Expected Loss versus baseline. This is a clear value-add over the scatter because it quantifies what the frontier chart visually suggests.

The **bottom Option C section** is much stronger now than the earlier single stacked-bar concept. It explains both sides of the counteroffer split: selective feasibility reduces counteroffer / offer exposure and shifts borderline cases toward review, while aggressive expansion creates governed override routing. This directly supports the architecture narrative that Option C is not “approve more,” but rather controlled feasibility routing.

The **operational summary box** is effective. It gives a non-technical reader enough context to understand why the bottom panels matter.

## Minor final proofread items

I would treat these as final visual QA, not redesign requests:

1. In the bottom-middle title, make sure the parenthetical says exactly:

```text
(Produces 0 Aggressive Override Rows)
```

In the screenshot, it is small enough that I would double-check that it does not visually read as “Products” or another word.

2. Double-check the bottom-middle selective feasibility row labels:

```text
M2-05
M2-18
M2-29
```

The near-prime label is small; make sure it says **M2-18**, not **M2-38**. M2-38 belongs to aggressive expansion.

3. The title is appropriate as-is:

```text
MODULE 2: CREDIT POLICY STRATEGY & DECISION OUTCOME SIMULATION ENGINE
```

Since this image is specifically a Module 2 dashboard, the module-specific title is better than the broader portfolio title. The full README can have the umbrella title above it:

```text
Enterprise Credit Decisioning Strategy Simulator
```

Then this image can sit under a Module 2 section.

## Final assessment

```text
Module 2 README collage: APPROVED

Purpose clarity: strong
Executive readability: strong
Visual consistency: strong
Project narrative fit: strong
Technical credibility: strong
Remaining work: only small proofreading checks
```

This should be one of the main visuals in the README.

## Should you also create a Module 1 collage?

Yes. I think a Module 1 collage would add real value, especially because this Module 2 collage is strong. Without a Module 1 companion visual, the README may feel like it jumps straight to strategy outcomes before showing the synthetic risk foundation that made those strategy outcomes possible.

Module 1 is the upstream synthetic application and risk modeling engine: it creates the governed synthetic application population, product structure, affordability metrics, estimated-PD proxy, LGD, Expected Loss, scenario archive outputs, and matched comparison foundation. The Module 1 BRD frames it as a governed, portfolio-scale pre-production strategy testing environment, and the validation summary emphasizes deterministic reproducibility, scenario capability, product/score composition, affordability relationships, estimated-risk behavior, and matched row-level scenario comparison. fileciteturn47file88 fileciteturn47file89

I would make the Module 1 collage complementary, not duplicative. Its story should be:

```text
Module 1 builds the synthetic population and risk foundation.
Module 2 applies governed policy strategy and outcome simulation.
```

A strong Module 1 collage could focus on:

```text
1. Product × score portfolio composition
2. Affordability → estimated-risk / Expected Loss transmission
3. Scenario comparison or mortgage realism / PD-proxy dispersion validation
```

The Module 2 collage tells the downstream strategy story. A Module 1 collage would tell the upstream synthetic population and risk-formation story. Together, they would make the README feel like a complete two-module system rather than one isolated campaign dashboard.
<!-- END_MESSAGE C040-M02406 -->


---

<a id="c040-m02407"></a>

### C040-M02407

**Andrew** · 2026-05-26T20:47:21.127000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02407 -->
do not generate images or charts yet.  attached is module 1 section 10 QA following the module 1 campaign.  i expect the detail we need for these charts to be found here.  let's focus on narrowing the table 1, 2, and 3 scope and what data we need for them.
<!-- END_MESSAGE C040-M02407 -->


**Attachments in export:** `module1_synthetic_application_risk_engine_v2.0_10.04B_QA_matched_row_level_delta_summary_campaign.csv`, `module1_synthetic_application_risk_engine_v2.0_10.04A_QA_matched_row_level_delta_sample_campaign.csv`, `module1_synthetic_application_risk_engine_v2.0_10.03_QA_product_score_scenario_summary_campaign(1).csv`, `module1_synthetic_application_risk_engine_v2.0_10.02_QA_portfolio_level_scenario_summary_campaign.csv`, `module1_synthetic_application_risk_engine_v2.0_10.01_QA_scenario_archive_inventory_campaign.csv`, `module1_synthetic_application_risk_engine_v2.0_10.04C_QA_matched_row_level_delta_summary_by_product_and_score_band_campaign.csv`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c040-m02417"></a>

### C040-M02417

**ChatGPT** · 2026-05-26T20:56:54.647425-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02417 -->
Yes — the Section 10 campaign QA outputs are the right place to build a **Module 1 README collage**, but the scope should be different from Module 2.

Module 2’s collage says: **what strategies did to outcomes**.  
Module 1’s collage should say: **why the synthetic population and risk foundation are credible enough to support those strategies**.

Module 1’s core story is the upstream chain:

```text
Application population
→ Product / score composition
→ APR / payment / PTI
→ synthetic estimated-PD proxy
→ Expected Loss
→ scenario archive and matched comparison
```

That aligns with the Module 1 BRD’s framing that risk emerges from borrower characteristics, loan structure, affordability, and macro conditions, and that the engine models the chain from rate environment through APR, payment, PTI, estimated-PD proxy, and Expected Loss. fileciteturn47file88 The validation summary also confirms the key claims we should visualize: deterministic reproducibility, configured product/score composition, coherent financial relationships, estimated-risk behavior, and matched scenario comparison. fileciteturn47file89

## Recommended Module 1 collage scope

I would lock the Module 1 collage around these three panels:

```text
1. Product × Score Risk Surface
2. Scenario Transmission Chain
3. Matched Rate-Shock Attribution
```

This gives the README a clean upstream/downstream progression:

```text
Panel 1:
    What did the synthetic portfolio look like?

Panel 2:
    How do scenario assumptions transmit through affordability and risk?

Panel 3:
    Can we compare scenarios on the same rows and identify where the shock lands?
```

That is a strong complement to the Module 2 dashboard.

---

# Panel 1 — Product × Score Risk Surface

## What we are trying to say

This panel should demonstrate that Module 1 is not a generic random-data generator. It creates a **product-aware and score-aware synthetic portfolio** where risk varies sensibly across both borrower quality and product structure.

The message:

```text
Risk is not only score-driven.
Product structure also matters.

Weak score bands carry higher synthetic estimated-risk and Expected Loss,
but products remain differentiated within score bands.
```

## Recommended visual

A **product × score heatmap**.

Best version:

```text
Rows:
    product_type

Columns:
    score_band

Color:
    avg_expected_loss

Cell label:
    avg_pd as %
```

Alternative:

```text
Color:
    avg_pd

Cell label:
    avg_expected_loss
```

I prefer **avg_expected_loss as color** because it combines risk and exposure size. For a credit strategy portfolio, Expected Loss is the more executive-readable metric.

## Source file

```text
10.03_QA_product_score_scenario_summary_campaign
```

## Filter

```text
scenario_name = BASELINE_V2
population_id = BASE_POPULATION_V1
```

## Required fields

```text
product_type
score_band
applications
avg_requested_amount
avg_pti
avg_pd
avg_expected_loss
```

## Data we need to hardcode

Use the 25 baseline product × score rows:

```text
5 products × 5 score bands
```

Key values worth calling out:

```text
MORTGAGE_SUBPRIME:
    avg_expected_loss ≈ $17.7K

HELOC_DEEP_SUBPRIME:
    avg_expected_loss ≈ $14.0K

MORTGAGE_NEAR_PRIME:
    avg_expected_loss ≈ $10.5K

REVOLVING_LINE_SUPER_PRIME:
    avg_expected_loss ≈ $200
```

## Why this is a value add

It visually proves the population has **cross-sectional realism**. Module 2 strategy results are more credible when the upstream population already has plausible product × score risk differentiation.

---

# Panel 2 — Scenario Transmission Chain

## What we are trying to say

This panel should demonstrate Module 1’s central economic chain:

```text
Rate environment
→ APR
→ monthly payment
→ PTI
→ synthetic estimated-PD proxy
→ Expected Loss
```

The message:

```text
Scenario changes do not just relabel the portfolio.
They flow through pricing, payment burden, affordability, and risk.
```

## Recommended visual

A compact **scenario transmission chart** for the rate environment scenarios.

Best version:

```text
X-axis:
    RATE_DOWN_200BP
    BASELINE_V2
    RATE_UP_200BP
    RATE_UP_300BP

Series:
    avg_apr
    avg_pti
    avg_expected_loss
```

Because these have different units, we have two good options:

### Option A — normalized line chart

Index each metric to baseline:

```text
BASELINE_V2 = 100
RATE_DOWN / RATE_UP values shown as % of baseline
```

This is visually clean and lets all three metrics fit in one panel.

### Option B — grouped bars with direct labels

Show:

```text
avg_apr as %
avg_pti as %
avg_expected_loss as $K
```

This is more literal but visually busier.

I recommend **Option A** for the collage.

## Source file

```text
10.02_QA_portfolio_level_scenario_summary_campaign
```

## Filter

```text
scenario_set_name = MODULE1_V2_BASELINE_SET
scenario_name in:
    RATE_DOWN_200BP
    BASELINE_V2
    RATE_UP_200BP
    RATE_UP_300BP
```

## Required fields

```text
scenario_name
avg_apr
avg_monthly_payment
avg_pti
avg_pd
avg_expected_loss
total_expected_loss
```

## Key values to show or annotate

```text
BASELINE_V2:
    avg_apr = 14.56%
    avg_pti = 16.50%
    avg_expected_loss = $4,788.67

RATE_DOWN_200BP:
    avg_apr = 12.85%
    avg_pti = 15.35%
    avg_expected_loss = $4,765.49

RATE_UP_200BP:
    avg_apr = 16.14%
    avg_pti = 17.41%
    avg_expected_loss = $4,804.46

RATE_UP_300BP:
    avg_apr = 16.85%
    avg_pti = 17.71%
    avg_expected_loss = $4,809.80
```

## Why this is a value add

This is the cleanest “Module 1 engine” story. It shows the engine is not just producing a static population; it is transmitting structural scenario pressure through affordability into risk.

---

# Panel 3 — Matched Rate-Shock Attribution

## What we are trying to say

This panel should prove that Module 1 supports **matched, row-level scenario comparison**, not just aggregate scenario summaries.

The message:

```text
The same 50,000 synthetic applicants can be compared before and after a scenario shock.
The rate-up scenario increases APR, payment, PTI, and Expected Loss, and the impact concentrates
in specific product × score cells.
```

This is one of the most important credibility points because Module 2 later depends on the same idea: matched comparison over population drift.

## Recommended visual

A **product-level horizontal bar chart** showing total Expected Loss delta under the matched rate shock.

Best version:

```text
Rows:
    product_type

Bar:
    total_delta_expected_loss

Annotations:
    top product × score cells driving the movement
```

This is more readable than another product × score heatmap, because Panel 1 is already a heatmap. We do not want two heatmaps in the same collage.

## Source files

Use both:

```text
10.04B_QA_matched_row_level_delta_summary_campaign
10.04C_QA_matched_row_level_delta_summary_by_product_and_score_band_campaign
```

## Comparison represented

This appears to be:

```text
BASELINE_V2 vs RATE_UP_200BP
```

because the portfolio-level deltas match the 10.02 difference between those two scenarios.

## Required fields from 10.04B

```text
matched_rows
avg_delta_requested_amount
avg_delta_apr
avg_delta_monthly_payment
avg_delta_pti
avg_delta_pd
avg_delta_expected_loss
rows_pd_increased
rows_pd_decreased
rows_pd_unchanged
rows_el_increased
rows_el_decreased
rows_el_unchanged
```

Key callout values:

```text
matched_rows = 50,000
avg_delta_apr = +1.58pp
avg_delta_monthly_payment = +$101.30
avg_delta_pti = +0.90pp
avg_delta_pd = +0.05pp
avg_delta_expected_loss = +$15.79
total implied EL delta ≈ +$0.79M
```

## Required fields from 10.04C

```text
product_type
score_band
matched_rows
avg_delta_apr
avg_delta_monthly_payment
avg_delta_pti
avg_delta_pd
avg_delta_expected_loss
total_delta_expected_loss
```

Aggregate by `product_type` for the main bars:

```text
HELOC:
    total_delta_expected_loss ≈ +$341K

MORTGAGE:
    total_delta_expected_loss ≈ +$168K

AUTO_LOAN:
    total_delta_expected_loss ≈ +$156K

UNSECURED_PERSONAL_LOAN:
    total_delta_expected_loss ≈ +$77K

REVOLVING_LINE:
    total_delta_expected_loss ≈ +$48K
```

Top product × score callouts:

```text
HELOC_NEAR_PRIME:
    total_delta_expected_loss ≈ +$203K

HELOC_PRIME:
    total_delta_expected_loss ≈ +$108K

MORTGAGE_PRIME:
    total_delta_expected_loss ≈ +$92K

AUTO_LOAN_NEAR_PRIME:
    total_delta_expected_loss ≈ +$62K

AUTO_LOAN_SUBPRIME:
    total_delta_expected_loss ≈ +$59K
```

## Why this is a value add

This panel shows the campaign’s comparison discipline:

```text
same population
same application IDs
same row count
controlled scenario difference
measurable product / score attribution
```

It turns Module 1 from “synthetic generator” into a **scenario-comparison engine**.

---

# What about 10.01 and 10.04A?

## 10.01 — Scenario archive inventory

Use this for a **dashboard KPI strip**, not a main chart.

Data:

```text
19 archived scenarios
50,000 rows per scenario
950,000 total archived scenario rows
same population_id = BASE_POPULATION_V1
```

Possible header line:

```text
19 governed scenarios | 50,000 matched applications each | 950,000 archived scenario rows
```

This would be excellent at the top of a Module 1 collage.

## 10.04A — Matched row-level delta sample

I would **not** use this in the collage.

It is valuable evidence, but it is too row-level for a README hero image. It belongs in the validation appendix or an example table if you want to show one applicant-level before/after row.

---

# Recommended final three-panel Module 1 collage

```text
MODULE 1: SYNTHETIC APPLICATION & RISK MODELING ENGINE

Top KPI strip:
    19 scenarios | 50K rows each | 950K archived rows | same population_id

Panel 1:
    Product × Score Risk Surface
    Source: 10.03 baseline product-score summary
    Shows: avg_expected_loss heatmap, avg_pd labels

Panel 2:
    Scenario Transmission Chain
    Source: 10.02 portfolio-level scenario summary
    Shows: rate environment → APR / PTI / EL movement

Panel 3:
    Matched Rate-Shock Attribution
    Source: 10.04B + 10.04C
    Shows: product-level total EL delta under RATE_UP_200BP, with top product-score drivers
```

## Final recommendation

I would lock these three. They are distinct, readable, and complementary:

```text
Panel 1 proves portfolio realism.
Panel 2 proves scenario transmission.
Panel 3 proves matched comparison and attribution.
```

Together, they tell the Module 1 story cleanly:

> **Module 1 builds a deterministic, product-aware, score-aware synthetic risk foundation where structural scenario changes transmit through affordability into expected-loss movement, and those changes can be compared row-for-row without population drift.**
<!-- END_MESSAGE C040-M02417 -->


---

<a id="c040-m02419"></a>

### C040-M02419

**Andrew** · 2026-05-26T21:06:33.855000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02419 -->
sounds great.  let's focus on panel 1 to start.  please lock down panel 1 framework.  do not produce python code or generate any images.  just lock down panel 1 framework.
<!-- END_MESSAGE C040-M02419 -->


---

<a id="c040-m02425"></a>

### C040-M02425

**ChatGPT** · 2026-05-26T21:13:00.400030-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02425 -->
## Panel 1 framework locked: Product × Score Risk Surface

### Panel title

```text
Product × Score Risk Surface
Baseline Synthetic Portfolio
```

Optional subtitle:

```text
Average Expected Loss by product and score band; cell labels show synthetic estimated-PD proxy
```

This panel should establish the **Module 1 credibility foundation**: the synthetic portfolio is not a generic random dataset. It is product-aware, score-aware, and risk-sensitive. That fits Module 1’s stated purpose as a governed synthetic application and risk modeling engine where risk emerges from borrower characteristics, product structure, affordability, and macro conditions—not borrower profile alone. fileciteturn47file88

---

## 1. What the panel is trying to demonstrate

Panel 1 should answer:

> **Does the baseline synthetic population produce intuitive risk differentiation across both product structure and credit score quality?**

The reader should see three things quickly:

```text
1. Score quality matters:
   weaker score bands carry higher synthetic estimated-PD proxy and Expected Loss.

2. Product structure matters:
   products remain differentiated within the same score band.

3. Expected Loss is not just PD:
   higher-balance products can carry larger Expected Loss even when PD is not the highest.
```

That third point is important. Module 1’s risk story is not just “bad score = bad risk.” It is:

```text
borrower profile × product structure × affordability × exposure × LGD = Expected Loss
```

The validation summary specifically highlights that Module 1 preserves configured product / score composition, coherent financial relationships, and directionally correct estimated-risk / Expected Loss behavior. fileciteturn47file89

---

## 2. Data source

Use:

```text
module1_synthetic_application_risk_engine_v2.0_10.03_QA_product_score_scenario_summary_campaign.csv
```

This is the correct source because it already aggregates the portfolio at the required grain:

```text
scenario_set_name
scenario_name
population_id
product_type
score_band
```

For Panel 1, use only the baseline scenario slice:

```text
scenario_set_name = MODULE1_V2_BASELINE_SET
scenario_name     = BASELINE_V2
population_id     = BASE_POPULATION_V1
```

Expected panel data shape:

```text
5 products × 5 score bands = 25 cells
```

---

## 3. Required data fields

Minimum fields needed for the chart:

```text
product_type
score_band
applications
avg_expected_loss
avg_pd
```

Recommended fields to carry in the hardcoded dataset, even if not all are shown in the final panel:

```text
product_type
score_band
applications
avg_requested_amount
avg_pti
avg_pd
avg_expected_loss
```

Interpretation labels should avoid calling `avg_pd` a calibrated PD. The chart should label it as:

```text
Avg synthetic-PD proxy
```

or shorter inside the graphic:

```text
PD proxy
```

The SQL field name can remain `avg_pd`, but chart language should remain governed and precise.

---

## 4. Chart type

Use a **heatmap**.

```text
Rows:
    product_type

Columns:
    score_band

Color:
    avg_expected_loss

Cell label:
    avg_pd as a percentage
```

This gives the panel two layers of information:

```text
Color intensity = average Expected Loss
Cell text       = average synthetic-PD proxy
```

That is stronger than coloring by `avg_pd` because Expected Loss reflects both risk and exposure structure. It is the more executive-friendly risk surface.

---

## 5. Axis order

### Columns: score bands

Use strongest-to-weakest left to right:

```text
SUPER_PRIME
PRIME
NEAR_PRIME
SUBPRIME
DEEP_SUBPRIME
```

This makes the risk gradient intuitive: risk should generally intensify as the reader moves right.

### Rows: products

Use a product-structure order rather than alphabetical order:

```text
MORTGAGE
HELOC
AUTO_LOAN
UNSECURED_PERSONAL_LOAN
REVOLVING_LINE
```

Reasoning:

```text
MORTGAGE / HELOC:
    larger-balance real-estate-secured exposure structures

AUTO_LOAN:
    secured installment product

UNSECURED_PERSONAL_LOAN / REVOLVING_LINE:
    unsecured / revolving structures
```

That ordering is more meaningful for README storytelling than alphabetical order.

---

## 6. Color scale

Use:

```text
avg_expected_loss
```

Format colorbar as:

```text
Avg Expected Loss ($K)
```

Because the range is wide, I would use a softened or mildly nonlinear scale later in code so the highest cells do not drown out the middle of the matrix.

For the framework, lock this:

```text
Sequential heatmap color scale
Dark dashboard style
Colorbar labeled in $K
Cell labels in white or black depending on cell contrast
```

No diverging scale here. This is not a positive/negative delta chart. It is a risk-intensity surface.

---

## 7. Cell labels

Use compact labels:

```text
PD proxy %
```

Example cell text format:

```text
38.4%
```

Do not put full `EL $17.7K / PD 38.4%` in every cell. That will become too dense in a three-panel collage.

Instead:

```text
Color = Avg EL
Cell label = Avg synthetic-PD proxy
```

Then use the colorbar and a few callouts for Expected Loss values.

---

## 8. Callouts to include

Use two or three callouts only.

Recommended callouts:

```text
Highest baseline cell:
    MORTGAGE × SUBPRIME
    Avg EL ≈ $17.7K
    PD proxy ≈ 38.4%

High-risk secured exposure cell:
    HELOC × DEEP_SUBPRIME
    Avg EL ≈ $14.0K
    PD proxy ≈ 44.7%

Low-risk reference cell:
    REVOLVING_LINE × SUPER_PRIME
    Avg EL ≈ $0.2K
    PD proxy ≈ 1.2%
```

These callouts make the panel readable without forcing every cell to carry too much text.

---

## 9. What the caption should say

Recommended README caption:

```text
The baseline synthetic portfolio is differentiated across both score quality and product structure. Color shows average Expected Loss, while cell labels show the average synthetic estimated-PD proxy. The surface demonstrates that Expected Loss is shaped by both borrower risk and exposure structure, not score alone.
```

Shorter collage caption:

```text
Product × score risk surface: color = Avg Expected Loss; cell label = Avg synthetic-PD proxy.
```

---

## 10. What this panel should not do

Do **not** include scenario deltas in Panel 1. Panel 2 will handle scenario transmission.

Do **not** include all 19 scenarios. Panel 1 should be baseline only.

Do **not** use total Expected Loss as the color metric. Total EL would mix portfolio size/counts into the risk surface. Use average Expected Loss to show cell-level risk intensity.

Do **not** over-label every cell with EL, PD, PTI, applications, and amount. That will make the panel unreadable.

Do **not** call `avg_pd` a production PD or calibrated default probability. Use “synthetic-PD proxy” language.

---

## Final locked Panel 1 spec

```text
Panel name:
    Product × Score Risk Surface

Purpose:
    Show that Module 1 creates a product-aware and score-aware synthetic risk foundation.

Source:
    Section 10.03 product × score scenario summary campaign CSV

Filter:
    scenario_set_name = MODULE1_V2_BASELINE_SET
    scenario_name = BASELINE_V2
    population_id = BASE_POPULATION_V1

Rows:
    MORTGAGE
    HELOC
    AUTO_LOAN
    UNSECURED_PERSONAL_LOAN
    REVOLVING_LINE

Columns:
    SUPER_PRIME
    PRIME
    NEAR_PRIME
    SUBPRIME
    DEEP_SUBPRIME

Color:
    avg_expected_loss

Cell text:
    avg_pd formatted as synthetic-PD proxy %

Colorbar:
    Avg Expected Loss ($K)

Callouts:
    MORTGAGE × SUBPRIME as the highest EL concentration
    HELOC × DEEP_SUBPRIME as high-risk secured exposure
    REVOLVING_LINE × SUPER_PRIME as low-risk reference

Primary message:
    Risk varies by both borrower score quality and product structure.
    Expected Loss is not just a score metric; it is shaped by exposure, product, LGD, affordability, and synthetic estimated-risk proxy.
```

This is the right first panel for the Module 1 collage. It establishes the upstream synthetic-risk foundation before Panels 2 and 3 show scenario transmission and matched rate-shock attribution.
<!-- END_MESSAGE C040-M02425 -->


---

<a id="c040-m02427"></a>

### C040-M02427

**Andrew** · 2026-05-26T21:29:10.146000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02427 -->
i agree with this module 1 panel 1 locked down strategy.  please build the python code to create this module 1 panel 1.
<!-- END_MESSAGE C040-M02427 -->


---

<a id="c040-m02432"></a>

### C040-M02432

**ChatGPT** · 2026-05-26T21:36:06.651486-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02432 -->
Below is the full-copy Python script for **Module 1 Panel 1 — Product × Score Risk Surface**. It uses hardcoded values from the final Module 1 Section 10.03 campaign QA baseline slice.

```python
"""
Module 1 README Panel 1
Product × Score Risk Surface: Baseline Synthetic Portfolio

This version uses hardcoded final-campaign Section 10.03 values.

Panel thesis:
    Module 1 is not a generic random-data generator.
    It creates a product-aware and score-aware synthetic risk foundation.

    Risk varies by:
        borrower score quality,
        product structure,
        exposure size,
        affordability,
        LGD,
        and the synthetic estimated-PD proxy.

Data source:
    Final campaign Section 10.03:
    Product × score scenario summary.

Data scope:
    scenario_set_name = MODULE1_V2_BASELINE_SET
    scenario_name     = BASELINE_V2
    population_id     = BASE_POPULATION_V1

Chart design:
    Rows:
        product_type

    Columns:
        score_band

    Cell color:
        avg_expected_loss, shown in $K

    Cell label:
        avg synthetic-PD proxy, shown as %

Output:
    assets/module1_product_score_risk_surface.png
    assets/module1_product_score_risk_surface.svg
"""

from __future__ import annotations

from pathlib import Path
import textwrap

import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.ticker as mtick
from matplotlib.colors import PowerNorm
from matplotlib.patches import Rectangle


# =============================================================================
# 1. OUTPUT SETTINGS
# =============================================================================

OUTPUT_DIR = Path("assets")
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

OUTPUT_PNG = OUTPUT_DIR / "module1_product_score_risk_surface.png"
OUTPUT_SVG = OUTPUT_DIR / "module1_product_score_risk_surface.svg"


# =============================================================================
# 2. HARDCODED SECTION 10.03 BASELINE PRODUCT × SCORE DATA
# =============================================================================

PRODUCT_SCORE_DATA = [
    {
        "product_type": "MORTGAGE",
        "score_band": "SUPER_PRIME",
        "applications": 2747,
        "avg_requested_amount": 468486.10,
        "avg_pti": 0.2641,
        "avg_pd": 0.0162,
        "avg_expected_loss": 1611.61,
    },
    {
        "product_type": "MORTGAGE",
        "score_band": "PRIME",
        "applications": 4285,
        "avg_requested_amount": 407876.71,
        "avg_pti": 0.2971,
        "avg_pd": 0.0474,
        "avg_expected_loss": 4058.79,
    },
    {
        "product_type": "MORTGAGE",
        "score_band": "NEAR_PRIME",
        "applications": 3644,
        "avg_requested_amount": 331987.76,
        "avg_pti": 0.3252,
        "avg_pd": 0.1537,
        "avg_expected_loss": 10521.24,
    },
    {
        "product_type": "MORTGAGE",
        "score_band": "SUBPRIME",
        "applications": 2639,
        "avg_requested_amount": 229340.19,
        "avg_pti": 0.3054,
        "avg_pd": 0.3835,
        "avg_expected_loss": 17746.70,
    },
    {
        "product_type": "MORTGAGE",
        "score_band": "DEEP_SUBPRIME",
        "applications": 1750,
        "avg_requested_amount": 147576.45,
        "avg_pti": 0.2745,
        "avg_pd": 0.4490,
        "avg_expected_loss": 13257.06,
    },

    {
        "product_type": "HELOC",
        "score_band": "SUPER_PRIME",
        "applications": 900,
        "avg_requested_amount": 154463.01,
        "avg_pti": 0.0865,
        "avg_pd": 0.0130,
        "avg_expected_loss": 532.17,
    },
    {
        "product_type": "HELOC",
        "score_band": "PRIME",
        "applications": 1326,
        "avg_requested_amount": 144556.42,
        "avg_pti": 0.1159,
        "avg_pd": 0.0398,
        "avg_expected_loss": 1556.18,
    },
    {
        "product_type": "HELOC",
        "score_band": "NEAR_PRIME",
        "applications": 1176,
        "avg_requested_amount": 141084.72,
        "avg_pti": 0.1704,
        "avg_pd": 0.1342,
        "avg_expected_loss": 5177.18,
    },
    {
        "product_type": "HELOC",
        "score_band": "SUBPRIME",
        "applications": 894,
        "avg_requested_amount": 131376.16,
        "avg_pti": 0.2474,
        "avg_pd": 0.3693,
        "avg_expected_loss": 12706.83,
    },
    {
        "product_type": "HELOC",
        "score_band": "DEEP_SUBPRIME",
        "applications": 666,
        "avg_requested_amount": 124955.09,
        "avg_pti": 0.3431,
        "avg_pd": 0.4468,
        "avg_expected_loss": 14021.27,
    },

    {
        "product_type": "AUTO_LOAN",
        "score_band": "SUPER_PRIME",
        "applications": 1786,
        "avg_requested_amount": 46136.81,
        "avg_pti": 0.0755,
        "avg_pd": 0.0119,
        "avg_expected_loss": 256.74,
    },
    {
        "product_type": "AUTO_LOAN",
        "score_band": "PRIME",
        "applications": 2771,
        "avg_requested_amount": 45278.25,
        "avg_pti": 0.0918,
        "avg_pd": 0.0361,
        "avg_expected_loss": 775.82,
    },
    {
        "product_type": "AUTO_LOAN",
        "score_band": "NEAR_PRIME",
        "applications": 2390,
        "avg_requested_amount": 43788.68,
        "avg_pti": 0.1161,
        "avg_pd": 0.1198,
        "avg_expected_loss": 2500.59,
    },
    {
        "product_type": "AUTO_LOAN",
        "score_band": "SUBPRIME",
        "applications": 1759,
        "avg_requested_amount": 40236.91,
        "avg_pti": 0.1614,
        "avg_pd": 0.3488,
        "avg_expected_loss": 6600.61,
    },
    {
        "product_type": "AUTO_LOAN",
        "score_band": "DEEP_SUBPRIME",
        "applications": 1240,
        "avg_requested_amount": 39537.25,
        "avg_pti": 0.2421,
        "avg_pd": 0.4453,
        "avg_expected_loss": 7964.68,
    },

    {
        "product_type": "UNSECURED_PERSONAL_LOAN",
        "score_band": "SUPER_PRIME",
        "applications": 1361,
        "avg_requested_amount": 31563.60,
        "avg_pti": 0.0765,
        "avg_pd": 0.0128,
        "avg_expected_loss": 291.17,
    },
    {
        "product_type": "UNSECURED_PERSONAL_LOAN",
        "score_band": "PRIME",
        "applications": 2091,
        "avg_requested_amount": 29391.67,
        "avg_pti": 0.0892,
        "avg_pd": 0.0382,
        "avg_expected_loss": 822.76,
    },
    {
        "product_type": "UNSECURED_PERSONAL_LOAN",
        "score_band": "NEAR_PRIME",
        "applications": 1838,
        "avg_requested_amount": 27818.26,
        "avg_pti": 0.1079,
        "avg_pd": 0.1258,
        "avg_expected_loss": 2594.60,
    },
    {
        "product_type": "UNSECURED_PERSONAL_LOAN",
        "score_band": "SUBPRIME",
        "applications": 1390,
        "avg_requested_amount": 25908.37,
        "avg_pti": 0.1435,
        "avg_pd": 0.3587,
        "avg_expected_loss": 6721.05,
    },
    {
        "product_type": "UNSECURED_PERSONAL_LOAN",
        "score_band": "DEEP_SUBPRIME",
        "applications": 892,
        "avg_requested_amount": 24454.98,
        "avg_pti": 0.1996,
        "avg_pd": 0.4472,
        "avg_expected_loss": 7679.58,
    },

    {
        "product_type": "REVOLVING_LINE",
        "score_band": "SUPER_PRIME",
        "applications": 2190,
        "avg_requested_amount": 19003.21,
        "avg_pti": 0.0415,
        "avg_pd": 0.0122,
        "avg_expected_loss": 200.05,
    },
    {
        "product_type": "REVOLVING_LINE",
        "score_band": "PRIME",
        "applications": 3514,
        "avg_requested_amount": 18002.43,
        "avg_pti": 0.0482,
        "avg_pd": 0.0355,
        "avg_expected_loss": 553.11,
    },
    {
        "product_type": "REVOLVING_LINE",
        "score_band": "NEAR_PRIME",
        "applications": 3025,
        "avg_requested_amount": 17098.68,
        "avg_pti": 0.0586,
        "avg_pd": 0.1143,
        "avg_expected_loss": 1709.23,
    },
    {
        "product_type": "REVOLVING_LINE",
        "score_band": "SUBPRIME",
        "applications": 2220,
        "avg_requested_amount": 16390.66,
        "avg_pti": 0.0793,
        "avg_pd": 0.3366,
        "avg_expected_loss": 4800.50,
    },
    {
        "product_type": "REVOLVING_LINE",
        "score_band": "DEEP_SUBPRIME",
        "applications": 1506,
        "avg_requested_amount": 14980.44,
        "avg_pti": 0.1123,
        "avg_pd": 0.4443,
        "avg_expected_loss": 5680.01,
    },
]


# =============================================================================
# 3. CHART STYLE SETTINGS
# =============================================================================

PRODUCT_ORDER = [
    "MORTGAGE",
    "HELOC",
    "AUTO_LOAN",
    "UNSECURED_PERSONAL_LOAN",
    "REVOLVING_LINE",
]

SCORE_ORDER = [
    "SUPER_PRIME",
    "PRIME",
    "NEAR_PRIME",
    "SUBPRIME",
    "DEEP_SUBPRIME",
]

PRODUCT_LABELS = {
    "MORTGAGE": "Mortgage",
    "HELOC": "HELOC",
    "AUTO_LOAN": "Auto Loan",
    "UNSECURED_PERSONAL_LOAN": "Unsecured\nPersonal Loan",
    "REVOLVING_LINE": "Revolving\nLine",
}

SCORE_LABELS = {
    "SUPER_PRIME": "Super\nPrime",
    "PRIME": "Prime",
    "NEAR_PRIME": "Near\nPrime",
    "SUBPRIME": "Subprime",
    "DEEP_SUBPRIME": "Deep\nSubprime",
}

FIG_FACE = "black"
AX_FACE = "black"
TEXT_COLOR = "white"
GRID_COLOR = "white"
CALLOUT_BOX_COLOR = "#4f8fc4"
HIGHLIGHT_EDGE_COLOR = "white"

# A mildly nonlinear color scale keeps the highest-EL cells from washing out
# the rest of the matrix while preserving the risk-intensity story.
COLOR_NORM_GAMMA = 0.62


# =============================================================================
# 4. HELPER FUNCTIONS
# =============================================================================

def format_pd_pct(value: float) -> str:
    """Format synthetic estimated-PD proxy as percentage label."""
    return f"{value * 100:.1f}%"


def format_el_k(value: float) -> str:
    """Format Expected Loss dollars as $K."""
    return f"${value / 1000:.1f}K"


def format_amount_k(value: float) -> str:
    """Format requested amount as $K."""
    return f"${value / 1000:.0f}K"


def text_color_for_cell(rgba: tuple[float, float, float, float]) -> str:
    """
    Pick white or black cell text based on background luminance.

    This keeps PD-proxy labels readable across the heatmap.
    """
    r, g, b, _ = rgba
    luminance = 0.299 * r + 0.587 * g + 0.114 * b
    return "black" if luminance > 0.62 else "white"


def style_dark_axis(ax: plt.Axes) -> None:
    """Apply shared dark chart styling."""
    ax.set_facecolor(AX_FACE)
    ax.tick_params(colors=TEXT_COLOR, labelsize=9)

    for spine in ax.spines.values():
        spine.set_color(TEXT_COLOR)
        spine.set_linewidth(0.9)


# =============================================================================
# 5. PREPARE DATA
# =============================================================================

df = pd.DataFrame(PRODUCT_SCORE_DATA)

df["product_type"] = pd.Categorical(
    df["product_type"],
    categories=PRODUCT_ORDER,
    ordered=True,
)

df["score_band"] = pd.Categorical(
    df["score_band"],
    categories=SCORE_ORDER,
    ordered=True,
)

df = df.sort_values(["product_type", "score_band"]).reset_index(drop=True)

el_matrix = (
    df.pivot(index="product_type", columns="score_band", values="avg_expected_loss")
    .loc[PRODUCT_ORDER, SCORE_ORDER]
)

pd_matrix = (
    df.pivot(index="product_type", columns="score_band", values="avg_pd")
    .loc[PRODUCT_ORDER, SCORE_ORDER]
)

applications_matrix = (
    df.pivot(index="product_type", columns="score_band", values="applications")
    .loc[PRODUCT_ORDER, SCORE_ORDER]
)

requested_amount_matrix = (
    df.pivot(index="product_type", columns="score_band", values="avg_requested_amount")
    .loc[PRODUCT_ORDER, SCORE_ORDER]
)

el_matrix_k = el_matrix / 1000.0

vmin = 0
vmax = el_matrix_k.to_numpy().max()

norm = PowerNorm(
    gamma=COLOR_NORM_GAMMA,
    vmin=vmin,
    vmax=vmax,
)

cmap = plt.get_cmap("inferno")


# =============================================================================
# 6. BUILD CHART
# =============================================================================

fig, ax = plt.subplots(figsize=(12.5, 7.4), dpi=160)
fig.patch.set_facecolor(FIG_FACE)

style_dark_axis(ax)

image = ax.imshow(
    el_matrix_k.to_numpy(),
    cmap=cmap,
    norm=norm,
    aspect="auto",
)

# Axis labels.
ax.set_xticks(range(len(SCORE_ORDER)))
ax.set_xticklabels(
    [SCORE_LABELS[s] for s in SCORE_ORDER],
    color=TEXT_COLOR,
    fontsize=9.5,
)

ax.set_yticks(range(len(PRODUCT_ORDER)))
ax.set_yticklabels(
    [PRODUCT_LABELS[p] for p in PRODUCT_ORDER],
    color=TEXT_COLOR,
    fontsize=9.5,
)

ax.set_xlabel(
    "Score Band",
    color=TEXT_COLOR,
    fontsize=10.5,
    labelpad=10,
)

ax.set_ylabel(
    "Product Type",
    color=TEXT_COLOR,
    fontsize=10.5,
    labelpad=10,
)

# Gridlines between cells.
ax.set_xticks([x - 0.5 for x in range(1, len(SCORE_ORDER))], minor=True)
ax.set_yticks([y - 0.5 for y in range(1, len(PRODUCT_ORDER))], minor=True)

ax.grid(
    which="minor",
    color=GRID_COLOR,
    linewidth=0.75,
    alpha=0.30,
)

ax.tick_params(which="minor", bottom=False, left=False)

# Cell labels: avg synthetic-PD proxy.
for row_idx, product in enumerate(PRODUCT_ORDER):
    for col_idx, score in enumerate(SCORE_ORDER):
        pd_value = pd_matrix.loc[product, score]
        el_value_k = el_matrix_k.loc[product, score]

        rgba = cmap(norm(el_value_k))
        label_color = text_color_for_cell(rgba)

        ax.text(
            col_idx,
            row_idx,
            format_pd_pct(pd_value),
            ha="center",
            va="center",
            color=label_color,
            fontsize=9.0,
            fontweight="bold",
        )

# Colorbar.
cbar = fig.colorbar(
    image,
    ax=ax,
    fraction=0.035,
    pad=0.035,
)

cbar.set_label(
    "Avg Expected Loss ($K)",
    color=TEXT_COLOR,
    fontsize=10,
    labelpad=10,
)

cbar.ax.tick_params(colors=TEXT_COLOR, labelsize=8.5)
cbar.outline.set_edgecolor(TEXT_COLOR)

cbar.ax.yaxis.set_major_formatter(
    mtick.FuncFormatter(lambda value, _: f"${value:.0f}K")
)

# Highlight cells.
highlight_cells = [
    {
        "product_type": "MORTGAGE",
        "score_band": "SUBPRIME",
        "note": "Highest baseline EL cell",
    },
    {
        "product_type": "HELOC",
        "score_band": "DEEP_SUBPRIME",
        "note": "High-risk secured exposure",
    },
    {
        "product_type": "REVOLVING_LINE",
        "score_band": "SUPER_PRIME",
        "note": "Low-risk reference cell",
    },
]

for cell in highlight_cells:
    row_idx = PRODUCT_ORDER.index(cell["product_type"])
    col_idx = SCORE_ORDER.index(cell["score_band"])

    ax.add_patch(
        Rectangle(
            (col_idx - 0.5, row_idx - 0.5),
            1.0,
            1.0,
            fill=False,
            edgecolor=HIGHLIGHT_EDGE_COLOR,
            linewidth=1.8,
            alpha=0.92,
        )
    )

# Titles.
fig.suptitle(
    "Product × Score Risk Surface",
    fontsize=20,
    fontweight="bold",
    color=TEXT_COLOR,
    y=0.970,
)

fig.text(
    0.5,
    0.925,
    "Baseline synthetic portfolio: color = avg Expected Loss; cell label = avg synthetic-PD proxy",
    ha="center",
    va="center",
    fontsize=11,
    color=TEXT_COLOR,
)

fig.text(
    0.5,
    0.888,
    "Module 1 risk foundation: product structure and score quality jointly shape synthetic estimated-risk and Expected Loss",
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

# Right-side callout box.
mortgage_subprime_el = el_matrix.loc["MORTGAGE", "SUBPRIME"]
mortgage_subprime_pd = pd_matrix.loc["MORTGAGE", "SUBPRIME"]

heloc_deep_el = el_matrix.loc["HELOC", "DEEP_SUBPRIME"]
heloc_deep_pd = pd_matrix.loc["HELOC", "DEEP_SUBPRIME"]

rev_super_el = el_matrix.loc["REVOLVING_LINE", "SUPER_PRIME"]
rev_super_pd = pd_matrix.loc["REVOLVING_LINE", "SUPER_PRIME"]

callout_text = (
    "How to read:\n\n"
    "Color intensity\n"
    "= average Expected Loss\n\n"
    "Cell label\n"
    "= synthetic-PD proxy\n\n"
    "Callouts:\n"
    f"Mortgage × Subprime:\n"
    f"  {format_el_k(mortgage_subprime_el)} EL | {format_pd_pct(mortgage_subprime_pd)} PD proxy\n\n"
    f"HELOC × Deep Subprime:\n"
    f"  {format_el_k(heloc_deep_el)} EL | {format_pd_pct(heloc_deep_pd)} PD proxy\n\n"
    f"Revolving × Super Prime:\n"
    f"  {format_el_k(rev_super_el)} EL | {format_pd_pct(rev_super_pd)} PD proxy"
)

ax.text(
    1.03,
    0.52,
    callout_text,
    transform=ax.transAxes,
    fontsize=8.3,
    va="center",
    ha="left",
    color=TEXT_COLOR,
    bbox={
        "boxstyle": "round,pad=0.55",
        "facecolor": CALLOUT_BOX_COLOR,
        "edgecolor": CALLOUT_BOX_COLOR,
        "alpha": 0.88,
    },
)

# Footer caption.
caption = (
    "The baseline synthetic portfolio is differentiated across both borrower score quality and "
    "product structure. Expected Loss is not just a score metric; it is shaped by exposure size, "
    "product structure, LGD, affordability, and the synthetic estimated-PD proxy."
)

fig.text(
    0.5,
    0.035,
    "\n".join(textwrap.wrap(caption, width=155)),
    ha="center",
    va="center",
    fontsize=9.0,
    color=TEXT_COLOR,
)

# Layout room:
#   top for title/subtitle,
#   right for interpretation callout,
#   bottom for caption.
fig.tight_layout(rect=[0.04, 0.09, 0.80, 0.84])


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

print("\nPanel data used:")
for _, row in df.iterrows():
    print(
        f"{str(row['product_type']):<26} | "
        f"{str(row['score_band']):<14} | "
        f"Apps: {int(row['applications']):>5,} | "
        f"Avg amount: {format_amount_k(row['avg_requested_amount']):>7} | "
        f"Avg PTI: {row['avg_pti']:.1%} | "
        f"PD proxy: {format_pd_pct(row['avg_pd']):>6} | "
        f"Avg EL: {format_el_k(row['avg_expected_loss']):>7}"
    )
```
<!-- END_MESSAGE C040-M02432 -->


---

<a id="c040-m02434"></a>

### C040-M02434

**Andrew** · 2026-05-26T22:01:50.509000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02434 -->
this is very good, but the right hand blue box is being hidden by the scale.  please place that blue box to the right of the scale.
<!-- END_MESSAGE C040-M02434 -->


**Attachments in export:** `image(81).png`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c040-m02435"></a>

### C040-M02435

**Andrew** · 2026-05-26T22:08:17.527000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02435 -->
stop wasting our time/resources generating images! we are building python code to create these output.  please update module 1 panel 1 python code to correct the right hand scale overlap with the right hand blue box.
<!-- END_MESSAGE C040-M02435 -->


---

<a id="c040-m02438"></a>

### C040-M02438

**ChatGPT** · 2026-05-26T22:12:34.553106-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02438 -->
You’re right — staying code-only. Below is the updated **full Module 1 Panel 1 Python code**. The key layout fix is that the heatmap, color scale, and blue interpretation box are now placed in separate figure regions:

```text
heatmap → color scale → blue interpretation box
```

The colorbar label is also moved above the scale instead of vertically beside it, which prevents overlap.

```python
"""
Module 1 README Panel 1
Product × Score Risk Surface: Baseline Synthetic Portfolio

This version uses hardcoded final-campaign Section 10.03 values.

Panel thesis:
    Module 1 is not a generic random-data generator.
    It creates a product-aware and score-aware synthetic risk foundation.

    Risk varies by:
        borrower score quality,
        product structure,
        exposure size,
        affordability,
        LGD,
        and the synthetic estimated-PD proxy.

Data source:
    Final campaign Section 10.03:
    Product × score scenario summary.

Data scope:
    scenario_set_name = MODULE1_V2_BASELINE_SET
    scenario_name     = BASELINE_V2
    population_id     = BASE_POPULATION_V1

Chart design:
    Rows:
        product_type

    Columns:
        score_band

    Cell color:
        avg_expected_loss, shown in $K

    Cell label:
        avg synthetic-PD proxy, shown as %

Layout note:
    The heatmap, color scale, and interpretation box are intentionally placed
    in separate figure regions to avoid overlap:

        heatmap -> color scale -> blue interpretation box

Output:
    assets/module1_product_score_risk_surface.png
    assets/module1_product_score_risk_surface.svg
"""

from __future__ import annotations

from pathlib import Path
import textwrap

import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.ticker as mtick
from matplotlib.colors import PowerNorm
from matplotlib.patches import Rectangle


# =============================================================================
# 1. OUTPUT SETTINGS
# =============================================================================

OUTPUT_DIR = Path("assets")
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

OUTPUT_PNG = OUTPUT_DIR / "module1_product_score_risk_surface.png"
OUTPUT_SVG = OUTPUT_DIR / "module1_product_score_risk_surface.svg"


# =============================================================================
# 2. HARDCODED SECTION 10.03 BASELINE PRODUCT × SCORE DATA
# =============================================================================

PRODUCT_SCORE_DATA = [
    {
        "product_type": "MORTGAGE",
        "score_band": "SUPER_PRIME",
        "applications": 2747,
        "avg_requested_amount": 468486.10,
        "avg_pti": 0.2641,
        "avg_pd": 0.0162,
        "avg_expected_loss": 1611.61,
    },
    {
        "product_type": "MORTGAGE",
        "score_band": "PRIME",
        "applications": 4285,
        "avg_requested_amount": 407876.71,
        "avg_pti": 0.2971,
        "avg_pd": 0.0474,
        "avg_expected_loss": 4058.79,
    },
    {
        "product_type": "MORTGAGE",
        "score_band": "NEAR_PRIME",
        "applications": 3644,
        "avg_requested_amount": 331987.76,
        "avg_pti": 0.3252,
        "avg_pd": 0.1537,
        "avg_expected_loss": 10521.24,
    },
    {
        "product_type": "MORTGAGE",
        "score_band": "SUBPRIME",
        "applications": 2639,
        "avg_requested_amount": 229340.19,
        "avg_pti": 0.3054,
        "avg_pd": 0.3835,
        "avg_expected_loss": 17746.70,
    },
    {
        "product_type": "MORTGAGE",
        "score_band": "DEEP_SUBPRIME",
        "applications": 1750,
        "avg_requested_amount": 147576.45,
        "avg_pti": 0.2745,
        "avg_pd": 0.4490,
        "avg_expected_loss": 13257.06,
    },

    {
        "product_type": "HELOC",
        "score_band": "SUPER_PRIME",
        "applications": 900,
        "avg_requested_amount": 154463.01,
        "avg_pti": 0.0865,
        "avg_pd": 0.0130,
        "avg_expected_loss": 532.17,
    },
    {
        "product_type": "HELOC",
        "score_band": "PRIME",
        "applications": 1326,
        "avg_requested_amount": 144556.42,
        "avg_pti": 0.1159,
        "avg_pd": 0.0398,
        "avg_expected_loss": 1556.18,
    },
    {
        "product_type": "HELOC",
        "score_band": "NEAR_PRIME",
        "applications": 1176,
        "avg_requested_amount": 141084.72,
        "avg_pti": 0.1704,
        "avg_pd": 0.1342,
        "avg_expected_loss": 5177.18,
    },
    {
        "product_type": "HELOC",
        "score_band": "SUBPRIME",
        "applications": 894,
        "avg_requested_amount": 131376.16,
        "avg_pti": 0.2474,
        "avg_pd": 0.3693,
        "avg_expected_loss": 12706.83,
    },
    {
        "product_type": "HELOC",
        "score_band": "DEEP_SUBPRIME",
        "applications": 666,
        "avg_requested_amount": 124955.09,
        "avg_pti": 0.3431,
        "avg_pd": 0.4468,
        "avg_expected_loss": 14021.27,
    },

    {
        "product_type": "AUTO_LOAN",
        "score_band": "SUPER_PRIME",
        "applications": 1786,
        "avg_requested_amount": 46136.81,
        "avg_pti": 0.0755,
        "avg_pd": 0.0119,
        "avg_expected_loss": 256.74,
    },
    {
        "product_type": "AUTO_LOAN",
        "score_band": "PRIME",
        "applications": 2771,
        "avg_requested_amount": 45278.25,
        "avg_pti": 0.0918,
        "avg_pd": 0.0361,
        "avg_expected_loss": 775.82,
    },
    {
        "product_type": "AUTO_LOAN",
        "score_band": "NEAR_PRIME",
        "applications": 2390,
        "avg_requested_amount": 43788.68,
        "avg_pti": 0.1161,
        "avg_pd": 0.1198,
        "avg_expected_loss": 2500.59,
    },
    {
        "product_type": "AUTO_LOAN",
        "score_band": "SUBPRIME",
        "applications": 1759,
        "avg_requested_amount": 40236.91,
        "avg_pti": 0.1614,
        "avg_pd": 0.3488,
        "avg_expected_loss": 6600.61,
    },
    {
        "product_type": "AUTO_LOAN",
        "score_band": "DEEP_SUBPRIME",
        "applications": 1240,
        "avg_requested_amount": 39537.25,
        "avg_pti": 0.2421,
        "avg_pd": 0.4453,
        "avg_expected_loss": 7964.68,
    },

    {
        "product_type": "UNSECURED_PERSONAL_LOAN",
        "score_band": "SUPER_PRIME",
        "applications": 1361,
        "avg_requested_amount": 31563.60,
        "avg_pti": 0.0765,
        "avg_pd": 0.0128,
        "avg_expected_loss": 291.17,
    },
    {
        "product_type": "UNSECURED_PERSONAL_LOAN",
        "score_band": "PRIME",
        "applications": 2091,
        "avg_requested_amount": 29391.67,
        "avg_pti": 0.0892,
        "avg_pd": 0.0382,
        "avg_expected_loss": 822.76,
    },
    {
        "product_type": "UNSECURED_PERSONAL_LOAN",
        "score_band": "NEAR_PRIME",
        "applications": 1838,
        "avg_requested_amount": 27818.26,
        "avg_pti": 0.1079,
        "avg_pd": 0.1258,
        "avg_expected_loss": 2594.60,
    },
    {
        "product_type": "UNSECURED_PERSONAL_LOAN",
        "score_band": "SUBPRIME",
        "applications": 1390,
        "avg_requested_amount": 25908.37,
        "avg_pti": 0.1435,
        "avg_pd": 0.3587,
        "avg_expected_loss": 6721.05,
    },
    {
        "product_type": "UNSECURED_PERSONAL_LOAN",
        "score_band": "DEEP_SUBPRIME",
        "applications": 892,
        "avg_requested_amount": 24454.98,
        "avg_pti": 0.1996,
        "avg_pd": 0.4472,
        "avg_expected_loss": 7679.58,
    },

    {
        "product_type": "REVOLVING_LINE",
        "score_band": "SUPER_PRIME",
        "applications": 2190,
        "avg_requested_amount": 19003.21,
        "avg_pti": 0.0415,
        "avg_pd": 0.0122,
        "avg_expected_loss": 200.05,
    },
    {
        "product_type": "REVOLVING_LINE",
        "score_band": "PRIME",
        "applications": 3514,
        "avg_requested_amount": 18002.43,
        "avg_pti": 0.0482,
        "avg_pd": 0.0355,
        "avg_expected_loss": 553.11,
    },
    {
        "product_type": "REVOLVING_LINE",
        "score_band": "NEAR_PRIME",
        "applications": 3025,
        "avg_requested_amount": 17098.68,
        "avg_pti": 0.0586,
        "avg_pd": 0.1143,
        "avg_expected_loss": 1709.23,
    },
    {
        "product_type": "REVOLVING_LINE",
        "score_band": "SUBPRIME",
        "applications": 2220,
        "avg_requested_amount": 16390.66,
        "avg_pti": 0.0793,
        "avg_pd": 0.3366,
        "avg_expected_loss": 4800.50,
    },
    {
        "product_type": "REVOLVING_LINE",
        "score_band": "DEEP_SUBPRIME",
        "applications": 1506,
        "avg_requested_amount": 14980.44,
        "avg_pti": 0.1123,
        "avg_pd": 0.4443,
        "avg_expected_loss": 5680.01,
    },
]


# =============================================================================
# 3. CHART STYLE SETTINGS
# =============================================================================

PRODUCT_ORDER = [
    "MORTGAGE",
    "HELOC",
    "AUTO_LOAN",
    "UNSECURED_PERSONAL_LOAN",
    "REVOLVING_LINE",
]

SCORE_ORDER = [
    "SUPER_PRIME",
    "PRIME",
    "NEAR_PRIME",
    "SUBPRIME",
    "DEEP_SUBPRIME",
]

PRODUCT_LABELS = {
    "MORTGAGE": "Mortgage",
    "HELOC": "HELOC",
    "AUTO_LOAN": "Auto Loan",
    "UNSECURED_PERSONAL_LOAN": "Unsecured\nPersonal Loan",
    "REVOLVING_LINE": "Revolving\nLine",
}

SCORE_LABELS = {
    "SUPER_PRIME": "Super\nPrime",
    "PRIME": "Prime",
    "NEAR_PRIME": "Near\nPrime",
    "SUBPRIME": "Subprime",
    "DEEP_SUBPRIME": "Deep\nSubprime",
}

FIG_FACE = "black"
AX_FACE = "black"
TEXT_COLOR = "white"
GRID_COLOR = "white"
CALLOUT_BOX_COLOR = "#4f8fc4"
HIGHLIGHT_EDGE_COLOR = "white"

# A mildly nonlinear color scale keeps the highest-EL cells from washing out
# the rest of the matrix while preserving the risk-intensity story.
COLOR_NORM_GAMMA = 0.62


# =============================================================================
# 4. HELPER FUNCTIONS
# =============================================================================

def format_pd_pct(value: float) -> str:
    """Format synthetic estimated-PD proxy as percentage label."""
    return f"{value * 100:.1f}%"


def format_el_k(value: float) -> str:
    """Format Expected Loss dollars as $K."""
    return f"${value / 1000:.1f}K"


def format_amount_k(value: float) -> str:
    """Format requested amount as $K."""
    return f"${value / 1000:.0f}K"


def text_color_for_cell(rgba: tuple[float, float, float, float]) -> str:
    """
    Pick white or black cell text based on background luminance.

    This keeps PD-proxy labels readable across the heatmap.
    """
    r, g, b, _ = rgba
    luminance = 0.299 * r + 0.587 * g + 0.114 * b
    return "black" if luminance > 0.62 else "white"


def style_dark_axis(ax: plt.Axes) -> None:
    """Apply shared dark chart styling."""
    ax.set_facecolor(AX_FACE)
    ax.tick_params(colors=TEXT_COLOR, labelsize=9)

    for spine in ax.spines.values():
        spine.set_color(TEXT_COLOR)
        spine.set_linewidth(0.9)


# =============================================================================
# 5. PREPARE DATA
# =============================================================================

df = pd.DataFrame(PRODUCT_SCORE_DATA)

df["product_type"] = pd.Categorical(
    df["product_type"],
    categories=PRODUCT_ORDER,
    ordered=True,
)

df["score_band"] = pd.Categorical(
    df["score_band"],
    categories=SCORE_ORDER,
    ordered=True,
)

df = df.sort_values(["product_type", "score_band"]).reset_index(drop=True)

el_matrix = (
    df.pivot(index="product_type", columns="score_band", values="avg_expected_loss")
    .loc[PRODUCT_ORDER, SCORE_ORDER]
)

pd_matrix = (
    df.pivot(index="product_type", columns="score_band", values="avg_pd")
    .loc[PRODUCT_ORDER, SCORE_ORDER]
)

applications_matrix = (
    df.pivot(index="product_type", columns="score_band", values="applications")
    .loc[PRODUCT_ORDER, SCORE_ORDER]
)

requested_amount_matrix = (
    df.pivot(index="product_type", columns="score_band", values="avg_requested_amount")
    .loc[PRODUCT_ORDER, SCORE_ORDER]
)

el_matrix_k = el_matrix / 1000.0

vmin = 0
vmax = el_matrix_k.to_numpy().max()

norm = PowerNorm(
    gamma=COLOR_NORM_GAMMA,
    vmin=vmin,
    vmax=vmax,
)

cmap = plt.get_cmap("inferno")


# =============================================================================
# 6. BUILD CHART
# =============================================================================

fig = plt.figure(figsize=(15.2, 7.4), dpi=160)
fig.patch.set_facecolor(FIG_FACE)

# Manual layout:
#   ax   = heatmap
#   cax  = color scale
#   text = interpretation box to the right of the color scale
#
# This avoids overlap between the color scale and the blue interpretation box.
ax = fig.add_axes([0.07, 0.16, 0.58, 0.68])
cax = fig.add_axes([0.685, 0.19, 0.025, 0.61])

style_dark_axis(ax)

image = ax.imshow(
    el_matrix_k.to_numpy(),
    cmap=cmap,
    norm=norm,
    aspect="auto",
)

# Axis labels.
ax.set_xticks(range(len(SCORE_ORDER)))
ax.set_xticklabels(
    [SCORE_LABELS[s] for s in SCORE_ORDER],
    color=TEXT_COLOR,
    fontsize=9.5,
)

ax.set_yticks(range(len(PRODUCT_ORDER)))
ax.set_yticklabels(
    [PRODUCT_LABELS[p] for p in PRODUCT_ORDER],
    color=TEXT_COLOR,
    fontsize=9.5,
)

ax.set_xlabel(
    "Score Band",
    color=TEXT_COLOR,
    fontsize=10.5,
    labelpad=10,
)

ax.set_ylabel(
    "Product Type",
    color=TEXT_COLOR,
    fontsize=10.5,
    labelpad=10,
)

# Gridlines between cells.
ax.set_xticks([x - 0.5 for x in range(1, len(SCORE_ORDER))], minor=True)
ax.set_yticks([y - 0.5 for y in range(1, len(PRODUCT_ORDER))], minor=True)

ax.grid(
    which="minor",
    color=GRID_COLOR,
    linewidth=0.75,
    alpha=0.30,
)

ax.tick_params(which="minor", bottom=False, left=False)

# Cell labels: avg synthetic-PD proxy.
for row_idx, product in enumerate(PRODUCT_ORDER):
    for col_idx, score in enumerate(SCORE_ORDER):
        pd_value = pd_matrix.loc[product, score]
        el_value_k = el_matrix_k.loc[product, score]

        rgba = cmap(norm(el_value_k))
        label_color = text_color_for_cell(rgba)

        ax.text(
            col_idx,
            row_idx,
            format_pd_pct(pd_value),
            ha="center",
            va="center",
            color=label_color,
            fontsize=9.0,
            fontweight="bold",
        )

# Colorbar in its own axis.
cbar = fig.colorbar(
    image,
    cax=cax,
)

# Put the colorbar title above the scale rather than vertically beside it.
# This prevents it from crowding the blue interpretation box.
cbar.ax.set_title(
    "Avg Expected\nLoss ($K)",
    color=TEXT_COLOR,
    fontsize=8.6,
    pad=10,
)

cbar.ax.tick_params(colors=TEXT_COLOR, labelsize=8.5)
cbar.outline.set_edgecolor(TEXT_COLOR)

cbar.ax.yaxis.set_major_formatter(
    mtick.FuncFormatter(lambda value, _: f"${value:.0f}K")
)

# Highlight cells.
highlight_cells = [
    {
        "product_type": "MORTGAGE",
        "score_band": "SUBPRIME",
        "note": "Highest baseline EL cell",
    },
    {
        "product_type": "HELOC",
        "score_band": "DEEP_SUBPRIME",
        "note": "High-risk secured exposure",
    },
    {
        "product_type": "REVOLVING_LINE",
        "score_band": "SUPER_PRIME",
        "note": "Low-risk reference cell",
    },
]

for cell in highlight_cells:
    row_idx = PRODUCT_ORDER.index(cell["product_type"])
    col_idx = SCORE_ORDER.index(cell["score_band"])

    ax.add_patch(
        Rectangle(
            (col_idx - 0.5, row_idx - 0.5),
            1.0,
            1.0,
            fill=False,
            edgecolor=HIGHLIGHT_EDGE_COLOR,
            linewidth=1.8,
            alpha=0.92,
        )
    )

# Titles.
fig.suptitle(
    "Product × Score Risk Surface",
    fontsize=20,
    fontweight="bold",
    color=TEXT_COLOR,
    y=0.970,
)

fig.text(
    0.5,
    0.925,
    "Baseline synthetic portfolio: color = avg Expected Loss; cell label = avg synthetic-PD proxy",
    ha="center",
    va="center",
    fontsize=11,
    color=TEXT_COLOR,
)

fig.text(
    0.5,
    0.888,
    "Module 1 risk foundation: product structure and score quality jointly shape synthetic estimated-risk and Expected Loss",
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

# Right-side callout box.
mortgage_subprime_el = el_matrix.loc["MORTGAGE", "SUBPRIME"]
mortgage_subprime_pd = pd_matrix.loc["MORTGAGE", "SUBPRIME"]

heloc_deep_el = el_matrix.loc["HELOC", "DEEP_SUBPRIME"]
heloc_deep_pd = pd_matrix.loc["HELOC", "DEEP_SUBPRIME"]

rev_super_el = el_matrix.loc["REVOLVING_LINE", "SUPER_PRIME"]
rev_super_pd = pd_matrix.loc["REVOLVING_LINE", "SUPER_PRIME"]

callout_text = (
    "How to read:\n\n"
    "Color intensity\n"
    "= average Expected Loss\n\n"
    "Cell label\n"
    "= synthetic-PD proxy\n\n"
    "Callouts:\n"
    f"Mortgage × Subprime:\n"
    f"  {format_el_k(mortgage_subprime_el)} EL | {format_pd_pct(mortgage_subprime_pd)} PD proxy\n\n"
    f"HELOC × Deep Subprime:\n"
    f"  {format_el_k(heloc_deep_el)} EL | {format_pd_pct(heloc_deep_pd)} PD proxy\n\n"
    f"Revolving × Super Prime:\n"
    f"  {format_el_k(rev_super_el)} EL | {format_pd_pct(rev_super_pd)} PD proxy"
)

# This box is intentionally placed to the right of the color scale.
fig.text(
    0.755,
    0.50,
    callout_text,
    fontsize=8.4,
    va="center",
    ha="left",
    color=TEXT_COLOR,
    bbox={
        "boxstyle": "round,pad=0.55",
        "facecolor": CALLOUT_BOX_COLOR,
        "edgecolor": CALLOUT_BOX_COLOR,
        "alpha": 0.88,
    },
)

# Footer caption.
caption = (
    "The baseline synthetic portfolio is differentiated across both borrower score quality and "
    "product structure. Expected Loss is not just a score metric; it is shaped by exposure size, "
    "product structure, LGD, affordability, and the synthetic estimated-PD proxy."
)

fig.text(
    0.5,
    0.045,
    "\n".join(textwrap.wrap(caption, width=155)),
    ha="center",
    va="center",
    fontsize=9.0,
    color=TEXT_COLOR,
)


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

print("\nPanel data used:")
for _, row in df.iterrows():
    print(
        f"{str(row['product_type']):<26} | "
        f"{str(row['score_band']):<14} | "
        f"Apps: {int(row['applications']):>5,} | "
        f"Avg amount: {format_amount_k(row['avg_requested_amount']):>7} | "
        f"Avg PTI: {row['avg_pti']:.1%} | "
        f"PD proxy: {format_pd_pct(row['avg_pd']):>6} | "
        f"Avg EL: {format_el_k(row['avg_expected_loss']):>7}"
    )
```
<!-- END_MESSAGE C040-M02438 -->


---

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_07.md) · [Next](Part_09.md)
