"""Offline structure and rejection tests; temporary fixtures never enter the website."""
import argparse
import base64
import csv
from datetime import timedelta
from decimal import Decimal
import hashlib
import json
from pathlib import Path
import tempfile
import zlib

import pack_full_campaign as pc


def verify_public_sample(sample):
    ref = pc.reference()
    with sample.open(encoding='utf-8-sig', newline='') as stream:
        archived = list(csv.DictReader(stream))
    archived.sort(key=lambda row: (row['application_id'], row['module2_run_id']))
    assert len(archived) == ref['sampleRows'] == 13_583
    digest = hashlib.sha256()
    for row in archived:
        digest.update(pc.sample_record(row, ref['columns']))
    assert digest.hexdigest() == ref['sampleProjectionSha256']
    # If the separately published refresh excerpt is available, compare the
    # same fields that guard the full import, using the historical assertions.
    later = sample.with_name(sample.name.replace('_archive.csv', '_m2_01.csv'))
    if later == sample or not later.is_file():
        return
    with later.open(encoding='utf-8-sig', newline='') as stream:
        refresher = csv.DictReader(stream)
        assert set(ref['columns']).issubset(refresher.fieldnames)
        refresh = {row['application_id']: row for row in refresher}
    old = {r['application_id']: r for r in archived if r['module2_run_id']=='M2-01'}
    overlap = old.keys() & refresh.keys()
    assert (len(old), len(refresh), len(overlap)) == (341, 1_408, 61)
    for key in overlap:
        assert pc.sample_record(old[key], ref['columns']) == pc.sample_record(refresh[key], ref['columns'])
    print('PASS public archive checksum for all 13,583 rows and May 28 comparison of 47 fields for all 61 overlapping applications.')


def verify_execution_identity(sample):
    """Test the observed Windows baseline alongside all original campaign runs."""
    ref = pc.reference()
    with sample.open(encoding='utf-8-sig', newline='') as stream:
        exemplars = {}
        for row in csv.DictReader(stream):
            exemplars.setdefault(row['module2_run_id'], row)
    assert set(exemplars) == set(ref['runs']) and len(exemplars) == 39
    refresh = '2026-05-28T12:40:03.698802+00:00'
    with tempfile.TemporaryDirectory() as temp:
        root = Path(temp)
        for run, exemplar in exemplars.items():
            folder = root/run
            folder.mkdir()
            reader = pc.OriginalCampaign(ref, folder)
            reader.expected = int(exemplar['application_id'][4:])
            original = ref['runs'][run]['exportUTC']
            stamp = refresh if run == 'M2-01' else original
            row = dict(exemplar, sample_reason=pc.ORIGINAL, strategy_run_ts=stamp)
            if run != 'M2-01':
                wrong = (pc.utc(original)+timedelta(microseconds=1)).isoformat(timespec='microseconds')
                for changed in (refresh, wrong):
                    try:
                        reader.add(dict(row, strategy_run_ts=changed))
                    except ValueError as exc:
                        assert 'Unknown execution timestamp' in str(exc), (run, changed, exc)
                    else:
                        raise AssertionError((run, 'unexpectedly accepted', changed))
            reader.add(row)
            assert reader.execution_provenance[run] == dict(
                authorityUTC=original, observedUTC=stamp,
                basis='may-28-archive-refresh' if run == 'M2-01' else 'original-snapshot')
    print('PASS exact May 28 Windows timestamp .698802, all 38 original timestamps, and 76 rejected changes to the other 38 runs.')


def fixture(sample):
    ref=pc.reference()
    runs=['M2-01','M2-03']
    by_run={r:{} for r in runs}
    with sample.open(encoding='utf-8-sig',newline='') as f:
        for row in csv.DictReader(f):
            if row['module2_run_id'] in runs:
                by_run[row['module2_run_id']][row['application_id']]=row
    ids=sorted(set(by_run[runs[0]])&set(by_run[runs[1]]))
    assert len(ids)>10
    output=[]
    digest=hashlib.sha256()
    apps=101
    ref['applications']=apps;ref['sources']=['M1-01'];ref['groups']={'CG02':[0,1]}
    ref['runs']={r:dict(ref['runs'][r]) for r in runs}
    for r in runs:
        ref['runs'][r]['totals']={k:Decimal(0) for k in ref['runs'][r]['totals']}
        bits=bytearray((apps+7)//8)
        bits[0]=2
        ref['runs'][r]['sampleBits']=base64.b64encode(zlib.compress(bits)).decode()
    for i in range(1,apps+1):
        src=ids[i%len(ids)]
        for run in runs:
            cfg=ref['runs'][run];row=dict(by_run[run][src])
            row.update(application_id=f'APP-{i:08}',applicant_id=f'CUST-{i:08}',sample_reason=pc.ORIGINAL,
                       strategy_run_ts=cfg['exportUTC'])
            t=cfg['totals'];t[row['decision_outcome']]+=1
            for key,col in [('approved','approved_amount'),('loss','approved_expected_loss_amount'),('requested','requested_amount')]:
                t[key]+=Decimal(row[col] or '0')
            if i==2:digest.update(pc.sample_record(row,ref['columns']))
            output.append(row)
    for r in runs:
        ref['runs'][r]['totals']={k:str(v) for k,v in ref['runs'][r]['totals'].items()}
    ref['sampleRows']=2;ref['sampleProjectionSha256']=digest.hexdigest()
    return ref,output


def write(path,columns,rows):
    with path.open('w',encoding='utf-8-sig',newline='') as f:
        w=csv.DictWriter(f,columns);w.writeheader();w.writerows(rows)


def verify(sample):
    verify_public_sample(sample)
    verify_execution_identity(sample)
    ref,rows=fixture(sample)
    with tempfile.TemporaryDirectory() as temp:
        root=Path(temp);left,right=root/'part1.csv',root/'part2.csv';site=root/'site';out=site/'data/full'
        write(left,ref['columns'],rows[:60]);write(right,ref['columns'],rows[60:])
        manifest=pc.pack([left,right],out,ref,site)
        assert (out/'manifest.json').exists() and manifest['observations']==202
        assert [(s['first'],s['last']) for s in manifest['shards']]==[(1,100),(101,101)]
        assert manifest['verifiedHistoricalSampleRows']==2 and len(manifest['inputFiles'])==2
        assert manifest['executionProvenance']=={r:dict(authorityUTC=ref['runs'][r]['exportUTC'],
                  observedUTC=ref['runs'][r]['exportUTC'],basis='original-snapshot') for r in ref['runs']}
        raw_rows=[]
        for shard in manifest['shards']:
            compressed=(out/shard['file']).read_bytes();plain=pc.gzip.decompress(compressed);obj=json.loads(plain)
            assert pc.sha(compressed)==shard['sha256'] and pc.sha(plain)==shard['uncompressedSha256']
            for sources,source_map,sides,side_map in obj['rows']:
                for i in range(2):
                    def expand(keys,array):
                        return [obj['words'][v] if k in pc.TEXT_FIELDS and v is not None else v for k,v in zip(keys,array)]
                    raw_rows.append((expand(pc.SOURCE_FIELDS,sources[source_map[manifest['runSource'][i]]]),
                                     expand(pc.SIDE_FIELDS,sides[side_map[i]])))
        assert len(raw_rows)==len(rows)
        for raw,(src,side) in zip(rows,raw_rows):
            assert tuple(src)==pc.vector(raw,pc.SOURCE_FIELDS,pc.SOURCE_COLS)
            assert tuple(side)==pc.vector(raw,pc.SIDE_FIELDS,pc.SIDE_COLS)
        def rejected(data,why,output='bad'):
            bad=root/'bad.csv';write(bad,ref['columns'],data)
            try: pc.pack([bad],site/output,ref,site)
            except ValueError as error:
                assert why.lower() in str(error).lower(),(why,error)
                assert not (site/output).exists() and not list((site/output).parent.glob('.campaign-build-*'))
            else: raise AssertionError(why)
        for i,field,value,error in [
                (0,'strategy_run_ts','2026-05-19T23:12:23.669631-04:00','timestamp'),
                (0,'module2_run_id','M2-99','unknown run'),(0,'population_id','TEST','identity'),
                (0,'sample_reason','GUI_GENERATED','identity'),(1,'annual_income','1.00','matched source'),
                (3,'secondary_reason_code','CHANGED_REASON','stratified sample'),
                (1,'application_id','APP-00000002','expected APP-'),(3,'applicant_id','CUST-00000099','applicant ID')]:
            edited=list(rows);edited[i]=dict(edited[i],**{field:value});rejected(edited,error)
        # .698802 is Andrew’s owner-verified database value. The two endpoints
        # are fixtures for the resolver’s unique published-millisecond check.
        for stamp in ('2026-05-28T12:40:03.698000+00:00','2026-05-28T12:40:03.698802+00:00',
                      '2026-05-28T12:40:03.698999+00:00'):
            refreshed=[dict(r, strategy_run_ts=stamp) if r['module2_run_id']=='M2-01' else dict(r) for r in rows]
            q=root/'refresh.csv';write(q,ref['columns'],refreshed)
            fresh_dir=site/('fresh-'+stamp[20:26])
            fresh=pc.pack([q],fresh_dir,ref,site)
            evidence=fresh['executionProvenance']['M2-01']
            assert evidence==dict(authorityUTC=ref['runs']['M2-01']['exportUTC'],observedUTC=stamp,basis='may-28-archive-refresh')
            assert fresh['executionProvenance']['M2-03']==manifest['executionProvenance']['M2-03']
            assert json.loads((fresh_dir/'manifest.json').read_text())['executionProvenance']==fresh['executionProvenance']
        # Both executions are admissible in isolation; any interleaving is rejected.
        for bad_stamp,error in [
                (ref['runs']['M2-01']['exportUTC'],'Mixed execution timestamps'),
                ('2026-05-28T12:40:03.698001+00:00','Mixed execution timestamps'),
                ('2026-05-28T12:40:03.697999+00:00','Unknown execution timestamp'),
                ('2026-05-28T12:40:03.699000+00:00','Unknown execution timestamp'),
                ('2026-05-28T12:40:03.698+00:00','six-digit database'),
                ('2026-05-28T12:40:03.6989997+00:00','six-digit database')]:
            changed=list(refreshed);changed[2]=dict(changed[2],strategy_run_ts=bad_stamp);rejected(changed,error)
        other_run=list(refreshed);other_run[1]=dict(other_run[1],strategy_run_ts=stamp)
        rejected(other_run,'Unknown execution timestamp')
        drift=list(refreshed);drift[2]=dict(drift[2],tertiary_reason_code='DIFFERENT_AFTER_REFRESH')
        rejected(drift,'stratified sample')
        rejected(rows[:-1],'incomplete archive');rejected([rows[0],rows[0],*rows[2:]],'duplicate')
        edited=list(rows)
        for k in [18,19]:edited[k]=dict(edited[k],requested_amount=rows[k]['requested_amount'])
        ref['runs']['M2-01']['totals']['loss']=str(Decimal(ref['runs']['M2-01']['totals']['loss'])+1)
        rejected(edited,'differs from historical')
        ref['runs']['M2-01']['totals']['loss']=str(Decimal(ref['runs']['M2-01']['totals']['loss'])-1)
        budget=pc.DATA_BYTES
        try:pc.DATA_BYTES=40;rejected(rows,'publication budget')
        finally:pc.DATA_BYTES=budget
        budget=pc.SITE_BYTES
        try:pc.SITE_BYTES=40;rejected(rows,'site plus data')
        finally:pc.SITE_BYTES=budget
        try:pc.pack([left,right],out,ref,site)
        except ValueError as error:assert 'existing' in str(error)
        else:raise AssertionError('existing validated output')
    print('PASS: two-part realistic fixture, 101 applicants, 2 shards, every projected value round-tripped, verified separate original and May 28 manifest provenance, mixed/unknown execution rejection, corruption and budget rejection, atomic output preservation.')


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('public_sample',type=Path)
    verify(parser.parse_args().public_sample)
