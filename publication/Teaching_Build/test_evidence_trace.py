"""Verify the distributed evidence text against Git objects and the saved case identifiers."""
import argparse
import csv
from hashlib import sha256
import json
from pathlib import Path
import re
import subprocess

from lxml import html


def data_block(page, key):
    value, = page.xpath(f'//script[@id="{key}"]/text()')
    return json.loads(value)


def check(repo, site):
    page = html.parse(str(site / 'index.html'))
    traces = data_block(page, 'source-trace-data')
    files = traces['files']
    original = {}
    for key, file in files.items():
        raw = subprocess.check_output(['git', '-C', str(repo), 'cat-file', 'blob',
                                       f'{traces["commit"]}:{file["path"]}'])
        assert sha256(raw).hexdigest() == file['sha256'], (key, 'source hash')
        original[key] = raw.decode('utf-8').splitlines(keepends=True)
    for key in ('input', 'scenario', 'decisions'):
        file = files[key]
        assert file['header'] == original[key][0]
        columns = next(csv.reader([file['header']]))
        for label, record in file['records'].items():
            assert record['csv'] == original[key][int(label)-1], (key, label, 'exact CSV')
            source_row = next(csv.reader([record['csv']]))
            assert record['values'] == [source_row[columns.index(f)] for f in file['fields']], (key, label)
    cases = data_block(page, 'archived-case-data')
    pair_count = 0
    for group in cases['groups'].values():
        for case in group['cases']:
            if case['base']['source'] != 'archive':
                continue
            pair_count += 1
            for side, run in [('base',group['baseRun']), ('challenge',group['challengeRun'])]:
                record = files['decisions']['records'][str(case[side]['line'])]
                fields = dict(zip(files['decisions']['fields'], record['values'], strict=True))
                assert (fields['module2_run_id'], fields['application_id'], fields['decision_outcome']) == (
                    run, case['id'], case[side]['outcome']), (run, case['id'], side)
    assert pair_count == 452
    sql_page = html.parse(str(site / 'evidence' / 'module2-sql.html'))
    code_lines = {}
    for span in sql_page.xpath('//span[@class="source-line"]'):
        no = int(span.get('id')[1:])
        assert no not in code_lines
        code_lines[no] = span.find('code').text or ''
    expected = {start + i: code for start, block in files['sql']['blocks'] for i, code in enumerate(block)}
    assert code_lines == expected
    for number, line in code_lines.items():
        assert line == original['sql'][number-1].rstrip('\r\n'), number
    for address in files['sql']['ranges']:
        lo, hi = map(int, address.split('-'))
        assert all(no in code_lines for no in range(lo, hi+1)), address
    static = page.xpath('//a[@data-credit-trace]')
    assert len(static) >= 23
    for a in static:
        token = a.get('data-credit-trace')
        kind, nums = token.split('.')
        assert re.fullmatch(r'\d+(?:-\d+)?', nums) and '?trace='+token+'#' in a.get('href')
        if kind == 'sql':
            assert nums in files['sql']['ranges']
        else:
            assert nums in files[kind]['records']
    opening = page.xpath('//*[@id="application-lesson"]//a[@data-credit-trace]')
    assert {a.get('data-credit-trace') for a in opening} == {
        'input.32477', 'decisions.229', 'decisions.666', 'sql.11350-11351', 'sql.14332-14347'}
    paths = set(f['url'] for f in files.values())
    assert not [a.get('href') for a in page.xpath('//a[@href]') if a.get('href').partition('#')[0] in paths
                and '#' in a.get('href')], 'A static large-file line link bypasses its local evidence.'
    print(f'PASS {pair_count} archived decision pairs, {len(files["decisions"]["records"])} distinct decision rows, '
          f'{len(files["input"]["records"])+len(files["scenario"]["records"])} input rows, '
          f'{len(code_lines):,} SQL lines and {len(static)} static reader links against Git {traces["commit"][:7]}.')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--repo', type=Path, default=Path('.'))
    parser.add_argument('--site', type=Path, default=Path('site'))
    args = parser.parse_args()
    check(args.repo, args.site)
