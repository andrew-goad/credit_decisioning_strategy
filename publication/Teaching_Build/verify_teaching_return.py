"""Verify a Cases-mode CSV and execution receipt against the published campaign."""
import argparse
import csv
import hashlib
import json
import re
import sys
from collections import Counter, defaultdict
from datetime import datetime
from decimal import Decimal, ROUND_HALF_UP
from pathlib import Path

LESSONS = {
    1: 'New offer', 2: 'Lost offer', 3: 'Same counteroffer outcome, different amount',
    4: 'Ordinary counteroffer candidate receives an offer', 5: 'Override candidate ends in review',
    6: 'The reason changes for the same outcome', 7: 'An unchanged approval at the requested amount',
}
OFFERS = {'APPROVE', 'COUNTEROFFER'}
NONOFFERS = {'MANUAL_REVIEW', 'DECLINE'}
SOURCE = dict(product='product_type', score_band='score_band', credit_score='credit_score', annual_income='annual_income',
              requested_amount='requested_amount', requested_payment_to_income_ratio='requested_payment_to_income_ratio',
              estimated_pd='estimated_pd', estimated_lgd='estimated_lgd', requested_expected_loss_amount='requested_expected_loss_amount')
SIDE = dict(outcome='decision_outcome', amount='approved_amount', el='approved_expected_loss_amount',
            reason='primary_reason_code', path='decision_path')
TEXT = {'product', 'score_band', 'outcome', 'reason', 'path'}
EXAMPLE = ['example_number', 'application_id', *SOURCE,
           *(p+'_'+k for p in ('base','test') for k in SIDE), 'ordinary_candidate', 'override_candidate']
IDENTITY = ['lesson', 'baseline_run', 'challenger_run', 'scenario_set', 'scenario_name', 'population_id',
            'baseline_rows', 'challenger_rows', 'matched_ids', 'changed_inputs', 'pair_status']
HASH = 'b4546614dfe851ae43c316afa31d672a80cd7b15ca5b9289e211556301d9f43d'
# Three historical challenger runs have aggressive overrides. The two archived
# summary columns below are (final counteroffers, final manual reviews) for the
# override subset. The other runs record zero in both. Source file with LF:
# ..._OUTPUT_strategy_run_evidence_summary.csv SHA-256 54fe051dee84cf6a04f43afb73d842323eaac158e70a1557c3aec28ffb9eb2bd.
OVERRIDE = {'M2-37':(4067,547), 'M2-38':(3699,681), 'M2-39':(7081,1811)}


def check(condition, message):
    if not condition:
        raise ValueError(message)


def read_csv(path):
    with path.open(encoding='utf-8-sig', newline='') as stream:
        reader = csv.DictReader(stream)
        check(len(reader.fieldnames) == len(set(reader.fieldnames)), f'Duplicate column in {path.name}.')
        rows = list(reader)
        check(all(None not in row and None not in row.values() for row in rows), f'Malformed CSV in {path.name}.')
        return rows


def number(value):
    if value == '':
        return None
    d = Decimal(value)
    check(d.is_finite(), f'Non-finite decimal {value}.')
    return d


def verify_receipt(receipt, ref):
    base = ref['runs']['M2-01']
    expected = {'verified_runs':39, 'other_runs_exact_original':38, 'unique_applications_per_run':50000,
                'analysis_mode':'Cases', 'run':'M2-01', 'strategy_run_id':base['strategy_run_id'],
                'published_time_utc':base['exportUTC']}
    check(all(receipt.get(k) == v for k,v in expected.items()), 'Cases receipt differs from published run authority.')
    value = receipt['selected_time_utc']
    check(re.fullmatch(r'\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{6}\+00:00', value), 'Expected a six-digit UTC receipt.')
    datetime.fromisoformat(value)
    method = receipt['selection']
    check((method == 'PUBLISHED_ORIGINAL' and value == base['exportUTC']) or
          (method == 'OWNER_APPROVED_MAY28_REFRESH' and value.startswith('2026-05-28T12:40:03.698')),
          'Unknown M2-01 execution.')


def check_case(row, lesson):
    context = f"{row['pair_id']} lesson {lesson} {row['application_id']}"
    check(re.fullmatch(r'APP-\d{8}',row['application_id']) and 1<=int(row['application_id'][4:])<=50000, context)
    check(all(row[k] for k in SOURCE), f'Missing source value on {context}')
    check(all(row[k] in ('t','f') for k in ('ordinary_candidate','override_candidate')), context)
    request, pd, lgd, requested_el = map(number, (row['requested_amount'],row['estimated_pd'],row['estimated_lgd'],row['requested_expected_loss_amount']))
    check(request>0 and 0<=pd<=1 and 0<=lgd<=1 and requested_el==(request*pd*lgd).quantize(Decimal('.01'), ROUND_HALF_UP), f'Requested EL on {context}')
    for side in ('base', 'test'):
        outcome = row[side+'_outcome']
        amount, loss = number(row[side+'_amount']), number(row[side+'_el'])
        check(outcome in OFFERS|NONOFFERS and row[side+'_reason'] and row[side+'_path'], context)
        if outcome=='APPROVE':
            ok = amount==request and loss==requested_el
        elif outcome=='COUNTEROFFER':
            ok = amount is not None and 0<amount<request and loss==amount*pd*lgd
        elif outcome=='MANUAL_REVIEW':
            ok = amount is None and loss is None
        else:
            ok = amount==0 and loss==0
        check(ok,f'{side} approved principal/loss on {context}')
    b,c = row['base_outcome'],row['test_outcome']
    tests = [b in NONOFFERS and c in OFFERS, b in OFFERS and c in NONOFFERS,
             b==c=='COUNTEROFFER' and number(row['base_amount'])!=number(row['test_amount']),
             c=='COUNTEROFFER' and row['ordinary_candidate']=='t' and row['override_candidate']=='f',
             c=='MANUAL_REVIEW' and row['override_candidate']=='t',
             b==c and row['base_reason']!=row['test_reason'], b==c=='APPROVE']
    check(tests[lesson-1], f'Selected example fails its predicate on {context}')


def check_source_repo(repo, events, ledger):
    """Additional verification against independently retained full-run summaries and available row overlaps."""
    def table(pattern):
        matches = list(repo.rglob(pattern))
        check(len(matches)==1, f'Expected one source matching {pattern}.')
        return read_csv(matches[0])
    historical = {r['module2_run_id']:r for r in table('*OUTPUT_strategy_run_evidence_summary.csv')}
    for group in ledger.values():
        run = historical[group['challenger']]
        counts = group['counts']
        check(counts[4]==int(run['counteroffer_count'])-int(run['aggressive_override_final_counteroffer_rows'])
              and counts[5]==int(run['aggressive_override_final_manual_review_rows']), 'Archived channel counts mismatch.')
    matrix = table('*13.5A_QA_decision_outcome_migration_matrix_m2_02.csv')
    reasons = table('*13.8B_QA_primary_reason_code_migration_matrix_m2_02.csv')
    movements = Counter()
    for row in matrix:
        b,c = row['baseline_decision_outcome'],row['challenger_decision_outcome']
        for lesson, yes in ((1,b in NONOFFERS and c in OFFERS),(2,b in OFFERS and c in NONOFFERS),(7,b==c=='APPROVE')):
            movements[lesson] += int(row['row_count']) if yes else 0
    movements[6] = sum(int(r['row_count']) for r in reasons if r['baseline_primary_reason_family']==r['challenger_primary_reason_family']
                       and r['baseline_primary_reason_code']!=r['challenger_primary_reason_code'])
    check(all(ledger['CG01']['counts'][i]==n for i,n in movements.items()), 'CG01 historical migration matrices differ.')
    matches = {}
    for title, pattern in [('campaign sample','*RANDOM_SAMPLE_strategy_decisions_archive.csv'),('May 28 sample','*RANDOM_SAMPLE_strategy_decisions_m2_01.csv')]:
        historic = {(r['module2_run_id'],r['application_id']):r for r in table(pattern)}
        count = 0
        for row in events:
            for side,runk in (('base','baseline_run'),('test','challenger_run')):
                observed = historic.get((row[runk],row['application_id']))
                if observed is None:
                    continue
                for key,column in SOURCE.items():
                    actual = row[key]; raw = observed[column]
                    check(actual==raw if key in TEXT else number(actual)==number(raw), f'Disagrees with archived source {column}.')
                for key,column in SIDE.items():
                    actual = row[side+'_'+key]; raw = observed[column]
                    check(actual==raw if key in TEXT else number(actual)==number(raw), f'Disagrees with archived decision {column}.')
                count+=1
        matches[title] = count
    return matches


def validate(rows, ref):
    cases = defaultdict(list)
    fields = set(['pair_id','lesson_id','qualifying_applications',*IDENTITY,*EXAMPLE])
    check(rows and set(rows[0])==fields, 'Unexpected teaching CSV schema.')
    for row in rows:
        cells = (row['pair_id'],int(row['lesson_id']))
        cases[cells].append(row)
    registered = sorted(ref['groups'])
    check(set(cases)=={(p,i) for p in registered for i in LESSONS}, 'Missing or unexpected pair / lesson cell.')
    ledger, events = {}, []
    runs = list(ref['runs'])
    for group in registered:
        b,c = [runs[i] for i in ref['groups'][group]]
        cfg = ref['runs'][b]
        counts = {}
        for lesson,label in LESSONS.items():
            batch = cases[group,lesson]
            cell = f'{group} lesson {lesson}'
            expected = [label,b,c,cfg['module1_scenario_set_name'],cfg['module1_scenario_name'],cfg['population_id'],'50000','50000','50000','0','READY']
            check(all([r[k] for k in IDENTITY]==expected for r in batch), f'Source identity, row counts, or match status on {cell}.')
            count = counts[lesson] = int(batch[0]['qualifying_applications'])
            check(0<=count<=50000 and all(int(r['qualifying_applications'])==count for r in batch), f'Conflicting count on {cell}.')
            if count==0:
                check(len(batch)==1 and all(batch[0][k]=='' for k in EXAMPLE), f'Invalid zero marker on {cell}.')
                continue
            check([int(r['example_number']) for r in batch]==list(range(1,min(count,4)+1)), f'Invalid sample allocation on {cell}.')
            check(len({r['application_id'] for r in batch})==len(batch), f'Duplicate ID in {cell}.')
            # SQL sample orders by within-stratum rank, then stable MD5, then ID.
            seen = Counter()
            order = []
            for r in batch:
                check_case(r,lesson)
                stratum = r['product'],r['score_band']
                seen[stratum]+=1
                digest = hashlib.md5(f"{group}/{lesson}/{r['application_id']}".encode(),usedforsecurity=False).hexdigest()
                order.append((seen[stratum], digest, r['application_id']))
            check(order==sorted(order), f'Stratified sample order differs on {cell}.')
            events.extend(batch)
        bt,ct = (ref['runs'][run]['totals'] for run in (b,c))
        bo,co = (sum(int(t[k]) for k in OFFERS) for t in (bt,ct))
        check(counts[1]-counts[2]==co-bo and counts[1]<=min(50000-bo,co) and counts[2]<=min(bo,50000-co), f'Offer turnover differs from published totals on {group}.')
        override_co, override_mr = OVERRIDE.get(c,(0,0))
        check(counts[4]==int(ct['COUNTEROFFER'])-override_co and counts[5]==override_mr, f'Counteroffer channels on {group}.')
        check(counts[3]<=min(int(bt['COUNTEROFFER']),int(ct['COUNTEROFFER'])) and counts[7]<=min(int(bt['APPROVE']),int(ct['APPROVE']))
              and counts[3]+counts[7]<=bo-counts[2] and counts[6]<=50000-counts[1]-counts[2], f'Impossible matched counts on {group}.')
        ledger[group] = dict(baseline=b,challenger=c,denominator=50000,counts=counts)
    return ledger,events


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('csv',type=Path)
    parser.add_argument('receipt',type=Path)
    parser.add_argument('--reference',type=Path, help='full_lookup/full_campaign_reference.json from the kit')
    parser.add_argument('--repo',type=Path,help='Optional original repository for independent source file and row-overlap checks')
    parser.add_argument('--output',type=Path)
    args=parser.parse_args()
    here=Path(__file__).resolve().parent
    ref_file=args.reference or next((p for p in (here/'full_campaign_reference.json',here/'full_lookup/full_campaign_reference.json',here.parent/'full_lookup/full_campaign_reference.json') if p.is_file()), None)
    check(ref_file is not None,'Use --reference to select the original kit reference.')
    raw=ref_file.read_bytes().replace(b'\r\n',b'\n')
    check(hashlib.sha256(raw).hexdigest()==HASH,'Pinned historical reference hash differs.')
    ref=json.loads(raw)
    receipt=json.loads(args.receipt.read_text(encoding='utf-8-sig'))
    verify_receipt(receipt,ref)
    ledger,events=validate(read_csv(args.csv),ref)
    if args.repo:
        matches=check_source_repo(args.repo,events,ledger)
        print('PASS archived channel totals, two CG01 migration matrices and overlapping example sides',matches)
    if args.output:
        args.output.write_text(json.dumps(dict(schemaVersion=1,lessons=LESSONS,groups=ledger),separators=(',',':'))+'\n',encoding='utf-8')
    print(f'PASS {len(ledger)} comparisons, {len(ledger)*len(LESSONS)} counts, {len(events)} selected case rows, {len(events)*2} decision-side economics.')

if __name__=='__main__':
    try:
        main()
    except (ValueError, OSError, KeyError, ArithmeticError) as error:
        sys.exit(f'Verification stopped: {error}')
