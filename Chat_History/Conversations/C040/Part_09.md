# Campaign QA and strategy expansion

## Part 09

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_08.md) · [Next](Part_10.md)

<a id="c040-m02439"></a>

### C040-M02439

**Andrew** · 2026-05-26T22:24:18.968000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02439 -->
do not generate images.  only update python code (provide full copy paste).  I love this last iteration, but please center the chart titles and footnote.  do not change anything else.
<!-- END_MESSAGE C040-M02439 -->


---

<a id="c040-m02441"></a>

### C040-M02441

**ChatGPT** · 2026-05-26T22:30:11.816957-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02441 -->
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

# Center x-position for all top titles and the footer.
# The content area includes the heatmap, color scale, and right interpretation box.
CONTENT_CENTER_X = 0.52

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
    x=CONTENT_CENTER_X,
    y=0.970,
)

fig.text(
    CONTENT_CENTER_X,
    0.925,
    "Baseline synthetic portfolio: color = avg Expected Loss; cell label = avg synthetic-PD proxy",
    ha="center",
    va="center",
    fontsize=11,
    color=TEXT_COLOR,
)

fig.text(
    CONTENT_CENTER_X,
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
    CONTENT_CENTER_X,
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
<!-- END_MESSAGE C040-M02441 -->


---

<a id="c040-m02443"></a>

### C040-M02443

**Andrew** · 2026-05-26T22:41:00.379000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02443 -->
do not generate an image.  first take a moment to understand the issue, then provide full updated python code. this title/footnote is not centered at all (see image).  notice the title and footnote are 2/3 on the right.
<!-- END_MESSAGE C040-M02443 -->


**Attachments in export:** `image(82).png`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c040-m02446"></a>

### C040-M02446

**ChatGPT** · 2026-05-26T22:46:57.258476-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02446 -->
The centering issue is coming from the interaction between manually positioned axes and `bbox_inches="tight"`. The tight crop changes the visible canvas after the title and footer have already been positioned, so `x=0.52` ends up looking far to the right in the final exported image.

The update below keeps the chart layout the same, but centers the title/subtitle/footer on the full figure canvas and removes the tight bounding-box crop from `savefig`.

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

    The title, subtitle, callout banner, and footer are centered on the full
    figure canvas. The output intentionally does not use bbox_inches="tight",
    because tight cropping can visually shift manually positioned figure text.

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

# Center x-position for all top titles and the footer.
# This now uses the full figure canvas center.
CONTENT_CENTER_X = 0.50

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
    x=CONTENT_CENTER_X,
    y=0.970,
)

fig.text(
    CONTENT_CENTER_X,
    0.925,
    "Baseline synthetic portfolio: color = avg Expected Loss; cell label = avg synthetic-PD proxy",
    ha="center",
    va="center",
    fontsize=11,
    color=TEXT_COLOR,
)

fig.text(
    CONTENT_CENTER_X,
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
    CONTENT_CENTER_X,
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
    facecolor=fig.get_facecolor(),
)

fig.savefig(
    OUTPUT_SVG,
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
<!-- END_MESSAGE C040-M02446 -->


---

<a id="c040-m02447"></a>

### C040-M02447

**Andrew** · 2026-05-27T02:00:39.314000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02447 -->
do not generate any images or python code in this next response. lets lockdown module 1 panel 2 spec.
<!-- END_MESSAGE C040-M02447 -->


---

<a id="c040-m02451"></a>

### C040-M02451

**ChatGPT** · 2026-05-27T02:07:21.063225-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02451 -->
## Module 1 Panel 2 framework locked: Scenario Transmission Chain

### Panel title

```text
Scenario Transmission Chain
Rate Environment → APR → Payment → PTI → Expected Loss
```

Optional subtitle:

```text
Portfolio-level rate-environment sensitivity indexed to baseline
```

This panel should show the **economic engine** inside Module 1: controlled scenario changes do not simply relabel the portfolio. They transmit through pricing, payment burden, affordability, synthetic estimated-risk proxy, and Expected Loss. That is one of Module 1’s core design claims: risk is not assigned arbitrarily; it emerges through a governed chain of borrower profile, product structure, affordability, and macro/rate assumptions. fileciteturn48file0

---

# 1. What Panel 2 is trying to demonstrate

Panel 2 should answer:

> **When the rate environment changes, does Module 1 transmit that scenario pressure through APR, payment burden, affordability, synthetic estimated-risk proxy, and Expected Loss in a coherent direction?**

The reader should see:

```text
RATE_DOWN_200BP:
    lower APR
    lower payment burden / PTI
    slightly lower Expected Loss

BASELINE_V2:
    reference point

RATE_UP_200BP:
    higher APR
    higher payment burden / PTI
    slightly higher Expected Loss

RATE_UP_300BP:
    higher again
    stronger affordability pressure
    highest rate-environment EL result among the selected rate scenarios
```

The important message is not that the Expected Loss movement is enormous. The important message is that the **transmission chain is directionally coherent** and controlled.

Module 1 is designed specifically around this chain:

```text
Rate Environment → APR → Payment → PTI → estimated-PD proxy → Expected Loss
```

and Section 10.2 is explicitly the portfolio-level scenario summary query for comparing average requested amount, APR, monthly payment, PTI, estimated-PD proxy, LGD, average Expected Loss, and total Expected Loss across scenarios. fileciteturn48file7

---

# 2. Why this panel adds value versus Panel 1

Panel 1 says:

```text
The baseline synthetic population is product-aware and score-aware.
```

Panel 2 says:

```text
The engine is scenario-aware: changing a rate assumption flows through the model.
```

That is a different credibility claim.

Panel 1 is **cross-sectional realism**.  
Panel 2 is **scenario transmission realism**.

Together:

```text
Panel 1:
    “The baseline risk surface makes sense.”

Panel 2:
    “Scenario pressure moves the portfolio through the intended economic chain.”
```

This is a strong Module 1 story because Module 1 is not just a static synthetic data generator. It is a scenario-capable simulation framework.

---

# 3. Data source

Use:

```text
module1_synthetic_application_risk_engine_v2.0_10.02_QA_portfolio_level_scenario_summary_campaign.csv
```

This is the correct source because Section 10.2 is designed to compare portfolio-level scenario metrics and show first-order impact of parameter changes across exposure, APR, PTI, estimated-PD proxy, and Expected Loss. fileciteturn48file3

---

# 4. Scenario scope

Use the rate-environment scenario family only.

Filter to:

```text
scenario_set_name = MODULE1_V2_BASELINE_SET
population_id     = BASE_POPULATION_V1
scenario_name IN (
    RATE_DOWN_200BP,
    BASELINE_V2,
    RATE_UP_200BP,
    RATE_UP_300BP
)
```

Order the x-axis like this:

```text
RATE_DOWN_200BP
BASELINE_V2
RATE_UP_200BP
RATE_UP_300BP
```

Display labels:

```text
Rate Down
200bp

Baseline

Rate Up
200bp

Rate Up
300bp
```

This ordering creates a clear left-to-right rate-pressure story.

---

# 5. Required data fields

Minimum fields:

```text
scenario_set_name
scenario_name
population_id
applications
avg_apr
avg_monthly_payment
avg_pti
avg_pd
avg_expected_loss
total_expected_loss
```

Recommended fields to carry in the hardcoded data later:

```text
scenario_name
applications
avg_requested_amount
avg_apr
avg_monthly_payment
avg_pti
avg_pd
avg_lgd
avg_expected_loss
total_expected_loss
```

Even if the panel does not display all of them, keeping these fields in the hardcoded dataset will make later annotations and QA easier.

Terminology rule:

```text
avg_pd should be labeled as Avg synthetic-PD proxy
```

not calibrated PD.

---

# 6. Recommended chart type

Use an **indexed multi-line chart**.

Each metric is converted to:

```text
Baseline = 100
Scenario index = scenario metric / baseline metric × 100
```

Lines:

```text
Avg APR
Avg Monthly Payment
Avg PTI
Avg Expected Loss
```

Optional fifth line:

```text
Avg synthetic-PD proxy
```

I would include the synthetic-PD proxy only if it remains visually legible. If the line is too compressed or redundant with PTI / EL, keep it as a smaller annotation rather than a full line.

## Why index to baseline?

Because the units differ:

```text
APR = percentage
Monthly payment = dollars
PTI = percentage
Expected Loss = dollars
Synthetic-PD proxy = percentage
```

Indexing lets the chart show **directional transmission** cleanly without using multiple axes.

---

# 7. Locked metric set

I recommend locking these four primary lines:

```text
1. Avg APR
2. Avg Monthly Payment
3. Avg PTI
4. Avg Expected Loss
```

Then include this interpretation text in the chart or caption:

```text
Synthetic-PD proxy is part of the chain and is reviewed in the underlying QA output, but the panel focuses on the clearest portfolio-level transmission metrics.
```

Alternative: include five lines if it still looks clean.

My recommendation for the README collage is **four lines**. It will be easier to read.

---

# 8. Axis design

## X-axis

```text
Rate scenario
```

Display labels:

```text
Rate Down
200bp

Baseline

Rate Up
200bp

Rate Up
300bp
```

## Y-axis

```text
Index vs Baseline
```

Format:

```text
Baseline = 100
```

Suggested y-axis range:

```text
98 to 112
```

or dynamically:

```text
min(indexed values) - buffer
max(indexed values) + buffer
```

The line movement may be subtle, so the axis needs enough resolution to show directional change without exaggerating too aggressively.

---

# 9. Labeling

Each line should be labeled at the rightmost endpoint rather than relying only on a legend.

Example endpoint labels:

```text
APR
Payment
PTI
Avg EL
```

At the baseline x-position, add a vertical reference line or small marker:

```text
Baseline = 100
```

Do not label every point. It will clutter the panel.

---

# 10. Callouts

Use two callouts only.

### Callout 1 — rate-down side

```text
Rate-down:
lower APR and payment burden
```

### Callout 2 — rate-up side

```text
Rate-up:
APR pressure flows through PTI and EL
```

Optional micro-callout:

```text
Controlled sensitivity, not a market forecast
```

That last phrase is important. Module 1’s documentation explicitly frames rate scenarios as controlled sensitivity assumptions, not forecasts of actual market rates or customer outcomes. fileciteturn48file12

---

# 11. Recommended caption

README caption:

```text
Rate-environment scenarios are indexed to the BASELINE_V2 portfolio. The panel shows how a controlled rate shift propagates through APR, monthly payment, PTI, and Expected Loss. This demonstrates scenario transmission rather than forecasting: the same synthetic population is tested under governed assumptions.
```

Short collage caption:

```text
Scenario transmission chain: rate assumptions flow through APR, payment, PTI, and Expected Loss.
```

---

# 12. What this panel should not do

Do **not** include all 19 scenarios. That would dilute the specific story.

Do **not** mix rate scenarios with product-mix, credit-box, LGD, or exposure-intensity scenarios in this panel.

Do **not** use a dual-axis chart. It will look more complex and less trustworthy.

Do **not** plot raw dollar and percentage values on the same y-axis.

Do **not** imply forecasting. This is controlled sensitivity testing.

Do **not** overstate the Expected Loss movement. If EL moves modestly, that is fine. The panel’s claim is coherent transmission, not dramatic shock.

---

# 13. Data values we need later for Python

For each of the four selected scenarios, hardcode:

```text
scenario_name
applications
avg_apr
avg_monthly_payment
avg_pti
avg_pd
avg_expected_loss
total_expected_loss
```

The earlier values we discussed for the rate scenario family were:

```text
BASELINE_V2:
    avg_apr ≈ 14.56%
    avg_pti ≈ 16.50%
    avg_expected_loss ≈ $4,788.67

RATE_DOWN_200BP:
    avg_apr ≈ 12.85%
    avg_pti ≈ 15.35%
    avg_expected_loss ≈ $4,765.49

RATE_UP_200BP:
    avg_apr ≈ 16.14%
    avg_pti ≈ 17.41%
    avg_expected_loss ≈ $4,804.46

RATE_UP_300BP:
    avg_apr ≈ 16.85%
    avg_pti ≈ 17.71%
    avg_expected_loss ≈ $4,809.80
```

Before coding, we should confirm the exact `avg_monthly_payment`, `avg_pd`, and `total_expected_loss` values from the final 10.02 CSV.

---

# 14. Final locked Panel 2 spec

```text
Panel name:
    Scenario Transmission Chain

Purpose:
    Show that Module 1 is scenario-capable and that rate-environment changes
    propagate coherently through APR, payment burden, PTI, and Expected Loss.

Source:
    Section 10.02 portfolio-level scenario summary campaign CSV

Filter:
    scenario_set_name = MODULE1_V2_BASELINE_SET
    population_id = BASE_POPULATION_V1
    scenario_name IN (
        RATE_DOWN_200BP,
        BASELINE_V2,
        RATE_UP_200BP,
        RATE_UP_300BP
    )

Chart type:
    Indexed multi-line chart

Index basis:
    BASELINE_V2 = 100 for each metric

X-axis:
    Rate Down 200bp
    Baseline
    Rate Up 200bp
    Rate Up 300bp

Y-axis:
    Index vs Baseline

Lines:
    Avg APR
    Avg Monthly Payment
    Avg PTI
    Avg Expected Loss

Optional annotation:
    Avg synthetic-PD proxy reviewed in QA / available in data

Callouts:
    Rate-down lowers APR and payment burden
    Rate-up pressure flows through PTI and Expected Loss
    Controlled sensitivity, not a forecast

Primary message:
    Module 1 does not just generate static synthetic records.
    It transmits controlled scenario pressure through a governed economic chain:
    Rate Environment → APR → Payment → PTI → estimated-PD proxy → Expected Loss.
```

This is the right Panel 2. It complements Panel 1 cleanly and sets up Panel 3, which can then show **where** the rate shock concentrated using matched row-level/product attribution.
<!-- END_MESSAGE C040-M02451 -->


---

<a id="c040-m02453"></a>

### C040-M02453

**Andrew** · 2026-05-27T02:10:45.284000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02453 -->
do not generate image. i approve module 1 panel 2 locked down spec. produce module 1 panel 2 python code to generate intended output.
<!-- END_MESSAGE C040-M02453 -->


---

<a id="c040-m02458"></a>

### C040-M02458

**ChatGPT** · 2026-05-27T02:18:11.770060-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02458 -->
```python
"""
Module 1 README Panel 2
Scenario Transmission Chain: Rate Environment → APR → Payment → PTI → Expected Loss

This version uses hardcoded final-campaign Section 10.02 values.

Panel thesis:
    Module 1 is not just a static synthetic population generator.
    It is scenario-capable: controlled rate-environment changes transmit through
    APR, monthly payment burden, PTI, and Expected Loss.

Data source:
    Final campaign Section 10.02:
    Portfolio-level scenario summary.

Data scope:
    scenario_set_name = MODULE1_V2_BASELINE_SET
    population_id     = BASE_POPULATION_V1

Scenario family:
    RATE_DOWN_200BP
    BASELINE_V2
    RATE_UP_200BP
    RATE_UP_300BP

Chart design:
    Indexed multi-line chart.

    Each metric is indexed to:
        BASELINE_V2 = 100

    Lines:
        Avg APR
        Avg Monthly Payment
        Avg PTI
        Avg Expected Loss

Interpretation:
    This is controlled scenario sensitivity, not a market forecast.
    The point is directional transmission through the governed synthetic-risk chain.

Output:
    assets/module1_scenario_transmission_chain.png
    assets/module1_scenario_transmission_chain.svg
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

OUTPUT_PNG = OUTPUT_DIR / "module1_scenario_transmission_chain.png"
OUTPUT_SVG = OUTPUT_DIR / "module1_scenario_transmission_chain.svg"


# =============================================================================
# 2. HARDCODED SECTION 10.02 PORTFOLIO-LEVEL SCENARIO DATA
# =============================================================================

SCENARIO_DATA = [
    {
        "scenario_set_name": "MODULE1_V2_BASELINE_SET",
        "scenario_name": "RATE_DOWN_200BP",
        "display_label": "Rate Down\n200bp",
        "population_id": "BASE_POPULATION_V1",
        "applications": 50000,
        "avg_requested_amount": 133390.33,
        "avg_apr": 0.1285,
        "avg_monthly_payment": 1385.24,
        "avg_pti": 0.1535,
        "avg_pd": 0.1627,
        "avg_lgd": 0.4923,
        "avg_expected_loss": 4765.49,
        "total_expected_loss": 238274612.94,
    },
    {
        "scenario_set_name": "MODULE1_V2_BASELINE_SET",
        "scenario_name": "BASELINE_V2",
        "display_label": "Baseline",
        "population_id": "BASE_POPULATION_V1",
        "applications": 50000,
        "avg_requested_amount": 133329.28,
        "avg_apr": 0.1456,
        "avg_monthly_payment": 1510.70,
        "avg_pti": 0.1650,
        "avg_pd": 0.1634,
        "avg_lgd": 0.4923,
        "avg_expected_loss": 4788.67,
        "total_expected_loss": 239433477.53,
    },
    {
        "scenario_set_name": "MODULE1_V2_BASELINE_SET",
        "scenario_name": "RATE_UP_200BP",
        "display_label": "Rate Up\n200bp",
        "population_id": "BASE_POPULATION_V1",
        "applications": 50000,
        "avg_requested_amount": 133208.64,
        "avg_apr": 0.1614,
        "avg_monthly_payment": 1612.00,
        "avg_pti": 0.1741,
        "avg_pd": 0.1639,
        "avg_lgd": 0.4923,
        "avg_expected_loss": 4804.46,
        "total_expected_loss": 240223118.88,
    },
    {
        "scenario_set_name": "MODULE1_V2_BASELINE_SET",
        "scenario_name": "RATE_UP_300BP",
        "display_label": "Rate Up\n300bp",
        "population_id": "BASE_POPULATION_V1",
        "applications": 50000,
        "avg_requested_amount": 133164.06,
        "avg_apr": 0.1685,
        "avg_monthly_payment": 1645.42,
        "avg_pti": 0.1771,
        "avg_pd": 0.1640,
        "avg_lgd": 0.4923,
        "avg_expected_loss": 4809.80,
        "total_expected_loss": 240489995.27,
    },
]


# =============================================================================
# 3. CHART STYLE SETTINGS
# =============================================================================

SCENARIO_ORDER = [
    "RATE_DOWN_200BP",
    "BASELINE_V2",
    "RATE_UP_200BP",
    "RATE_UP_300BP",
]

FIG_FACE = "black"
AX_FACE = "black"
TEXT_COLOR = "white"
GRID_COLOR = "white"
BASELINE_LINE_COLOR = "white"
CALLOUT_BOX_COLOR = "#4f8fc4"

# Dark README dashboard palette.
APR_COLOR = "#2f84c4"
PAYMENT_COLOR = "#f0a62e"
PTI_COLOR = "#2ca02c"
EXPECTED_LOSS_COLOR = "#d95f5f"

LINE_WIDTH = 2.3
MARKER_SIZE = 7.0

# Center x-position for title / subtitle / footer.
CONTENT_CENTER_X = 0.50


# =============================================================================
# 4. HELPER FUNCTIONS
# =============================================================================

def format_pct(value: float) -> str:
    """Format a decimal as percent."""
    return f"{value * 100:.2f}%"


def format_dollars(value: float) -> str:
    """Format dollars without decimals."""
    return f"${value:,.0f}"


def format_dollars_k(value: float) -> str:
    """Format dollars as $K."""
    return f"${value / 1000:.1f}K"


def format_total_loss_m(value: float) -> str:
    """Format total Expected Loss as $M."""
    return f"${value / 1_000_000:.1f}M"


def index_to_baseline(series: pd.Series, baseline_value: float) -> pd.Series:
    """Index a metric so BASELINE_V2 equals 100."""
    return 100.0 * series / baseline_value


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


# =============================================================================
# 5. PREPARE DATA
# =============================================================================

df = pd.DataFrame(SCENARIO_DATA)

df["scenario_name"] = pd.Categorical(
    df["scenario_name"],
    categories=SCENARIO_ORDER,
    ordered=True,
)

df = df.sort_values("scenario_name").reset_index(drop=True)
df["x"] = range(len(df))

baseline_row = df.loc[df["scenario_name"] == "BASELINE_V2"].iloc[0]

METRIC_SPECS = [
    {
        "metric_label": "Avg APR",
        "short_label": "APR",
        "column": "avg_apr",
        "indexed_column": "avg_apr_index",
        "color": APR_COLOR,
        "raw_formatter": format_pct,
    },
    {
        "metric_label": "Avg Monthly Payment",
        "short_label": "Payment",
        "column": "avg_monthly_payment",
        "indexed_column": "avg_monthly_payment_index",
        "color": PAYMENT_COLOR,
        "raw_formatter": format_dollars,
    },
    {
        "metric_label": "Avg PTI",
        "short_label": "PTI",
        "column": "avg_pti",
        "indexed_column": "avg_pti_index",
        "color": PTI_COLOR,
        "raw_formatter": format_pct,
    },
    {
        "metric_label": "Avg Expected Loss",
        "short_label": "Avg EL",
        "column": "avg_expected_loss",
        "indexed_column": "avg_expected_loss_index",
        "color": EXPECTED_LOSS_COLOR,
        "raw_formatter": format_dollars_k,
    },
]

for spec in METRIC_SPECS:
    baseline_value = baseline_row[spec["column"]]
    df[spec["indexed_column"]] = index_to_baseline(df[spec["column"]], baseline_value)

indexed_columns = [spec["indexed_column"] for spec in METRIC_SPECS]

min_index_value = df[indexed_columns].min().min()
max_index_value = df[indexed_columns].max().max()

y_min = min(86, min_index_value - 2.0)
y_max = max(118, max_index_value + 2.0)

rate_down_row = df.loc[df["scenario_name"] == "RATE_DOWN_200BP"].iloc[0]
rate_up_300_row = df.loc[df["scenario_name"] == "RATE_UP_300BP"].iloc[0]


# =============================================================================
# 6. BUILD CHART
# =============================================================================

fig = plt.figure(figsize=(15.2, 7.4), dpi=160)
fig.patch.set_facecolor(FIG_FACE)

# Manual layout:
#   ax = indexed line chart
#   right-side figure text = interpretation / raw value readout
#
# No bbox_inches="tight" is used during export so title / footer centering
# remains visually stable.
ax = fig.add_axes([0.08, 0.18, 0.69, 0.64])
style_dark_axis(ax)

# Baseline reference lines.
ax.axvline(
    x=1,
    color=BASELINE_LINE_COLOR,
    linewidth=1.0,
    linestyle="--",
    alpha=0.65,
)

ax.axhline(
    y=100,
    color=BASELINE_LINE_COLOR,
    linewidth=1.0,
    linestyle="--",
    alpha=0.65,
)

# Plot indexed metric lines.
for spec in METRIC_SPECS:
    ax.plot(
        df["x"],
        df[spec["indexed_column"]],
        marker="o",
        markersize=MARKER_SIZE,
        linewidth=LINE_WIDTH,
        color=spec["color"],
        label=spec["metric_label"],
    )

# X axis.
ax.set_xticks(df["x"])
ax.set_xticklabels(
    df["display_label"],
    color=TEXT_COLOR,
    fontsize=9.5,
)

ax.set_xlabel(
    "Rate Environment Scenario",
    color=TEXT_COLOR,
    fontsize=10.5,
    labelpad=10,
)

# Y axis.
ax.set_ylabel(
    "Index vs Baseline",
    color=TEXT_COLOR,
    fontsize=10.5,
    labelpad=10,
)

ax.set_ylim(y_min, y_max)
ax.yaxis.set_major_formatter(mtick.FuncFormatter(lambda value, _: f"{value:.0f}"))

# Baseline label.
ax.text(
    1.0,
    100.6,
    "Baseline = 100",
    ha="center",
    va="bottom",
    fontsize=8.5,
    color=TEXT_COLOR,
    bbox={
        "boxstyle": "round,pad=0.28",
        "facecolor": AX_FACE,
        "edgecolor": TEXT_COLOR,
        "alpha": 0.80,
    },
)

# Right endpoint labels.
# Slight manual offsets keep the labels separated when lines are close.
ENDPOINT_LABEL_OFFSETS = {
    "Avg APR": 0.2,
    "Avg Monthly Payment": 0.0,
    "Avg PTI": -0.8,
    "Avg Expected Loss": -1.3,
}

for spec in METRIC_SPECS:
    final_value = rate_up_300_row[spec["indexed_column"]]
    raw_value = rate_up_300_row[spec["column"]]
    y_offset = ENDPOINT_LABEL_OFFSETS.get(spec["metric_label"], 0.0)

    ax.text(
        rate_up_300_row["x"] + 0.10,
        final_value + y_offset,
        f"{spec['short_label']} {final_value:.1f}\n({spec['raw_formatter'](raw_value)})",
        ha="left",
        va="center",
        fontsize=8.3,
        color=spec["color"],
        fontweight="bold",
    )

# Give room for endpoint labels inside the axis.
ax.set_xlim(-0.15, 3.55)

# Legend.
legend = ax.legend(
    loc="upper left",
    fontsize=8.2,
    frameon=True,
    title="Indexed metric",
    title_fontsize=8.7,
)

legend.get_frame().set_facecolor(AX_FACE)
legend.get_frame().set_edgecolor(TEXT_COLOR)
for text in legend.get_texts():
    text.set_color(TEXT_COLOR)
legend.get_title().set_color(TEXT_COLOR)

# Callout: rate-down side.
ax.text(
    0.03,
    0.12,
    "Rate-down:\nlower APR,\npayment burden,\nand PTI",
    transform=ax.transAxes,
    fontsize=8.6,
    va="bottom",
    ha="left",
    color=TEXT_COLOR,
    bbox={
        "boxstyle": "round,pad=0.42",
        "facecolor": CALLOUT_BOX_COLOR,
        "edgecolor": CALLOUT_BOX_COLOR,
        "alpha": 0.88,
    },
)

# Callout: rate-up side.
ax.text(
    0.63,
    0.94,
    "Rate-up:\nAPR pressure flows\nthrough payment and PTI;\nEL moves modestly",
    transform=ax.transAxes,
    fontsize=8.6,
    va="top",
    ha="left",
    color=TEXT_COLOR,
    bbox={
        "boxstyle": "round,pad=0.42",
        "facecolor": CALLOUT_BOX_COLOR,
        "edgecolor": CALLOUT_BOX_COLOR,
        "alpha": 0.88,
    },
)

# Titles.
fig.suptitle(
    "Scenario Transmission Chain",
    fontsize=20,
    fontweight="bold",
    color=TEXT_COLOR,
    x=CONTENT_CENTER_X,
    y=0.970,
)

fig.text(
    CONTENT_CENTER_X,
    0.925,
    "Rate Environment → APR → Payment → PTI → Expected Loss",
    ha="center",
    va="center",
    fontsize=12.0,
    color=TEXT_COLOR,
)

fig.text(
    CONTENT_CENTER_X,
    0.888,
    "Portfolio-level rate-environment sensitivity indexed to BASELINE_V2 = 100",
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

# Right-side interpretation / raw value box.
raw_value_text = (
    "How to read:\n\n"
    "Each line is indexed\n"
    "to baseline = 100.\n\n"
    "Controlled sensitivity,\n"
    "not a market forecast.\n\n"
    "Baseline portfolio:\n"
    f"  APR: {format_pct(baseline_row['avg_apr'])}\n"
    f"  Payment: {format_dollars(baseline_row['avg_monthly_payment'])}\n"
    f"  PTI: {format_pct(baseline_row['avg_pti'])}\n"
    f"  Avg EL: {format_dollars_k(baseline_row['avg_expected_loss'])}\n\n"
    "Rate Up 300bp:\n"
    f"  APR: {format_pct(rate_up_300_row['avg_apr'])}\n"
    f"  Payment: {format_dollars(rate_up_300_row['avg_monthly_payment'])}\n"
    f"  PTI: {format_pct(rate_up_300_row['avg_pti'])}\n"
    f"  Avg EL: {format_dollars_k(rate_up_300_row['avg_expected_loss'])}\n\n"
    "Synthetic-PD proxy:\n"
    f"  {format_pct(rate_down_row['avg_pd'])} → "
    f"{format_pct(rate_up_300_row['avg_pd'])}"
)

fig.text(
    0.805,
    0.52,
    raw_value_text,
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
    "Rate-environment scenarios are indexed to the BASELINE_V2 portfolio. "
    "The panel shows how a controlled rate shift propagates through APR, monthly payment, PTI, "
    "and Expected Loss. This demonstrates scenario transmission rather than forecasting: the same "
    "synthetic population is tested under governed assumptions."
)

fig.text(
    CONTENT_CENTER_X,
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
    facecolor=fig.get_facecolor(),
)

fig.savefig(
    OUTPUT_SVG,
    facecolor=fig.get_facecolor(),
)

plt.close(fig)

print(f"Saved PNG: {OUTPUT_PNG}")
print(f"Saved SVG: {OUTPUT_SVG}")

print("\nPanel data used:")
for _, row in df.iterrows():
    print(
        f"{row['scenario_name']:<18} | "
        f"Apps: {int(row['applications']):>5,} | "
        f"APR: {format_pct(row['avg_apr']):>7} | "
        f"Payment: {format_dollars(row['avg_monthly_payment']):>8} | "
        f"PTI: {format_pct(row['avg_pti']):>7} | "
        f"PD proxy: {format_pct(row['avg_pd']):>7} | "
        f"Avg EL: {format_dollars_k(row['avg_expected_loss']):>7} | "
        f"Total EL: {format_total_loss_m(row['total_expected_loss']):>8}"
    )

print("\nIndexed values:")
for _, row in df.iterrows():
    print(
        f"{row['scenario_name']:<18} | "
        f"APR index: {row['avg_apr_index']:>6.1f} | "
        f"Payment index: {row['avg_monthly_payment_index']:>6.1f} | "
        f"PTI index: {row['avg_pti_index']:>6.1f} | "
        f"Avg EL index: {row['avg_expected_loss_index']:>6.1f}"
    )
```
<!-- END_MESSAGE C040-M02458 -->


---

<a id="c040-m02460"></a>

### C040-M02460

**Andrew** · 2026-05-27T02:32:51.241000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02460 -->
do not generate image.  update python code and provide full copy paste. the Rate Down blue bubble - please place to the right of the dots, not on top of them.  I like how rate up blue bubble was placed in between rateup 200 and rate up 300 perfectly so it wasn't on top of the dots, but the rate down 200 bubble is right on top of the dots.
<!-- END_MESSAGE C040-M02460 -->


---

<a id="c040-m02462"></a>

### C040-M02462

**ChatGPT** · 2026-05-27T02:40:22.555093-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02462 -->
Updated full Python code below. The only substantive placement change is the **Rate-down callout**, moved to the right of the leftmost dots by changing its axes-position from the lower-left corner to a position between `RATE_DOWN_200BP` and `BASELINE_V2`.

```python
"""
Module 1 README Panel 2
Scenario Transmission Chain: Rate Environment → APR → Payment → PTI → Expected Loss

This version uses hardcoded final-campaign Section 10.02 values.

Panel thesis:
    Module 1 is not just a static synthetic population generator.
    It is scenario-capable: controlled rate-environment changes transmit through
    APR, monthly payment burden, PTI, and Expected Loss.

Data source:
    Final campaign Section 10.02:
    Portfolio-level scenario summary.

Data scope:
    scenario_set_name = MODULE1_V2_BASELINE_SET
    population_id     = BASE_POPULATION_V1

Scenario family:
    RATE_DOWN_200BP
    BASELINE_V2
    RATE_UP_200BP
    RATE_UP_300BP

Chart design:
    Indexed multi-line chart.

    Each metric is indexed to:
        BASELINE_V2 = 100

    Lines:
        Avg APR
        Avg Monthly Payment
        Avg PTI
        Avg Expected Loss

Interpretation:
    This is controlled scenario sensitivity, not a market forecast.
    The point is directional transmission through the governed synthetic-risk chain.

Output:
    assets/module1_scenario_transmission_chain.png
    assets/module1_scenario_transmission_chain.svg
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

OUTPUT_PNG = OUTPUT_DIR / "module1_scenario_transmission_chain.png"
OUTPUT_SVG = OUTPUT_DIR / "module1_scenario_transmission_chain.svg"


# =============================================================================
# 2. HARDCODED SECTION 10.02 PORTFOLIO-LEVEL SCENARIO DATA
# =============================================================================

SCENARIO_DATA = [
    {
        "scenario_set_name": "MODULE1_V2_BASELINE_SET",
        "scenario_name": "RATE_DOWN_200BP",
        "display_label": "Rate Down\n200bp",
        "population_id": "BASE_POPULATION_V1",
        "applications": 50000,
        "avg_requested_amount": 133390.33,
        "avg_apr": 0.1285,
        "avg_monthly_payment": 1385.24,
        "avg_pti": 0.1535,
        "avg_pd": 0.1627,
        "avg_lgd": 0.4923,
        "avg_expected_loss": 4765.49,
        "total_expected_loss": 238274612.94,
    },
    {
        "scenario_set_name": "MODULE1_V2_BASELINE_SET",
        "scenario_name": "BASELINE_V2",
        "display_label": "Baseline",
        "population_id": "BASE_POPULATION_V1",
        "applications": 50000,
        "avg_requested_amount": 133329.28,
        "avg_apr": 0.1456,
        "avg_monthly_payment": 1510.70,
        "avg_pti": 0.1650,
        "avg_pd": 0.1634,
        "avg_lgd": 0.4923,
        "avg_expected_loss": 4788.67,
        "total_expected_loss": 239433477.53,
    },
    {
        "scenario_set_name": "MODULE1_V2_BASELINE_SET",
        "scenario_name": "RATE_UP_200BP",
        "display_label": "Rate Up\n200bp",
        "population_id": "BASE_POPULATION_V1",
        "applications": 50000,
        "avg_requested_amount": 133208.64,
        "avg_apr": 0.1614,
        "avg_monthly_payment": 1612.00,
        "avg_pti": 0.1741,
        "avg_pd": 0.1639,
        "avg_lgd": 0.4923,
        "avg_expected_loss": 4804.46,
        "total_expected_loss": 240223118.88,
    },
    {
        "scenario_set_name": "MODULE1_V2_BASELINE_SET",
        "scenario_name": "RATE_UP_300BP",
        "display_label": "Rate Up\n300bp",
        "population_id": "BASE_POPULATION_V1",
        "applications": 50000,
        "avg_requested_amount": 133164.06,
        "avg_apr": 0.1685,
        "avg_monthly_payment": 1645.42,
        "avg_pti": 0.1771,
        "avg_pd": 0.1640,
        "avg_lgd": 0.4923,
        "avg_expected_loss": 4809.80,
        "total_expected_loss": 240489995.27,
    },
]


# =============================================================================
# 3. CHART STYLE SETTINGS
# =============================================================================

SCENARIO_ORDER = [
    "RATE_DOWN_200BP",
    "BASELINE_V2",
    "RATE_UP_200BP",
    "RATE_UP_300BP",
]

FIG_FACE = "black"
AX_FACE = "black"
TEXT_COLOR = "white"
GRID_COLOR = "white"
BASELINE_LINE_COLOR = "white"
CALLOUT_BOX_COLOR = "#4f8fc4"

# Dark README dashboard palette.
APR_COLOR = "#2f84c4"
PAYMENT_COLOR = "#f0a62e"
PTI_COLOR = "#2ca02c"
EXPECTED_LOSS_COLOR = "#d95f5f"

LINE_WIDTH = 2.3
MARKER_SIZE = 7.0

# Center x-position for title / subtitle / footer.
CONTENT_CENTER_X = 0.50


# =============================================================================
# 4. HELPER FUNCTIONS
# =============================================================================

def format_pct(value: float) -> str:
    """Format a decimal as percent."""
    return f"{value * 100:.2f}%"


def format_dollars(value: float) -> str:
    """Format dollars without decimals."""
    return f"${value:,.0f}"


def format_dollars_k(value: float) -> str:
    """Format dollars as $K."""
    return f"${value / 1000:.1f}K"


def format_total_loss_m(value: float) -> str:
    """Format total Expected Loss as $M."""
    return f"${value / 1_000_000:.1f}M"


def index_to_baseline(series: pd.Series, baseline_value: float) -> pd.Series:
    """Index a metric so BASELINE_V2 equals 100."""
    return 100.0 * series / baseline_value


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


# =============================================================================
# 5. PREPARE DATA
# =============================================================================

df = pd.DataFrame(SCENARIO_DATA)

df["scenario_name"] = pd.Categorical(
    df["scenario_name"],
    categories=SCENARIO_ORDER,
    ordered=True,
)

df = df.sort_values("scenario_name").reset_index(drop=True)
df["x"] = range(len(df))

baseline_row = df.loc[df["scenario_name"] == "BASELINE_V2"].iloc[0]

METRIC_SPECS = [
    {
        "metric_label": "Avg APR",
        "short_label": "APR",
        "column": "avg_apr",
        "indexed_column": "avg_apr_index",
        "color": APR_COLOR,
        "raw_formatter": format_pct,
    },
    {
        "metric_label": "Avg Monthly Payment",
        "short_label": "Payment",
        "column": "avg_monthly_payment",
        "indexed_column": "avg_monthly_payment_index",
        "color": PAYMENT_COLOR,
        "raw_formatter": format_dollars,
    },
    {
        "metric_label": "Avg PTI",
        "short_label": "PTI",
        "column": "avg_pti",
        "indexed_column": "avg_pti_index",
        "color": PTI_COLOR,
        "raw_formatter": format_pct,
    },
    {
        "metric_label": "Avg Expected Loss",
        "short_label": "Avg EL",
        "column": "avg_expected_loss",
        "indexed_column": "avg_expected_loss_index",
        "color": EXPECTED_LOSS_COLOR,
        "raw_formatter": format_dollars_k,
    },
]

for spec in METRIC_SPECS:
    baseline_value = baseline_row[spec["column"]]
    df[spec["indexed_column"]] = index_to_baseline(df[spec["column"]], baseline_value)

indexed_columns = [spec["indexed_column"] for spec in METRIC_SPECS]

min_index_value = df[indexed_columns].min().min()
max_index_value = df[indexed_columns].max().max()

y_min = min(86, min_index_value - 2.0)
y_max = max(118, max_index_value + 2.0)

rate_down_row = df.loc[df["scenario_name"] == "RATE_DOWN_200BP"].iloc[0]
rate_up_300_row = df.loc[df["scenario_name"] == "RATE_UP_300BP"].iloc[0]


# =============================================================================
# 6. BUILD CHART
# =============================================================================

fig = plt.figure(figsize=(15.2, 7.4), dpi=160)
fig.patch.set_facecolor(FIG_FACE)

# Manual layout:
#   ax = indexed line chart
#   right-side figure text = interpretation / raw value readout
#
# No bbox_inches="tight" is used during export so title / footer centering
# remains visually stable.
ax = fig.add_axes([0.08, 0.18, 0.69, 0.64])
style_dark_axis(ax)

# Baseline reference lines.
ax.axvline(
    x=1,
    color=BASELINE_LINE_COLOR,
    linewidth=1.0,
    linestyle="--",
    alpha=0.65,
)

ax.axhline(
    y=100,
    color=BASELINE_LINE_COLOR,
    linewidth=1.0,
    linestyle="--",
    alpha=0.65,
)

# Plot indexed metric lines.
for spec in METRIC_SPECS:
    ax.plot(
        df["x"],
        df[spec["indexed_column"]],
        marker="o",
        markersize=MARKER_SIZE,
        linewidth=LINE_WIDTH,
        color=spec["color"],
        label=spec["metric_label"],
    )

# X axis.
ax.set_xticks(df["x"])
ax.set_xticklabels(
    df["display_label"],
    color=TEXT_COLOR,
    fontsize=9.5,
)

ax.set_xlabel(
    "Rate Environment Scenario",
    color=TEXT_COLOR,
    fontsize=10.5,
    labelpad=10,
)

# Y axis.
ax.set_ylabel(
    "Index vs Baseline",
    color=TEXT_COLOR,
    fontsize=10.5,
    labelpad=10,
)

ax.set_ylim(y_min, y_max)
ax.yaxis.set_major_formatter(mtick.FuncFormatter(lambda value, _: f"{value:.0f}"))

# Baseline label.
ax.text(
    1.0,
    100.6,
    "Baseline = 100",
    ha="center",
    va="bottom",
    fontsize=8.5,
    color=TEXT_COLOR,
    bbox={
        "boxstyle": "round,pad=0.28",
        "facecolor": AX_FACE,
        "edgecolor": TEXT_COLOR,
        "alpha": 0.80,
    },
)

# Right endpoint labels.
# Slight manual offsets keep the labels separated when lines are close.
ENDPOINT_LABEL_OFFSETS = {
    "Avg APR": 0.2,
    "Avg Monthly Payment": 0.0,
    "Avg PTI": -0.8,
    "Avg Expected Loss": -1.3,
}

for spec in METRIC_SPECS:
    final_value = rate_up_300_row[spec["indexed_column"]]
    raw_value = rate_up_300_row[spec["column"]]
    y_offset = ENDPOINT_LABEL_OFFSETS.get(spec["metric_label"], 0.0)

    ax.text(
        rate_up_300_row["x"] + 0.10,
        final_value + y_offset,
        f"{spec['short_label']} {final_value:.1f}\n({spec['raw_formatter'](raw_value)})",
        ha="left",
        va="center",
        fontsize=8.3,
        color=spec["color"],
        fontweight="bold",
    )

# Give room for endpoint labels inside the axis.
ax.set_xlim(-0.15, 3.55)

# Legend.
legend = ax.legend(
    loc="upper left",
    fontsize=8.2,
    frameon=True,
    title="Indexed metric",
    title_fontsize=8.7,
)

legend.get_frame().set_facecolor(AX_FACE)
legend.get_frame().set_edgecolor(TEXT_COLOR)
for text in legend.get_texts():
    text.set_color(TEXT_COLOR)
legend.get_title().set_color(TEXT_COLOR)

# Callout: rate-down side.
# Placed to the right of the Rate Down 200bp dots, between Rate Down and Baseline,
# so it does not sit directly on top of the leftmost line markers.
ax.text(
    0.23,
    0.13,
    "Rate-down:\nlower APR,\npayment burden,\nand PTI",
    transform=ax.transAxes,
    fontsize=8.6,
    va="bottom",
    ha="left",
    color=TEXT_COLOR,
    bbox={
        "boxstyle": "round,pad=0.42",
        "facecolor": CALLOUT_BOX_COLOR,
        "edgecolor": CALLOUT_BOX_COLOR,
        "alpha": 0.88,
    },
)

# Callout: rate-up side.
ax.text(
    0.63,
    0.94,
    "Rate-up:\nAPR pressure flows\nthrough payment and PTI;\nEL moves modestly",
    transform=ax.transAxes,
    fontsize=8.6,
    va="top",
    ha="left",
    color=TEXT_COLOR,
    bbox={
        "boxstyle": "round,pad=0.42",
        "facecolor": CALLOUT_BOX_COLOR,
        "edgecolor": CALLOUT_BOX_COLOR,
        "alpha": 0.88,
    },
)

# Titles.
fig.suptitle(
    "Scenario Transmission Chain",
    fontsize=20,
    fontweight="bold",
    color=TEXT_COLOR,
    x=CONTENT_CENTER_X,
    y=0.970,
)

fig.text(
    CONTENT_CENTER_X,
    0.925,
    "Rate Environment → APR → Payment → PTI → Expected Loss",
    ha="center",
    va="center",
    fontsize=12.0,
    color=TEXT_COLOR,
)

fig.text(
    CONTENT_CENTER_X,
    0.888,
    "Portfolio-level rate-environment sensitivity indexed to BASELINE_V2 = 100",
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

# Right-side interpretation / raw value box.
raw_value_text = (
    "How to read:\n\n"
    "Each line is indexed\n"
    "to baseline = 100.\n\n"
    "Controlled sensitivity,\n"
    "not a market forecast.\n\n"
    "Baseline portfolio:\n"
    f"  APR: {format_pct(baseline_row['avg_apr'])}\n"
    f"  Payment: {format_dollars(baseline_row['avg_monthly_payment'])}\n"
    f"  PTI: {format_pct(baseline_row['avg_pti'])}\n"
    f"  Avg EL: {format_dollars_k(baseline_row['avg_expected_loss'])}\n\n"
    "Rate Up 300bp:\n"
    f"  APR: {format_pct(rate_up_300_row['avg_apr'])}\n"
    f"  Payment: {format_dollars(rate_up_300_row['avg_monthly_payment'])}\n"
    f"  PTI: {format_pct(rate_up_300_row['avg_pti'])}\n"
    f"  Avg EL: {format_dollars_k(rate_up_300_row['avg_expected_loss'])}\n\n"
    "Synthetic-PD proxy:\n"
    f"  {format_pct(rate_down_row['avg_pd'])} → "
    f"{format_pct(rate_up_300_row['avg_pd'])}"
)

fig.text(
    0.805,
    0.52,
    raw_value_text,
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
    "Rate-environment scenarios are indexed to the BASELINE_V2 portfolio. "
    "The panel shows how a controlled rate shift propagates through APR, monthly payment, PTI, "
    "and Expected Loss. This demonstrates scenario transmission rather than forecasting: the same "
    "synthetic population is tested under governed assumptions."
)

fig.text(
    CONTENT_CENTER_X,
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
    facecolor=fig.get_facecolor(),
)

fig.savefig(
    OUTPUT_SVG,
    facecolor=fig.get_facecolor(),
)

plt.close(fig)

print(f"Saved PNG: {OUTPUT_PNG}")
print(f"Saved SVG: {OUTPUT_SVG}")

print("\nPanel data used:")
for _, row in df.iterrows():
    print(
        f"{row['scenario_name']:<18} | "
        f"Apps: {int(row['applications']):>5,} | "
        f"APR: {format_pct(row['avg_apr']):>7} | "
        f"Payment: {format_dollars(row['avg_monthly_payment']):>8} | "
        f"PTI: {format_pct(row['avg_pti']):>7} | "
        f"PD proxy: {format_pct(row['avg_pd']):>7} | "
        f"Avg EL: {format_dollars_k(row['avg_expected_loss']):>7} | "
        f"Total EL: {format_total_loss_m(row['total_expected_loss']):>8}"
    )

print("\nIndexed values:")
for _, row in df.iterrows():
    print(
        f"{row['scenario_name']:<18} | "
        f"APR index: {row['avg_apr_index']:>6.1f} | "
        f"Payment index: {row['avg_monthly_payment_index']:>6.1f} | "
        f"PTI index: {row['avg_pti_index']:>6.1f} | "
        f"Avg EL index: {row['avg_expected_loss_index']:>6.1f}"
    )
```
<!-- END_MESSAGE C040-M02462 -->


---

<a id="c040-m02464"></a>

### C040-M02464

**Andrew** · 2026-05-27T02:49:33.770000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02464 -->
do not generate image or python code. lets lockdown the module 1 panel 3 spec in this next prompt.
<!-- END_MESSAGE C040-M02464 -->


---

<a id="c040-m02467"></a>

### C040-M02467

**ChatGPT** · 2026-05-27T02:56:19.393520-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02467 -->
## Module 1 Panel 3 framework locked: Matched Rate-Shock Attribution

### Panel title

```text
Matched Rate-Shock Attribution
Same Population, Controlled Scenario Delta
```

Recommended subtitle:

```text
BASELINE_V2 → RATE_UP_200BP | 50,000 matched applications
```

This panel should complete the Module 1 collage by proving the **matched-comparison discipline** behind the engine. Panel 1 shows the baseline risk surface. Panel 2 shows rate-environment transmission. Panel 3 should show **where the controlled rate shock landed** across product and score segments.

Module 1’s design explicitly depends on deterministic population generation and scenario comparison: the engine uses stable populations so scenarios can be evaluated without population noise, and the validation summary confirms row-level matched scenario comparison as a validated capability. fileciteturn49file89

---

# 1. What Panel 3 is trying to demonstrate

Panel 3 should answer:

> **When the same 50,000 synthetic applicants are compared under BASELINE_V2 and RATE_UP_200BP, which product and score segments absorb the Expected Loss movement?**

The reader should see:

```text
1. The comparison is matched:
   same population_id, same application population, controlled scenario delta.

2. The rate shock has measurable but governed impact:
   APR, monthly payment, PTI, synthetic-PD proxy, and Expected Loss move directionally.

3. The impact is not evenly distributed:
   product structure and score composition determine where the Expected Loss delta concentrates.

4. HELOC / Mortgage / Auto absorb more of the total EL movement than smaller-balance unsecured or revolving segments.
```

This reinforces Module 1’s core thesis: credit risk is not only borrower profile; it is shaped by loan structure, affordability, and macro/rate environment. fileciteturn49file88

---

# 2. Why this panel adds value versus Panels 1 and 2

Panel 1 says:

```text
The baseline synthetic portfolio is product-aware and score-aware.
```

Panel 2 says:

```text
Rate environment changes transmit through APR, payment, PTI, and Expected Loss.
```

Panel 3 says:

```text
The scenario movement can be attributed back to matched product × score cells.
```

So the three panels form a clean Module 1 story:

```text
Panel 1:
    Cross-sectional risk realism.

Panel 2:
    Scenario transmission realism.

Panel 3:
    Matched attribution / comparison discipline.
```

Panel 3 should not duplicate the line chart from Panel 2. It should show **where** the shock concentrated, not merely that the shock transmitted.

---

# 3. Data sources

Use two Section 10 QA outputs:

```text
10.04B — matched row-level delta summary
10.04C — matched row-level delta summary by product and score band
```

Use **10.04B** for the compact matched-comparison readout:

```text
matched rows
average APR delta
average monthly payment delta
average PTI delta
average synthetic-PD proxy delta
average Expected Loss delta
```

Use **10.04C** for the actual chart:

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

Do **not** use 10.04A for the panel. The row-level sample is useful as appendix evidence, but it is too granular for a README collage panel.

---

# 4. Scenario comparison scope

Lock the comparison to:

```text
BASELINE_V2 → RATE_UP_200BP
population_id = BASE_POPULATION_V1
matched_rows = 50,000
```

This is the right comparison because it is a clean, interpretable rate shock and matches the Panel 2 rate-transmission story. Panel 2 shows the rate ladder; Panel 3 deepens one representative rate-up comparison.

---

# 5. Recommended chart type

Use a **stacked horizontal bar chart**.

### Y-axis

```text
product_type
```

Order by total Expected Loss delta, descending:

```text
HELOC
MORTGAGE
AUTO_LOAN
UNSECURED_PERSONAL_LOAN
REVOLVING_LINE
```

This order is better than the Panel 1 product order because Panel 3 is an attribution chart. The most impacted product should appear first.

### X-axis

```text
Total Expected Loss Delta ($K)
```

### Stack segments

```text
score_band contribution
```

Stack order:

```text
SUPER_PRIME
PRIME
NEAR_PRIME
SUBPRIME
DEEP_SUBPRIME
```

This shows not only which products moved most, but which score bands contributed to the movement inside each product.

---

# 6. Metric to plot

Use:

```text
total_delta_expected_loss
```

converted to:

```text
$K
```

Do **not** use `avg_delta_expected_loss` as the bar length. Average deltas are useful, but Panel 3 is answering an attribution question:

> **Where did the portfolio-level Expected Loss movement concentrate?**

That requires total contribution, not only average per-row sensitivity.

---

# 7. Expected readout / approximate values

The product-level total Expected Loss delta should be approximately:

```text
HELOC:
    +$341K

MORTGAGE:
    +$168K

AUTO_LOAN:
    +$156K

UNSECURED_PERSONAL_LOAN:
    +$77K

REVOLVING_LINE:
    +$48K
```

Overall matched shock readout from 10.04B:

```text
matched rows:
    50,000

avg APR delta:
    +1.58 percentage points

avg monthly payment delta:
    +$101

avg PTI delta:
    +0.90 percentage points

avg synthetic-PD proxy delta:
    approximately +0.05 percentage points

avg Expected Loss delta:
    +$15.79

total implied Expected Loss delta:
    approximately +$0.79M
```

The exact values should come from the final 10.04B and 10.04C files when hardcoded.

---

# 8. Top product × score callouts

Use two or three callouts only.

Recommended callouts:

```text
HELOC × Near Prime:
    largest product-score contribution
    approx +$203K total EL delta

HELOC × Prime:
    approx +$108K total EL delta

Mortgage × Prime:
    approx +$92K total EL delta
```

If space is tight, move these into the right-side interpretation box instead of annotating the bars directly.

---

# 9. Right-side interpretation box

Panel 3 should include a compact blue readout box, consistent with the prior dark dashboard style.

Suggested text:

```text
Matched shock readout:

50,000 same applications

Rate Up 200bp vs Baseline:
APR: +1.58pp
Payment: +$101
PTI: +0.90pp
Avg EL: +$15.79

Total EL delta:
≈ +$0.79M

Largest driver:
HELOC × Near Prime
≈ +$203K
```

This makes the chart self-contained. A reader can understand the comparison without needing to inspect the raw table.

---

# 10. Legend and color strategy

Use a score-band legend:

```text
Super Prime
Prime
Near Prime
Subprime
Deep Subprime
```

Use a clear categorical or ordinal palette. Since score quality has natural ordering, use a gradient-like sequence where weaker score bands become visually more intense.

Example interpretation:

```text
lighter / cooler = stronger score band
brighter / warmer = weaker score band
```

But do not rely entirely on color for meaning; the legend must be explicit.

---

# 11. Labels

Use:

```text
bar-end labels = total product-level EL delta
```

Example:

```text
+$341K
+$168K
+$156K
+$77K
+$48K
```

Inside-stack labels should be limited. Label only segments above a materiality threshold, for example:

```text
label segments >= $50K
```

or label only the top three product-score contributors.

This keeps the panel readable in a collage.

---

# 12. Caption

Recommended README caption:

```text
The matched rate-shock attribution panel compares the same 50,000 synthetic applications under BASELINE_V2 and RATE_UP_200BP. Bars show total Expected Loss delta by product, stacked by score-band contribution. This demonstrates that Module 1 can attribute controlled scenario movement without population drift.
```

Short collage caption:

```text
Matched scenario attribution: same applicants, controlled rate shock, product × score Expected Loss delta.
```

---

# 13. What this panel should not do

Do **not** show all 19 scenarios.

Do **not** use the row-level sample from 10.04A.

Do **not** duplicate the Panel 2 indexed line chart.

Do **not** use raw APR / PTI / payment lines again.

Do **not** imply that RATE_UP_200BP is a market forecast. It is a controlled sensitivity scenario.

Do **not** call `avg_pd` a calibrated PD. Label it as:

```text
synthetic-PD proxy
```

or:

```text
estimated-PD proxy
```

---

# 14. Final locked Panel 3 spec

```text
Panel name:
    Matched Rate-Shock Attribution

Purpose:
    Show that Module 1 supports matched scenario comparison and can attribute
    scenario movement by product and score segment.

Source:
    10.04B matched row-level delta summary
    10.04C matched row-level delta summary by product and score band

Comparison:
    BASELINE_V2 → RATE_UP_200BP
    population_id = BASE_POPULATION_V1
    matched_rows = 50,000

Chart type:
    Stacked horizontal bar chart

Rows:
    product_type ordered by total_delta_expected_loss descending

Stack:
    score_band contribution

X-axis:
    Total Expected Loss Delta ($K)

Primary metric:
    total_delta_expected_loss

Bar-end labels:
    product-level total EL delta in $K

Right-side readout:
    matched rows
    avg APR delta
    avg payment delta
    avg PTI delta
    avg Expected Loss delta
    total implied EL delta
    largest product × score driver

Primary message:
    Module 1 supports controlled, matched scenario attribution:
    the same synthetic applicants can be compared row-for-row, and the
    rate-shock impact can be traced to product × score cells rather than
    population drift.
```

This is the right third panel. It completes the Module 1 collage by showing that the engine is not only realistic and scenario-sensitive, but also **comparison-ready and attribution-ready**.
<!-- END_MESSAGE C040-M02467 -->


---

<a id="c040-m02469"></a>

### C040-M02469

**Andrew** · 2026-05-27T02:58:58.603000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02469 -->
do not generate image.  i approve module 1 panel 3 spec.  proceed to write python code to deliver module 1 panel 3 output.
<!-- END_MESSAGE C040-M02469 -->


---

<a id="c040-m02476"></a>

### C040-M02476

**ChatGPT** · 2026-05-27T03:08:19.594538-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02476 -->
```python
"""
Module 1 README Panel 3
Matched Rate-Shock Attribution: Same Population, Controlled Scenario Delta

This version uses hardcoded final-campaign Section 10.04B and 10.04C values.

Panel thesis:
    Module 1 supports matched scenario attribution.

    The same 50,000 synthetic applications can be compared row-for-row under:
        BASELINE_V2
        RATE_UP_200BP

    The panel shows where the controlled rate shock landed by product and score band,
    using total Expected Loss delta as the attribution metric.

Data sources:
    Final campaign Section 10.04B:
        Matched row-level delta summary.

    Final campaign Section 10.04C:
        Matched row-level delta summary by product and score band.

Comparison:
    BASELINE_V2 -> RATE_UP_200BP
    population_id = BASE_POPULATION_V1
    matched_rows = 50,000

Chart design:
    Stacked horizontal bar chart.

    Rows:
        product_type, ordered by total Expected Loss delta descending.

    Stack:
        score_band contribution.

    X-axis:
        Total Expected Loss Delta ($K)

Interpretation:
    This is controlled scenario sensitivity, not a market forecast.
    The point is matched attribution: same applications, controlled rate shock,
    product × score Expected Loss movement.

Output:
    assets/module1_matched_rate_shock_attribution.png
    assets/module1_matched_rate_shock_attribution.svg
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

OUTPUT_PNG = OUTPUT_DIR / "module1_matched_rate_shock_attribution.png"
OUTPUT_SVG = OUTPUT_DIR / "module1_matched_rate_shock_attribution.svg"


# =============================================================================
# 2. HARDCODED SECTION 10.04B MATCHED ROW-LEVEL DELTA SUMMARY
# =============================================================================

MATCHED_SUMMARY = {
    "baseline_scenario_name": "BASELINE_V2",
    "comparison_scenario_name": "RATE_UP_200BP",
    "population_id": "BASE_POPULATION_V1",
    "matched_rows": 50000,
    "avg_delta_requested_amount": -120.64,
    "avg_delta_apr": 0.0158,
    "avg_delta_monthly_payment": 101.30,
    "avg_delta_pti": 0.0090,
    "avg_delta_pd": 0.0005,
    "avg_delta_expected_loss": 15.79,
    "rows_pd_increased": 3367,
    "rows_pd_decreased": 0,
    "rows_pd_unchanged": 46633,
    "rows_el_increased": 3367,
    "rows_el_decreased": 1655,
    "rows_el_unchanged": 44978,
}


# =============================================================================
# 3. HARDCODED SECTION 10.04C PRODUCT × SCORE DELTA DATA
# =============================================================================

ATTRIBUTION_DATA = [
    {
        "product_type": "AUTO_LOAN",
        "score_band": "SUPER_PRIME",
        "matched_rows": 1786,
        "avg_delta_requested_amount": 0.00,
        "avg_delta_apr": 0.0200,
        "avg_delta_monthly_payment": 44.43,
        "avg_delta_pti": 0.0034,
        "avg_delta_pd": 0.0001,
        "avg_delta_expected_loss": 2.42,
        "total_delta_expected_loss": 4325.89,
    },
    {
        "product_type": "AUTO_LOAN",
        "score_band": "PRIME",
        "matched_rows": 2771,
        "avg_delta_requested_amount": 0.00,
        "avg_delta_apr": 0.0200,
        "avg_delta_monthly_payment": 44.54,
        "avg_delta_pti": 0.0041,
        "avg_delta_pd": 0.0003,
        "avg_delta_expected_loss": 9.58,
        "total_delta_expected_loss": 26559.89,
    },
    {
        "product_type": "AUTO_LOAN",
        "score_band": "NEAR_PRIME",
        "matched_rows": 2390,
        "avg_delta_requested_amount": 0.00,
        "avg_delta_apr": 0.0200,
        "avg_delta_monthly_payment": 44.45,
        "avg_delta_pti": 0.0050,
        "avg_delta_pd": 0.0010,
        "avg_delta_expected_loss": 26.00,
        "total_delta_expected_loss": 62139.99,
    },
    {
        "product_type": "AUTO_LOAN",
        "score_band": "SUBPRIME",
        "matched_rows": 1759,
        "avg_delta_requested_amount": 0.00,
        "avg_delta_apr": 0.0200,
        "avg_delta_monthly_payment": 42.80,
        "avg_delta_pti": 0.0069,
        "avg_delta_pd": 0.0016,
        "avg_delta_expected_loss": 33.51,
        "total_delta_expected_loss": 58942.09,
    },
    {
        "product_type": "AUTO_LOAN",
        "score_band": "DEEP_SUBPRIME",
        "matched_rows": 1240,
        "avg_delta_requested_amount": 0.00,
        "avg_delta_apr": 0.0175,
        "avg_delta_monthly_payment": 36.65,
        "avg_delta_pti": 0.0082,
        "avg_delta_pd": 0.0002,
        "avg_delta_expected_loss": 3.07,
        "total_delta_expected_loss": 3812.19,
    },

    {
        "product_type": "HELOC",
        "score_band": "SUPER_PRIME",
        "matched_rows": 900,
        "avg_delta_requested_amount": 0.00,
        "avg_delta_apr": 0.0200,
        "avg_delta_monthly_payment": 257.44,
        "avg_delta_pti": 0.0196,
        "avg_delta_pd": 0.0005,
        "avg_delta_expected_loss": 27.15,
        "total_delta_expected_loss": 24438.70,
    },
    {
        "product_type": "HELOC",
        "score_band": "PRIME",
        "matched_rows": 1326,
        "avg_delta_requested_amount": 0.00,
        "avg_delta_apr": 0.0200,
        "avg_delta_monthly_payment": 240.93,
        "avg_delta_pti": 0.0226,
        "avg_delta_pd": 0.0017,
        "avg_delta_expected_loss": 81.10,
        "total_delta_expected_loss": 107540.20,
    },
    {
        "product_type": "HELOC",
        "score_band": "NEAR_PRIME",
        "matched_rows": 1176,
        "avg_delta_requested_amount": 0.00,
        "avg_delta_apr": 0.0180,
        "avg_delta_monthly_payment": 201.04,
        "avg_delta_pti": 0.0228,
        "avg_delta_pd": 0.0043,
        "avg_delta_expected_loss": 172.65,
        "total_delta_expected_loss": 203039.68,
    },
    {
        "product_type": "HELOC",
        "score_band": "SUBPRIME",
        "matched_rows": 894,
        "avg_delta_requested_amount": 0.00,
        "avg_delta_apr": 0.0017,
        "avg_delta_monthly_payment": 10.40,
        "avg_delta_pti": 0.0016,
        "avg_delta_pd": 0.0003,
        "avg_delta_expected_loss": 6.45,
        "total_delta_expected_loss": 5764.22,
    },
    {
        "product_type": "HELOC",
        "score_band": "DEEP_SUBPRIME",
        "matched_rows": 666,
        "avg_delta_requested_amount": 0.00,
        "avg_delta_apr": 0.0000,
        "avg_delta_monthly_payment": 0.00,
        "avg_delta_pti": 0.0000,
        "avg_delta_pd": 0.0000,
        "avg_delta_expected_loss": 0.00,
        "total_delta_expected_loss": 0.00,
    },

    {
        "product_type": "MORTGAGE",
        "score_band": "SUPER_PRIME",
        "matched_rows": 2747,
        "avg_delta_requested_amount": -983.20,
        "avg_delta_apr": 0.0200,
        "avg_delta_monthly_payment": 577.76,
        "avg_delta_pti": 0.0424,
        "avg_delta_pd": 0.0003,
        "avg_delta_expected_loss": 14.65,
        "total_delta_expected_loss": 40239.11,
    },
    {
        "product_type": "MORTGAGE",
        "score_band": "PRIME",
        "matched_rows": 4285,
        "avg_delta_requested_amount": -767.57,
        "avg_delta_apr": 0.0166,
        "avg_delta_monthly_payment": 405.44,
        "avg_delta_pti": 0.0348,
        "avg_delta_pd": 0.0006,
        "avg_delta_expected_loss": 21.42,
        "total_delta_expected_loss": 91771.89,
    },
    {
        "product_type": "MORTGAGE",
        "score_band": "NEAR_PRIME",
        "matched_rows": 3644,
        "avg_delta_requested_amount": -11.57,
        "avg_delta_apr": 0.0022,
        "avg_delta_monthly_payment": 33.66,
        "avg_delta_pti": 0.0036,
        "avg_delta_pd": 0.0003,
        "avg_delta_expected_loss": 9.77,
        "total_delta_expected_loss": 35606.71,
    },
    {
        "product_type": "MORTGAGE",
        "score_band": "SUBPRIME",
        "matched_rows": 2639,
        "avg_delta_requested_amount": 0.00,
        "avg_delta_apr": 0.0000,
        "avg_delta_monthly_payment": 0.00,
        "avg_delta_pti": 0.0000,
        "avg_delta_pd": 0.0000,
        "avg_delta_expected_loss": 0.00,
        "total_delta_expected_loss": 0.00,
    },
    {
        "product_type": "MORTGAGE",
        "score_band": "DEEP_SUBPRIME",
        "matched_rows": 1750,
        "avg_delta_requested_amount": 0.00,
        "avg_delta_apr": 0.0000,
        "avg_delta_monthly_payment": 0.00,
        "avg_delta_pti": 0.0000,
        "avg_delta_pd": 0.0000,
        "avg_delta_expected_loss": 0.00,
        "total_delta_expected_loss": 0.00,
    },

    {
        "product_type": "REVOLVING_LINE",
        "score_band": "SUPER_PRIME",
        "matched_rows": 2190,
        "avg_delta_requested_amount": 0.00,
        "avg_delta_apr": 0.0200,
        "avg_delta_monthly_payment": 15.84,
        "avg_delta_pti": 0.0012,
        "avg_delta_pd": 0.0000,
        "avg_delta_expected_loss": 0.69,
        "total_delta_expected_loss": 1516.58,
    },
    {
        "product_type": "REVOLVING_LINE",
        "score_band": "PRIME",
        "matched_rows": 3514,
        "avg_delta_requested_amount": 0.00,
        "avg_delta_apr": 0.0200,
        "avg_delta_monthly_payment": 15.00,
        "avg_delta_pti": 0.0014,
        "avg_delta_pd": 0.0001,
        "avg_delta_expected_loss": 1.07,
        "total_delta_expected_loss": 3751.23,
    },
    {
        "product_type": "REVOLVING_LINE",
        "score_band": "NEAR_PRIME",
        "matched_rows": 3025,
        "avg_delta_requested_amount": 0.00,
        "avg_delta_apr": 0.0200,
        "avg_delta_monthly_payment": 14.25,
        "avg_delta_pti": 0.0016,
        "avg_delta_pd": 0.0003,
        "avg_delta_expected_loss": 6.12,
        "total_delta_expected_loss": 18500.24,
    },
    {
        "product_type": "REVOLVING_LINE",
        "score_band": "SUBPRIME",
        "matched_rows": 2220,
        "avg_delta_requested_amount": 0.00,
        "avg_delta_apr": 0.0200,
        "avg_delta_monthly_payment": 13.66,
        "avg_delta_pti": 0.0021,
        "avg_delta_pd": 0.0006,
        "avg_delta_expected_loss": 10.47,
        "total_delta_expected_loss": 23249.53,
    },
    {
        "product_type": "REVOLVING_LINE",
        "score_band": "DEEP_SUBPRIME",
        "matched_rows": 1506,
        "avg_delta_requested_amount": 0.00,
        "avg_delta_apr": 0.0158,
        "avg_delta_monthly_payment": 9.12,
        "avg_delta_pti": 0.0020,
        "avg_delta_pd": 0.0001,
        "avg_delta_expected_loss": 0.92,
        "total_delta_expected_loss": 1380.69,
    },

    {
        "product_type": "UNSECURED_PERSONAL_LOAN",
        "score_band": "SUPER_PRIME",
        "matched_rows": 1361,
        "avg_delta_requested_amount": 0.00,
        "avg_delta_apr": 0.0200,
        "avg_delta_monthly_payment": 30.88,
        "avg_delta_pti": 0.0023,
        "avg_delta_pd": 0.0001,
        "avg_delta_expected_loss": 1.64,
        "total_delta_expected_loss": 2229.76,
    },
    {
        "product_type": "UNSECURED_PERSONAL_LOAN",
        "score_band": "PRIME",
        "matched_rows": 2091,
        "avg_delta_requested_amount": 0.00,
        "avg_delta_apr": 0.0200,
        "avg_delta_monthly_payment": 29.18,
        "avg_delta_pti": 0.0027,
        "avg_delta_pd": 0.0002,
        "avg_delta_expected_loss": 5.45,
        "total_delta_expected_loss": 11389.83,
    },
    {
        "product_type": "UNSECURED_PERSONAL_LOAN",
        "score_band": "NEAR_PRIME",
        "matched_rows": 1838,
        "avg_delta_requested_amount": 0.00,
        "avg_delta_apr": 0.0200,
        "avg_delta_monthly_payment": 28.28,
        "avg_delta_pti": 0.0032,
        "avg_delta_pd": 0.0007,
        "avg_delta_expected_loss": 18.96,
        "total_delta_expected_loss": 34855.88,
    },
    {
        "product_type": "UNSECURED_PERSONAL_LOAN",
        "score_band": "SUBPRIME",
        "matched_rows": 1390,
        "avg_delta_requested_amount": 0.00,
        "avg_delta_apr": 0.0200,
        "avg_delta_monthly_payment": 27.14,
        "avg_delta_pti": 0.0042,
        "avg_delta_pd": 0.0009,
        "avg_delta_expected_loss": 20.36,
        "total_delta_expected_loss": 28303.11,
    },
    {
        "product_type": "UNSECURED_PERSONAL_LOAN",
        "score_band": "DEEP_SUBPRIME",
        "matched_rows": 892,
        "avg_delta_requested_amount": 0.00,
        "avg_delta_apr": 0.0200,
        "avg_delta_monthly_payment": 26.70,
        "avg_delta_pti": 0.0058,
        "avg_delta_pd": 0.0000,
        "avg_delta_expected_loss": 0.32,
        "total_delta_expected_loss": 283.94,
    },
]


# =============================================================================
# 4. CHART STYLE SETTINGS
# =============================================================================

SCORE_ORDER = [
    "SUPER_PRIME",
    "PRIME",
    "NEAR_PRIME",
    "SUBPRIME",
    "DEEP_SUBPRIME",
]

SCORE_LABELS = {
    "SUPER_PRIME": "Super Prime",
    "PRIME": "Prime",
    "NEAR_PRIME": "Near Prime",
    "SUBPRIME": "Subprime",
    "DEEP_SUBPRIME": "Deep Subprime",
}

PRODUCT_LABELS = {
    "HELOC": "HELOC",
    "MORTGAGE": "Mortgage",
    "AUTO_LOAN": "Auto Loan",
    "UNSECURED_PERSONAL_LOAN": "Unsecured\nPersonal Loan",
    "REVOLVING_LINE": "Revolving\nLine",
}

FIG_FACE = "black"
AX_FACE = "black"
TEXT_COLOR = "white"
GRID_COLOR = "white"
BASELINE_LINE_COLOR = "white"
CALLOUT_BOX_COLOR = "#4f8fc4"

# Score bands use an ordered palette: stronger bands are cooler;
# weaker bands are warmer.
SCORE_COLORS = {
    "SUPER_PRIME": "#2f84c4",
    "PRIME": "#5ab4ac",
    "NEAR_PRIME": "#2ca02c",
    "SUBPRIME": "#f0a62e",
    "DEEP_SUBPRIME": "#d95f5f",
}

BAR_ALPHA = 0.92
SEGMENT_LABEL_THRESHOLD_K = 50.0

# Center x-position for title / subtitle / footer.
CONTENT_CENTER_X = 0.50


# =============================================================================
# 5. HELPER FUNCTIONS
# =============================================================================

def format_k(value: float, decimals: int = 0) -> str:
    """Format a dollar value already converted to $K."""
    sign = "+" if value >= 0 else "-"
    return f"{sign}${abs(value):,.{decimals}f}K"


def format_m(value: float, decimals: int = 2) -> str:
    """Format dollar value in dollars as $M."""
    sign = "+" if value >= 0 else "-"
    return f"{sign}${abs(value) / 1_000_000:,.{decimals}f}M"


def format_dollars(value: float, decimals: int = 0) -> str:
    """Format dollars with a sign."""
    sign = "+" if value >= 0 else "-"
    return f"{sign}${abs(value):,.{decimals}f}"


def format_pp(value: float, decimals: int = 2) -> str:
    """Format decimal movement as percentage points."""
    sign = "+" if value >= 0 else "-"
    return f"{sign}{abs(value) * 100:.{decimals}f}pp"


def format_pct(value: float, decimals: int = 2) -> str:
    """Format decimal as percent."""
    return f"{value * 100:.{decimals}f}%"


def format_count(value: float | int) -> str:
    """Format row counts with commas."""
    return f"{int(value):,}"


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
# 6. PREPARE DATA
# =============================================================================

df = pd.DataFrame(ATTRIBUTION_DATA)

df["score_band"] = pd.Categorical(
    df["score_band"],
    categories=SCORE_ORDER,
    ordered=True,
)

df["total_delta_expected_loss_k"] = df["total_delta_expected_loss"] / 1000.0

product_totals = (
    df.groupby("product_type", as_index=False)["total_delta_expected_loss"]
    .sum()
    .sort_values("total_delta_expected_loss", ascending=False)
    .reset_index(drop=True)
)

PRODUCT_ORDER = product_totals["product_type"].tolist()

pivot_k = (
    df.pivot(index="product_type", columns="score_band", values="total_delta_expected_loss_k")
    .reindex(PRODUCT_ORDER)
    .reindex(columns=SCORE_ORDER)
    .fillna(0.0)
)

product_totals["product_label"] = product_totals["product_type"].map(PRODUCT_LABELS)
product_totals["product_label"] = product_totals["product_label"].fillna(product_totals["product_type"])

product_totals["total_delta_expected_loss_k"] = (
    product_totals["total_delta_expected_loss"] / 1000.0
)

total_el_delta_from_segments = df["total_delta_expected_loss"].sum()
total_el_delta_from_summary = (
    MATCHED_SUMMARY["matched_rows"] * MATCHED_SUMMARY["avg_delta_expected_loss"]
)

top_segments = (
    df.sort_values("total_delta_expected_loss", ascending=False)
    .head(3)
    .copy()
)

largest_segment = top_segments.iloc[0]


# =============================================================================
# 7. BUILD CHART
# =============================================================================

fig = plt.figure(figsize=(15.2, 7.4), dpi=160)
fig.patch.set_facecolor(FIG_FACE)

# Manual layout:
#   ax = stacked horizontal attribution chart
#   right-side figure text = matched shock readout
#
# No bbox_inches="tight" is used during export so title / footer centering
# remains visually stable.
ax = fig.add_axes([0.08, 0.18, 0.66, 0.64])
style_dark_axis(ax)

y_positions = list(range(len(PRODUCT_ORDER)))
left = pd.Series([0.0] * len(PRODUCT_ORDER), index=PRODUCT_ORDER)

# Stacked horizontal bars by score-band contribution.
for score_band in SCORE_ORDER:
    values = pivot_k[score_band]
    color = SCORE_COLORS[score_band]

    ax.barh(
        y_positions,
        values,
        left=left.values,
        color=color,
        alpha=BAR_ALPHA,
        label=SCORE_LABELS[score_band],
        height=0.62,
    )

    # Label material segments only.
    for y, product_type in zip(y_positions, PRODUCT_ORDER):
        segment_value = values.loc[product_type]
        segment_start = left.loc[product_type]

        if segment_value >= SEGMENT_LABEL_THRESHOLD_K:
            ax.text(
                segment_start + segment_value / 2.0,
                y,
                f"{SCORE_LABELS[score_band]}\n{format_k(segment_value)}",
                ha="center",
                va="center",
                fontsize=7.6,
                color=text_color_for_hex(color),
                fontweight="bold",
            )

    left = left + values

# Product-level total labels at bar ends.
for y, (_, row) in zip(y_positions, product_totals.iterrows()):
    total_k = row["total_delta_expected_loss_k"]

    ax.text(
        total_k + 8.0,
        y,
        format_k(total_k),
        ha="left",
        va="center",
        fontsize=8.8,
        color=TEXT_COLOR,
        fontweight="bold",
    )

# Axis setup.
ax.set_yticks(y_positions)
ax.set_yticklabels(
    product_totals["product_label"].tolist(),
    color=TEXT_COLOR,
    fontsize=9.5,
)

ax.invert_yaxis()

ax.set_xlabel(
    "Total Expected Loss Delta ($K)",
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

x_max = max(product_totals["total_delta_expected_loss_k"]) * 1.22
ax.set_xlim(0, x_max)

ax.xaxis.set_major_formatter(
    mtick.FuncFormatter(lambda value, _: f"${value:,.0f}K")
)

# Legend.
legend = ax.legend(
    loc="upper right",
    fontsize=8.1,
    frameon=True,
    title="Score-band contribution",
    title_fontsize=8.6,
)

legend.get_frame().set_facecolor(AX_FACE)
legend.get_frame().set_edgecolor(TEXT_COLOR)
for text in legend.get_texts():
    text.set_color(TEXT_COLOR)
legend.get_title().set_color(TEXT_COLOR)

# Titles.
fig.suptitle(
    "Matched Rate-Shock Attribution",
    fontsize=20,
    fontweight="bold",
    color=TEXT_COLOR,
    x=CONTENT_CENTER_X,
    y=0.970,
)

fig.text(
    CONTENT_CENTER_X,
    0.925,
    "Same Population, Controlled Scenario Delta",
    ha="center",
    va="center",
    fontsize=12.0,
    color=TEXT_COLOR,
)

fig.text(
    CONTENT_CENTER_X,
    0.888,
    "BASELINE_V2 → RATE_UP_200BP | 50,000 matched applications | bars = product × score Expected Loss delta",
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

# Right-side matched shock readout.
readout_text = (
    "Matched shock readout:\n\n"
    f"{format_count(MATCHED_SUMMARY['matched_rows'])} same applications\n\n"
    "Rate Up 200bp vs Baseline:\n"
    f"APR: {format_pp(MATCHED_SUMMARY['avg_delta_apr'])}\n"
    f"Payment: {format_dollars(MATCHED_SUMMARY['avg_delta_monthly_payment'])}\n"
    f"PTI: {format_pp(MATCHED_SUMMARY['avg_delta_pti'])}\n"
    f"PD proxy: {format_pp(MATCHED_SUMMARY['avg_delta_pd'])}\n"
    f"Avg EL: {format_dollars(MATCHED_SUMMARY['avg_delta_expected_loss'], decimals=2)}\n\n"
    "Total EL delta:\n"
    f"{format_m(total_el_delta_from_segments)}\n\n"
    "Largest driver:\n"
    f"{largest_segment['product_type'].replace('_', ' ').title()}\n"
    f"× {largest_segment['score_band'].replace('_', ' ').title()}\n"
    f"{format_k(largest_segment['total_delta_expected_loss'] / 1000.0)}"
)

fig.text(
    0.785,
    0.54,
    readout_text,
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

# Secondary top-driver note below the main readout.
top_driver_text = (
    "Top product × score drivers:\n\n"
    + "\n".join(
        [
            f"{idx + 1}. {row['product_type'].replace('_', ' ').title()} "
            f"× {row['score_band'].replace('_', ' ').title()}: "
            f"{format_k(row['total_delta_expected_loss'] / 1000.0)}"
            for idx, (_, row) in enumerate(top_segments.iterrows())
        ]
    )
)

fig.text(
    0.785,
    0.225,
    top_driver_text,
    fontsize=8.1,
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
    "The matched rate-shock attribution panel compares the same 50,000 synthetic applications under "
    "BASELINE_V2 and RATE_UP_200BP. Bars show total Expected Loss delta by product, stacked by score-band "
    "contribution. This demonstrates that Module 1 can attribute controlled scenario movement without "
    "population drift."
)

fig.text(
    CONTENT_CENTER_X,
    0.045,
    "\n".join(textwrap.wrap(caption, width=155)),
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

print(f"Saved PNG: {OUTPUT_PNG}")
print(f"Saved SVG: {OUTPUT_SVG}")

print("\nMatched summary used:")
print(
    f"Matched rows: {format_count(MATCHED_SUMMARY['matched_rows'])} | "
    f"APR Δ: {format_pp(MATCHED_SUMMARY['avg_delta_apr'])} | "
    f"Payment Δ: {format_dollars(MATCHED_SUMMARY['avg_delta_monthly_payment'])} | "
    f"PTI Δ: {format_pp(MATCHED_SUMMARY['avg_delta_pti'])} | "
    f"PD proxy Δ: {format_pp(MATCHED_SUMMARY['avg_delta_pd'])} | "
    f"Avg EL Δ: {format_dollars(MATCHED_SUMMARY['avg_delta_expected_loss'], decimals=2)} | "
    f"Total EL Δ from product × score sum: {format_m(total_el_delta_from_segments)}"
)

print("\nProduct-level total Expected Loss delta:")
for _, row in product_totals.iterrows():
    print(
        f"{row['product_type']:<26} | "
        f"Total EL Δ: {format_k(row['total_delta_expected_loss_k']):>8}"
    )

print("\nTop product × score contributors:")
for _, row in top_segments.iterrows():
    print(
        f"{row['product_type']:<26} | "
        f"{row['score_band']:<14} | "
        f"Matched rows: {format_count(row['matched_rows']):>6} | "
        f"Avg EL Δ: {format_dollars(row['avg_delta_expected_loss'], decimals=2):>9} | "
        f"Total EL Δ: {format_k(row['total_delta_expected_loss'] / 1000.0):>8}"
    )

print("\nFull product × score attribution data used:")
for _, row in df.sort_values(["product_type", "score_band"]).iterrows():
    print(
        f"{row['product_type']:<26} | "
        f"{row['score_band']:<14} | "
        f"Matched rows: {format_count(row['matched_rows']):>6} | "
        f"APR Δ: {format_pp(row['avg_delta_apr']):>8} | "
        f"Payment Δ: {format_dollars(row['avg_delta_monthly_payment']):>7} | "
        f"PTI Δ: {format_pp(row['avg_delta_pti']):>8} | "
        f"PD proxy Δ: {format_pp(row['avg_delta_pd']):>8} | "
        f"Avg EL Δ: {format_dollars(row['avg_delta_expected_loss'], decimals=2):>9} | "
        f"Total EL Δ: {format_k(row['total_delta_expected_loss'] / 1000.0):>8}"
    )
```
<!-- END_MESSAGE C040-M02476 -->


---

<a id="c040-m02477"></a>

### C040-M02477

**Andrew** · 2026-05-27T03:19:06.644000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02477 -->
do not generate image.  update python code (provide full copy paste) to : 1) move the score band contribution legend outside above the matched shock readout blue bubble. 2) tighten up dead space.                                i also wonder about the chart type.  i think it works here because the delta's are all positive.  they increased across the board, but what if that were not the case?  someone reading this chart type might ponder about that.  thoughts?
<!-- END_MESSAGE C040-M02477 -->


---

<a id="c040-m02480"></a>

### C040-M02480

**ChatGPT** · 2026-05-27T03:26:07.717959-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02480 -->
The stacked horizontal bar is appropriate **for this specific RATE_UP_200BP comparison** because all product × score Expected Loss deltas are positive or zero. For a future comparison with mixed positive and negative deltas, I would **not** use this same positive-only stacked chart; I would use a **diverging stacked contribution chart** with positive contributions extending right of zero and negative contributions extending left of zero.  

The updated code below includes a guardrail: if a future hardcoded dataset contains any negative `total_delta_expected_loss`, it raises a clear error rather than silently creating a misleading positive-only stack.

```python
"""
Module 1 README Panel 3
Matched Rate-Shock Attribution: Same Population, Controlled Scenario Delta

This version uses hardcoded final-campaign Section 10.04B and 10.04C values.

Panel thesis:
    Module 1 supports matched scenario attribution.

    The same 50,000 synthetic applications can be compared row-for-row under:
        BASELINE_V2
        RATE_UP_200BP

    The panel shows where the controlled rate shock landed by product and score band,
    using total Expected Loss delta as the attribution metric.

Data sources:
    Final campaign Section 10.04B:
        Matched row-level delta summary.

    Final campaign Section 10.04C:
        Matched row-level delta summary by product and score band.

Comparison:
    BASELINE_V2 -> RATE_UP_200BP
    population_id = BASE_POPULATION_V1
    matched_rows = 50,000

Chart design:
    Stacked horizontal bar chart.

    Rows:
        product_type, ordered by total Expected Loss delta descending.

    Stack:
        score_band contribution.

    X-axis:
        Total Expected Loss Delta ($K)

Interpretation:
    This is controlled scenario sensitivity, not a market forecast.
    The point is matched attribution: same applications, controlled rate shock,
    product × score Expected Loss movement.

Important chart-type boundary:
    This positive-only stacked attribution chart is appropriate for the selected
    RATE_UP_200BP comparison because all displayed product × score Expected Loss
    deltas are positive or zero.

    If a future comparison contains mixed positive and negative deltas, use a
    diverging stacked contribution chart instead.

Output:
    assets/module1_matched_rate_shock_attribution.png
    assets/module1_matched_rate_shock_attribution.svg
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

OUTPUT_PNG = OUTPUT_DIR / "module1_matched_rate_shock_attribution.png"
OUTPUT_SVG = OUTPUT_DIR / "module1_matched_rate_shock_attribution.svg"


# =============================================================================
# 2. HARDCODED SECTION 10.04B MATCHED ROW-LEVEL DELTA SUMMARY
# =============================================================================

MATCHED_SUMMARY = {
    "baseline_scenario_name": "BASELINE_V2",
    "comparison_scenario_name": "RATE_UP_200BP",
    "population_id": "BASE_POPULATION_V1",
    "matched_rows": 50000,
    "avg_delta_requested_amount": -120.64,
    "avg_delta_apr": 0.0158,
    "avg_delta_monthly_payment": 101.30,
    "avg_delta_pti": 0.0090,
    "avg_delta_pd": 0.0005,
    "avg_delta_expected_loss": 15.79,
    "rows_pd_increased": 3367,
    "rows_pd_decreased": 0,
    "rows_pd_unchanged": 46633,
    "rows_el_increased": 3367,
    "rows_el_decreased": 1655,
    "rows_el_unchanged": 44978,
}


# =============================================================================
# 3. HARDCODED SECTION 10.04C PRODUCT × SCORE DELTA DATA
# =============================================================================

ATTRIBUTION_DATA = [
    {
        "product_type": "AUTO_LOAN",
        "score_band": "SUPER_PRIME",
        "matched_rows": 1786,
        "avg_delta_requested_amount": 0.00,
        "avg_delta_apr": 0.0200,
        "avg_delta_monthly_payment": 44.43,
        "avg_delta_pti": 0.0034,
        "avg_delta_pd": 0.0001,
        "avg_delta_expected_loss": 2.42,
        "total_delta_expected_loss": 4325.89,
    },
    {
        "product_type": "AUTO_LOAN",
        "score_band": "PRIME",
        "matched_rows": 2771,
        "avg_delta_requested_amount": 0.00,
        "avg_delta_apr": 0.0200,
        "avg_delta_monthly_payment": 44.54,
        "avg_delta_pti": 0.0041,
        "avg_delta_pd": 0.0003,
        "avg_delta_expected_loss": 9.58,
        "total_delta_expected_loss": 26559.89,
    },
    {
        "product_type": "AUTO_LOAN",
        "score_band": "NEAR_PRIME",
        "matched_rows": 2390,
        "avg_delta_requested_amount": 0.00,
        "avg_delta_apr": 0.0200,
        "avg_delta_monthly_payment": 44.45,
        "avg_delta_pti": 0.0050,
        "avg_delta_pd": 0.0010,
        "avg_delta_expected_loss": 26.00,
        "total_delta_expected_loss": 62139.99,
    },
    {
        "product_type": "AUTO_LOAN",
        "score_band": "SUBPRIME",
        "matched_rows": 1759,
        "avg_delta_requested_amount": 0.00,
        "avg_delta_apr": 0.0200,
        "avg_delta_monthly_payment": 42.80,
        "avg_delta_pti": 0.0069,
        "avg_delta_pd": 0.0016,
        "avg_delta_expected_loss": 33.51,
        "total_delta_expected_loss": 58942.09,
    },
    {
        "product_type": "AUTO_LOAN",
        "score_band": "DEEP_SUBPRIME",
        "matched_rows": 1240,
        "avg_delta_requested_amount": 0.00,
        "avg_delta_apr": 0.0175,
        "avg_delta_monthly_payment": 36.65,
        "avg_delta_pti": 0.0082,
        "avg_delta_pd": 0.0002,
        "avg_delta_expected_loss": 3.07,
        "total_delta_expected_loss": 3812.19,
    },

    {
        "product_type": "HELOC",
        "score_band": "SUPER_PRIME",
        "matched_rows": 900,
        "avg_delta_requested_amount": 0.00,
        "avg_delta_apr": 0.0200,
        "avg_delta_monthly_payment": 257.44,
        "avg_delta_pti": 0.0196,
        "avg_delta_pd": 0.0005,
        "avg_delta_expected_loss": 27.15,
        "total_delta_expected_loss": 24438.70,
    },
    {
        "product_type": "HELOC",
        "score_band": "PRIME",
        "matched_rows": 1326,
        "avg_delta_requested_amount": 0.00,
        "avg_delta_apr": 0.0200,
        "avg_delta_monthly_payment": 240.93,
        "avg_delta_pti": 0.0226,
        "avg_delta_pd": 0.0017,
        "avg_delta_expected_loss": 81.10,
        "total_delta_expected_loss": 107540.20,
    },
    {
        "product_type": "HELOC",
        "score_band": "NEAR_PRIME",
        "matched_rows": 1176,
        "avg_delta_requested_amount": 0.00,
        "avg_delta_apr": 0.0180,
        "avg_delta_monthly_payment": 201.04,
        "avg_delta_pti": 0.0228,
        "avg_delta_pd": 0.0043,
        "avg_delta_expected_loss": 172.65,
        "total_delta_expected_loss": 203039.68,
    },
    {
        "product_type": "HELOC",
        "score_band": "SUBPRIME",
        "matched_rows": 894,
        "avg_delta_requested_amount": 0.00,
        "avg_delta_apr": 0.0017,
        "avg_delta_monthly_payment": 10.40,
        "avg_delta_pti": 0.0016,
        "avg_delta_pd": 0.0003,
        "avg_delta_expected_loss": 6.45,
        "total_delta_expected_loss": 5764.22,
    },
    {
        "product_type": "HELOC",
        "score_band": "DEEP_SUBPRIME",
        "matched_rows": 666,
        "avg_delta_requested_amount": 0.00,
        "avg_delta_apr": 0.0000,
        "avg_delta_monthly_payment": 0.00,
        "avg_delta_pti": 0.0000,
        "avg_delta_pd": 0.0000,
        "avg_delta_expected_loss": 0.00,
        "total_delta_expected_loss": 0.00,
    },

    {
        "product_type": "MORTGAGE",
        "score_band": "SUPER_PRIME",
        "matched_rows": 2747,
        "avg_delta_requested_amount": -983.20,
        "avg_delta_apr": 0.0200,
        "avg_delta_monthly_payment": 577.76,
        "avg_delta_pti": 0.0424,
        "avg_delta_pd": 0.0003,
        "avg_delta_expected_loss": 14.65,
        "total_delta_expected_loss": 40239.11,
    },
    {
        "product_type": "MORTGAGE",
        "score_band": "PRIME",
        "matched_rows": 4285,
        "avg_delta_requested_amount": -767.57,
        "avg_delta_apr": 0.0166,
        "avg_delta_monthly_payment": 405.44,
        "avg_delta_pti": 0.0348,
        "avg_delta_pd": 0.0006,
        "avg_delta_expected_loss": 21.42,
        "total_delta_expected_loss": 91771.89,
    },
    {
        "product_type": "MORTGAGE",
        "score_band": "NEAR_PRIME",
        "matched_rows": 3644,
        "avg_delta_requested_amount": -11.57,
        "avg_delta_apr": 0.0022,
        "avg_delta_monthly_payment": 33.66,
        "avg_delta_pti": 0.0036,
        "avg_delta_pd": 0.0003,
        "avg_delta_expected_loss": 9.77,
        "total_delta_expected_loss": 35606.71,
    },
    {
        "product_type": "MORTGAGE",
        "score_band": "SUBPRIME",
        "matched_rows": 2639,
        "avg_delta_requested_amount": 0.00,
        "avg_delta_apr": 0.0000,
        "avg_delta_monthly_payment": 0.00,
        "avg_delta_pti": 0.0000,
        "avg_delta_pd": 0.0000,
        "avg_delta_expected_loss": 0.00,
        "total_delta_expected_loss": 0.00,
    },
    {
        "product_type": "MORTGAGE",
        "score_band": "DEEP_SUBPRIME",
        "matched_rows": 1750,
        "avg_delta_requested_amount": 0.00,
        "avg_delta_apr": 0.0000,
        "avg_delta_monthly_payment": 0.00,
        "avg_delta_pti": 0.0000,
        "avg_delta_pd": 0.0000,
        "avg_delta_expected_loss": 0.00,
        "total_delta_expected_loss": 0.00,
    },

    {
        "product_type": "REVOLVING_LINE",
        "score_band": "SUPER_PRIME",
        "matched_rows": 2190,
        "avg_delta_requested_amount": 0.00,
        "avg_delta_apr": 0.0200,
        "avg_delta_monthly_payment": 15.84,
        "avg_delta_pti": 0.0012,
        "avg_delta_pd": 0.0000,
        "avg_delta_expected_loss": 0.69,
        "total_delta_expected_loss": 1516.58,
    },
    {
        "product_type": "REVOLVING_LINE",
        "score_band": "PRIME",
        "matched_rows": 3514,
        "avg_delta_requested_amount": 0.00,
        "avg_delta_apr": 0.0200,
        "avg_delta_monthly_payment": 15.00,
        "avg_delta_pti": 0.0014,
        "avg_delta_pd": 0.0001,
        "avg_delta_expected_loss": 1.07,
        "total_delta_expected_loss": 3751.23,
    },
    {
        "product_type": "REVOLVING_LINE",
        "score_band": "NEAR_PRIME",
        "matched_rows": 3025,
        "avg_delta_requested_amount": 0.00,
        "avg_delta_apr": 0.0200,
        "avg_delta_monthly_payment": 14.25,
        "avg_delta_pti": 0.0016,
        "avg_delta_pd": 0.0003,
        "avg_delta_expected_loss": 6.12,
        "total_delta_expected_loss": 18500.24,
    },
    {
        "product_type": "REVOLVING_LINE",
        "score_band": "SUBPRIME",
        "matched_rows": 2220,
        "avg_delta_requested_amount": 0.00,
        "avg_delta_apr": 0.0200,
        "avg_delta_monthly_payment": 13.66,
        "avg_delta_pti": 0.0021,
        "avg_delta_pd": 0.0006,
        "avg_delta_expected_loss": 10.47,
        "total_delta_expected_loss": 23249.53,
    },
    {
        "product_type": "REVOLVING_LINE",
        "score_band": "DEEP_SUBPRIME",
        "matched_rows": 1506,
        "avg_delta_requested_amount": 0.00,
        "avg_delta_apr": 0.0158,
        "avg_delta_monthly_payment": 9.12,
        "avg_delta_pti": 0.0020,
        "avg_delta_pd": 0.0001,
        "avg_delta_expected_loss": 0.92,
        "total_delta_expected_loss": 1380.69,
    },

    {
        "product_type": "UNSECURED_PERSONAL_LOAN",
        "score_band": "SUPER_PRIME",
        "matched_rows": 1361,
        "avg_delta_requested_amount": 0.00,
        "avg_delta_apr": 0.0200,
        "avg_delta_monthly_payment": 30.88,
        "avg_delta_pti": 0.0023,
        "avg_delta_pd": 0.0001,
        "avg_delta_expected_loss": 1.64,
        "total_delta_expected_loss": 2229.76,
    },
    {
        "product_type": "UNSECURED_PERSONAL_LOAN",
        "score_band": "PRIME",
        "matched_rows": 2091,
        "avg_delta_requested_amount": 0.00,
        "avg_delta_apr": 0.0200,
        "avg_delta_monthly_payment": 29.18,
        "avg_delta_pti": 0.0027,
        "avg_delta_pd": 0.0002,
        "avg_delta_expected_loss": 5.45,
        "total_delta_expected_loss": 11389.83,
    },
    {
        "product_type": "UNSECURED_PERSONAL_LOAN",
        "score_band": "NEAR_PRIME",
        "matched_rows": 1838,
        "avg_delta_requested_amount": 0.00,
        "avg_delta_apr": 0.0200,
        "avg_delta_monthly_payment": 28.28,
        "avg_delta_pti": 0.0032,
        "avg_delta_pd": 0.0007,
        "avg_delta_expected_loss": 18.96,
        "total_delta_expected_loss": 34855.88,
    },
    {
        "product_type": "UNSECURED_PERSONAL_LOAN",
        "score_band": "SUBPRIME",
        "matched_rows": 1390,
        "avg_delta_requested_amount": 0.00,
        "avg_delta_apr": 0.0200,
        "avg_delta_monthly_payment": 27.14,
        "avg_delta_pti": 0.0042,
        "avg_delta_pd": 0.0009,
        "avg_delta_expected_loss": 20.36,
        "total_delta_expected_loss": 28303.11,
    },
    {
        "product_type": "UNSECURED_PERSONAL_LOAN",
        "score_band": "DEEP_SUBPRIME",
        "matched_rows": 892,
        "avg_delta_requested_amount": 0.00,
        "avg_delta_apr": 0.0200,
        "avg_delta_monthly_payment": 26.70,
        "avg_delta_pti": 0.0058,
        "avg_delta_pd": 0.0000,
        "avg_delta_expected_loss": 0.32,
        "total_delta_expected_loss": 283.94,
    },
]


# =============================================================================
# 4. CHART STYLE SETTINGS
# =============================================================================

SCORE_ORDER = [
    "SUPER_PRIME",
    "PRIME",
    "NEAR_PRIME",
    "SUBPRIME",
    "DEEP_SUBPRIME",
]

SCORE_LABELS = {
    "SUPER_PRIME": "Super Prime",
    "PRIME": "Prime",
    "NEAR_PRIME": "Near Prime",
    "SUBPRIME": "Subprime",
    "DEEP_SUBPRIME": "Deep Subprime",
}

PRODUCT_LABELS = {
    "HELOC": "HELOC",
    "MORTGAGE": "Mortgage",
    "AUTO_LOAN": "Auto Loan",
    "UNSECURED_PERSONAL_LOAN": "Unsecured\nPersonal Loan",
    "REVOLVING_LINE": "Revolving\nLine",
}

FIG_FACE = "black"
AX_FACE = "black"
TEXT_COLOR = "white"
GRID_COLOR = "white"
CALLOUT_BOX_COLOR = "#4f8fc4"

# Score bands use an ordered palette: stronger bands are cooler;
# weaker bands are warmer.
SCORE_COLORS = {
    "SUPER_PRIME": "#2f84c4",
    "PRIME": "#5ab4ac",
    "NEAR_PRIME": "#2ca02c",
    "SUBPRIME": "#f0a62e",
    "DEEP_SUBPRIME": "#d95f5f",
}

BAR_ALPHA = 0.92
SEGMENT_LABEL_THRESHOLD_K = 50.0

# Center x-position for title / subtitle / footer.
CONTENT_CENTER_X = 0.50


# =============================================================================
# 5. HELPER FUNCTIONS
# =============================================================================

def format_k(value: float, decimals: int = 0) -> str:
    """Format a dollar value already converted to $K."""
    sign = "+" if value >= 0 else "-"
    return f"{sign}${abs(value):,.{decimals}f}K"


def format_m(value: float, decimals: int = 2) -> str:
    """Format dollar value in dollars as $M."""
    sign = "+" if value >= 0 else "-"
    return f"{sign}${abs(value) / 1_000_000:,.{decimals}f}M"


def format_dollars(value: float, decimals: int = 0) -> str:
    """Format dollars with a sign."""
    sign = "+" if value >= 0 else "-"
    return f"{sign}${abs(value):,.{decimals}f}"


def format_pp(value: float, decimals: int = 2) -> str:
    """Format decimal movement as percentage points."""
    sign = "+" if value >= 0 else "-"
    return f"{sign}{abs(value) * 100:.{decimals}f}pp"


def format_count(value: float | int) -> str:
    """Format row counts with commas."""
    return f"{int(value):,}"


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
# 6. PREPARE DATA
# =============================================================================

df = pd.DataFrame(ATTRIBUTION_DATA)

negative_segments = df.loc[df["total_delta_expected_loss"] < 0].copy()

if not negative_segments.empty:
    raise ValueError(
        "This positive-only stacked attribution chart assumes all "
        "product × score total_delta_expected_loss values are nonnegative. "
        "For mixed-sign scenario comparisons, use a diverging stacked attribution chart instead. "
        "Negative segment(s):\n"
        + negative_segments[
            ["product_type", "score_band", "total_delta_expected_loss"]
        ].to_string(index=False)
    )

df["score_band"] = pd.Categorical(
    df["score_band"],
    categories=SCORE_ORDER,
    ordered=True,
)

df["total_delta_expected_loss_k"] = df["total_delta_expected_loss"] / 1000.0

product_totals = (
    df.groupby("product_type", as_index=False)["total_delta_expected_loss"]
    .sum()
    .sort_values("total_delta_expected_loss", ascending=False)
    .reset_index(drop=True)
)

PRODUCT_ORDER = product_totals["product_type"].tolist()

pivot_k = (
    df.pivot(index="product_type", columns="score_band", values="total_delta_expected_loss_k")
    .reindex(PRODUCT_ORDER)
    .reindex(columns=SCORE_ORDER)
    .fillna(0.0)
)

product_totals["product_label"] = product_totals["product_type"].map(PRODUCT_LABELS)
product_totals["product_label"] = product_totals["product_label"].fillna(product_totals["product_type"])

product_totals["total_delta_expected_loss_k"] = (
    product_totals["total_delta_expected_loss"] / 1000.0
)

total_el_delta_from_segments = df["total_delta_expected_loss"].sum()
total_el_delta_from_summary = (
    MATCHED_SUMMARY["matched_rows"] * MATCHED_SUMMARY["avg_delta_expected_loss"]
)

top_segments = (
    df.sort_values("total_delta_expected_loss", ascending=False)
    .head(3)
    .copy()
)

largest_segment = top_segments.iloc[0]


# =============================================================================
# 7. BUILD CHART
# =============================================================================

fig = plt.figure(figsize=(15.2, 7.4), dpi=160)
fig.patch.set_facecolor(FIG_FACE)

# Manual layout:
#   ax = stacked horizontal attribution chart
#   right-side figure text = legend, matched shock readout, and top-driver readout
#
# No bbox_inches="tight" is used during export so title / footer centering
# remains visually stable.
#
# Layout update:
#   - Chart area widened slightly.
#   - Score-band legend moved outside the plot above the matched shock readout.
#   - Product-level x-axis padding tightened.
ax = fig.add_axes([0.075, 0.18, 0.685, 0.64])
style_dark_axis(ax)

y_positions = list(range(len(PRODUCT_ORDER)))
left = pd.Series([0.0] * len(PRODUCT_ORDER), index=PRODUCT_ORDER)

# Stacked horizontal bars by score-band contribution.
for score_band in SCORE_ORDER:
    values = pivot_k[score_band]
    color = SCORE_COLORS[score_band]

    ax.barh(
        y_positions,
        values,
        left=left.values,
        color=color,
        alpha=BAR_ALPHA,
        label=SCORE_LABELS[score_band],
        height=0.62,
    )

    # Label material segments only.
    for y, product_type in zip(y_positions, PRODUCT_ORDER):
        segment_value = values.loc[product_type]
        segment_start = left.loc[product_type]

        if segment_value >= SEGMENT_LABEL_THRESHOLD_K:
            ax.text(
                segment_start + segment_value / 2.0,
                y,
                f"{SCORE_LABELS[score_band]}\n{format_k(segment_value)}",
                ha="center",
                va="center",
                fontsize=7.6,
                color=text_color_for_hex(color),
                fontweight="bold",
            )

    left = left + values

# Product-level total labels at bar ends.
for y, (_, row) in zip(y_positions, product_totals.iterrows()):
    total_k = row["total_delta_expected_loss_k"]

    ax.text(
        total_k + 5.0,
        y,
        format_k(total_k),
        ha="left",
        va="center",
        fontsize=8.8,
        color=TEXT_COLOR,
        fontweight="bold",
    )

# Axis setup.
ax.set_yticks(y_positions)
ax.set_yticklabels(
    product_totals["product_label"].tolist(),
    color=TEXT_COLOR,
    fontsize=9.5,
)

ax.invert_yaxis()

ax.set_xlabel(
    "Total Expected Loss Delta ($K)",
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

# Tightened x-axis padding.
x_max = max(product_totals["total_delta_expected_loss_k"]) * 1.14
ax.set_xlim(0, x_max)

ax.xaxis.set_major_formatter(
    mtick.FuncFormatter(lambda value, _: f"${value:,.0f}K")
)

# Legend moved outside the chart area, above the matched shock readout.
handles, labels = ax.get_legend_handles_labels()

legend = fig.legend(
    handles,
    labels,
    loc="upper left",
    bbox_to_anchor=(0.785, 0.825),
    fontsize=7.8,
    frameon=True,
    title="Score-band contribution",
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
    "Matched Rate-Shock Attribution",
    fontsize=20,
    fontweight="bold",
    color=TEXT_COLOR,
    x=CONTENT_CENTER_X,
    y=0.970,
)

fig.text(
    CONTENT_CENTER_X,
    0.925,
    "Same Population, Controlled Scenario Delta",
    ha="center",
    va="center",
    fontsize=12.0,
    color=TEXT_COLOR,
)

fig.text(
    CONTENT_CENTER_X,
    0.888,
    "BASELINE_V2 → RATE_UP_200BP | 50,000 matched applications | bars = product × score Expected Loss delta",
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

# Right-side matched shock readout.
readout_text = (
    "Matched shock readout:\n\n"
    f"{format_count(MATCHED_SUMMARY['matched_rows'])} same applications\n\n"
    "Rate Up 200bp vs Baseline:\n"
    f"APR: {format_pp(MATCHED_SUMMARY['avg_delta_apr'])}\n"
    f"Payment: {format_dollars(MATCHED_SUMMARY['avg_delta_monthly_payment'])}\n"
    f"PTI: {format_pp(MATCHED_SUMMARY['avg_delta_pti'])}\n"
    f"PD proxy: {format_pp(MATCHED_SUMMARY['avg_delta_pd'])}\n"
    f"Avg EL: {format_dollars(MATCHED_SUMMARY['avg_delta_expected_loss'], decimals=2)}\n\n"
    "Total EL delta:\n"
    f"{format_m(total_el_delta_from_segments)}\n\n"
    "Chart scope:\n"
    "positive EL contributions\n"
    "under this rate-up shock"
)

fig.text(
    0.785,
    0.505,
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

# Secondary top-driver note below the main readout.
top_driver_text = (
    "Top product × score drivers:\n\n"
    + "\n".join(
        [
            f"{idx + 1}. {row['product_type'].replace('_', ' ').title()} "
            f"× {row['score_band'].replace('_', ' ').title()}: "
            f"{format_k(row['total_delta_expected_loss'] / 1000.0)}"
            for idx, (_, row) in enumerate(top_segments.iterrows())
        ]
    )
)

fig.text(
    0.785,
    0.205,
    top_driver_text,
    fontsize=8.0,
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
    "The matched rate-shock attribution panel compares the same 50,000 synthetic applications under "
    "BASELINE_V2 and RATE_UP_200BP. Bars show total Expected Loss delta by product, stacked by score-band "
    "contribution. This demonstrates that Module 1 can attribute controlled scenario movement without "
    "population drift. For future mixed-sign comparisons, use a diverging attribution chart."
)

fig.text(
    CONTENT_CENTER_X,
    0.045,
    "\n".join(textwrap.wrap(caption, width=155)),
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

print(f"Saved PNG: {OUTPUT_PNG}")
print(f"Saved SVG: {OUTPUT_SVG}")

print("\nMatched summary used:")
print(
    f"Matched rows: {format_count(MATCHED_SUMMARY['matched_rows'])} | "
    f"APR Δ: {format_pp(MATCHED_SUMMARY['avg_delta_apr'])} | "
    f"Payment Δ: {format_dollars(MATCHED_SUMMARY['avg_delta_monthly_payment'])} | "
    f"PTI Δ: {format_pp(MATCHED_SUMMARY['avg_delta_pti'])} | "
    f"PD proxy Δ: {format_pp(MATCHED_SUMMARY['avg_delta_pd'])} | "
    f"Avg EL Δ: {format_dollars(MATCHED_SUMMARY['avg_delta_expected_loss'], decimals=2)} | "
    f"Total EL Δ from product × score sum: {format_m(total_el_delta_from_segments)}"
)

print("\nProduct-level total Expected Loss delta:")
for _, row in product_totals.iterrows():
    print(
        f"{row['product_type']:<26} | "
        f"Total EL Δ: {format_k(row['total_delta_expected_loss_k']):>8}"
    )

print("\nTop product × score contributors:")
for _, row in top_segments.iterrows():
    print(
        f"{row['product_type']:<26} | "
        f"{row['score_band']:<14} | "
        f"Matched rows: {format_count(row['matched_rows']):>6} | "
        f"Avg EL Δ: {format_dollars(row['avg_delta_expected_loss'], decimals=2):>9} | "
        f"Total EL Δ: {format_k(row['total_delta_expected_loss'] / 1000.0):>8}"
    )

print("\nFull product × score attribution data used:")
for _, row in df.sort_values(["product_type", "score_band"]).iterrows():
    print(
        f"{row['product_type']:<26} | "
        f"{row['score_band']:<14} | "
        f"Matched rows: {format_count(row['matched_rows']):>6} | "
        f"APR Δ: {format_pp(row['avg_delta_apr']):>8} | "
        f"Payment Δ: {format_dollars(row['avg_delta_monthly_payment']):>7} | "
        f"PTI Δ: {format_pp(row['avg_delta_pti']):>8} | "
        f"PD proxy Δ: {format_pp(row['avg_delta_pd']):>8} | "
        f"Avg EL Δ: {format_dollars(row['avg_delta_expected_loss'], decimals=2):>9} | "
        f"Total EL Δ: {format_k(row['total_delta_expected_loss'] / 1000.0):>8}"
    )
```
<!-- END_MESSAGE C040-M02480 -->


---

<a id="c040-m02482"></a>

### C040-M02482

**Andrew** · 2026-05-27T03:33:55.553000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02482 -->
do not generate image or python code.  these are good charts, but what about the other scenarios from module 1?  i feel like the rate up/down scenarios are the simplest ones.
<!-- END_MESSAGE C040-M02482 -->


---

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_08.md) · [Next](Part_10.md)
