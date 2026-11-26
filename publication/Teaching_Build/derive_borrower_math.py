"""Derive Module 1 v2 borrower mathematics for the displayed historical cases.

Uses pg_temp only. Set PGHOST, PGUSER, PGDATABASE and PGPORT to a scratch
PostgreSQL 17 instance. The two controls are the original Module 1 DBeaver
CSV exports and the decision inputs retained in each original/returned case.
"""
import argparse
import csv
import hashlib
import io
import json
import re
import subprocess
from collections import Counter, defaultdict
from decimal import Decimal as D, ROUND_HALF_UP
from pathlib import Path
from urllib.parse import quote

PIN = '65e7cc84528008ea40c6f9bb70a02745df592f4c'
ROOT = 'https://github.com/andrew-goad/credit_decisioning_strategy/blob/' + PIN + '/'
HASH = 'ae9875d8f4a23eef2441bb6948ab5d71270bafebb086322d8db67711347e42f4'
# UI key, source observation, multiplier in SQL, display name, display unit.
FACTORS = [
 ('delinquency','delinquency_count_12m','mult_delinq','Delinquencies in 12 months','count'),
 ('derogatory','major_derogatory_flag','mult_derog','Major derogatory event','flag'),
 ('bankruptcy','bankruptcy_flag','mult_bankruptcy','Bankruptcy','flag'),
 ('utilization','utilization_rate','mult_util','Revolving credit utilization','percent'),
 ('dti','debt_to_income_ratio','mult_dti','Existing debt-to-income ratio','percent'),
 ('inquiries','recent_inquiry_count','mult_inquiry','Recent credit inquiries','count'),
 ('tradelines','tradeline_count','mult_tradeline','Credit accounts on file','count'),
 ('fileAge','months_since_oldest_trade','mult_file_age','Age of oldest credit account','months'),
 ('pti','payment_to_income_ratio','mult_pti','New payment / monthly income','percent'),
 ('amountIncome','amount_to_income_ratio','mult_amt_income','Amount requested / annual income','percent'),
 ('product','product_type','mult_product','Product','category')]
SOURCE = {'product':'product_type','band':'score_band','score':'credit_score','income':'annual_income',
 'request':'requested_amount','payment':'monthly_payment_proxy','pti':'payment_to_income_ratio',
 'dti':'debt_to_income_ratio','pd':'estimated_pd','lgd':'estimated_lgd','requestEL':'expected_loss_amount'}
INTAKE = {'product':'product','band':'score_band','score':'credit_score','income':'annual_income',
 'request':'requested_amount','pti':'requested_payment_to_income_ratio','pd':'estimated_pd',
 'lgd':'estimated_lgd','requestEL':'requested_expected_loss_amount'}
LGD = {'MORTGAGE':'lgd_mortgage','HELOC':'lgd_heloc','REVOLVING_LINE':'lgd_revolving',
       'AUTO_LOAN':'lgd_auto','UNSECURED_PERSONAL_LOAN':'lgd_personal'}
SIX, CENT = D('.000001'), D('.01')


def require(value, message):
    if not value: raise ValueError(message)


def rounded(value, precision=SIX):
    return value.quantize(precision, rounding=ROUND_HALF_UP)


def match(left, right):
    if str(left)==str(right): return True
    try: return D(str(left))==D(str(right))
    except ArithmeticError: return (str(left).lower(),str(right).lower()) in {('true','t'),('false','f'),('t','true'),('f','false')}


def inputs(target, case, where):
    s = target.setdefault(where, {})
    for k,v in case.items():
        if k in SOURCE and v not in ('',None):
            col=SOURCE[k]
            require(col not in s or match(v,s[col]),f'Conflicting saved {col} for {where}')
            s[col]=v


def literal(value, sql_type):
    if sql_type in ('TEXT','DATE'): return "'"+str(value).replace("'","''")+"'"
    if sql_type=='BOOLEAN':
        require(type(value) is bool,'Expected boolean parameter')
        return 'TRUE' if value else 'FALSE'
    return format(D(str(value)),'f')


def source_rows(path):
    with path.open(encoding='utf-8-sig',newline='') as f:
        reader=csv.DictReader(f)
        for row in reader: yield reader.line_num,row


def extract(args):
    repo=args.repository; data=args.case_dir
    p,=repo.glob('Module_1*/v2.0/src/*.sql')
    s=p.read_text(encoding='utf-8-sig')
    require(hashlib.sha256(s.encode()).hexdigest()==HASH,'Unexpected Module 1 SQL source')
    lines=s.splitlines(keepends=True)
    # Restrict generate_series to the actual selected IDs. No source formula changes.
    tmpl=('BEGIN;\nSET LOCAL search_path=pg_temp,pg_catalog;\nSET LOCAL standard_conforming_strings=on;\n'
          +''.join(lines[1047:1226])+'%%PARAMETERS%%\n'+''.join(lines[1436:4812]))
    generate='FROM generate_series(1, (SELECT application_count FROM params)) AS gs'
    dest='CREATE TABLE credit_decisioning_sim.synthetic_applications AS'
    require(tmpl.count(generate)==1 and tmpl.count(dest)==1,'Unexpected source anchors')
    tmpl=tmpl.replace(generate,generate+' WHERE gs=ANY(ARRAY[%%IDS%%])').replace(dest,'CREATE TEMP TABLE synthetic_applications AS')
    tmpl+=("""
COPY (SELECT a.*,s.u15, (0.95+(s.u15*0.10)) AS jitter
      FROM pg_temp.synthetic_applications a JOIN pg_temp.tmp_m1_stage_4_risk s USING (application_id))
 TO STDOUT WITH (FORMAT CSV,HEADER);
ROLLBACK;""")
    observed={}
    groups=json.loads((data/'cases.json').read_text())['groups']
    for group in groups.values():
        for case in group['cases']: inputs(observed,case,(group['scenario'],case['id']))
    june_path=data/'june_cases.json'
    if june_path.exists():
        for case in json.loads(june_path.read_text())['cases']: inputs(observed,case,(case['scenario'],case['id']))
    intake_rows=0
    for _,r in source_rows(args.returned):
        if not r['application_id']: continue
        intake_rows+=1
        inputs(observed,{key:r[col] for key,col in INTAKE.items()},(r['scenario_name'],r['application_id']))
    refs={}
    baseline,=repo.glob('Module_1*/v2.0/outputs/*OUTPUT_synthetic_applications.csv')
    archive,=repo.glob('Module_1*/v2.0/outputs/*OUTPUT_RANDOM_SAMPLE_synthetic_applications_scenario_archive.csv')
    for f,kind in [(archive,'scenario-sample'),(baseline,'baseline-output')]:
        for n,r in source_rows(f):
            key=r['scenario_name'],r['application_id']
            if key in observed: refs[key]=(kind,f,n,r)
    cfg=json.loads(args.catalog.read_text()); fields=cfg['fields']
    defaults={f['name']:f['default'] for f in fields}
    scenarios={v['scenario_name']:defaults|v['overrides'] for v in cfg['presets']}
    records=defaultdict(dict); quality=Counter()
    for name in sorted(set(scn for scn,_ in observed)):
        params=scenarios[name]; ids=sorted(a for scn,a in observed if scn==name)
        require(all(re.fullmatch(r'APP-\d{8}',a) and 0<int(a[4:])<=50000 for a in ids),'Bad application identifier')
        sql=tmpl.replace('%%PARAMETERS%%',',\n'.join(literal(params[f['name']],f['sql_type']) for f in fields))
        sql=sql.replace('%%IDS%%',','.join(str(int(a[4:])) for a in ids))
        r=subprocess.run([args.psql,'-Xq','-v','ON_ERROR_STOP=1','-f','-'],input=sql,text=True,capture_output=True)
        require(r.returncode==0,r.stderr)
        for a in csv.DictReader(io.StringIO(r.stdout)):
            app=a['application_id']; key=(name,app); require(app not in records[name] and a['scenario_name']==name,'Duplicate or incorrect source')
            for col,v in observed[key].items(): require(match(a[col],v),f'{key} saved {col} {v} vs SQL {a[col]}')
            source='canonical-replay'; source_line=None
            if key in refs:
                source,_,source_line,orig=refs[key]
                for k,v in orig.items():
                    if k in ('created_ts','sample_reason'):continue
                    column='base_apr_for_payment_calc' if k=='apr_proxy' else k
                    require(match(a[column],v),f'{key} M1 {k} {v} vs SQL {a[column]}')
            obs={}; fac={}; product=D(a['base_pd'])
            for k,c,m,_,unit in FACTORS:
                val=a[c]; obs[k]=val in ('t','true') if unit=='flag' else val if unit=='category' else int(val) if unit in ('count','months') else float(val)
                fac[k]=float(a[m]); product*=D(a[m])
            # Independently recompute each post-multiplication stage from the emitted operands.
            seed=app+'|'+a['population_id']+'|u15'
            uniform=D(int(hashlib.md5(seed.encode()).hexdigest()[:15],16))/D(16**15)
            require(abs(uniform-D(a['u15']))<D('0.00000000000000005'),f'{key} seed draw')
            raw=rounded(product*D(a['jitter']))
            sat=rounded(raw if raw<=D('.30') else D('.30')+(raw-D('.30'))*D('.50') if raw<=D('.55') else D('.425')+(raw-D('.55'))*D('.15'))
            pd=rounded(max(D('.005'),min(D('.45'),sat))); lgd=D(str(params[LGD[a['product_type']]]))
            loss=rounded(D(a['requested_amount'])*pd*lgd,CENT)
            for col,value in [('pd_raw_pre_saturation_v2',raw),('pd_after_saturation_v2',sat),('estimated_pd',pd),('estimated_lgd',lgd),('expected_loss_amount',loss)]:
                require(D(a[col])==value,f'{key} independent {col} check failed')
            records[name][app]=dict(basePD=float(a['base_pd']),factors=fac,observations=obs,
                band=a['score_band'],score=int(a['credit_score']),income=float(a['annual_income']),
                request=float(a['requested_amount']),payment=float(a['monthly_payment_proxy']),
                aprForPayment=float(a['base_apr_for_payment_calc']),termMonths=int(a['loan_term_months']) if a['loan_term_months'] else None,
                population=a['population_id'],u15=float(a['u15']),jitter=float(a['jitter']),rawPD=float(raw),zone=a['pd_saturation_zone_v2'],
                afterSaturation=float(sat),pd=float(pd),lgd=float(lgd),lgdParameter=LGD[a['product_type']],requestedEL=float(loss),
                source=source,sourceRow=source_line)
            quality[source]+=1
        require(sorted(records[name])==ids,'Missing returned IDs')
    result=dict(schemaVersion=1,sqlSHA256=HASH,records=records,sourceFiles={
        'sql':ROOT+quote(p.relative_to(repo).as_posix()),'baseline-output':ROOT+quote(baseline.relative_to(repo).as_posix()),
        'scenario-sample':ROOT+quote(archive.relative_to(repo).as_posix())},
        factorMeta=[dict(key=k,label=title,unit=unit,observation=c,sqlFactor=m) for k,c,m,title,unit in FACTORS],
        evidence=dict(matchedReturnedRows=intake_rows,scenarioApplications=len(observed),scenarios=len(records),sources=dict(quality)),
        methodology='Synthetic risk proxy. The score band supplies the starting value. Eleven factors and a repeatable population-and-application-specific multiplier precede six-decimal rounding, tail compression, and the 0.5% to 45% limits. The effective product LGD parameter supplies assumed loss severity. Direct-source row numbers refer to retained DBeaver exports. Other inputs were recovered by executing the pinned Module 1 logic for the historical scenario and matching the saved decision inputs.')
    args.output.write_text(json.dumps(result,separators=(',',':'),ensure_ascii=False)+'\n')
    print(json.dumps(result['evidence'],indent=2))


if __name__=='__main__':
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--repository',type=Path,required=True)
    ap.add_argument('--catalog',type=Path,required=True)
    ap.add_argument('--case-dir',type=Path,default=Path(__file__).parent)
    ap.add_argument('--returned',type=Path,required=True)
    ap.add_argument('--output',type=Path,required=True)
    ap.add_argument('--psql',default='psql')
    extract(ap.parse_args())
