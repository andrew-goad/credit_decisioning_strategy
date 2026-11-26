"""Build an applicant-level GitHub Pages archive from reconciled DBeaver campaign exports."""
import argparse
import base64
from collections import Counter, defaultdict
from datetime import date, datetime, timezone
from functools import lru_cache
from decimal import Decimal, InvalidOperation
import csv
import gzip
import hashlib
import io
import json
from pathlib import Path
import random
import re
import shutil
import sys
import tempfile
import zlib

ROOT = Path(__file__).resolve().parent
REFERENCE = ROOT / 'full_campaign_reference.json'
REFERENCE_HASH = 'b4546614dfe851ae43c316afa31d672a80cd7b15ca5b9289e211556301d9f43d'
SOURCE_FIELDS = ('product', 'band', 'score', 'income', 'dti', 'request', 'payment', 'pti', 'pd', 'lgd', 'requestEL')
SOURCE_COLS = ('product_type','score_band','credit_score','annual_income','debt_to_income_ratio','requested_amount',
               'requested_monthly_payment_proxy','requested_payment_to_income_ratio','estimated_pd','estimated_lgd',
               'requested_expected_loss_amount')
SIDE_FIELDS = ('outcome','approved','approvedEL','payment','pti','primary','secondary','tertiary','path','resolution')
SIDE_COLS = ('decision_outcome','approved_amount','approved_expected_loss_amount','approved_monthly_payment_proxy',
             'approved_payment_to_income_ratio','primary_reason_code','secondary_reason_code','tertiary_reason_code',
             'decision_path','decision_resolution_source')
TEXT_FIELDS = {'product','band','outcome','primary','secondary','tertiary','path','resolution'}
OUTCOMES = ('APPROVE','COUNTEROFFER','MANUAL_REVIEW','DECLINE')
FLAGS = ('approval_flag','counteroffer_flag','manual_review_flag','decline_flag')
IDENTITY = ('strategy_set_name','strategy_name','strategy_version','strategy_run_id','module1_scenario_set_name','module1_scenario_name','population_id')
REASONS = ('APPROVAL','COUNTEROFFER','MANUAL_REVIEW','POLICY_STOP')
NUMERIC = {'credit_score','reason_code_count','counteroffer_amount','exposure_reduction_amount','exposure_reduction_pct',
           'approved_el_reduction_amount','approved_el_reduction_pct',*SOURCE_COLS[2:],*SIDE_COLS[1:5]}
SHARD_SIZE = 100
ORIGINAL = 'ORIGINAL_FULL_DBEAVER_CAMPAIGN'
DATA_BYTES = 800_000_000
SITE_BYTES = 1_000_000_000
# The preserved May 28 M2-01 extract exposes the millisecond. The CSV query
# writes the six-digit time actually stored in the database for every row.
M2_01_REFRESH_MS = datetime(2026, 5, 28, 12, 40, 3, 698000, tzinfo=timezone.utc)
FULL_DB_STAMP = re.compile(r'\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}:\d{2}\.\d{6}\s?(?:Z|[+-]\d{2}:?\d{2})')


def binary_json(value):
    return json.dumps(value, separators=(',',':'), ensure_ascii=True, allow_nan=False).encode('ascii')


def sha(data):
    return hashlib.sha256(data).hexdigest()


def utc(raw):
    value = datetime.fromisoformat(raw.replace(' -','-').replace(' +','+'))
    if value.tzinfo is None:
        raise ValueError('Execution time needs a UTC offset.')
    return value.astimezone(timezone.utc)


@lru_cache(maxsize=1024)
def valid_date(value):
    when = date.fromisoformat(value)
    return when.year == 2025 and when.isoformat() == value


def num(value):
    number = Decimal(value)
    if not number.is_finite():
        raise ValueError('A finite numeric value is required.')
    return number


def sample_record(row, columns):
    """Representation shared by the public stratified extract and the full DBeaver export."""
    record = []
    for name in columns:
        if name in ('strategy_run_ts','sample_reason'):
            continue
        raw = row[name]
        if raw and name in NUMERIC:
            raw = format(num(raw), 'f')
            if '.' in raw:
                raw = raw.rstrip('0').rstrip('.')
            if raw in ('-0',''): raw = '0'
        if name.endswith('_flag'):
            raw = {'true':'true','false':'false','t':'true','f':'false'}[raw.lower()]
        record.append(raw)
    return binary_json(record)+b'\n'


def vector(row, names, columns):
    result = []
    for name, key in zip(names,columns):
        value = row[key]
        if value == '':
            result.append(None)
        elif name in TEXT_FIELDS:
            result.append(value)
        elif name == 'score':
            result.append(int(value))
        else:
            # Use standard browser numeric precision; exact decimals are reconciled before projection.
            result.append(float(num(value)))
    return tuple(result)


def unique_vectors(vectors, fields, vocabulary):
    lookup, unique, indices = {}, [], []
    for vec in vectors:
        index = lookup.get(vec)
        if index is None:
            index = len(unique)
            lookup[vec] = index
            unique.append([vocabulary.setdefault(v,len(vocabulary)) if v is not None and k in TEXT_FIELDS else v
                           for k,v in zip(fields,vec)])
        indices.append(index)
    return unique, indices


def encode_case(source_rows, outcomes, vocabulary):
    sv, si = unique_vectors(source_rows,SOURCE_FIELDS,vocabulary)
    ov, oi = unique_vectors(outcomes,SIDE_FIELDS,vocabulary)
    return [sv,si,ov,oi]


def compress_shard(first, records, vocabulary):
    raw = binary_json(dict(first=first,words=list(vocabulary),rows=records))
    packed = gzip.compress(raw, compresslevel=6,mtime=0)
    return raw, packed


class DigestedReader(io.RawIOBase):
    def __init__(self, stream, digest):
        self.stream, self.digest = stream,digest

    def readable(self):
        return True

    def readinto(self, target):
        count = self.stream.readinto(target)
        if count:
            self.digest.update(memoryview(target)[:count])
        return count


class OriginalCampaign:
    def __init__(self, ref, folder):
        self.ref,self.folder=ref,folder
        self.runs=list(ref['runs'])
        self.run_index={run:i for i,run in enumerate(self.runs)}
        self.sources=ref['sources']
        self.source_index={name:i for i,name in enumerate(self.sources)}
        self.run_source=[self.source_index[ref['runs'][run]['source']] for run in self.runs]
        self.masks=[zlib.decompress(base64.b64decode(ref['runs'][run]['sampleBits'])) for run in self.runs]
        self.seen_sample=hashlib.sha256()
        self.sample_rows=0
        self.counts=[Counter() for _ in self.runs]
        self.input_hashes=[]
        self.assets=[]
        self.written=0
        self.stamps={r:set() for r in self.runs}
        self.execution_provenance={}
        self.shard=self.vocab=None
        self.new_shard()
        self.source_rows=self.source_check=self.outcomes=self.samples=None
        self.new_app()
        self.expected=1
        self.rows=0
        (folder/'shards').mkdir()

    def new_app(self):
        self.source_rows=[None]*len(self.sources)
        self.source_check=[None]*len(self.sources)
        self.outcomes=[None]*len(self.runs)
        self.samples={}

    def new_shard(self):
        self.shard=[]
        self.vocab={}

    def add(self, row):
        run=row['module2_run_id']
        if run not in self.run_index:
            raise ValueError(f'Unknown run {run!r}.')
        i=self.run_index[run]; source=self.run_source[i]; cfg=self.ref['runs'][run]
        expected_id=f'APP-{self.expected:08}'
        if row['application_id']!=expected_id:
            raise ValueError(f'Expected {expected_id}; got {row["application_id"]}. Check sorting, duplicates and missing IDs.')
        if row['applicant_id']!=f'CUST-{self.expected:08}':
            raise ValueError(f'Unexpected applicant ID on {expected_id}.')
        if self.outcomes[i] is not None:
            raise ValueError(f'Duplicate {run}/{expected_id}.')
        if row['sample_reason']!=ORIGINAL or any(row[k]!=cfg[k] for k in IDENTITY):
            raise ValueError(f'Original strategy or source identity mismatch for {run}/{expected_id}.')
        stamp=row['strategy_run_ts']
        if stamp not in self.stamps[run]:
            if not FULL_DB_STAMP.fullmatch(stamp):
                raise ValueError(f'Expected a six-digit database execution timestamp with UTC offset for {run}/{expected_id}.')
            observed=utc(stamp)
            authority=utc(cfg['exportUTC'])
            if observed==authority:
                basis='original-snapshot'
            elif run=='M2-01' and observed.replace(microsecond=(observed.microsecond//1000)*1000)==M2_01_REFRESH_MS:
                basis='may-28-archive-refresh'
            else:
                raise ValueError(f'Unknown execution timestamp for {run}/{expected_id}.')
            instant=observed.isoformat(timespec='microseconds')
            evidence=self.execution_provenance.get(run)
            if evidence and evidence['observedUTC']!=instant:
                raise ValueError(f'Mixed execution timestamps for {run}/{expected_id}.')
            self.execution_provenance[run]=dict(authorityUTC=authority.isoformat(timespec='microseconds'),
                                               observedUTC=instant,basis=basis)
            self.stamps[run].add(stamp)
        outcome=row['decision_outcome']
        if outcome not in OUTCOMES:
            raise ValueError(f'Unknown decision outcome {outcome}.')
        flag=lambda key: {'true':True,'false':False,'t':True,'f':False}[row[key].lower()]
        idx=OUTCOMES.index(outcome)
        if any(flag(k)!=(n==idx) for n,k in enumerate(FLAGS)) or flag('simulated_offer_exposure_flag')!=(idx<2):
            raise ValueError(f'Decision and flags disagree for {run}/{expected_id}.')
        if not row['primary_reason_code'] or row['primary_reason_family']!=REASONS[idx] or not row['decision_path'] or not row['decision_resolution_source']:
            raise ValueError(f'Incomplete reason or route for {run}/{expected_id}.')
        request=num(row['requested_amount'])
        amount=num(row['approved_amount']) if row['approved_amount'] else None
        loss=num(row['approved_expected_loss_amount']) if row['approved_expected_loss_amount'] else None
        if idx==0: valid=amount==request and loss is not None and loss>=0
        elif idx==1: valid=amount is not None and 0<amount<request and amount==num(row['counteroffer_amount']) and loss is not None and loss>=0
        elif idx==2: valid=amount is None and loss is None
        else: valid=amount==0 and loss==0
        if not valid:
            raise ValueError(f'Invalid amount or loss for {outcome} on {run}/{expected_id}.')
        # Compare decimal source values exactly before binary numeric projection for browsers.
        attrs=tuple(row[k] for k in ('application_date','product_type','score_band'))+tuple(num(row[k]) for k in SOURCE_COLS[2:])
        if (not valid_date(attrs[0]) or attrs[1] not in ('MORTGAGE','AUTO_LOAN','HELOC','REVOLVING_LINE','UNSECURED_PERSONAL_LOAN')
            or attrs[2] not in ('SUPER_PRIME','PRIME','NEAR_PRIME','SUBPRIME','DEEP_SUBPRIME')):
            raise ValueError(f'Unexpected application date, product or score band for {expected_id}.')
        if self.source_check[source] is not None and self.source_check[source]!=attrs:
            raise ValueError(f'Matched source differs between policies for {self.sources[source]}/{expected_id}.')
        if self.source_rows[source] is None:
            self.source_check[source]=attrs
            self.source_rows[source]=vector(row,SOURCE_FIELDS,SOURCE_COLS)
        self.outcomes[i]=vector(row,SIDE_FIELDS,SIDE_COLS)
        counts=self.counts[i];counts[outcome]+=1;counts['requested']+=request
        counts['approved']+=amount or 0;counts['loss']+=loss or 0
        x=self.expected-1
        if self.masks[i][x//8] & (1<<(x%8)):
            self.samples[i]=sample_record(row,self.ref['columns'])
        self.rows+=1
        if self.rows % len(self.runs)==0:
            if None in self.outcomes or None in self.source_rows:
                raise ValueError(f'Incomplete run set for {expected_id}.')
            for k in sorted(self.samples):
                self.seen_sample.update(self.samples[k]);self.sample_rows+=1
            self.shard.append(encode_case(self.source_rows,self.outcomes,self.vocab));self.expected+=1
            self.new_app()
            if len(self.shard)==SHARD_SIZE:
                self.flush()

    def flush(self):
        first=self.expected-len(self.shard);last=self.expected-1
        raw,packed=compress_shard(first,self.shard,self.vocab)
        name=f'shards/{first:05}-{last:05}.json.gz'
        self.written+=len(packed)
        if self.written>DATA_BYTES:
            raise ValueError('Packed full-campaign data exceeds its 800 MB publication budget.')
        (self.folder/name).write_bytes(packed)
        self.assets.append(dict(first=first,last=last,file=name,bytes=len(packed),sha256=sha(packed),
                                uncompressedBytes=len(raw),uncompressedSha256=sha(raw)))
        self.new_shard()

    def read(self,path):
        digest=hashlib.sha256();count=0
        with path.open('rb') as source, io.TextIOWrapper(io.BufferedReader(DigestedReader(source,digest)),
                                                         encoding='utf-8-sig',newline='') as stream:
            reader=csv.DictReader(stream)
            if not reader.fieldnames or set(reader.fieldnames)!=set(self.ref['columns']) or len(reader.fieldnames)!=len(self.ref['columns']):
                raise ValueError(f'{path.name}: expected all original archive columns exactly once.')
            for count,row in enumerate(reader,1):
                if self.expected>self.ref['applications'] or None in row or None in row.values():
                    raise ValueError(f'{path.name} row {count+1}: excess or malformed row.')
                try:
                    self.add(row)
                except (ArithmeticError,ValueError,KeyError,IndexError) as exc:
                    raise ValueError(f'{path.name} row {count+1}: {exc}') from exc
        if not count:raise ValueError(f'{path.name}: no original data rows.')
        self.input_hashes.append(dict(bytes=path.stat().st_size,sha256=digest.hexdigest(),rows=count))

    def finish(self):
        if self.rows!=len(self.runs)*self.ref['applications'] or self.expected!=self.ref['applications']+1:
            raise ValueError(f'Incomplete archive: {self.rows:,} rows / {self.expected-1:,} complete applicants.')
        if self.sample_rows!=self.ref['sampleRows'] or self.seen_sample.hexdigest()!=self.ref['sampleProjectionSha256']:
            raise ValueError('Original stratified sample disagrees with the full export.')
        for i,run in enumerate(self.runs):
            for k,v in self.ref['runs'][run]['totals'].items():
                if self.counts[i][k]!=Decimal(v):
                    raise ValueError(f'{run} {k}: full export {self.counts[i][k]} differs from historical {v}.')
        if self.shard:self.flush()
        return dict(schemaVersion=1,kind='original-full-dbeaver',authorityCommit=self.ref['authorityCommit'],
                    applications=self.ref['applications'],shardSize=SHARD_SIZE,sources=self.sources,runs=self.runs,
                    runSource=self.run_source,groups=self.ref['groups'],sourceFields=SOURCE_FIELDS,outcomeFields=SIDE_FIELDS,
                    symbolFields=sorted(TEXT_FIELDS),shards=self.assets,packedDataBytes=self.written,
                    observations=self.rows,inputFiles=self.input_hashes,verifiedHistoricalSampleRows=self.sample_rows,
                    referenceSha256=REFERENCE_HASH,exportSelection=ORIGINAL,
                    executionProvenance={r:self.execution_provenance[r] for r in self.runs})


def pack(paths,out,ref,site_root=None):
    if out.exists(): raise ValueError('Choose a new output directory; an existing build will be preserved.')
    out.parent.mkdir(parents=True,exist_ok=True)
    if site_root and not out.resolve().is_relative_to(site_root.resolve()):
        raise ValueError('Output must lie within the supplied --site-root.')
    stage=Path(tempfile.mkdtemp(prefix='.campaign-build-',dir=out.parent))
    try:
        campaign=OriginalCampaign(ref,stage)
        for p in paths:campaign.read(p)
        manifest=campaign.finish()
        (stage/'manifest.json').write_bytes(binary_json(manifest))
        actual=sum(p.stat().st_size for p in stage.rglob('*') if p.is_file())
        if actual>DATA_BYTES:raise ValueError('Data plus manifest exceed the 800 MB budget.')
        if site_root:
            site_total=sum(p.stat().st_size for p in site_root.rglob('*') if p.is_file()
                           and '.git' not in p.relative_to(site_root).parts)
            if site_total>SITE_BYTES:raise ValueError(f'Site plus data exceed {SITE_BYTES:,} bytes.')
        stage.rename(out)
        return manifest
    finally:
        if stage.exists():shutil.rmtree(stage)


def reference():
    raw=REFERENCE.read_bytes().replace(b'\r\n',b'\n')
    if sha(raw)!=REFERENCE_HASH:raise ValueError('Historical reference file checksum differs.')
    return json.loads(raw)


def estimate(sample_path,ref):
    """Unpaired resampling gives two planning scenarios, not a measured full-export size."""
    if sha(sample_path.read_bytes().replace(b'\r\n',b'\n')) != ref['estimationSampleFileSha256']:
        raise ValueError('Historical estimation sample checksum differs.')
    by_run=defaultdict(lambda: defaultdict(list))
    with sample_path.open(encoding='utf-8-sig',newline='') as f:
        for row in csv.DictReader(f):
            by_run[row['module2_run_id']][row['decision_outcome']].append((vector(row,SOURCE_FIELDS,SOURCE_COLS),vector(row,SIDE_FIELDS,SIDE_COLS)))
    if set(by_run)!=set(ref['runs']) or sum(len(rows) for v in by_run.values() for rows in v.values())!=ref['sampleRows']:
        raise ValueError('Estimate requires the original 13,583-row public sample.')
    outcome_weights={run:[int(cfg['totals'][o]) for o in OUTCOMES] for run,cfg in ref['runs'].items()}
    result={}
    for model in ('weighted-archived-observations','weighted-with-novel-numeric-values'):
        rng=random.Random(20260519)
        sizes=[]
        for batch in range(15):
            vocab={};records=[]
            for person in range(SHARD_SIZE):
                source_rows={};outcomes=[]
                for run,config in ref['runs'].items():
                    outcome=rng.choices(OUTCOMES,weights=outcome_weights[run],k=1)[0]
                    inp,side=rng.choice(by_run[run][outcome])
                    if model=='weighted-with-novel-numeric-values':
                        # Perturb numerical values only to reduce repeated-value compression.
                        # These simulated bytes are never distributed as campaign results.
                        def jitter(vec):
                            return tuple(round(x*(1+rng.uniform(-0.02,0.02)),6) if type(x) is float and x else x for x in vec)
                        inp,side=jitter(inp),jitter(side)
                    source_rows.setdefault(config['source'],inp);outcomes.append(side)
                records.append(encode_case([source_rows[s] for s in ref['sources']],outcomes,vocab))
            sizes.append(len(compress_shard(1+batch*SHARD_SIZE,records,vocab)[1]))
        result[model]={'shards_measured':len(sizes),'mean_shard_bytes':round(sum(sizes)/len(sizes)),
                       'projected_500_shard_bytes':round(sum(sizes)/len(sizes)*500),
                       'largest_measured_shard_bytes':max(sizes)}
    return result


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('csv',nargs='*',type=Path,help='Full CSV or ordered sequential export parts')
    parser.add_argument('--output',type=Path,default=Path('data/full'))
    parser.add_argument('--site-root',type=Path,help='Also enforce the full-site 1,000,000,000-byte budget')
    parser.add_argument('--estimate',type=Path,help='Estimate transport size using the original public sample CSV')
    args=parser.parse_args();ref=reference()
    if args.estimate:
        if args.csv:parser.error('Use either --estimate or the full CSV inputs.')
        print(json.dumps(estimate(args.estimate,ref),indent=2));return
    if not args.csv:parser.error('A complete original export is required.')
    summary=pack(args.csv,args.output,ref,args.site_root)
    execution=summary['executionProvenance']['M2-01']
    print(f"M2-01 {execution['basis']} | observed UTC {execution['observedUTC']} | "
          f"authority UTC {execution['authorityUTC']}")
    print(f"PASS {summary['observations']:,} historical campaign decisions, {summary['applications']:,} applicants, "
          f"{len(summary['shards'])} verified shards, {summary['packedDataBytes']:,} compressed bytes. {args.output}")
if __name__=='__main__':
    try:main()
    except (ValueError,OSError,InvalidOperation,csv.Error) as error:
        sys.exit(f'Pack stopped: {error}')
