# Campaign QA and strategy expansion

## Part 11

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_10.md) · [Next](Part_12.md)

<a id="c040-m02539"></a>

### C040-M02539

**ChatGPT** · 2026-05-27T13:51:23.834525-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02539 -->
```python
"""
Module 1 README Panel 3
Scenario Expected-Loss Impact Decomposition:
Product Contribution to Portfolio EL Movement

This script reads the final-campaign Section 10.03 CSV and derives product-level
Expected Loss contribution deltas for selected non-rate scenario levers.

Panel thesis:
    Module 1 does not merely generate scenarios.
    It makes scenario impact attributable.

    Scenario Expected Loss movement can be decomposed into:
        scenario family
        scenario lever
        product contribution
        product × score-band driver

Data source:
    Final campaign Section 10.03:
    Product × score scenario summary.

Expected input file:
    module1_synthetic_application_risk_engine_v2.0_10.03_QA_product_score_scenario_summary_campaign.csv

Chart design:
    Diverging stacked horizontal bar chart.

    Rows:
        selected non-rate scenario levers.

    X-axis:
        Δ Total Expected Loss ($M)

    Stack:
        product_type contribution.

    Direction:
        left of zero  = lower total Expected Loss versus family reference
        right of zero = higher total Expected Loss versus family reference

    Right-side callout:
        Top product × score movements by absolute Δ Total Expected Loss.

Output:
    assets/module1_scenario_expected_loss_decomposition.png
    assets/module1_scenario_expected_loss_decomposition.svg
"""

from __future__ import annotations

from pathlib import Path
import textwrap

import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.ticker as mtick


# =============================================================================
# 1. INPUT / OUTPUT SETTINGS
# =============================================================================

# The script tries these paths in order. Keep the first one for local README use.
CANDIDATE_INPUT_CSVS = [
    Path("module1_synthetic_application_risk_engine_v2.0_10.03_QA_product_score_scenario_summary_campaign.csv"),
    Path("module1_synthetic_application_risk_engine_v2.0_10.03_QA_product_score_scenario_summary_campaign(1).csv"),
    Path("module1_synthetic_application_risk_engine_v2.0_10.03_QA_product_score_scenario_summary_campaign(2).csv"),
    Path("/mnt/data/module1_synthetic_application_risk_engine_v2.0_10.03_QA_product_score_scenario_summary_campaign.csv"),
    Path("/mnt/data/module1_synthetic_application_risk_engine_v2.0_10.03_QA_product_score_scenario_summary_campaign(1).csv"),
    Path("/mnt/data/module1_synthetic_application_risk_engine_v2.0_10.03_QA_product_score_scenario_summary_campaign(2).csv"),
]

OUTPUT_DIR = Path("assets")
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

OUTPUT_PNG = OUTPUT_DIR / "module1_scenario_expected_loss_decomposition.png"
OUTPUT_SVG = OUTPUT_DIR / "module1_scenario_expected_loss_decomposition.svg"


# =============================================================================
# 2. SCENARIO FAMILY / REFERENCE CONFIGURATION
# =============================================================================

# Panel 3 intentionally focuses on selected non-rate scenario levers.
# Rate environment is already visible in the scenario lever matrix.
SELECTED_SCENARIOS = [
    {
        "family": "Credit Box",
        "family_label": "Credit\nBox",
        "scenario_name": "PRIME_GROWTH_SCORE_MIX",
        "display_label": "Prime\nGrowth",
        "reference_scenario_name": "CREDIT_BOX_BASELINE_REFERENCE",
    },
    {
        "family": "Credit Box",
        "family_label": "Credit\nBox",
        "scenario_name": "CREDIT_STRESS_SCORE_MIX",
        "display_label": "Credit\nStress",
        "reference_scenario_name": "CREDIT_BOX_BASELINE_REFERENCE",
    },
    {
        "family": "Exposure",
        "family_label": "Exposure\nIntensity",
        "scenario_name": "LOW_BALANCE_CONSERVATIVE_REQUESTS",
        "display_label": "Low-Balance\nConservative",
        "reference_scenario_name": "EXPOSURE_BASELINE_REFERENCE",
    },
    {
        "family": "Exposure",
        "family_label": "Exposure\nIntensity",
        "scenario_name": "HIGH_BALANCE_APPETITE",
        "display_label": "High-Balance\nAppetite",
        "reference_scenario_name": "EXPOSURE_BASELINE_REFERENCE",
    },
    {
        "family": "LGD",
        "family_label": "LGD\nSeverity",
        "scenario_name": "BROAD_LGD_STRESS",
        "display_label": "Broad LGD\nStress",
        "reference_scenario_name": "LGD_BASELINE_REFERENCE",
    },
    {
        "family": "Portfolio Mix",
        "family_label": "Portfolio\nMix",
        "scenario_name": "REVOLVING_LINE_EXPANSION_MIX",
        "display_label": "Revolving\nExpansion",
        "reference_scenario_name": "PORTFOLIO_MIX_BASELINE_REFERENCE",
    },
    {
        "family": "Portfolio Mix",
        "family_label": "Portfolio\nMix",
        "scenario_name": "SECURED_BALANCE_GROWTH_MIX",
        "display_label": "Secured Balance\nGrowth",
        "reference_scenario_name": "PORTFOLIO_MIX_BASELINE_REFERENCE",
    },
]

TARGET_POPULATION_ID = "BASE_POPULATION_V1"

PRODUCT_ORDER = [
    "MORTGAGE",
    "HELOC",
    "AUTO_LOAN",
    "UNSECURED_PERSONAL_LOAN",
    "REVOLVING_LINE",
]

PRODUCT_LABELS = {
    "MORTGAGE": "Mortgage",
    "HELOC": "HELOC",
    "AUTO_LOAN": "Auto Loan",
    "UNSECURED_PERSONAL_LOAN": "Unsecured\nPersonal Loan",
    "REVOLVING_LINE": "Revolving\nLine",
}

PRODUCT_LEGEND_LABELS = {
    "MORTGAGE": "Mortgage",
    "HELOC": "HELOC",
    "AUTO_LOAN": "Auto Loan",
    "UNSECURED_PERSONAL_LOAN": "Unsecured Personal Loan",
    "REVOLVING_LINE": "Revolving Line",
}

SCORE_LABELS = {
    "SUPER_PRIME": "Super Prime",
    "PRIME": "Prime",
    "NEAR_PRIME": "Near Prime",
    "SUBPRIME": "Subprime",
    "DEEP_SUBPRIME": "Deep Subprime",
}


# =============================================================================
# 3. CHART STYLE SETTINGS
# =============================================================================

FIG_FACE = "black"
AX_FACE = "black"
TEXT_COLOR = "white"
GRID_COLOR = "white"
ZERO_LINE_COLOR = "white"
CALLOUT_BOX_COLOR = "#4f8fc4"

CONTENT_CENTER_X = 0.50

PRODUCT_COLORS = {
    "MORTGAGE": "#7fcdbb",
    "HELOC": "#2f84c4",
    "AUTO_LOAN": "#f0a62e",
    "UNSECURED_PERSONAL_LOAN": "#2ca02c",
    "REVOLVING_LINE": "#d95f5f",
}

BAR_ALPHA = 0.90

# Inside-segment labels are only shown when product contribution is material.
# Product names are intentionally omitted inside bars; the legend identifies product colors.
SEGMENT_LABEL_THRESHOLD_M = 10.0

# Right-side callout top-N.
TOP_DRIVER_COUNT = 5


# =============================================================================
# 4. HELPER FUNCTIONS
# =============================================================================

def resolve_input_path(candidate_paths: list[Path]) -> Path:
    """Return the first existing input path."""
    for candidate in candidate_paths:
        if candidate.exists():
            return candidate

    raise FileNotFoundError(
        "Could not find the Section 10.03 CSV. Checked:\n"
        + "\n".join(str(path) for path in candidate_paths)
    )


def coerce_numeric(series: pd.Series) -> pd.Series:
    """
    Convert a Series to numeric, allowing for commas / currency symbols if present.
    """
    if pd.api.types.is_numeric_dtype(series):
        return series

    cleaned = (
        series.astype(str)
        .str.replace(",", "", regex=False)
        .str.replace("$", "", regex=False)
        .str.replace("%", "", regex=False)
        .str.strip()
    )

    return pd.to_numeric(cleaned, errors="coerce")


def require_columns(df: pd.DataFrame, required_columns: list[str]) -> None:
    """Raise a clear error if required columns are missing."""
    missing = [column for column in required_columns if column not in df.columns]

    if missing:
        raise ValueError(
            "Input CSV is missing required column(s): "
            + ", ".join(missing)
            + "\n\nAvailable columns:\n"
            + "\n".join(df.columns)
        )


def find_total_el_column(df: pd.DataFrame) -> str | None:
    """
    Prefer a true segment total Expected Loss column if the export has one.
    Otherwise the script derives segment total EL as:
        applications × avg_expected_loss
    """
    candidates = [
        "total_expected_loss",
        "total_expected_loss_amount",
        "segment_total_expected_loss",
        "sum_expected_loss",
        "total_el",
    ]

    for candidate in candidates:
        if candidate in df.columns:
            return candidate

    return None


def format_m(value: float, decimals: int = 1) -> str:
    """Format a value in millions with sign."""
    if abs(value) < 0.05:
        return "$0.0M"

    sign = "+" if value >= 0 else "-"
    return f"{sign}${abs(value):,.{decimals}f}M"


def format_m_compact(value: float) -> str:
    """Compact format for segment labels."""
    if abs(value) < 0.05:
        return "$0M"

    sign = "+" if value >= 0 else "-"
    return f"{sign}${abs(value):.0f}M"


def format_count(value: float | int) -> str:
    """Format row counts with commas."""
    return f"{int(value):,}"


def prettify_scenario_name(value: str) -> str:
    """Readable scenario label fallback."""
    return str(value).replace("_", " ").title()


def prettify_product(value: str) -> str:
    """Readable product label fallback."""
    return PRODUCT_LEGEND_LABELS.get(value, str(value).replace("_", " ").title())


def prettify_score(value: str) -> str:
    """Readable score-band label fallback."""
    return SCORE_LABELS.get(value, str(value).replace("_", " ").title())


def text_color_for_hex(hex_color: str) -> str:
    """
    Pick black or white text based on background luminance.

    This keeps inside-segment labels readable.
    """
    hex_color = hex_color.lstrip("#")

    r = int(hex_color[0:2], 16) / 255.0
    g = int(hex_color[2:4], 16) / 255.0
    b = int(hex_color[4:6], 16) / 255.0

    luminance = 0.299 * r + 0.587 * g + 0.114 * b

    return "black" if luminance > 0.58 else "white"


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
        axis="x",
        linewidth=0.45,
        alpha=0.28,
        color=GRID_COLOR,
    )


# =============================================================================
# 5. LOAD AND PREPARE INPUT DATA
# =============================================================================

input_csv = resolve_input_path(CANDIDATE_INPUT_CSVS)
raw_df = pd.read_csv(input_csv)

required = [
    "scenario_name",
    "population_id",
    "product_type",
    "score_band",
    "applications",
    "avg_expected_loss",
]

require_columns(raw_df, required)

df = raw_df.copy()

# Population filter keeps the campaign comparison aligned to the same synthetic population.
df = df.loc[df["population_id"] == TARGET_POPULATION_ID].copy()

if df.empty:
    raise ValueError(
        f"No rows found for population_id = {TARGET_POPULATION_ID}."
    )

# Normalize text keys.
for column in ["scenario_name", "population_id", "product_type", "score_band"]:
    df[column] = df[column].astype(str).str.strip()

# Numeric coercion.
df["applications"] = coerce_numeric(df["applications"])
df["avg_expected_loss"] = coerce_numeric(df["avg_expected_loss"])

total_el_col = find_total_el_column(df)

if total_el_col is not None:
    df[total_el_col] = coerce_numeric(df[total_el_col])
    df["segment_total_expected_loss"] = df[total_el_col]
else:
    df["segment_total_expected_loss"] = df["applications"] * df["avg_expected_loss"]

# Guardrails.
if df["applications"].isna().any():
    raise ValueError("applications contains null / nonnumeric values after coercion.")

if df["avg_expected_loss"].isna().any():
    raise ValueError("avg_expected_loss contains null / nonnumeric values after coercion.")

if df["segment_total_expected_loss"].isna().any():
    raise ValueError("segment_total_expected_loss contains null values after derivation.")

# Aggregate in case the export has duplicate rows at the same scenario × product × score grain.
segment_df = (
    df.groupby(
        ["scenario_name", "product_type", "score_band"],
        as_index=False,
    )
    .agg(
        applications=("applications", "sum"),
        segment_total_expected_loss=("segment_total_expected_loss", "sum"),
    )
)

available_scenarios = set(segment_df["scenario_name"].unique())

required_scenarios = set()
for item in SELECTED_SCENARIOS:
    required_scenarios.add(item["scenario_name"])
    required_scenarios.add(item["reference_scenario_name"])

missing_scenarios = sorted(required_scenarios - available_scenarios)

if missing_scenarios:
    raise ValueError(
        "The input Section 10.03 CSV is missing required scenario(s): "
        + ", ".join(missing_scenarios)
    )


# =============================================================================
# 6. BUILD SCENARIO × PRODUCT × SCORE DELTAS
# =============================================================================

delta_records: list[dict] = []

for row_order, scenario_config in enumerate(SELECTED_SCENARIOS):
    scenario_name = scenario_config["scenario_name"]
    reference_name = scenario_config["reference_scenario_name"]

    scenario_slice = segment_df.loc[
        segment_df["scenario_name"] == scenario_name,
        [
            "product_type",
            "score_band",
            "applications",
            "segment_total_expected_loss",
        ],
    ].rename(
        columns={
            "applications": "scenario_applications",
            "segment_total_expected_loss": "scenario_segment_total_expected_loss",
        }
    )

    reference_slice = segment_df.loc[
        segment_df["scenario_name"] == reference_name,
        [
            "product_type",
            "score_band",
            "applications",
            "segment_total_expected_loss",
        ],
    ].rename(
        columns={
            "applications": "reference_applications",
            "segment_total_expected_loss": "reference_segment_total_expected_loss",
        }
    )

    merged = pd.merge(
        scenario_slice,
        reference_slice,
        on=["product_type", "score_band"],
        how="outer",
    )

    merged["scenario_applications"] = merged["scenario_applications"].fillna(0)
    merged["reference_applications"] = merged["reference_applications"].fillna(0)

    merged["scenario_segment_total_expected_loss"] = (
        merged["scenario_segment_total_expected_loss"].fillna(0.0)
    )

    merged["reference_segment_total_expected_loss"] = (
        merged["reference_segment_total_expected_loss"].fillna(0.0)
    )

    merged["delta_segment_total_expected_loss"] = (
        merged["scenario_segment_total_expected_loss"]
        - merged["reference_segment_total_expected_loss"]
    )

    for _, segment_row in merged.iterrows():
        delta_records.append(
            {
                "row_order": row_order,
                "family": scenario_config["family"],
                "family_label": scenario_config["family_label"],
                "scenario_name": scenario_name,
                "display_label": scenario_config["display_label"],
                "reference_scenario_name": reference_name,
                "product_type": segment_row["product_type"],
                "score_band": segment_row["score_band"],
                "scenario_applications": segment_row["scenario_applications"],
                "reference_applications": segment_row["reference_applications"],
                "scenario_segment_total_expected_loss": segment_row[
                    "scenario_segment_total_expected_loss"
                ],
                "reference_segment_total_expected_loss": segment_row[
                    "reference_segment_total_expected_loss"
                ],
                "delta_segment_total_expected_loss": segment_row[
                    "delta_segment_total_expected_loss"
                ],
            }
        )

delta_df = pd.DataFrame(delta_records)

delta_df["delta_segment_total_expected_loss_m"] = (
    delta_df["delta_segment_total_expected_loss"] / 1_000_000.0
)

# Product-level contribution matrix.
product_contrib = (
    delta_df.groupby(
        ["row_order", "family", "family_label", "scenario_name", "display_label", "product_type"],
        as_index=False,
    )
    .agg(
        delta_product_total_expected_loss=("delta_segment_total_expected_loss", "sum")
    )
)

product_contrib["delta_product_total_expected_loss_m"] = (
    product_contrib["delta_product_total_expected_loss"] / 1_000_000.0
)

scenario_totals = (
    product_contrib.groupby(
        ["row_order", "family", "family_label", "scenario_name", "display_label"],
        as_index=False,
    )
    .agg(
        delta_scenario_total_expected_loss=("delta_product_total_expected_loss", "sum")
    )
)

scenario_totals["delta_scenario_total_expected_loss_m"] = (
    scenario_totals["delta_scenario_total_expected_loss"] / 1_000_000.0
)

# Ensure product contribution matrix contains every selected product for every selected scenario.
scenario_rows = scenario_totals[
    ["row_order", "family", "family_label", "scenario_name", "display_label"]
].drop_duplicates()

complete_index = pd.MultiIndex.from_product(
    [
        scenario_rows["row_order"].tolist(),
        PRODUCT_ORDER,
    ],
    names=["row_order", "product_type"],
).to_frame(index=False)

complete_index = complete_index.merge(
    scenario_rows,
    on="row_order",
    how="left",
)

plot_product = complete_index.merge(
    product_contrib[
        [
            "row_order",
            "product_type",
            "delta_product_total_expected_loss_m",
        ]
    ],
    on=["row_order", "product_type"],
    how="left",
)

plot_product["delta_product_total_expected_loss_m"] = (
    plot_product["delta_product_total_expected_loss_m"].fillna(0.0)
)

plot_product = plot_product.sort_values(["row_order"]).reset_index(drop=True)

# Top product × score drivers by absolute movement.
top_segments = (
    delta_df.assign(
        abs_delta_segment_total_expected_loss=lambda x: x[
            "delta_segment_total_expected_loss"
        ].abs()
    )
    .sort_values("abs_delta_segment_total_expected_loss", ascending=False)
    .head(TOP_DRIVER_COUNT)
    .copy()
)

# Group ranges for family labels.
group_ranges = []
for family, group in scenario_totals.groupby("family", sort=False):
    start = int(group["row_order"].min())
    end = int(group["row_order"].max())

    family_label = group["family_label"].iloc[0]

    group_ranges.append(
        {
            "family": family,
            "family_label": family_label,
            "start": start,
            "end": end,
            "center": (start + end) / 2.0,
        }
    )


# =============================================================================
# 7. BUILD CHART
# =============================================================================

fig = plt.figure(figsize=(16.0, 8.8), dpi=160)
fig.patch.set_facecolor(FIG_FACE)

# Manual layout:
#   ax = diverging stacked horizontal contribution chart
#   right-side figure text = legend + interpretation + top product × score drivers
#
# No bbox_inches="tight" is used during export so title / footer centering
# remains visually stable.
ax = fig.add_axes([0.155, 0.170, 0.595, 0.655])
style_dark_axis(ax)

y_positions = list(range(len(scenario_totals)))

# Positive and negative stacks need separate cumulative bases.
positive_base = pd.Series([0.0] * len(scenario_totals), index=scenario_totals["row_order"])
negative_base = pd.Series([0.0] * len(scenario_totals), index=scenario_totals["row_order"])

bar_handles = {}

for product_type in PRODUCT_ORDER:
    product_rows = plot_product.loc[plot_product["product_type"] == product_type].copy()
    product_rows = product_rows.sort_values("row_order")

    color = PRODUCT_COLORS.get(product_type, "#999999")
    label = PRODUCT_LEGEND_LABELS.get(product_type, prettify_product(product_type))

    for _, row in product_rows.iterrows():
        y = int(row["row_order"])
        value = float(row["delta_product_total_expected_loss_m"])

        if abs(value) < 1e-9:
            continue

        if value >= 0:
            left = positive_base.loc[y]
            positive_base.loc[y] += value
        else:
            left = negative_base.loc[y]
            negative_base.loc[y] += value

        bar = ax.barh(
            y,
            value,
            left=left,
            height=0.62,
            color=color,
            alpha=BAR_ALPHA,
            label=label if product_type not in bar_handles else None,
        )

        if product_type not in bar_handles:
            bar_handles[product_type] = bar[0]

        # Keep inside labels compact: the legend identifies product colors.
        if abs(value) >= SEGMENT_LABEL_THRESHOLD_M:
            ax.text(
                left + value / 2.0,
                y,
                format_m_compact(value),
                ha="center",
                va="center",
                fontsize=7.5,
                color="black",
                fontweight="bold",
            )

# Scenario total labels at left/right bar ends.
scenario_totals = scenario_totals.sort_values("row_order").reset_index(drop=True)

x_positive_max = max(positive_base.max(), 0.0)
x_negative_min = min(negative_base.min(), 0.0)

x_span = max(abs(x_positive_max), abs(x_negative_min), 1.0)

for _, row in scenario_totals.iterrows():
    y = int(row["row_order"])
    total_m = float(row["delta_scenario_total_expected_loss_m"])

    if total_m >= 0:
        x_text = positive_base.loc[y] + x_span * 0.025
        ha = "left"
    else:
        x_text = negative_base.loc[y] - x_span * 0.025
        ha = "right"

    ax.text(
        x_text,
        y,
        format_m(total_m),
        ha=ha,
        va="center",
        fontsize=8.7,
        color=TEXT_COLOR,
        fontweight="bold",
    )

# Axes and labels.
ax.axvline(
    0,
    color=ZERO_LINE_COLOR,
    linewidth=1.1,
    alpha=0.85,
)

ax.set_yticks(y_positions)
ax.set_yticklabels(
    scenario_totals["display_label"].tolist(),
    color=TEXT_COLOR,
    fontsize=9.0,
)

ax.invert_yaxis()

# Family group separators and labels.
for group in group_ranges:
    if group["start"] > 0:
        ax.axhline(
            group["start"] - 0.5,
            color=TEXT_COLOR,
            linewidth=1.0,
            alpha=0.55,
        )

    # Family labels are placed between the y-axis label and the scenario row labels.
    ax.text(
        -0.145,
        group["center"],
        group["family_label"],
        transform=ax.get_yaxis_transform(),
        ha="center",
        va="center",
        fontsize=8.5,
        color=TEXT_COLOR,
        fontweight="bold",
        clip_on=False,
    )

ax.set_xlabel(
    "Δ Total Expected Loss ($M)",
    color=TEXT_COLOR,
    fontsize=10.5,
    labelpad=10,
)

ax.set_ylabel(
    "Scenario Family / Selected Scenario Lever",
    color=TEXT_COLOR,
    fontsize=10.2,
    labelpad=72,
)

# Symmetric x-axis limits for mixed-sign comparison.
max_abs = max(abs(x_positive_max), abs(x_negative_min), 1.0)
ax.set_xlim(-max_abs * 1.20, max_abs * 1.20)

ax.xaxis.set_major_formatter(
    mtick.FuncFormatter(lambda value, _: f"${value:,.0f}M")
)

# Direction note inside chart.
ax.text(
    0.50,
    1.015,
    "Left of zero = lower EL vs reference     |     Right of zero = higher EL vs reference",
    transform=ax.transAxes,
    ha="center",
    va="bottom",
    fontsize=8.4,
    color=TEXT_COLOR,
    bbox={
        "boxstyle": "round,pad=0.30",
        "facecolor": CALLOUT_BOX_COLOR,
        "edgecolor": CALLOUT_BOX_COLOR,
        "alpha": 0.88,
    },
)

# Product legend outside chart.
handles = [bar_handles[p] for p in PRODUCT_ORDER if p in bar_handles]
labels = [PRODUCT_LEGEND_LABELS[p] for p in PRODUCT_ORDER if p in bar_handles]

legend = fig.legend(
    handles,
    labels,
    loc="upper left",
    bbox_to_anchor=(0.785, 0.825),
    fontsize=7.8,
    frameon=True,
    title="Product contribution",
    title_fontsize=8.4,
    ncol=1,
    borderpad=0.55,
    labelspacing=0.35,
    handlelength=1.2,
)

legend.get_frame().set_facecolor(AX_FACE)
legend.get_frame().set_edgecolor(TEXT_COLOR)
for text in legend.get_texts():
    text.set_color(TEXT_COLOR)
legend.get_title().set_color(TEXT_COLOR)

# Titles.
fig.suptitle(
    "Scenario Expected-Loss Impact Decomposition",
    fontsize=20,
    fontweight="bold",
    color=TEXT_COLOR,
    x=CONTENT_CENTER_X,
    y=0.970,
)

fig.text(
    CONTENT_CENTER_X,
    0.925,
    "Product Contribution to Portfolio EL Movement",
    ha="center",
    va="center",
    fontsize=12.0,
    color=TEXT_COLOR,
)

fig.text(
    CONTENT_CENTER_X,
    0.888,
    "Selected scenario levers vs family reference | stacked by product contribution",
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

# Right-side interpretation box.
readout_text = (
    "How to read:\n\n"
    "Each row compares a\n"
    "scenario to its own\n"
    "family reference.\n\n"
    "Bars show Δ Total EL.\n\n"
    "Left = lower EL\n"
    "Right = higher EL\n\n"
    "Stack color = product\n"
    "contribution.\n\n"
    "Inside labels show only\n"
    "material dollar moves."
)

fig.text(
    0.785,
    0.555,
    readout_text,
    fontsize=8.25,
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

# Top product × score movements.
top_driver_lines = []
for idx, (_, row) in enumerate(top_segments.iterrows(), start=1):
    scenario_display = scenario_totals.loc[
        scenario_totals["scenario_name"] == row["scenario_name"],
        "display_label",
    ]

    if not scenario_display.empty:
        scenario_label = scenario_display.iloc[0].replace("\n", " ")
    else:
        scenario_label = prettify_scenario_name(row["scenario_name"])

    product_label = prettify_product(row["product_type"])
    score_label = prettify_score(row["score_band"])
    delta_m = row["delta_segment_total_expected_loss"] / 1_000_000.0

    top_driver_lines.append(
        f"{idx}. {scenario_label}\n"
        f"   {product_label} × {score_label}: {format_m(delta_m)}"
    )

top_driver_text = (
    "Largest product × score\n"
    "movements:\n\n"
    + "\n\n".join(top_driver_lines)
)

fig.text(
    0.785,
    0.205,
    top_driver_text,
    fontsize=7.65,
    va="center",
    ha="left",
    color=TEXT_COLOR,
    bbox={
        "boxstyle": "round,pad=0.50",
        "facecolor": AX_FACE,
        "edgecolor": TEXT_COLOR,
        "alpha": 0.82,
    },
)

# Footer caption.
caption = (
    "Scenario Expected-Loss Impact Decomposition compares selected scenario levers to their family "
    "reference slices. Bars show total Expected Loss movement, stacked by product contribution, while "
    "the callout identifies the largest product × score drivers. This shows that Module 1 can explain "
    "where scenario risk movement concentrates rather than only reporting aggregate portfolio deltas."
)

fig.text(
    CONTENT_CENTER_X,
    0.045,
    "\n".join(textwrap.wrap(caption, width=165)),
    ha="center",
    va="center",
    fontsize=9.0,
    color=TEXT_COLOR,
)


# =============================================================================
# 8. SAVE OUTPUTS
# =============================================================================

fig.savefig(
    OUTPUT_PNG,
    facecolor=fig.get_facecolor(),
)

fig.savefig(
    OUTPUT_SVG,
    facecolor=fig.get_facecolor(),
)

plt.close(fig)


# =============================================================================
# 9. CONSOLE QA / TRACE OUTPUT
# =============================================================================

print(f"Input CSV: {input_csv}")
print(f"Saved PNG: {OUTPUT_PNG}")
print(f"Saved SVG: {OUTPUT_SVG}")

print("\nScenario totals used:")
for _, row in scenario_totals.iterrows():
    print(
        f"{row['family']:<18} | "
        f"{row['scenario_name']:<38} | "
        f"Δ Total EL: {format_m(row['delta_scenario_total_expected_loss_m'])}"
    )

print("\nProduct contribution by scenario:")
for _, row in product_contrib.sort_values(["row_order", "product_type"]).iterrows():
    print(
        f"{row['scenario_name']:<38} | "
        f"{row['product_type']:<26} | "
        f"Δ Product Total EL: {format_m(row['delta_product_total_expected_loss_m'])}"
    )

print("\nTop product × score movements:")
for idx, (_, row) in enumerate(top_segments.iterrows(), start=1):
    print(
        f"{idx}. "
        f"{row['scenario_name']:<38} | "
        f"{row['product_type']:<26} | "
        f"{row['score_band']:<14} | "
        f"Scenario apps: {format_count(row['scenario_applications'])} | "
        f"Reference apps: {format_count(row['reference_applications'])} | "
        f"Δ Segment Total EL: {format_m(row['delta_segment_total_expected_loss'] / 1_000_000.0)}"
    )
```
<!-- END_MESSAGE C040-M02539 -->


---

<a id="c040-m02540"></a>

### C040-M02540

**Andrew** · 2026-05-27T14:08:27.512000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02540 -->
how well do these three panels go together for our overall module 1 read me? and how well do they align with the module 2 read me collage?
<!-- END_MESSAGE C040-M02540 -->


**Attachments in export:** `module1_scenario_expected_loss_decomposition.png`, `module1_scenario_level_matrix.png`, `module1_product_score_risk_surface_updated_title.png`, `module2_executive_dashboard_preview(2).png`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c040-m02544"></a>

### C040-M02544

**ChatGPT** · 2026-05-27T14:15:27.420620-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02544 -->
The three Module 1 panels go together **very well**. They now tell a complete upstream story rather than a narrow rate-shock story:

```text
Panel 1:
    Baseline synthetic risk foundation

Panel 2:
    Full governed scenario-lever framework

Panel 3:
    Scenario Expected Loss attribution by product and product × score
```

That is the right Module 1 README narrative. It aligns with Module 1’s documented purpose as a governed, portfolio-scale synthetic application and risk modeling engine where risk is shaped by borrower profile, product structure, affordability, and macro environment, not by score alone. fileciteturn54file88 It also fits the validation framing that Module 1 is deterministic, scenario-capable, product/score-aware, and supports controlled comparison without population noise. fileciteturn54file89

## How well the three Module 1 panels work together

**Panel 1 is the anchor.** The baseline product × score heatmap is the clearest “foundation” visual. It shows that the synthetic population has realistic structure before any scenario movement is introduced. It is simple, legible, and immediately communicates that Module 1 is not a random dataset.

**Panel 2 is the breadth proof.** The Scenario Lever Matrix fixes the earlier concern that rate up/down scenarios were too simple. It shows the reader that Module 1 supports multiple governed levers: rate, credit box, exposure intensity, LGD severity, and portfolio mix. This is probably the most important panel for proving the sophistication of Module 1 as a scenario framework.

**Panel 3 is the attribution proof.** The Expected-Loss decomposition is a strong final panel because it answers, “Where did the movement come from?” It takes Panel 2’s scenario deltas and makes them explainable by product contribution, with the right-side callout adding product × score depth. That is exactly the right level of detail for a README hero: technical enough to be credible, but still visually interpretable.

Together, the Module 1 panels say:

```text
Module 1 creates a credible synthetic risk surface.
Module 1 can stress the portfolio through multiple governed scenario levers.
Module 1 can explain where scenario Expected Loss movement concentrates.
```

That is a strong README-level story.

## How well they align with the Module 2 collage

They align **very strongly** in concept and reasonably well in visual style.

Conceptually, the sequence is excellent:

```text
Module 1:
    builds the synthetic application and risk foundation

Module 2:
    consumes that foundation and applies governed strategy/outcome simulation
```

That is exactly how the system is documented: Module 2 consumes completed Module 1 outputs, preserves Module 1 scenario lineage, and applies a downstream strategy layer rather than rewriting Module 1 or recalculating the synthetic estimated-PD proxy. fileciteturn55file2

The Module 1 collage will therefore complement the Module 2 collage rather than duplicate it.

```text
Module 1 collage:
    population realism
    scenario breadth
    risk attribution

Module 2 collage:
    strategy frontier
    baseline-relative strategy tradeoffs
    counteroffer governance mechanics
```

That is the full system story.

## Visual alignment

The dark theme, white titles, blue explanatory callouts, and compact footer captions are consistent with the Module 2 dashboard. The two collages will feel like they belong to the same portfolio.

The main difference is density. Module 1 is more matrix-heavy and technical. Module 2 feels more like an executive control tower because it has scatter, bars, operational summary, and stacked outcome charts. That difference is acceptable because the modules do different jobs:

```text
Module 1 is the evidence foundation.
Module 2 is the strategy outcome layer.
```

Still, when building the final Module 1 collage, I would be careful not to shrink these panels too aggressively. Panel 2 and Panel 3 need room.

## Recommended Module 1 collage layout

I would not force all three into equal thirds. Panel 2 and Panel 3 are information-dense. My preferred layout:

```text
MODULE 1: SYNTHETIC APPLICATION & RISK MODELING ENGINE

KPI strip:
19 governed scenarios | 50,000 applications each | 950,000 archived scenario rows | BASE_POPULATION_V1

Top row:
    Left:  Baseline Product × Score Risk Surface
    Right: Scenario Lever Matrix

Bottom row:
    Full width: Scenario Expected-Loss Impact Decomposition
```

Panel 3 deserves the full-width bottom row because its diverging bars and right-side product × score callout are easiest to read with horizontal space.

## Minor consistency polish before final collage

I would make only small visual/text consistency edits:

```text
1. Use “×” consistently instead of “x”
   Baseline Product × Score Risk Surface

2. Standardize “Expected Loss” vs “EL”
   Titles can use “Expected Loss”
   Axes / dense captions can use “EL”

3. Use the same parent-title style as Module 2
   MODULE 1: SYNTHETIC APPLICATION & RISK MODELING ENGINE

4. Add the 10.01 campaign KPI strip
   This will make the collage feel campaign-backed rather than chart-only.

5. Keep the blue callout language consistent:
   “How to read”
   “Left of zero”
   “Family reference”
```

I would not redesign the charts themselves. They are strong.

## Final assessment

```text
Module 1 panel set: approved
Narrative fit: strong
Technical credibility: strong
Visual consistency with Module 2: strong
README value-add: high
```

The two collages together will tell a very compelling portfolio story:

```text
Module 1 proves the synthetic risk foundation and scenario engine.
Module 2 proves the governed strategy decisioning layer built on top of it.
```

That is exactly the kind of visual progression a reviewer should see in the README.
<!-- END_MESSAGE C040-M02544 -->


---

<a id="c040-m02546"></a>

### C040-M02546

**Andrew** · 2026-05-27T14:31:15.653000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02546 -->
should I add a KPI strip subtitle to our module 2 collage?
<!-- END_MESSAGE C040-M02546 -->


---

<a id="c040-m02549"></a>

### C040-M02549

**ChatGPT** · 2026-05-27T14:35:17.231953-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02549 -->
Yes — I would add a **small KPI strip subtitle** to the Module 2 collage.

It will help Module 2 visually match the Module 1 collage, and it reinforces that the dashboard is backed by a completed governed campaign, not just a few illustrative chart examples. Module 2’s formal campaign framework is explicitly organized around 7 scenario families, 39 standard campaign runs, and 20 comparison groups, so a scope strip is justified. fileciteturn56file4

My recommended strip:

```text
39 governed strategy runs × 50K applicants | 1.95M archived strategy decisions | 20 matched comparison groups | 7 scenario families
```

That is the strongest version because it communicates scale, comparison discipline, and campaign breadth in one line.

I would place it directly under the main title:

```text
MODULE 2: CREDIT POLICY STRATEGY & DECISION OUTCOME SIMULATION ENGINE

39 governed strategy runs × 50K applicants | 1.95M archived strategy decisions | 20 matched comparison groups | 7 scenario families
```

Use a small font, probably white or light gray, not a large blue callout. The collage already has several blue interpretation boxes, so the KPI strip should feel like a subtitle, not another chart element.

One caveat: only use **1.95M archived strategy decisions** if your final archive inventory confirms all 39 active campaign runs archived 50,000 rows each. Section 17.1 is specifically designed to validate active campaign registry runs against expected Module 1 source row counts and archive row counts, so that is the right evidence source for the final number. fileciteturn56file21

A slightly safer version would be:

```text
39 governed strategy runs | 20 matched comparison groups | 7 scenario families | archive-backed frontier evidence
```

But I prefer the fuller version if the archive count is confirmed.

Final recommendation:

```text
Add it.
Keep it one line.
Keep it visually subordinate to the title.
Use it as campaign-scope evidence, not another explanatory box.
```

This will make the Module 2 collage feel more complete and better aligned with the Module 1 campaign-scope framing.
<!-- END_MESSAGE C040-M02549 -->


---

<a id="c040-m02550"></a>

### C040-M02550

**Andrew** · 2026-05-27T18:50:34.560000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02550 -->
evaluate our module 1 and 2 read me final collage's.
<!-- END_MESSAGE C040-M02550 -->


**Attachments in export:** `module1_executive_dashboard_preview.png`, `module2_executive_dashboard_preview(3).png`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c040-m02553"></a>

### C040-M02553

**ChatGPT** · 2026-05-27T18:56:26.642340-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02553 -->
These are **strong final README collages**. I would use both.

They work well as a paired system story:

```text
Module 1:
    Builds the governed synthetic application and risk foundation.

Module 2:
    Applies governed strategy controls and decision-outcome simulation on top of that foundation.
```

That is exactly the right portfolio narrative. Module 1 is documented as a governed, portfolio-scale synthetic application and risk modeling engine for pre-production strategy testing without PII, with risk shaped by borrower profile, product structure, affordability, and macro environment. fileciteturn56file88 Module 2 is documented as the downstream governed strategy simulation layer that consumes Module 1 outputs, applies strategy/product-policy controls, assigns simulated outcomes, persists archive outputs, supports matched comparison, and produces strategy frontier evidence. fileciteturn56file4

## Module 1 collage assessment

**Approved.** This is a very effective Module 1 executive dashboard.

The three-panel sequence is now much stronger than the earlier rate-heavy concept:

```text
1. Baseline Product × Score Risk Surface
   Proves the synthetic risk foundation is product-aware and score-aware.

2. Scenario Lever Matrix
   Proves Module 1 has multiple governed scenario levers, not just rate shocks.

3. Scenario Expected-Loss Impact Decomposition
   Proves scenario movement is attributable by product and product × score driver.
```

That arc is excellent. It shows baseline realism, scenario breadth, and attribution. It also aligns well with the Module 1 validation findings that the engine is deterministic, scenario-capable, product/score-aware, and supports matched comparison without population noise. fileciteturn56file89

The KPI strip is a strong addition:

```text
19 governed scenarios | 50,000 applications each | 950,000 archived scenario rows | BASE_POPULATION_V1
```

It makes the visual feel campaign-backed rather than merely illustrative.

The only small polish item I would check is typographic consistency: use `×` instead of `x` everywhere in “Product × Score,” if any title or label still uses a plain `x`.

## Module 2 collage assessment

**Approved, with two small proofread/unit checks.**

The Module 2 collage remains highly compelling. It tells a different and complementary story from Module 1:

```text
1. Strategy Frontier
   Where selected strategies sit on access versus approved-risk density.

2. Baseline-Relative Tradeoffs
   How challenger strategies move access, approved dollars, and approved Expected Loss.

3. Counteroffer Governance
   How selective versus aggressive Option C counteroffer treatment behaves operationally.
```

This fits the Section 15 purpose especially well: Section 15 is explicitly the archive-wide strategy control tower for summarizing strategy frontier tradeoffs across offer exposure, approved amount, approved Expected Loss, affordability, counteroffer behavior, review burden, decline rate, products, score bands, and reason-code movement. fileciteturn56file5

The KPI strip also works:

```text
39 governed strategy runs × 50K applicants | 1.95M archived strategy decisions | 20 matched comparison groups | 7 scenario families
```

That matches the formal Module 2 campaign shape, which is documented as 39 standard campaign runs and 20 comparison groups across the formal scenario framework. fileciteturn56file4 Section 17.1 is the right evidence layer for confirming archive inventory completeness against active registry rows and Module 1 source row counts. fileciteturn56file21

### Two small Module 2 checks before final

First, I would standardize the KPI strip style to match Module 1:

```text
39 governed strategy runs | 50,000 applicants each | 1.95M archived strategy decisions | 20 matched comparison groups | 7 scenario families
```

That reads slightly more polished than `39 governed strategy runs x 50K applicants`.

Second, double-check the top-right chart unit note and dollar labels. The top-right chart should make it unambiguous whether the orange/green bar lengths are percent-of-baseline while labels show dollar movement, or whether the bars themselves are dollar movement. The safest wording is:

```text
access = percentage points; $ and EL = % of baseline; labels show dollar movement
```

or, if the bars are direct dollar movement:

```text
access = percentage points; $ and EL = dollar movement
```

Also verify that the approved-dollar labels visually read as values like `-$149M` and `-$111M`, not `-$1.49M` or `-$1.11M` after scaling/rendering.

## How well the two collages align

They align **very well**.

The shared visual system works:

```text
dark background
white section titles
blue KPI strips / explanatory callouts
executive dashboard framing
dense but structured evidence panels
```

The conceptual alignment is even stronger:

```text
Module 1:
    synthetic population realism
    governed scenario framework
    Expected Loss attribution

Module 2:
    strategy frontier
    baseline-relative challenger movement
    counteroffer governance
```

That creates a clean two-module README sequence:

```text
Module 1 proves the upstream risk foundation.
Module 2 proves the downstream strategy decisioning layer.
```

This matters because Module 2 explicitly preserves Module 1 scenario lineage and treats Module 1 as the upstream synthetic application/risk foundation rather than recalculating the synthetic estimated-PD proxy. fileciteturn56file4

## Recommended README placement

I would use them in this order:

```markdown
## Executive System Overview

Brief paragraph:
The Enterprise Credit Decisioning Strategy Simulator is a two-module governed simulation system.
Module 1 creates the synthetic risk foundation; Module 2 applies strategy controls and simulates decision outcomes.

## Module 1 — Synthetic Application & Risk Modeling Engine

[Module 1 collage]

Short interpretation paragraph.

## Module 2 — Credit Policy Strategy & Decision Outcome Simulation Engine

[Module 2 collage]

Short interpretation paragraph.
```

Do **not** put the two collages side by side in the README. Stack them vertically. They are information-dense and need full-width presentation.

I would also add full-size links beneath each image:

```markdown
[Open Module 1 dashboard full size](assets/module1_executive_dashboard.png)
[Open Module 2 dashboard full size](assets/module2_executive_dashboard.png)
```

## Final verdict

```text
Module 1 collage: approved
Module 2 collage: approved
Pairing / portfolio narrative: very strong
README readiness: high
Remaining work: minor typography and unit-proofing only
```

Together, these two images materially elevate the README. They show that this is not a generic SQL project or a charting exercise; it is a governed, multi-stage credit decisioning simulation system with synthetic risk generation, scenario comparison, strategy simulation, archive-backed frontier analysis, and counteroffer governance.
<!-- END_MESSAGE C040-M02553 -->


---

<a id="c040-m02554"></a>

### C040-M02554

**Andrew** · 2026-05-27T19:08:04.449000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02554 -->
regarding the baseline relative tradeoffs legend, here is the original and the current legends.  there is a footnote that says (access = percentage points, $ and EL = $ at baseline, pps = basis points annualized).  please advise
<!-- END_MESSAGE C040-M02554 -->


**Attachments in export:** `image(90).png`, `image(91).png`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c040-m02557"></a>

### C040-M02557

**ChatGPT** · 2026-05-27T19:12:44.793238-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02557 -->
I would **not** keep the current footnote as written. It creates more ambiguity than it resolves.

The chart is mixing three different kinds of movement on one horizontal axis:

```text
Access:
    percentage-point movement

Approved $:
    percent change vs matched baseline, with dollar labels

Approved EL:
    percent change vs matched baseline, with dollar labels
```

That is a valid design, but only if the legend and footnote make the encoding explicit. Section 15 is meant to summarize archive-backed strategy tradeoffs across simulated offer exposure, approved amount, and approved Expected Loss, so those three measures are the right ones to show here. fileciteturn56file5

## Recommended final legend

Use this:

```text
Access Δ (pp)
Approved Amount Δ (% baseline; label=$M)
Approved EL Δ (% baseline; label=$M)
```

I would use **“Approved Amount”** instead of **“Approved $”** because it is clearer and more consistent with the Module 2 language around approved exposure / approved amount and approved Expected Loss. Module 2 explicitly treats access, approved exposure, and approved Expected Loss as governed strategy tradeoffs, not generic dollar metrics. fileciteturn56file4

## Recommended final footnote

Use this:

```text
Bar length: access = percentage-point change; approved amount and approved EL = % change vs matched baseline. Labels show absolute dollar movement in $M.
```

Shorter version for the collage:

```text
Bars: access in pp; approved amount and EL as % of baseline. Labels show $M movement.
```

## What to remove

Remove this wording:

```text
$ and EL = $ at baseline, pps = basis points annualized
```

Reasons:

```text
1. “$ and EL = $ at baseline” is unclear.
   It sounds like the bars are dollar-denominated, but they are not if the x-axis is shared.

2. “pps = basis points annualized” is incorrect/confusing here.
   “pp” means percentage points.
   “bps” means basis points.
   Nothing in this chart appears to be annualized basis points.

3. The chart is not showing pricing/APR movement.
   It is showing strategy movement in access, approved amount, and approved EL.
```

## Final answer

Use the current legend structure, but tighten it:

```text
Access Δ (pp)
Approved Amount Δ (% baseline; label=$M)
Approved EL Δ (% baseline; label=$M)
```

And use this footnote:

```text
Bars: access in percentage points; approved amount and approved EL as % change vs matched baseline. Labels show absolute $M movement.
```

That is the clearest and most technically defensible version.
<!-- END_MESSAGE C040-M02557 -->


---

<a id="c040-m02558"></a>

### C040-M02558

**Andrew** · 2026-05-27T20:25:38.040000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02558 -->
how is this updated module 2 collage?
<!-- END_MESSAGE C040-M02558 -->


**Attachments in export:** `module2_executive_dashboard_preview(4).png`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c040-m02561"></a>

### C040-M02561

**ChatGPT** · 2026-05-27T20:31:08.523317-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02561 -->
This updated Module 2 collage is **very close to final**. The KPI strip and revised top-right legend materially improve it.

The collage now clearly communicates that Module 2 is a governed downstream strategy simulation layer: it consumes Module 1 outputs, applies strategy/product-policy controls, assigns simulated outcomes, calculates approved exposure economics, supports archive-backed comparison, summarizes strategy frontier tradeoffs, and supports final campaign acceptance. That is exactly the architecture the Module 2 artifact is designed to demonstrate. fileciteturn56file4

## What improved

The **KPI strip is excellent**:

```text
39 governed strategy runs | 50,000 applicants each | 1.95M archived strategy decisions | 20 matched comparison groups | 7 scenario families
```

It gives the dashboard campaign scale and makes the visual feel evidence-backed rather than illustrative. That aligns with the formal Module 2 campaign framework: 39 runs, 20 comparison groups, and 7 scenario families. fileciteturn56file4

The **top-right legend is now much better**:

```text
Access Δ (pp)
Approved Amount Δ (% baseline; label=$M)
Approved EL Δ (% baseline; label=$M)
```

That is the right conceptual framing because the shared x-axis cannot simultaneously be percentage points and dollars. The legend now explains that access uses percentage-point movement, while approved amount and approved EL bars use percent-of-baseline movement with dollar labels.

The **footnote is directionally correct** and much clearer than the prior version. It now explains the encoding instead of introducing confusing “bps annualized” language.

## One wording fix I strongly recommend

Change the footnote from:

```text
Labels show absolute dollar movement in $M.
```

to:

```text
Labels show signed dollar movement in $M.
```

Reason: “absolute” can imply the sign is removed, but your labels are signed. For example, `-$188M` and `+$238M` are **signed movements**, not absolute values.

Best final footnote:

```text
Bar length: access = percentage-point change; approved amount and approved EL = % change vs matched baseline. Labels show signed dollar movement in $M.
```

That is technically clean.

## One numeric-label QA check

Before locking this, double-check the approved amount labels in the top-right chart. They should be approximately:

```text
M2-02: -$149M
M2-03: +$238M
M2-04: -$258M
M2-05: -$363M
M2-06: -$111M
M2-37: -$188M
```

In the screenshot, a few labels are small enough that they may visually read like `-$1.49M`, `-$1.11M`, or `-$1.88M`. If that is just image scaling, no issue. If the actual rendered label is using decimal-millions incorrectly, fix that before final.

Approved EL labels should remain around:

```text
M2-02: -$7.2M
M2-03: +$8.7M
M2-04: -$3.5M
M2-05: -$8.0M
M2-06: -$4.3M
M2-37: -$4.2M
```

Those look directionally right.

## Overall assessment

```text
Module 2 collage status: approved with minor proofread/numeric-label QA

Strengths:
    clear campaign scope
    strong strategy frontier visual
    improved baseline-relative tradeoff explanation
    strong Option C governance section
    consistent style with Module 1 collage

Final tweaks:
    replace “absolute dollar movement” with “signed dollar movement”
    verify top-right approved amount labels are in $M correctly
```

Once those two checks are complete, I would consider the Module 2 README collage final.
<!-- END_MESSAGE C040-M02561 -->


---

<a id="c040-m02562"></a>

### C040-M02562

**Andrew** · 2026-05-27T22:05:00.003000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02562 -->
module 2 dashboard panel corrected.  please review again.
<!-- END_MESSAGE C040-M02562 -->


**Attachments in export:** `module2_executive_dashboard_preview(5).png`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c040-m02565"></a>

### C040-M02565

**ChatGPT** · 2026-05-27T22:08:36.840588-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02565 -->
This updated Module 2 dashboard is **approved / final-ready**, with one small visual QA note.

The legend and footnote correction solved the main ambiguity in the baseline-relative tradeoff chart. It now clearly explains that access is shown in percentage-point movement, while approved amount and approved Expected Loss use percent-of-baseline bar length with signed dollar labels. That is the right framing for an executive README chart because Section 15 is meant to summarize archive-backed strategy frontier tradeoffs across offer exposure, approved amount, approved Expected Loss, counteroffer behavior, review burden, decline rate, and strategy movement. fileciteturn56file5

## What is now working especially well

The KPI strip is strong and visually aligned with the Module 1 dashboard:

```text
39 governed strategy runs | 50,000 applicants each | 1.95M archived strategy decisions | 20 matched comparison groups | 7 scenario families
```

That makes the collage feel campaign-backed. It also aligns with the formal Module 2 campaign framework, which is organized around 39 standard campaign runs, 20 comparison groups, and 7 scenario families. fileciteturn56file4

The top-right legend is now clear:

```text
Access Δ (pp)
Approved Amount Δ (% baseline; label=$M)
Approved EL Δ (% baseline; label=$M)
```

The footnote is also now technically clean:

```text
Bar length: access = percentage-point change; approved amount and approved EL = % change vs matched baseline. Labels show signed dollar movement in $M.
```

That is the wording I would keep.

## One small visual QA note

In the bottom-middle chart, the first orange label appears close to the right edge and may be slightly clipped:

```text
+6.9pp review
```

It looks like it may render as `+6.9pp revi...` depending on output size. If the full-size PNG shows the complete label, no action is needed. If it is actually clipped, slightly expand that subplot’s x-limit or move the orange labels a touch inward.

Everything else looks final.

## Final verdict

```text
Module 2 dashboard: APPROVED
Legend / unit issue: resolved
KPI strip: strong
Narrative clarity: strong
Visual alignment with Module 1: strong
Only remaining check: ensure bottom-middle “+6.9pp review” label is not clipped
```

This is a polished README-ready Module 2 executive dashboard. It clearly shows strategy frontier position, baseline-relative tradeoffs, and governed counteroffer mechanics—the right downstream companion to the Module 1 synthetic risk foundation dashboard.
<!-- END_MESSAGE C040-M02565 -->


---

<a id="c040-m02566"></a>

### C040-M02566

**Andrew** · 2026-05-27T22:27:13.730000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02566 -->
updated that visual QA note:
<!-- END_MESSAGE C040-M02566 -->


**Attachments in export:** `module2_executive_dashboard_preview(6).png`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c040-m02568"></a>

### C040-M02568

**ChatGPT** · 2026-05-27T22:31:06.582133-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02568 -->
This resolves the last visual QA issue. The bottom-middle labels now sit cleanly inside the bars, and the `+6.9pp review`, `+6.2pp review`, and `+2.9pp review` labels are all readable without clipping.

**Final assessment: approved / README-ready.**

What is working now:

- The KPI strip is clean and aligns well with the Module 1 dashboard style.
- The top-left frontier chart remains the strongest executive anchor.
- The top-right baseline-relative tradeoff legend and footnote are now technically defensible.
- The bottom counteroffer governance section reads clearly:
  - selective feasibility reduces counteroffer / offer exposure and shifts cases toward review;
  - aggressive expansion creates governed override volume without final aggressive override declines.
- The bottom-middle visual is now fixed and no longer looks cramped at the right edge.

One optional export note: because the footnote under the top-right chart is intentionally small, I would include a full-size image link in the README below the embedded dashboard. But visually and analytically, the dashboard itself is final.

This is a polished Module 2 executive visual. It accurately supports the documented Module 2 story: governed strategy simulation, archive-backed frontier analysis, matched comparison, counteroffer feasibility, Option C split governance, and post-campaign evidence readiness. fileciteturn56file4 Section 15 is explicitly designed as the archive-wide strategy control tower for this kind of README / executive interpretation view. fileciteturn56file5
<!-- END_MESSAGE C040-M02568 -->


---

<a id="c040-m02570"></a>

### C040-M02570

**Andrew** · 2026-05-27T22:38:08.977000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02570 -->
I increased the size of that footnote:
<!-- END_MESSAGE C040-M02570 -->


**Attachments in export:** `module2_executive_dashboard_preview(7).png`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c040-m02573"></a>

### C040-M02573

**ChatGPT** · 2026-05-27T22:41:47.454472-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02573 -->
This looks **final-ready**.

The enlarged footnote is now readable without overpowering the chart. It also resolves the earlier unit ambiguity cleanly:

```text
Bar length:
    access = percentage-point change
    approved amount and approved EL = % change vs matched baseline

Labels:
    signed dollar movement in $M
```

That is exactly the distinction the chart needs.

One small aesthetic note: the footnote is now close to the horizontal divider, but it is not cramped enough to require another change. I would **keep it as-is** unless you notice readability loss when GitHub scales the image down.

Final verdict:

```text
Module 2 dashboard: approved / final
Footnote issue: resolved
Legend issue: resolved
Bottom-middle label clipping: resolved
README readiness: yes
```

This is a polished executive dashboard and now matches the Module 1 collage well.
<!-- END_MESSAGE C040-M02573 -->


---

<a id="c040-m02574"></a>

### C040-M02574

**Andrew** · 2026-05-27T23:13:43.714000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02574 -->
i'd like sql code to pull random, sufficient samples (csv's must be less than 25mb) from strategy_decisions_archive and synthetic_applications_scenario_archive to upload to github.
<!-- END_MESSAGE C040-M02574 -->


---

<a id="c040-m02583"></a>

### C040-M02583

**ChatGPT** · 2026-05-27T23:24:47.392548-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02583 -->
Yes. For GitHub, I would create **small, stratified, deterministic-random samples** rather than pure `ORDER BY random()` samples.

That gives you:
- broad scenario/product/score/outcome coverage;
- reproducible samples;
- better odds of including rare decision paths;
- CSVs that should stay under 25MB.

This uses the archive tables because Module 1’s scenario archive supports stable scenario comparison on the same synthetic population, and Module 2’s strategy archive preserves completed strategy outputs for matched comparison and frontier analysis. fileciteturn56file89 fileciteturn56file35

```sql
/***************************************************************************************************
GITHUB SAMPLE EXPORTS — MODULE 1 + MODULE 2 ARCHIVE SAMPLES
****************************************************************************************************

PURPOSE:
    Create compact, random-looking but deterministic archive samples suitable for GitHub upload.

TARGET TABLES:
    credit_decisioning_sim.synthetic_applications_scenario_archive
    credit_decisioning_sim.strategy_decisions_archive

DESIGN:
    1. Do not export full archive tables.
    2. Do not SELECT *.
    3. Use selected representative fields only.
    4. Use deterministic MD5 ordering instead of ORDER BY random().
    5. Stratify the samples so the CSVs are analytically useful.
    6. Keep row caps conservative so CSVs should remain below 25MB.

HOW TO USE:
    1. Run this script in the same PostgreSQL session.
    2. Review the size / coverage diagnostics.
    3. Export the two temp tables from DBeaver as CSV, or use COPY if your PostgreSQL environment
       allows server-side file writes.

NOTES:
    - Change sample_seed to produce a different deterministic sample.
    - If either CSV exceeds 25MB, lower the row-count parameters in Section 0.
***************************************************************************************************/


/***************************************************************************************************
SECTION 0 — SAMPLE CONFIGURATION
****************************************************************************************************/

DROP TABLE IF EXISTS tmp_github_sample_config;

CREATE TEMP TABLE tmp_github_sample_config
ON COMMIT PRESERVE ROWS
AS
SELECT
    'GITHUB_SAMPLE_V1'::TEXT AS sample_seed,

    /***********************************************************************************************
    Module 1 sample size:
        max rows ≈ scenario_count × product_count × score_band_count × rows_per_cell

        With 19 scenarios, 5 products, 5 score bands, and 20 rows per cell:
            19 × 5 × 5 × 20 = 9,500 max rows
    ***********************************************************************************************/
    20::INT AS m1_rows_per_scenario_product_score,
    12000::INT AS m1_max_rows,

    /***********************************************************************************************
    Module 2 sample size:
        Core sample:
            module2_run_id × decision_outcome × product × score_band × rows_per_cell

        Path supplement:
            Adds extra ordinary/aggressive counteroffer-path examples where available.
    ***********************************************************************************************/
    2::INT AS m2_core_rows_per_run_outcome_product_score,
    5::INT AS m2_path_rows_per_run_outcome_product_score,
    15000::INT AS m2_max_rows;


/***************************************************************************************************
SECTION 1 — MODULE 1 SYNTHETIC APPLICATION SCENARIO ARCHIVE SAMPLE
****************************************************************************************************

Sampling grain:
    scenario_set_name
    scenario_name
    population_id
    product_type
    score_band

Sampling logic:
    Up to N rows per scenario × product × score-band cell.

Why:
    This preserves broad Module 1 scenario coverage while keeping the CSV compact.
****************************************************************************************************/

DROP TABLE IF EXISTS tmp_github_sample_m1_synthetic_applications;

CREATE TEMP TABLE tmp_github_sample_m1_synthetic_applications
ON COMMIT PRESERVE ROWS
AS
WITH cfg AS (
    SELECT *
    FROM tmp_github_sample_config
),

ranked AS (
    SELECT
        'M1_SCENARIO_PRODUCT_SCORE_STRATIFIED_RANDOM'::TEXT AS sample_reason,

        s.scenario_set_name,
        s.scenario_name,
        s.population_id,

        s.application_seq,
        s.application_id,
        s.applicant_id,
        s.application_date,

        s.product_type,
        s.score_band,
        s.credit_score,

        s.annual_income,
        s.debt_to_income_ratio,
        s.utilization_rate,
        s.tradeline_count,
        s.months_since_oldest_trade,
        s.recent_inquiry_count,
        s.delinquency_count_12m,
        s.derogatory_flag,
        s.bankruptcy_flag,

        s.requested_amount,
        s.apr_proxy,
        s.loan_term_months,
        s.monthly_payment_proxy,
        s.payment_to_income_ratio,
        s.amount_to_income_ratio,

        s.estimated_pd,
        s.estimated_lgd,
        s.expected_loss_amount,

        ROW_NUMBER() OVER (
            PARTITION BY
                s.scenario_set_name,
                s.scenario_name,
                s.population_id,
                s.product_type,
                s.score_band
            ORDER BY
                md5(
                    s.application_id
                    || '|'
                    || s.scenario_name
                    || '|'
                    || s.population_id
                    || '|'
                    || (SELECT sample_seed FROM cfg)
                )
        ) AS stratum_random_row_number

    FROM credit_decisioning_sim.synthetic_applications_scenario_archive s
)

SELECT
    sample_reason,

    scenario_set_name,
    scenario_name,
    population_id,

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
    recent_inquiry_count,
    delinquency_count_12m,
    derogatory_flag,
    bankruptcy_flag,

    requested_amount,
    apr_proxy,
    loan_term_months,
    monthly_payment_proxy,
    payment_to_income_ratio,
    amount_to_income_ratio,

    estimated_pd,
    estimated_lgd,
    expected_loss_amount

FROM ranked
WHERE stratum_random_row_number <= (
    SELECT m1_rows_per_scenario_product_score
    FROM cfg
)
ORDER BY
    md5(
        application_id
        || '|'
        || scenario_name
        || '|'
        || population_id
        || '|m1_global|'
        || (SELECT sample_seed FROM cfg)
    )
LIMIT (
    SELECT m1_max_rows
    FROM cfg
);


/***************************************************************************************************
SECTION 2 — MODULE 2 STRATEGY DECISIONS ARCHIVE SAMPLE
****************************************************************************************************

Core sampling grain:
    module2_run_id
    module1_scenario_name
    decision_outcome
    product_type
    score_band

Path supplements:
    1. Aggressive counteroffer override rows.
    2. Ordinary counteroffer candidate rows.

Why:
    A simple random sample can miss rare but important governance paths.
    This sample preserves ordinary and aggressive counteroffer evidence where available.
****************************************************************************************************/

DROP TABLE IF EXISTS tmp_github_sample_m2_strategy_decisions;

CREATE TEMP TABLE tmp_github_sample_m2_strategy_decisions
ON COMMIT PRESERVE ROWS
AS
WITH cfg AS (
    SELECT *
    FROM tmp_github_sample_config
),

core_ranked AS (
    SELECT
        30::INT AS sample_priority,
        'M2_CORE_RUN_OUTCOME_PRODUCT_SCORE_STRATIFIED_RANDOM'::TEXT AS sample_reason,

        a.module2_run_id,

        a.strategy_set_name,
        a.strategy_name,
        a.strategy_version,
        a.strategy_run_id,
        a.strategy_run_ts,

        a.module1_scenario_set_name,
        a.module1_scenario_name,
        a.population_id,

        a.application_id,
        a.applicant_id,
        a.application_date,

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

        a.approval_flag,
        a.counteroffer_flag,
        a.manual_review_flag,
        a.decline_flag,
        a.simulated_offer_exposure_flag,

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
        a.ordinary_counteroffer_candidate_flag,
        a.aggressive_counteroffer_requested_structure_override_flag,

        a.primary_reason_code,
        a.secondary_reason_code,
        a.tertiary_reason_code,
        a.primary_reason_family,
        a.reason_code_count,

        ROW_NUMBER() OVER (
            PARTITION BY
                a.module2_run_id,
                a.module1_scenario_set_name,
                a.module1_scenario_name,
                a.population_id,
                a.decision_outcome,
                a.product_type,
                a.score_band
            ORDER BY
                md5(
                    a.application_id
                    || '|'
                    || a.module2_run_id
                    || '|'
                    || a.module1_scenario_name
                    || '|'
                    || (SELECT sample_seed FROM cfg)
                )
        ) AS stratum_random_row_number

    FROM credit_decisioning_sim.strategy_decisions_archive a
),

core_sample AS (
    SELECT *
    FROM core_ranked
    WHERE stratum_random_row_number <= (
        SELECT m2_core_rows_per_run_outcome_product_score
        FROM cfg
    )
),

aggressive_override_ranked AS (
    SELECT
        10::INT AS sample_priority,
        'M2_OPTION_C_AGGRESSIVE_OVERRIDE_PATH_RANDOM'::TEXT AS sample_reason,

        a.module2_run_id,

        a.strategy_set_name,
        a.strategy_name,
        a.strategy_version,
        a.strategy_run_id,
        a.strategy_run_ts,

        a.module1_scenario_set_name,
        a.module1_scenario_name,
        a.population_id,

        a.application_id,
        a.applicant_id,
        a.application_date,

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

        a.approval_flag,
        a.counteroffer_flag,
        a.manual_review_flag,
        a.decline_flag,
        a.simulated_offer_exposure_flag,

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
        a.ordinary_counteroffer_candidate_flag,
        a.aggressive_counteroffer_requested_structure_override_flag,

        a.primary_reason_code,
        a.secondary_reason_code,
        a.tertiary_reason_code,
        a.primary_reason_family,
        a.reason_code_count,

        ROW_NUMBER() OVER (
            PARTITION BY
                a.module2_run_id,
                a.module1_scenario_set_name,
                a.module1_scenario_name,
                a.population_id,
                a.decision_outcome,
                a.product_type,
                a.score_band
            ORDER BY
                md5(
                    a.application_id
                    || '|aggressive_override|'
                    || a.module2_run_id
                    || '|'
                    || (SELECT sample_seed FROM cfg)
                )
        ) AS stratum_random_row_number

    FROM credit_decisioning_sim.strategy_decisions_archive a
    WHERE a.aggressive_counteroffer_requested_structure_override_flag IS TRUE
),

aggressive_override_sample AS (
    SELECT *
    FROM aggressive_override_ranked
    WHERE stratum_random_row_number <= (
        SELECT m2_path_rows_per_run_outcome_product_score
        FROM cfg
    )
),

ordinary_counteroffer_ranked AS (
    SELECT
        20::INT AS sample_priority,
        'M2_ORDINARY_COUNTEROFFER_CANDIDATE_PATH_RANDOM'::TEXT AS sample_reason,

        a.module2_run_id,

        a.strategy_set_name,
        a.strategy_name,
        a.strategy_version,
        a.strategy_run_id,
        a.strategy_run_ts,

        a.module1_scenario_set_name,
        a.module1_scenario_name,
        a.population_id,

        a.application_id,
        a.applicant_id,
        a.application_date,

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

        a.approval_flag,
        a.counteroffer_flag,
        a.manual_review_flag,
        a.decline_flag,
        a.simulated_offer_exposure_flag,

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
        a.ordinary_counteroffer_candidate_flag,
        a.aggressive_counteroffer_requested_structure_override_flag,

        a.primary_reason_code,
        a.secondary_reason_code,
        a.tertiary_reason_code,
        a.primary_reason_family,
        a.reason_code_count,

        ROW_NUMBER() OVER (
            PARTITION BY
                a.module2_run_id,
                a.module1_scenario_set_name,
                a.module1_scenario_name,
                a.population_id,
                a.decision_outcome,
                a.product_type,
                a.score_band
            ORDER BY
                md5(
                    a.application_id
                    || '|ordinary_counteroffer|'
                    || a.module2_run_id
                    || '|'
                    || (SELECT sample_seed FROM cfg)
                )
        ) AS stratum_random_row_number

    FROM credit_decisioning_sim.strategy_decisions_archive a
    WHERE a.ordinary_counteroffer_candidate_flag IS TRUE
),

ordinary_counteroffer_sample AS (
    SELECT *
    FROM ordinary_counteroffer_ranked
    WHERE stratum_random_row_number <= (
        SELECT m2_path_rows_per_run_outcome_product_score
        FROM cfg
    )
),

unioned AS (
    SELECT * FROM core_sample
    UNION ALL
    SELECT * FROM aggressive_override_sample
    UNION ALL
    SELECT * FROM ordinary_counteroffer_sample
),

deduped AS (
    SELECT
        u.*,

        ROW_NUMBER() OVER (
            PARTITION BY
                u.strategy_set_name,
                u.strategy_name,
                u.strategy_version,
                u.module1_scenario_set_name,
                u.module1_scenario_name,
                u.population_id,
                u.application_id
            ORDER BY
                u.sample_priority,
                md5(
                    u.application_id
                    || '|dedupe|'
                    || u.module2_run_id
                    || '|'
                    || (SELECT sample_seed FROM cfg)
                )
        ) AS dedupe_row_number

    FROM unioned u
)

SELECT
    sample_reason,

    module2_run_id,

    strategy_set_name,
    strategy_name,
    strategy_version,
    strategy_run_id,
    strategy_run_ts,

    module1_scenario_set_name,
    module1_scenario_name,
    population_id,

    application_id,
    applicant_id,
    application_date,

    product_type,
    score_band,
    credit_score,

    annual_income,
    debt_to_income_ratio,

    requested_amount,
    requested_monthly_payment_proxy,
    requested_payment_to_income_ratio,
    estimated_pd,
    estimated_lgd,
    requested_expected_loss_amount,

    decision_outcome,
    decision_path,
    decision_resolution_source,

    approval_flag,
    counteroffer_flag,
    manual_review_flag,
    decline_flag,
    simulated_offer_exposure_flag,

    approved_amount,
    counteroffer_amount,
    exposure_reduction_amount,
    exposure_reduction_pct,
    approved_monthly_payment_proxy,
    approved_payment_to_income_ratio,
    approved_expected_loss_amount,
    approved_el_reduction_amount,
    approved_el_reduction_pct,

    counteroffer_strategy_variant,
    ordinary_counteroffer_candidate_flag,
    aggressive_counteroffer_requested_structure_override_flag,

    primary_reason_code,
    secondary_reason_code,
    tertiary_reason_code,
    primary_reason_family,
    reason_code_count

FROM deduped
WHERE dedupe_row_number = 1
ORDER BY
    md5(
        application_id
        || '|'
        || module2_run_id
        || '|m2_global|'
        || (SELECT sample_seed FROM cfg)
    )
LIMIT (
    SELECT m2_max_rows
    FROM cfg
);


/***************************************************************************************************
SECTION 3 — SAMPLE SIZE / COVERAGE DIAGNOSTICS
****************************************************************************************************/

SELECT
    'tmp_github_sample_m1_synthetic_applications' AS sample_table,
    COUNT(*) AS sample_rows,
    COUNT(DISTINCT scenario_set_name) AS distinct_scenario_sets,
    COUNT(DISTINCT scenario_name) AS distinct_scenarios,
    COUNT(DISTINCT population_id) AS distinct_populations,
    COUNT(DISTINCT product_type) AS distinct_products,
    COUNT(DISTINCT score_band) AS distinct_score_bands,
    pg_size_pretty(SUM(pg_column_size(t))::BIGINT) AS estimated_in_memory_row_size
FROM tmp_github_sample_m1_synthetic_applications t;

SELECT
    scenario_set_name,
    scenario_name,
    product_type,
    score_band,
    COUNT(*) AS sample_rows
FROM tmp_github_sample_m1_synthetic_applications
GROUP BY
    scenario_set_name,
    scenario_name,
    product_type,
    score_band
ORDER BY
    scenario_set_name,
    scenario_name,
    product_type,
    score_band;

SELECT
    'tmp_github_sample_m2_strategy_decisions' AS sample_table,
    COUNT(*) AS sample_rows,
    COUNT(DISTINCT module2_run_id) AS distinct_module2_runs,
    COUNT(DISTINCT module1_scenario_name) AS distinct_module1_scenarios,
    COUNT(DISTINCT population_id) AS distinct_populations,
    COUNT(DISTINCT strategy_name) AS distinct_strategies,
    COUNT(DISTINCT decision_outcome) AS distinct_decision_outcomes,
    COUNT(DISTINCT product_type) AS distinct_products,
    COUNT(DISTINCT score_band) AS distinct_score_bands,
    SUM(CASE WHEN aggressive_counteroffer_requested_structure_override_flag IS TRUE THEN 1 ELSE 0 END)
        AS aggressive_override_sample_rows,
    SUM(CASE WHEN ordinary_counteroffer_candidate_flag IS TRUE THEN 1 ELSE 0 END)
        AS ordinary_counteroffer_candidate_sample_rows,
    pg_size_pretty(SUM(pg_column_size(t))::BIGINT) AS estimated_in_memory_row_size
FROM tmp_github_sample_m2_strategy_decisions t;

SELECT
    module2_run_id,
    module1_scenario_name,
    strategy_name,
    decision_outcome,
    product_type,
    score_band,
    COUNT(*) AS sample_rows
FROM tmp_github_sample_m2_strategy_decisions
GROUP BY
    module2_run_id,
    module1_scenario_name,
    strategy_name,
    decision_outcome,
    product_type,
    score_band
ORDER BY
    module2_run_id,
    decision_outcome,
    product_type,
    score_band;


/***************************************************************************************************
SECTION 4 — EXPORT-READY SELECTS
****************************************************************************************************

DBeaver export method:
    Run each SELECT below.
    Right-click result grid → Export Data → CSV.
    Save as:

        github_sample_synthetic_applications_scenario_archive.csv
        github_sample_strategy_decisions_archive.csv

If either CSV exceeds 25MB:
    Lower the row-count values in tmp_github_sample_config and rerun.
****************************************************************************************************/

SELECT *
FROM tmp_github_sample_m1_synthetic_applications
ORDER BY
    scenario_set_name,
    scenario_name,
    product_type,
    score_band,
    application_id;

SELECT *
FROM tmp_github_sample_m2_strategy_decisions
ORDER BY
    module2_run_id,
    decision_outcome,
    product_type,
    score_band,
    application_id;


/***************************************************************************************************
OPTIONAL — SERVER-SIDE COPY EXPORT
****************************************************************************************************

Use only if your PostgreSQL environment allows COPY to write server-side files.

For psql client-side export, use \copy instead of COPY. DBeaver users will usually prefer the
result-grid export method above.
****************************************************************************************************/

-- COPY (
--     SELECT *
--     FROM tmp_github_sample_m1_synthetic_applications
--     ORDER BY
--         scenario_set_name,
--         scenario_name,
--         product_type,
--         score_band,
--         application_id
-- )
-- TO '/tmp/github_sample_synthetic_applications_scenario_archive.csv'
-- WITH (FORMAT CSV, HEADER TRUE);


-- COPY (
--     SELECT *
--     FROM tmp_github_sample_m2_strategy_decisions
--     ORDER BY
--         module2_run_id,
--         decision_outcome,
--         product_type,
--         score_band,
--         application_id
-- )
-- TO '/tmp/github_sample_strategy_decisions_archive.csv'
-- WITH (FORMAT CSV, HEADER TRUE);
```

My suggested GitHub filenames:

```text
data/github_sample_synthetic_applications_scenario_archive.csv
data/github_sample_strategy_decisions_archive.csv
```

I would also add a README note like:

```text
The repository includes compact stratified samples of the Module 1 scenario archive and Module 2 strategy decision archive. Full campaign archives contain 950,000 Module 1 scenario rows and 1.95M Module 2 strategy decision rows; only representative samples are included to keep repository artifacts lightweight.
```
<!-- END_MESSAGE C040-M02583 -->


---

<a id="c040-m02585"></a>

### C040-M02585

**Andrew** · 2026-05-27T23:29:20.888000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02585 -->
SQL Error [42703]: ERROR: column s.derogatory_flag does not exist
  Position: 768
  ERROR: column s.derogatory_flag does not exist
  Position: 768
<!-- END_MESSAGE C040-M02585 -->


---

<a id="c040-m02589"></a>

### C040-M02589

**ChatGPT** · 2026-05-27T23:37:53.662609-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02589 -->
That error is from a stale Module 1 column name in my sample-export SQL. The final Module 1 / Module 2 handoff uses:

```sql
major_derogatory_flag
```

not:

```sql
derogatory_flag
```

The finalized Module 2 source-staging requirements list `major_derogatory_flag` and `bankruptcy_flag` as the borrower / behavioral fields to preserve from Module 1, so this should be corrected in the GitHub sample query. fileciteturn57file0

I would also update the APR field while we are here. The final Module 1 / Module 2 handoff expects `base_apr_for_payment_calc`, so the sample can expose it as `apr_proxy` for readability.

Replace **Section 1** of the sample script with this corrected version:

```sql
/***************************************************************************************************
SECTION 1 — MODULE 1 SYNTHETIC APPLICATION SCENARIO ARCHIVE SAMPLE
****************************************************************************************************

Sampling grain:
    scenario_set_name
    scenario_name
    population_id
    product_type
    score_band

Sampling logic:
    Up to N rows per scenario × product × score-band cell.

Why:
    This preserves broad Module 1 scenario coverage while keeping the CSV compact.

PATCH NOTE:
    Final Module 1 uses:
        major_derogatory_flag

    not:
        derogatory_flag

    The APR field is also sourced from:
        base_apr_for_payment_calc

    and exported as:
        apr_proxy

    for compact GitHub sample readability.
****************************************************************************************************/

DROP TABLE IF EXISTS tmp_github_sample_m1_synthetic_applications;

CREATE TEMP TABLE tmp_github_sample_m1_synthetic_applications
ON COMMIT PRESERVE ROWS
AS
WITH cfg AS (
    SELECT *
    FROM tmp_github_sample_config
),

ranked AS (
    SELECT
        'M1_SCENARIO_PRODUCT_SCORE_STRATIFIED_RANDOM'::TEXT AS sample_reason,

        s.scenario_set_name,
        s.scenario_name,
        s.population_id,

        s.application_seq,
        s.application_id,
        s.applicant_id,
        s.application_date,

        s.product_type,
        s.score_band,
        s.credit_score,

        s.annual_income,
        s.debt_to_income_ratio,
        s.utilization_rate,
        s.tradeline_count,
        s.months_since_oldest_trade,
        s.recent_inquiry_count,
        s.delinquency_count_12m,
        s.major_derogatory_flag,
        s.bankruptcy_flag,

        s.requested_amount,
        s.base_apr_for_payment_calc AS apr_proxy,
        s.loan_term_months,
        s.monthly_payment_proxy,
        s.payment_to_income_ratio,
        s.amount_to_income_ratio,

        s.estimated_pd,
        s.estimated_lgd,
        s.expected_loss_amount,

        ROW_NUMBER() OVER (
            PARTITION BY
                s.scenario_set_name,
                s.scenario_name,
                s.population_id,
                s.product_type,
                s.score_band
            ORDER BY
                md5(
                    s.application_id
                    || '|'
                    || s.scenario_name
                    || '|'
                    || s.population_id
                    || '|'
                    || (SELECT sample_seed FROM cfg)
                )
        ) AS stratum_random_row_number

    FROM credit_decisioning_sim.synthetic_applications_scenario_archive s
)

SELECT
    sample_reason,

    scenario_set_name,
    scenario_name,
    population_id,

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
    recent_inquiry_count,
    delinquency_count_12m,
    major_derogatory_flag,
    bankruptcy_flag,

    requested_amount,
    apr_proxy,
    loan_term_months,
    monthly_payment_proxy,
    payment_to_income_ratio,
    amount_to_income_ratio,

    estimated_pd,
    estimated_lgd,
    expected_loss_amount

FROM ranked
WHERE stratum_random_row_number <= (
    SELECT m1_rows_per_scenario_product_score
    FROM cfg
)
ORDER BY
    md5(
        application_id
        || '|'
        || scenario_name
        || '|'
        || population_id
        || '|m1_global|'
        || (SELECT sample_seed FROM cfg)
    )
LIMIT (
    SELECT m1_max_rows
    FROM cfg
);
```

Before rerunning the full sample script, you can also quickly confirm the relevant Module 1 archive columns with:

```sql
SELECT
    column_name,
    data_type,
    ordinal_position
FROM information_schema.columns
WHERE table_schema = 'credit_decisioning_sim'
  AND table_name = 'synthetic_applications_scenario_archive'
  AND column_name IN (
      'derogatory_flag',
      'major_derogatory_flag',
      'bankruptcy_flag',
      'apr_proxy',
      'base_apr_for_payment_calc'
  )
ORDER BY ordinal_position;
```

Expected result should include:

```text
major_derogatory_flag
bankruptcy_flag
base_apr_for_payment_calc
```

and should not require:

```text
derogatory_flag
```

Then rerun from **Section 0** onward so `tmp_github_sample_m1_synthetic_applications` is rebuilt cleanly.
<!-- END_MESSAGE C040-M02589 -->


---

<a id="c040-m02591"></a>

### C040-M02591

**Andrew** · 2026-05-27T23:41:41.418000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02591 -->
SQL Error [42703]: ERROR: column a.module2_run_id does not exist
  Position: 323
  ERROR: column a.module2_run_id does not exist
  Position: 323
<!-- END_MESSAGE C040-M02591 -->


---

<a id="c040-m02598"></a>

### C040-M02598

**ChatGPT** · 2026-05-27T23:49:09.610268-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02598 -->
The error is because `module2_run_id` is **registry metadata**, not a guaranteed column in `strategy_decisions_archive`. The archive grain is keyed by strategy identity, Module 1 scenario lineage, population, and `application_id`; the campaign registry supplies the formal `module2_run_id`. That matches your locked Module 2 design: archive rows preserve completed strategy output, while campaign IDs connect the run roadmap, archive slice, evidence rows, and validation story. fileciteturn59file4

Replace the **Module 2 sample section only** with this corrected version. It joins `strategy_decisions_archive` to `strategy_run_campaign_registry` first, then exports `r.module2_run_id AS module2_run_id`.

```sql
/***************************************************************************************************
SECTION 2 — MODULE 2 STRATEGY DECISIONS ARCHIVE SAMPLE
****************************************************************************************************

Sampling source:
    credit_decisioning_sim.strategy_decisions_archive

Formal campaign run ID source:
    credit_decisioning_sim.strategy_run_campaign_registry

PATCH NOTE:
    strategy_decisions_archive does not necessarily contain module2_run_id.

    module2_run_id is campaign / registry metadata, so this section derives it by joining the
    archive slice to active campaign registry rows on the locked archive replacement grain:

        strategy_set_name
        strategy_name
        strategy_version
        module1_scenario_set_name
        module1_scenario_name
        population_id

Core sampling grain:
    module2_run_id
    module1_scenario_name
    decision_outcome
    product_type
    score_band

Path supplements:
    1. Aggressive counteroffer override rows.
    2. Ordinary counteroffer candidate rows.

Why:
    A simple random sample can miss rare but important governance paths.
    This sample preserves ordinary and aggressive counteroffer evidence where available.
****************************************************************************************************/

DROP TABLE IF EXISTS tmp_github_sample_m2_strategy_decisions;

CREATE TEMP TABLE tmp_github_sample_m2_strategy_decisions
ON COMMIT PRESERVE ROWS
AS
WITH cfg AS (
    SELECT *
    FROM tmp_github_sample_config
),

active_campaign_runs AS (
    SELECT
        module2_run_id,

        strategy_set_name,
        strategy_name,
        strategy_version,

        module1_scenario_set_name,
        module1_scenario_name,
        population_id
    FROM credit_decisioning_sim.strategy_run_campaign_registry
    WHERE registry_active_flag IS TRUE
),

archive_with_registry AS (
    SELECT
        r.module2_run_id AS registry_module2_run_id,
        a.*
    FROM credit_decisioning_sim.strategy_decisions_archive a

    JOIN active_campaign_runs r
        ON r.strategy_set_name = a.strategy_set_name
       AND r.strategy_name = a.strategy_name
       AND r.strategy_version = a.strategy_version
       AND r.module1_scenario_set_name = a.module1_scenario_set_name
       AND r.module1_scenario_name = a.module1_scenario_name
       AND r.population_id = a.population_id
),

core_ranked AS (
    SELECT
        30::INT AS sample_priority,
        'M2_CORE_RUN_OUTCOME_PRODUCT_SCORE_STRATIFIED_RANDOM'::TEXT AS sample_reason,

        b.*,

        ROW_NUMBER() OVER (
            PARTITION BY
                b.registry_module2_run_id,
                b.module1_scenario_set_name,
                b.module1_scenario_name,
                b.population_id,
                b.decision_outcome,
                b.product_type,
                b.score_band
            ORDER BY
                md5(
                    COALESCE(b.application_id::TEXT, '')
                    || '|'
                    || COALESCE(b.registry_module2_run_id::TEXT, '')
                    || '|'
                    || COALESCE(b.module1_scenario_name::TEXT, '')
                    || '|'
                    || (SELECT sample_seed FROM cfg)
                )
        ) AS stratum_random_row_number

    FROM archive_with_registry b
),

core_sample AS (
    SELECT *
    FROM core_ranked
    WHERE stratum_random_row_number <= (
        SELECT m2_core_rows_per_run_outcome_product_score
        FROM cfg
    )
),

aggressive_override_ranked AS (
    SELECT
        10::INT AS sample_priority,
        'M2_OPTION_C_AGGRESSIVE_OVERRIDE_PATH_RANDOM'::TEXT AS sample_reason,

        b.*,

        ROW_NUMBER() OVER (
            PARTITION BY
                b.registry_module2_run_id,
                b.module1_scenario_set_name,
                b.module1_scenario_name,
                b.population_id,
                b.decision_outcome,
                b.product_type,
                b.score_band
            ORDER BY
                md5(
                    COALESCE(b.application_id::TEXT, '')
                    || '|aggressive_override|'
                    || COALESCE(b.registry_module2_run_id::TEXT, '')
                    || '|'
                    || (SELECT sample_seed FROM cfg)
                )
        ) AS stratum_random_row_number

    FROM archive_with_registry b
    WHERE b.aggressive_counteroffer_requested_structure_override_flag IS TRUE
),

aggressive_override_sample AS (
    SELECT *
    FROM aggressive_override_ranked
    WHERE stratum_random_row_number <= (
        SELECT m2_path_rows_per_run_outcome_product_score
        FROM cfg
    )
),

ordinary_counteroffer_ranked AS (
    SELECT
        20::INT AS sample_priority,
        'M2_ORDINARY_COUNTEROFFER_CANDIDATE_PATH_RANDOM'::TEXT AS sample_reason,

        b.*,

        ROW_NUMBER() OVER (
            PARTITION BY
                b.registry_module2_run_id,
                b.module1_scenario_set_name,
                b.module1_scenario_name,
                b.population_id,
                b.decision_outcome,
                b.product_type,
                b.score_band
            ORDER BY
                md5(
                    COALESCE(b.application_id::TEXT, '')
                    || '|ordinary_counteroffer|'
                    || COALESCE(b.registry_module2_run_id::TEXT, '')
                    || '|'
                    || (SELECT sample_seed FROM cfg)
                )
        ) AS stratum_random_row_number

    FROM archive_with_registry b
    WHERE b.ordinary_counteroffer_candidate_flag IS TRUE
),

ordinary_counteroffer_sample AS (
    SELECT *
    FROM ordinary_counteroffer_ranked
    WHERE stratum_random_row_number <= (
        SELECT m2_path_rows_per_run_outcome_product_score
        FROM cfg
    )
),

unioned AS (
    SELECT * FROM core_sample
    UNION ALL
    SELECT * FROM aggressive_override_sample
    UNION ALL
    SELECT * FROM ordinary_counteroffer_sample
),

deduped AS (
    SELECT
        u.*,

        ROW_NUMBER() OVER (
            PARTITION BY
                u.strategy_set_name,
                u.strategy_name,
                u.strategy_version,
                u.module1_scenario_set_name,
                u.module1_scenario_name,
                u.population_id,
                u.application_id
            ORDER BY
                u.sample_priority,
                md5(
                    COALESCE(u.application_id::TEXT, '')
                    || '|dedupe|'
                    || COALESCE(u.registry_module2_run_id::TEXT, '')
                    || '|'
                    || (SELECT sample_seed FROM cfg)
                )
        ) AS dedupe_row_number

    FROM unioned u
)

SELECT
    sample_reason,

    registry_module2_run_id AS module2_run_id,

    strategy_set_name,
    strategy_name,
    strategy_version,
    strategy_run_id,
    strategy_run_ts,

    module1_scenario_set_name,
    module1_scenario_name,
    population_id,

    application_id,
    applicant_id,
    application_date,

    product_type,
    score_band,
    credit_score,

    annual_income,
    debt_to_income_ratio,

    requested_amount,
    requested_monthly_payment_proxy,
    requested_payment_to_income_ratio,
    estimated_pd,
    estimated_lgd,
    requested_expected_loss_amount,

    decision_outcome,
    decision_path,
    decision_resolution_source,

    approval_flag,
    counteroffer_flag,
    manual_review_flag,
    decline_flag,
    simulated_offer_exposure_flag,

    approved_amount,
    counteroffer_amount,
    exposure_reduction_amount,
    exposure_reduction_pct,
    approved_monthly_payment_proxy,
    approved_payment_to_income_ratio,
    approved_expected_loss_amount,
    approved_el_reduction_amount,
    approved_el_reduction_pct,

    counteroffer_strategy_variant,
    ordinary_counteroffer_candidate_flag,
    aggressive_counteroffer_requested_structure_override_flag,

    primary_reason_code,
    secondary_reason_code,
    tertiary_reason_code,
    primary_reason_family,
    reason_code_count

FROM deduped
WHERE dedupe_row_number = 1
ORDER BY
    md5(
        COALESCE(application_id::TEXT, '')
        || '|'
        || COALESCE(registry_module2_run_id::TEXT, '')
        || '|m2_global|'
        || (SELECT sample_seed FROM cfg)
    )
LIMIT (
    SELECT m2_max_rows
    FROM cfg
);
```

Then rerun the Module 2 diagnostics and export query. Your existing export-ready select should still work:

```sql
SELECT *
FROM tmp_github_sample_m2_strategy_decisions
ORDER BY
    module2_run_id,
    decision_outcome,
    product_type,
    score_band,
    application_id;
```
<!-- END_MESSAGE C040-M02598 -->


---

<a id="c040-m02599"></a>

### C040-M02599

**Andrew** · 2026-05-28T08:25:30.320000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02599 -->
I want to refresh strategy_decisions for M2-01 to upload to github.  which sections of module 2 do i need to re-run?
<!-- END_MESSAGE C040-M02599 -->


---

<a id="c040-m02600"></a>

### C040-M02600

**ChatGPT** · 2026-05-28T08:26:02.874973-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02600 -->
For **refreshing M2-01 `strategy_decisions` / `strategy_decisions_archive` for GitHub**, rerun:

**Required path**
1. **Section 1** — reset latest-run/temp objects  
2. **Section 2** — set `selected_module2_run_id = 'M2-01'`  
3. **Section 3** — fail-fast config / registry gatekeeper  
4. **Sections 4–10** — rebuild staged strategy logic  
5. **Section 11** — recreates latest-run table: `credit_decisioning_sim.strategy_decisions`  
6. **Section 12** — refreshes archive: `credit_decisioning_sim.strategy_decisions_archive`

That aligns with the job aid: single governed runs go Section 1 → 2 → 3 → 4–11 → 12; Section 11 materializes latest-run output, and Section 12 persists it to archive. fileciteturn59file4 fileciteturn59file37 fileciteturn59file35

Before Section 12, make sure M2-01 has:

```sql
archive_run_flag = TRUE
strategy_archive_reset_mode = 'STRATEGY_SCENARIO_ONLY'
```

That will replace only the M2-01 strategy/scenario/population archive slice, not the full campaign.

**Recommended QA before export**
Run **Section 14** after Section 12 to validate the refreshed latest-run output. Section 14 is read-only and creates the validation summary used for evidence capture. fileciteturn59file6

**Not required for just the GitHub CSV**
You do **not** need Section 13, 15, 16, 16.9, or 17 unless you are also refreshing comparison evidence, frontier dashboards, README metrics, or campaign acceptance evidence.
<!-- END_MESSAGE C040-M02600 -->


---

<a id="c040-m02603"></a>

### C040-M02603

**Andrew** · 2026-05-28T08:55:38.997000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02603 -->
thanks. please update the sample code we wrote to include new sections that produce a sample of strategy_decisions.  I want to preserve a random sample of this M2-01 strategy_decisions.
<!-- END_MESSAGE C040-M02603 -->


---

<a id="c040-m02609"></a>

### C040-M02609

**ChatGPT** · 2026-05-28T09:06:28.309309-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02609 -->
Yes — add the following sections to the GitHub sample-export SQL. These sections create a **deterministic-random, stratified sample from the current latest-run `credit_decisioning_sim.strategy_decisions` table**, specifically for **M2-01**.

Run this **after you refresh M2-01 through Section 11 or Section 12**, and before running any other Module 2 run, because `strategy_decisions` is the replaceable latest-run table. Section 11 creates `credit_decisioning_sim.strategy_decisions`, while Section 12 persists that latest-run output to archive. fileciteturn59file37 fileciteturn59file35

```sql
/***************************************************************************************************
GITHUB SAMPLE ADDENDUM — M2-01 LATEST-RUN STRATEGY_DECISIONS SAMPLE
****************************************************************************************************

PURPOSE:
    Preserve a compact, deterministic-random sample of the refreshed M2-01 latest-run
    strategy_decisions table for GitHub upload.

TARGET TABLE:
    credit_decisioning_sim.strategy_decisions

IMPORTANT:
    strategy_decisions is the replaceable latest-run table.

    Run this sample section immediately after refreshing M2-01 and before running another Module 2
    strategy run.

WHY THIS IS SEPARATE FROM strategy_decisions_archive:
    strategy_decisions_archive preserves completed historical slices.

    strategy_decisions is useful for GitHub because it shows the direct final latest-run output
    surface created by Section 11 for one governed strategy run.

SAMPLING DESIGN:
    Deterministic-random sample using MD5 ordering.

    Stratified by:
        decision_outcome
        decision_path
        decision_resolution_source
        product_type
        score_band

    This preserves a useful spread of final outcome paths, products, and score bands while keeping
    the CSV compact.

CSV SIZE CONTROL:
    Default max rows = 5,000.

    If the exported CSV exceeds 25MB, lower:
        m2_01_strategy_decisions_max_rows
        m2_01_rows_per_outcome_path_product_score

***************************************************************************************************/


/***************************************************************************************************
SECTION A — M2-01 LATEST-RUN SAMPLE CONFIGURATION
****************************************************************************************************/

DROP TABLE IF EXISTS tmp_github_sample_m2_01_strategy_decisions_config;

CREATE TEMP TABLE tmp_github_sample_m2_01_strategy_decisions_config
ON COMMIT PRESERVE ROWS
AS
SELECT
    'M2-01'::TEXT AS target_module2_run_id,

    /***********************************************************************************************
    Change this seed if you want a different deterministic-random sample.
    ***********************************************************************************************/
    'GITHUB_M2_01_STRATEGY_DECISIONS_SAMPLE_V1'::TEXT AS sample_seed,

    /***********************************************************************************************
    Sampling cap per outcome/path/product/score stratum.
    ***********************************************************************************************/
    12::INT AS m2_01_rows_per_outcome_path_product_score,

    /***********************************************************************************************
    Global max row cap. Keep conservative for GitHub CSV size.
    ***********************************************************************************************/
    5000::INT AS m2_01_strategy_decisions_max_rows;


/***************************************************************************************************
SECTION B — M2-01 LATEST-RUN PREFLIGHT
****************************************************************************************************

PURPOSE:
    Confirm that strategy_decisions exists and that the current latest-run output joins to active
    campaign registry row M2-01.

WHY:
    strategy_decisions is replaceable. If another run was executed after M2-01, this preflight should
    fail or show zero M2-01 rows, preventing accidental sampling of the wrong latest-run output.
****************************************************************************************************/

DO $$
DECLARE
    v_latest_run_exists BOOLEAN;
    v_target_module2_run_id TEXT;
    v_active_registry_rows BIGINT;
    v_joined_latest_rows BIGINT;
BEGIN
    SELECT
        target_module2_run_id
    INTO
        v_target_module2_run_id
    FROM tmp_github_sample_m2_01_strategy_decisions_config;

    SELECT
        TO_REGCLASS('credit_decisioning_sim.strategy_decisions') IS NOT NULL
    INTO
        v_latest_run_exists;

    IF NOT v_latest_run_exists THEN
        RAISE EXCEPTION
            'GitHub M2-01 strategy_decisions sample failure: credit_decisioning_sim.strategy_decisions does not exist. Rerun Module 2 through Section 11 for M2-01 first.';
    END IF;

    SELECT
        COUNT(*)
    INTO
        v_active_registry_rows
    FROM credit_decisioning_sim.strategy_run_campaign_registry r
    WHERE r.registry_active_flag IS TRUE
      AND r.module2_run_id = v_target_module2_run_id;

    IF v_active_registry_rows <> 1 THEN
        RAISE EXCEPTION
            'GitHub M2-01 strategy_decisions sample failure: expected exactly one active campaign registry row for %, found %.',
            v_target_module2_run_id,
            v_active_registry_rows;
    END IF;

    SELECT
        COUNT(*)
    INTO
        v_joined_latest_rows
    FROM credit_decisioning_sim.strategy_decisions d
    JOIN credit_decisioning_sim.strategy_run_campaign_registry r
        ON r.strategy_set_name = d.strategy_set_name
       AND r.strategy_name = d.strategy_name
       AND r.strategy_version = d.strategy_version
       AND r.module1_scenario_set_name = d.module1_scenario_set_name
       AND r.module1_scenario_name = d.module1_scenario_name
       AND r.population_id = d.population_id
    WHERE r.registry_active_flag IS TRUE
      AND r.module2_run_id = v_target_module2_run_id;

    IF v_joined_latest_rows = 0 THEN
        RAISE EXCEPTION
            'GitHub M2-01 strategy_decisions sample failure: current strategy_decisions latest-run output does not join to active registry run %. Rerun M2-01 through Section 11 before sampling.',
            v_target_module2_run_id;
    END IF;

    RAISE NOTICE
        'GitHub M2-01 strategy_decisions sample preflight passed. Target run: %, joined latest-run rows: %.',
        v_target_module2_run_id,
        v_joined_latest_rows;
END $$;


/***************************************************************************************************
SECTION C — CREATE M2-01 LATEST-RUN STRATEGY_DECISIONS SAMPLE
****************************************************************************************************

OUTPUT TABLE:
    tmp_github_sample_m2_01_strategy_decisions

NOTES:
    This intentionally keeps all columns from strategy_decisions so the GitHub sample preserves the
    actual latest-run output shape.

    Additional sample metadata columns are prepended:
        sample_reason
        module2_run_id
        stratum_random_row_number
        global_random_row_number
****************************************************************************************************/

DROP TABLE IF EXISTS tmp_github_sample_m2_01_strategy_decisions;

CREATE TEMP TABLE tmp_github_sample_m2_01_strategy_decisions
ON COMMIT PRESERVE ROWS
AS
WITH cfg AS (
    SELECT *
    FROM tmp_github_sample_m2_01_strategy_decisions_config
),

target_campaign_run AS (
    SELECT
        r.module2_run_id,

        r.strategy_set_name,
        r.strategy_name,
        r.strategy_version,

        r.module1_scenario_set_name,
        r.module1_scenario_name,
        r.population_id
    FROM credit_decisioning_sim.strategy_run_campaign_registry r
    JOIN cfg
        ON cfg.target_module2_run_id = r.module2_run_id
    WHERE r.registry_active_flag IS TRUE
),

latest_run_with_registry AS (
    SELECT
        'M2_01_LATEST_RUN_DECISION_PATH_STRATIFIED_RANDOM'::TEXT AS sample_reason,
        r.module2_run_id,

        d.*
    FROM credit_decisioning_sim.strategy_decisions d

    JOIN target_campaign_run r
        ON r.strategy_set_name = d.strategy_set_name
       AND r.strategy_name = d.strategy_name
       AND r.strategy_version = d.strategy_version
       AND r.module1_scenario_set_name = d.module1_scenario_set_name
       AND r.module1_scenario_name = d.module1_scenario_name
       AND r.population_id = d.population_id
),

ranked AS (
    SELECT
        l.*,

        ROW_NUMBER() OVER (
            PARTITION BY
                l.decision_outcome,
                COALESCE(l.decision_path, 'UNKNOWN_DECISION_PATH'),
                COALESCE(l.decision_resolution_source, 'UNKNOWN_RESOLUTION_SOURCE'),
                l.product_type,
                l.score_band
            ORDER BY
                md5(
                    COALESCE(l.application_id::TEXT, '')
                    || '|'
                    || COALESCE(l.module2_run_id::TEXT, '')
                    || '|'
                    || COALESCE(l.decision_outcome::TEXT, '')
                    || '|'
                    || COALESCE(l.decision_path::TEXT, '')
                    || '|'
                    || COALESCE(l.product_type::TEXT, '')
                    || '|'
                    || COALESCE(l.score_band::TEXT, '')
                    || '|'
                    || (SELECT sample_seed FROM cfg)
                )
        ) AS stratum_random_row_number,

        ROW_NUMBER() OVER (
            ORDER BY
                md5(
                    COALESCE(l.application_id::TEXT, '')
                    || '|'
                    || COALESCE(l.module2_run_id::TEXT, '')
                    || '|m2_01_latest_global|'
                    || (SELECT sample_seed FROM cfg)
                )
        ) AS global_random_row_number

    FROM latest_run_with_registry l
)

SELECT *
FROM ranked
WHERE stratum_random_row_number <= (
    SELECT m2_01_rows_per_outcome_path_product_score
    FROM cfg
)
ORDER BY
    global_random_row_number
LIMIT (
    SELECT m2_01_strategy_decisions_max_rows
    FROM cfg
);


/***************************************************************************************************
SECTION D — M2-01 STRATEGY_DECISIONS SAMPLE DIAGNOSTICS
****************************************************************************************************/

SELECT
    'tmp_github_sample_m2_01_strategy_decisions' AS sample_table,
    COUNT(*) AS sample_rows,

    COUNT(DISTINCT module2_run_id) AS distinct_module2_runs,
    COUNT(DISTINCT strategy_set_name) AS distinct_strategy_sets,
    COUNT(DISTINCT strategy_name) AS distinct_strategy_names,
    COUNT(DISTINCT strategy_version) AS distinct_strategy_versions,

    COUNT(DISTINCT module1_scenario_set_name) AS distinct_module1_scenario_sets,
    COUNT(DISTINCT module1_scenario_name) AS distinct_module1_scenarios,
    COUNT(DISTINCT population_id) AS distinct_populations,

    COUNT(DISTINCT decision_outcome) AS distinct_decision_outcomes,
    COUNT(DISTINCT decision_path) AS distinct_decision_paths,
    COUNT(DISTINCT decision_resolution_source) AS distinct_resolution_sources,

    COUNT(DISTINCT product_type) AS distinct_products,
    COUNT(DISTINCT score_band) AS distinct_score_bands,

    SUM(CASE WHEN approval_flag IS TRUE THEN 1 ELSE 0 END) AS approval_sample_rows,
    SUM(CASE WHEN counteroffer_flag IS TRUE THEN 1 ELSE 0 END) AS counteroffer_sample_rows,
    SUM(CASE WHEN manual_review_flag IS TRUE THEN 1 ELSE 0 END) AS manual_review_sample_rows,
    SUM(CASE WHEN decline_flag IS TRUE THEN 1 ELSE 0 END) AS decline_sample_rows,

    SUM(CASE WHEN simulated_offer_exposure_flag IS TRUE THEN 1 ELSE 0 END)
        AS simulated_offer_exposure_sample_rows,

    SUM(CASE WHEN ordinary_counteroffer_candidate_flag IS TRUE THEN 1 ELSE 0 END)
        AS ordinary_counteroffer_candidate_sample_rows,

    SUM(CASE WHEN aggressive_counteroffer_requested_structure_override_flag IS TRUE THEN 1 ELSE 0 END)
        AS aggressive_override_sample_rows,

    pg_size_pretty(SUM(pg_column_size(t))::BIGINT) AS estimated_in_memory_row_size

FROM tmp_github_sample_m2_01_strategy_decisions t;


SELECT
    module2_run_id,
    strategy_name,
    module1_scenario_name,
    population_id,
    decision_outcome,
    decision_path,
    decision_resolution_source,
    product_type,
    score_band,
    COUNT(*) AS sample_rows
FROM tmp_github_sample_m2_01_strategy_decisions
GROUP BY
    module2_run_id,
    strategy_name,
    module1_scenario_name,
    population_id,
    decision_outcome,
    decision_path,
    decision_resolution_source,
    product_type,
    score_band
ORDER BY
    decision_outcome,
    decision_path,
    decision_resolution_source,
    product_type,
    score_band;


/***************************************************************************************************
SECTION E — EXPORT-READY SELECT FOR GITHUB CSV
****************************************************************************************************

DBeaver export method:
    Run the SELECT below.
    Right-click result grid → Export Data → CSV.

Suggested filename:
    data/github_sample_m2_01_strategy_decisions.csv

If CSV exceeds 25MB:
    Lower these config values and rerun Sections A–E:
        m2_01_rows_per_outcome_path_product_score
        m2_01_strategy_decisions_max_rows
****************************************************************************************************/

SELECT *
FROM tmp_github_sample_m2_01_strategy_decisions
ORDER BY
    module2_run_id,
    decision_outcome,
    decision_path,
    decision_resolution_source,
    product_type,
    score_band,
    application_id;


/***************************************************************************************************
OPTIONAL — SERVER-SIDE COPY EXPORT
****************************************************************************************************

Use only if PostgreSQL can write server-side files.

DBeaver users will usually prefer:
    result grid → Export Data → CSV
****************************************************************************************************/

-- COPY (
--     SELECT *
--     FROM tmp_github_sample_m2_01_strategy_decisions
--     ORDER BY
--         module2_run_id,
--         decision_outcome,
--         decision_path,
--         decision_resolution_source,
--         product_type,
--         score_band,
--         application_id
-- )
-- TO '/tmp/github_sample_m2_01_strategy_decisions.csv'
-- WITH (FORMAT CSV, HEADER TRUE);
```

Suggested README data note:

```text
The repository includes compact stratified samples of the Module 1 scenario archive, the Module 2 strategy archive, and the refreshed M2-01 latest-run strategy_decisions output. The full campaign archives are larger, so GitHub includes representative deterministic-random samples only.
```
<!-- END_MESSAGE C040-M02609 -->


---

<a id="c040-m02611"></a>

### C040-M02611

**Andrew** · 2026-05-28T09:49:04.597000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02611 -->
all module 1 and module 2 project artifacts are uploaded to github except for module 2 brd/validation summary (placeholders that detail those are coming soon are documented - we will work on those later).  i would like to work on the overall project readme next - incorporating the module 1 and module 2 executive dashboards we worked hard on (attached).  these are saved at: https://github.com/andrew-goad/credit_decisioning_strategy/blob/main/Module_1_Synthetic_Application_%26_Risk_Modeling_Engine/v2.0/docs/module1_executive_dashboard_preview.png    &        https://github.com/andrew-goad/credit_decisioning_strategy/blob/main/Module_2_Credit_Policy_Strategy_%26_Decision_Outcome_Simulation_Engine/v1.0/docs/module2_executive_dashboard_preview.png         recall the style of my other github readmes (example attached).
<!-- END_MESSAGE C040-M02611 -->


**Attachments in export:** `github_readme_example(1).pdf`, `module2_executive_dashboard_preview(8).png`, `module1_executive_dashboard_preview(1).png`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_10.md) · [Next](Part_12.md)
