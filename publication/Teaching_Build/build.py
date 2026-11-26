"""Build the self-contained teaching page from evidence and local HTML components."""
import argparse
import base64
import csv
from html import escape
import json
from pathlib import Path
from urllib.parse import quote

from lxml import html
from project_artifacts import build_artifacts
from bridge_intake import add_returned_cases
from bridge_june import add_june
from lookup_integration import integrate_lookup
from evidence_trace import integrate_evidence

WORK = Path(__file__).resolve().parent
COMMIT = '65e7cc84528008ea40c6f9bb70a02745df592f4c'


def text(path):
    return path.read_text(encoding='utf-8')


def read_json(path):
    return json.loads(text(path))


def compact(value):
    return json.dumps(value, ensure_ascii=True, separators=(',', ':')).replace('<', r'\u003c')


def json_block(name, value):
    return f'<script type="application/json" id="{name}">{compact(value)}</script>'


def script(js):
    return f'<script>{js}</script>'


def replace_one(source, old, new):
    if source.count(old) != 1:
        raise ValueError(f'Expected exactly one template marker {old!r}')
    return source.replace(old, new, 1)


def fragment(name):
    candidate = WORK / f'cds-teach-{name}.html'
    return text(candidate if candidate.exists() else WORK.parent / candidate.name)


def product_settings(repo):
    source = next(repo.glob('Module_2*/v1.0/outputs/*OUTPUT_strategy_run_parameter_snapshot.csv'))
    fields = ('product_max_approved_amount','product_approve_max_pti','product_min_approved_amount',
              'product_min_counteroffer_pct','product_max_exposure_reduction_pct','counteroffer_target_pti',
              'product_approved_el_cap','approved_amount_rounding_increment')
    settings = {}
    with source.open(encoding='utf-8-sig', newline='') as handle:
        for row in csv.DictReader(handle):
            strategy = json.loads(row['strategy_params_jsonb'])
            products = json.loads(row['product_policy_params_jsonb'])
            settings[row['module2_run_id']] = {
                'pd': strategy['approve_max_estimated_pd_proxy'], 'dti': strategy['approve_max_dti'],
                'severeDti': strategy['decline_min_dti'], 'severePd': strategy['decline_min_estimated_pd_proxy'],
                'products': {p['product_type']: {k:p[k] for k in fields} for p in products},
            }
    return settings


def build(repo, june_dir, returned_dir, evidence_folders=()):
    source_links = read_json(WORK / 'reference_links.json')
    def links(*labels):
        return ' · '.join(f'<a href="{escape(source_links[label],quote=True)}">{escape(label)}</a>' for label in labels)

    def source_url(pattern, raw=False):
        file = next(repo.glob(pattern))
        base = ('https://raw.githubusercontent.com/andrew-goad/credit_decisioning_strategy' if raw else
                'https://github.com/andrew-goad/credit_decisioning_strategy/blob')
        return f'{base}/{COMMIT}/{quote(file.relative_to(repo).as_posix())}'

    case = html.fromstring(fragment('case'))
    sources = html.tostring(case.xpath('./details')[0], encoding='unicode', method='html')
    rule = replace_one(text(WORK/'rule.html'), '<p class="formula">', '<p class="formula" id="auto-loss-calculation">')
    generation = fragment('generation').replace('a population ID and 15 different labels','a population ID and 15 numbered labels').replace('Each stands in for a draw from a distribution.','The engine can reproduce each draw and reuse it in more than one calculation.')
    compare = replace_one(fragment('compare'), '<h1 id="portfolio-title">', '<p class="eyebrow">Portfolio analytics</p><h1 id="portfolio-title">')
    flow = replace_one(text(WORK/'offer_flow.html'), '__OFFER_FLOW_DATA__', compact(read_json(WORK/'returned_counts.json')))
    table = '<table class="pf-table" aria-describedby="pf-units">'
    compare = replace_one(compare, table, flow + '\n' + table)
    pair, pair_js = integrate_lookup(WORK, text(WORK/'pair.html'), text(WORK/'pair.js'))
    cases = add_june(read_json(WORK/'cases.json'), june_dir, repo)
    cases = add_returned_cases(cases, returned_dir/'teaching_cases.csv')
    june_cases = read_json(WORK/'june_cases.json')['cases']
    personal = next(row for row in june_cases if row['id']=='APP-00040465')
    gate_record = next(june_dir.glob('strategy_decisions_archive*APP-00040465.csv'))
    trace = dict(limits=personal['gates'], filename=gate_record.name, download=base64.b64encode(gate_record.read_bytes()).decode('ascii'))
    risk = read_json(WORK/'borrower_math.json')
    embeds = [
        ('archived-case-data', cases), ('archived-case-settings', product_settings(repo)),
        ('counteroffer-calculation', trace), ('borrower-math-data', risk),
        ('worked-decision-math', read_json(WORK/'worked_decision_math.json')),
        ('counteroffer-gate-data', read_json(WORK/'counteroffer_gate_data.json')),
    ]
    js = ''.join(json_block(name,data) for name,data in embeds)
    for asset in ('counteroffer_gates.js','offer_economics.js','borrower_math.js'):
        js += script(text(WORK/asset))
    js += script(text(WORK/'parameter-finder.js'))
    js += text(WORK/'script.html') + script(text(WORK/'offer_flow.js')) + script(pair_js) + script(text(WORK/'casebook.js'))
    evidence_links = links('Comparison registry','Policy settings','Run results','Matching checks')
    first_sql = source_url('Module_1*/v2.0/src/*.sql')
    second_sql = source_url('Module_2*/v1.0/src/*.sql', raw=True)
    evidence_links += (f' · <a href="{first_sql}">Module 1 SQL</a>'
                       f' · <a href="{second_sql}">Open full Module 2 SQL (raw text)</a>')
    parts = {
        'GENERATION':generation, 'CASE':'<section id="application-lesson" aria-labelledby="application-title">'+rule+sources+'</section>',
        'CASEBOOK':text(WORK/'casebook.html'), 'PAIR':pair, 'COMPARE':compare, 'PAGEJS':js,
        'DELTAS':source_url('Module_2*/v1.0/tests/review_queries/campaign/*17.15*active_comparison_groups_campaign.csv'),
        'RATE_CASE':source_url('Module_1*/v2.0/tests/review_queries/campaign/*10.04A*campaign.csv'),
        'RATE_COUNTS':source_url('Module_1*/v2.0/tests/review_queries/campaign/*10.04B*campaign.csv'),
        'SEGMENTS':source_url('Module_2*/v1.0/outputs/*OUTPUT_strategy_run_segment_evidence_summary.csv'),
        'SEVERITY_RUNS':source_links['Run results'],
        'ARTIFACTS':build_artifacts(repo, COMMIT),
        'LINKS':evidence_links, 'BI':links('Preview the Module 1 report (image)','Download Module 1 Power BI report · Windows, 15.49 MiB'),
        'RELEASE':links('v2.0 requirements','v2.0 validation','Mortgage baseline source note'),
    }
    styles = '\n'.join(text(WORK/name) for name in ('borrower_math.css', 'artifacts.css', 'code-flows.css'))
    result = replace_one(text(WORK/'base.html'), '</head>', '<style>'+styles+'</style></head>')
    for key,value in parts.items():
        result = replace_one(result,'@@'+key+'@@',value)
    if '@@' in result:
        raise ValueError('Unfilled template marker')
    return integrate_evidence(result, repo, COMMIT, cases, risk, evidence_folders)


if __name__=='__main__':
    kit = WORK.parent
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--repo', type=Path, default=Path('cds-research'))
    parser.add_argument('--june-dir', type=Path, default=(kit/'Case_Discovery/Source_rows' if (kit/'Case_Discovery').is_dir() else Path('june-case-source')))
    parser.add_argument('--return-dir', type=Path, default=(kit/'Case_Discovery/Returned' if (kit/'Case_Discovery').is_dir() else Path('upload')))
    parser.add_argument('--output', type=Path, default=WORK/'Credit_Strategy_Explorer.html')
    parser.add_argument('--preview', type=Path, default=None)
    args = parser.parse_args()
    folders = {path.parent for path in (args.output, args.preview) if path}
    result = build(args.repo, args.june_dir, args.return_dir, folders).encode('utf-8')
    for path in filter(None,(args.output,args.preview)):
        path.parent.mkdir(parents=True,exist_ok=True)
        path.write_bytes(result)
        print(f'{path}: {len(result):,} bytes')
