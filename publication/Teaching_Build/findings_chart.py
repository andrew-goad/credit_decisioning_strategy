"""Draw the counteroffer comparison from the same values as its reconciled table."""
from decimal import Decimal
from html import escape

from lxml import html


def draw_findings(template):
    table, = html.fromstring(template).xpath('//*[@id="findings-exposure"]')
    groups = (("CG18", "Standard requests"), ("CG20", "Larger requests"))
    rows = (("gained", "New offers"), ("lost", "Lost offers"),
            ("both", "Offers under both policies"), ("net", "Net change"))
    bounds = (-300, 500)  # Millions of dollars. One scale for both series and all rows.
    span = bounds[1] - bounds[0]

    def position(value):
        return (value - bounds[0]) * 100 / span

    axis = []
    for value in (-250, 0, 250, 500):
        tick = f"{value:+d}".replace("-", "−") if value else "0"
        axis.append(f'<span style="--tick:{position(value):g}%">{tick}</span>')
    parts = ['<div class="exposure-axis"><div class="exposure-scale">' +
             ''.join(axis) + '</div></div>']
    summaries = []
    for key, label in rows:
        node, = (table.xpath("tfoot/tr") if key == "net" else
                 table.xpath('tbody/tr[@data-offer-group=$key]', key=key))
        parts.append(f'<div class="exposure-group" data-group="{key}">'
                     f'<div class="exposure-group-title">{label}</div>')
        for group, title in groups:
            count, amount = node.xpath('td[@data-comparison=$group]/span/text()', group=group)
            value = Decimal(amount.translate(str.maketrans("−", "-", "$M,")))
            if not bounds[0] <= value <= bounds[1]:
                raise ValueError(f"Amount outside chart axis for {group} {key}: {amount}")
            left = position(min(value, 0))
            width = abs(value) * 100 / span
            parts.append(
                f'<div class="exposure-series" data-comparison="{group}" '
                f'style="--left:{left:f}%;--width:{width:f}%">'
                '<div class="exposure-track"><i></i></div>'
                f'<span class="exposure-value">{escape(amount)}</span></div>')
            if key == "net":
                offers = int(count.replace(",", ""))
                count_dir = "more" if offers > 0 else "fewer"
                dollar_dir = "more" if value > 0 else "less"
                summaries.append(
                    f'<div data-comparison="{group}"><dt>{title} <small>{group}</small></dt>'
                    f'<dd>{abs(offers):,} {count_dir} offers, '
                    f'<strong>${abs(value):,.2f}M {dollar_dir} credit</strong></dd></div>')
        parts.append('</div>')
    caption = ('<figcaption id="exposure-title">Where the change in offered credit came from'
               '<small>Change from Baseline to the expanded counteroffer policy, in millions of dollars</small>'
               '</figcaption>')
    legend = '<div class="exposure-legend">' + ''.join(
        f'<span data-comparison="{group}"><i></i>{title}</span>' for group, title in groups) + '</div>'
    plot = (f'<div class="exposure-plot" aria-hidden="true" style="--zero:{position(0):g}%">'
            + ''.join(parts) + '</div>')
    # The adjacent data table gives screen readers both the labeled dollar values and their counts.
    figure = '<figure class="exposure-figure">' + caption + legend + plot + '</figure>'
    return {'EXPOSURE_SUMMARY': '<dl class="exposure-summary">' + ''.join(summaries) + '</dl>',
            'EXPOSURE_CHART': figure}
