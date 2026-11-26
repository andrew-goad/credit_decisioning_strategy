"""Attach the full archive search to the paired application panel."""
import json

def integrate_lookup(work, panel, script):
    search = (work / 'full_lookup.html').read_text(encoding='utf-8')
    lookup = (work / 'full_lookup.js').read_text(encoding='utf-8')
    ref = work/'full_campaign_reference.json'
    if not ref.is_file():
        ref = work.parent/'full_lookup/full_campaign_reference.json'
    reference=json.loads(ref.read_text(encoding='utf-8'))['runs']
    def readable(code):
        return code.replace('_',' ').lower().capitalize().replace('lgd','LGD').replace('200bp','200 bp').replace('300bp','300 bp')
    catalog={run: [row['source'], readable(row['module1_scenario_name']), readable(row['strategy_name'].removesuffix('_STRATEGY'))] for run,row in reference.items()}
    search += '<script type="application/json" id="pair-run-catalog">'+json.dumps(catalog,separators=(',',':')).replace('<',r'\u003c')+'</script>'
    handoff = """<div id="pair-handoff" hidden>
<a id="pair-handoff-link">Open this applicant in the full explorer</a>
<details id="pair-handoff-offline"><summary>Open this comparison from the offline ZIP</summary>
<p>Extract <code>CDS_Teaching_Explorer.zip</code>. In PowerShell in the extracted folder, run</p>
<p><code id="pair-handoff-command"></code></p></details></div>"""
    run_panel = """<details id="pair-all-runs" class="run-registry"><summary>See all 39 run decisions for this applicant</summary>
<p class="secondary" id="pair-run-status" role="status"></p><button id="pair-run-retry" type="button" class="reset" hidden>Retry all 39 runs</button>
<div id="pair-run-table" class="case-scroll" role="region" aria-label="All run decisions" tabindex="0" hidden><table>
<caption id="pair-run-caption">Recorded decisions</caption><thead><tr><th scope="col">Run</th><th scope="col">Source scenario</th><th scope="col">Policy</th><th scope="col">Decision</th><th scope="col">Amount requested</th><th scope="col">Amount offered</th></tr></thead><tbody id="pair-run-rows"></tbody></table></div></details>"""
    for old, new in (
        ('<div class="pair-switch">', search + '\n<div class="pair-switch">'),
        ('<label for="pair-id">Choose an application</label>', '<label for="pair-id">Browse saved examples</label>'),
        ('<p>The portfolio above includes every application in the selected comparison. Here you can inspect individual applications with a saved decision from both policies. The published sample includes deliberate examples of different decisions, so use the portfolio totals above when measuring how often an outcome occurs.</p>', ''),
        ('<p id="pair-economics"></p>', '<p id="pair-economics"></p><div id="pair-borrower-math"></div>'),
        ('<h3 id="pair-name">', '<div id="pair-result" hidden><h3 id="pair-name">'),
        ('<p class="secondary" id="pair-feedback" role="status"></p>', '</div><p class="secondary" id="pair-feedback" role="status"></p>' + handoff + '<button id="pair-return" type="button" class="reset" hidden>Show a saved comparison</button>' + run_panel),
    ):
        if panel.count(old) != 1:
            raise ValueError(f'Cannot attach the application lookup: expected one {old!r}.')
        panel = panel.replace(old, new, 1)
    return panel, lookup + '\n' + script
