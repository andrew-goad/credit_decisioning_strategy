"""Extract the cited CSV records and SQL lines from the four immutable campaign source files."""
from collections import defaultdict
import csv
from hashlib import sha256
from html import escape
import json
from pathlib import Path
import re
import subprocess
from urllib.parse import quote, unquote

from lxml import html

WORK = Path(__file__).resolve().parent
PROJECT = 'andrew-goad/credit_decisioning_strategy'
FILES = {
    'input': ('Module_1*/v2.0/outputs/*OUTPUT_synthetic_applications.csv',
              'acb9ff4dc23d5d9b034c419b6545a517dc7879051eb64e5321518f4918d486ce', 'Baseline application'),
    'scenario': ('Module_1*/v2.0/outputs/*RANDOM_SAMPLE*scenario_archive.csv',
                 '8b2b6a17f4652bfcb064c3d18a43144f59941ef71f09abda6cc931529048b642', 'Scenario application'),
    'decisions': ('Module_2*/v1.0/outputs/*RANDOM_SAMPLE_strategy_decisions_archive.csv',
                  'b79ec89c90b1c97174a5eb3eb1b56f0786fd267e2b3ae40977dc51b9e1bc1b74', 'Archived decision'),
    'sql': ('Module_2*/v1.0/src/*.sql',
            '5620d2e6b309c06000364b95a8c20cb2b141853b9cfc61faf29c9d741a83cf07', 'Module 2 decision rules'),
}
DECISION_FIELDS = (
    'application_id', 'module2_run_id', 'module1_scenario_name', 'strategy_name', 'product_type',
    'requested_amount', 'estimated_pd', 'estimated_lgd', 'requested_expected_loss_amount',
    'decision_outcome', 'primary_reason_code', 'decision_path', 'approved_amount',
    'approved_expected_loss_amount',
)
INPUT_FIELDS = (
    'application_id', 'scenario_name', 'product_type', 'credit_score', 'score_band',
    'annual_income', 'debt_to_income_ratio', 'utilization_rate', 'requested_amount',
    'loan_term_months', 'base_apr_for_payment_calc', 'apr_proxy', 'monthly_payment_proxy',
    'payment_to_income_ratio', 'base_pd', 'mult_util', 'mult_inquiry', 'mult_tradeline', 'mult_pti',
    'mult_amt_income', 'estimated_pd', 'estimated_lgd', 'expected_loss_amount',
)
RANGE = re.compile(r'L(\d+)(?:-L(\d+))?$')


def source_bytes(repo, path, commit, expected):
    raw = path.read_bytes()
    if sha256(raw).hexdigest() != expected:
        # A checkout may have platform-specific working-tree newlines. Use the archived blob.
        relative = path.relative_to(repo).as_posix()
        raw = subprocess.check_output(['git', '-C', str(repo), 'cat-file', 'blob', f'{commit}:{relative}'])
    if sha256(raw).hexdigest() != expected:
        raise ValueError(f'Original source hash differs: {path.name}')
    return raw


def read_sources(repo, commit):
    files, originals = {}, {}
    for key, (pattern, expected, title) in FILES.items():
        path, = repo.glob(pattern)
        relative = path.relative_to(repo).as_posix()
        url = f'https://github.com/{PROJECT}/blob/{commit}/{quote(relative)}'
        files[key] = {'title': title, 'path': relative, 'url': url,
                      'raw': f'https://raw.githubusercontent.com/{PROJECT}/{commit}/{quote(relative)}',
                      'sha256': expected}
        originals[key] = source_bytes(repo, path, commit, expected).decode('utf-8')
    return files, originals


def csv_records(file, original, requested, fields):
    lines = original.splitlines(keepends=True)
    # GitHub anchors use physical, header-inclusive CSV lines. Check selected ID and run at each.
    columns = next(csv.reader([lines[0]], strict=True))
    keys = [key for key in fields if key in columns]
    indexes = [columns.index(key) for key in keys]
    records = {}
    for line, (application, run_or_scenario) in sorted(requested.items()):
        raw = lines[line - 1]
        row, = csv.reader([raw], strict=True)
        if len(row) != len(columns):
            raise ValueError(f'CSV column mismatch at {file["path"]}:{line}')
        identity_key = 'module2_run_id' if 'module2_run_id' in columns else 'scenario_name'
        if (row[columns.index('application_id')], row[columns.index(identity_key)]) != (application, run_or_scenario):
            raise ValueError(f'CSV identity mismatch at {file["path"]}:{line}')
        records[line] = {'values': [row[index] for index in indexes], 'csv': raw}
    file.update(fields=keys, header=lines[0], records=records)


def trace_token(url, addresses):
    base, _, fragment = url.partition('#')
    key = addresses.get(unquote(base))
    if key is None:
        return None
    match = RANGE.fullmatch(fragment)
    if match is None:
        return None
    lo = int(match[1])
    hi = int(match[2] or lo)
    return key, lo, hi


def populate_rows(files, originals, examples, risk, addresses):
    wanted = defaultdict(dict)
    for group in examples['groups'].values():
        for case in group['cases']:
            for side, run in [('base', group['baseRun']), ('challenge', group['challengeRun'])]:
                data = case[side]
                if data['source'] == 'archive':
                    wanted['decisions'][data['line']] = (case['id'], run)
            if case.get('paymentProof'):
                which, line, _ = trace_token(case['paymentProof'], addresses)
                wanted[which][line] = (case['id'], group['scenario'])
    for scenario, cases in risk['records'].items():
        for application, details in cases.items():
            if details.get('sourceRow'):
                url = risk['sourceFiles'][details['source']]
                wanted[addresses[unquote(url)]][details['sourceRow']] = (application, scenario)
    for key in ('input', 'scenario', 'decisions'):
        csv_records(files[key], originals[key], wanted[key],
                    DECISION_FIELDS if key == 'decisions' else INPUT_FIELDS)


def document_ranges():
    indexed = json.loads((WORK/'evidence_trace_ranges.json').read_text(encoding='utf-8'))
    return {tuple(int(i) for i in (bounds.split('-') if '-' in bounds else [bounds, bounds])): title
            for bounds, title in indexed.items()}


def populate_sql(file, original, ranges):
    lines = original.splitlines()
    intervals = []
    for (lo, hi), title in sorted(ranges.items()):
        # A citation to a section header includes its introductory context.
        end = min(len(lines), lo + 17) if hi == lo else hi
        if not 0 < lo <= hi <= len(lines):
            raise ValueError(f'Invalid SQL citation: {lo}-{hi}')
        if intervals and lo <= intervals[-1][1] + 1:
            intervals[-1] = (intervals[-1][0], max(intervals[-1][1], end))
        else:
            intervals.append((lo, end))
    file['blocks'] = [[lo, lines[lo-1:hi]] for lo, hi in intervals]
    file['ranges'] = {f'{lo}-{hi}': title for (lo, hi), title in sorted(ranges.items())}


def sql_document(file, commit):
    title = 'Module 2 SQL excerpts'
    code = []
    for start, lines in file['blocks']:
        code.append(f'<section><h2>Lines {start:,}–{start+len(lines)-1:,}</h2><pre>')
        for number, row in enumerate(lines, start):
            code.append(f'<span class="source-line" id="L{number}"><a href="#L{number}" '
                        f'aria-label="Line {number}">{number}</a><code>{escape(row)}</code></span>')
        code.append('</pre></section>')
    return f'''<!doctype html><html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>{title} · Credit portfolio analytics</title>
<style>body{{margin:1.5rem auto;padding:0 1rem;max-width:75rem;color:#17363a;font:1rem/1.5 system-ui,sans-serif}}
h1,h2{{line-height:1.16}}h2{{font-size:1.1rem;margin-top:2rem}}a{{color:#00645b}}.identity{{overflow-wrap:anywhere}}
pre{{margin:0}}.source-line{{display:grid;grid-template-columns:4.8em 1fr;align-items:baseline;scroll-margin-top:1em}}
.source-line:nth-child(odd){{background:#eef4f1}}.source-line:target{{background:#ffedb2}}
.source-line>a{{text-decoration:none;font-size:.9em;text-align:right;padding-right:1em}}.source-line code{{white-space:pre-wrap;overflow-wrap:anywhere}}</style></head>
<body><main><a href="../index.html#artifacts">Project artifacts</a><h1>{title}</h1>
<p>These numbered excerpts contain the original lines cited by the teaching edition and the retrospective Module 2 documents. The complete program runs in PostgreSQL.</p>
<p class="identity">{escape(file["path"])}<br>Git commit <code>{commit}</code><br>Full source SHA-256 <code>{file["sha256"]}</code></p>
<p><a href="{file["raw"]}">Open the complete raw SQL</a> · <a href="{file["url"]}">View the pinned repository file</a></p>
{''.join(code)}</main></body></html>'''


def opening_result(file):
    keys = file['fields']
    def record(number):
        return dict(zip(keys, file['records'][number]['values'], strict=True))
    baseline, growth = record(229), record(666)
    if (baseline['application_id'], baseline['module2_run_id'], growth['application_id'], growth['module2_run_id']) != (
        'APP-00032476', 'M2-01', 'APP-00032476', 'M2-03'):
        raise ValueError('The saved opening decision rows disagree with the featured applicant.')
    rows = []
    for label, values in (('Recorded outcome', [baseline['decision_outcome'], growth['decision_outcome']]),
                          ('Amount offered', [baseline['approved_amount'], growth['approved_amount']]),
                          ('Modeled loss on offer', [baseline['approved_expected_loss_amount'], growth['approved_expected_loss_amount']])):
        if label == 'Recorded outcome':
            values = [{'MANUAL_REVIEW':'Manual review', 'APPROVE':'Approved as requested'}[val] for val in values]
        else:
            values = ['Unresolved' if v == '' else f'${float(v):,.2f}' for v in values]
        rows.append(f'<tr><th scope="row">{label}</th><td>{values[0]}</td><td>{values[1]}</td></tr>')
    return ('<table class="opening-records"><caption>Recorded decisions for APP-00032476</caption>'
            '<thead><tr><th scope="col">Field</th><th scope="col">Baseline · M2-01</th>'
            '<th scope="col">Growth · M2-03</th></tr></thead><tbody>'+''.join(rows)+'</tbody></table>')


def integrate_evidence(page, repo, commit, examples, risk, output_folders=()):
    files, originals = read_sources(repo, commit)
    addresses = {unquote(file['url']):key for key, file in files.items()}
    populate_rows(files, originals, examples, risk, addresses)
    # Direct the opening links at executed expressions as well as explanatory comments.
    aliases = {(11323,11323):(11350,11351), (14331,14331):(14332,14347)}
    ranges = document_ranges()
    ranges.update({(19675,19929): 'Counteroffer sizing and feasibility', (11323,11323):'Cutoff calculation',
                   (14331,14331):'Review rule', (19660,19660):'Counteroffer sizing',
                   (17080,17104):'Decision routing order'})
    replacements = {}
    for anchor in html.fromstring(page).xpath('//a[@href]'):
        url = anchor.get('href')
        token = trace_token(url, addresses)
        if not token:
            continue
        key, lo, hi = token
        if key == 'sql':
            lo, hi = aliases.get((lo, hi), (lo, hi))
            ranges[(lo,hi)] = anchor.text_content().strip()
        elif lo not in files[key]['records']:
            raise ValueError(f'Missing published CSV record: {key} row {lo}')
        view = next((node.get('data-page') for node in anchor.iterancestors() if node.get('data-page')), 'start')
        return_hash = 'application-lesson' if view == 'start' else view
        key_text = f'{key}.{lo}' + (f'-{hi}' if hi != lo else '')
        old = 'href="' + escape(url, quote=True) + '"'
        new = f'data-credit-trace="{key_text}" href="?trace={key_text}#{return_hash}"'
        replacements[old] = new
    for old, new in replacements.items():
        if old not in page:
            raise ValueError(f'Source link could not be rewritten: {old}')
        page = page.replace(old, new)
    populate_sql(files['sql'], originals['sql'], ranges)
    for directory in output_folders:
        destination = directory/'evidence'/'module2-sql.html'
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_bytes(sql_document(files['sql'], commit).encode('utf-8'))
    before = '<summary>Trace this example to the saved campaign</summary>'
    if page.count(before) != 1:
        raise ValueError('Opening trace has moved; insert its evidence exhibit beside its applicant record.')
    page = page.replace(before, before + opening_result(files['decisions']))
    packed = json.dumps(dict(commit=commit, files=files),ensure_ascii=True,separators=(',',':')).replace('<',r'\u003c')
    dialog = (WORK/'evidence_trace.html').read_text(encoding='utf-8')
    script = (WORK/'evidence_trace.js').read_text(encoding='utf-8')
    styles = (WORK/'evidence_trace.css').read_text(encoding='utf-8')
    mounts = dialog + f'<script type="application/json" id="source-trace-data">{packed}</script><script>{script}</script>'
    return page.replace('</head>', '<style>'+styles+'</style></head>',1).replace('</footer>','</footer>'+mounts,1)
