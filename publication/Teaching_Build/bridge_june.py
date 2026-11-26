"""Add study records only when run, application, scenario, and inputs match on both sides."""
import base64
import csv
import hashlib
from decimal import Decimal
from pathlib import Path
from urllib.parse import quote

CASES = {
    'APPROVE_COUNTEROFFER_REVIEW_CASE.csv': ('APP-00013809','BASELINE_V2','One mortgage, three decision paths','46770e362d0110bbbad4bfb363c36aedccd8835890101432024dbc4206fdbb95'),
    'APPROVE_COUNTEROFFER_REVIEW_CASE_MODULE1_V2_CREDIT_BOX_SENSITIVITY_SET_NEAR_PRIME_EXPANSION_MIX.csv':('APP-00010577','NEAR_PRIME_EXPANSION_MIX','A mortgage in the near-prime mix','46de27718d311fe4d024f7555f74a09c0c4d4433eaa7f21cf32e8f68e9f8821c'),
    'MANUAL_REVIEW_TO_DECLINE_GOVERNANCE_CASE.csv':('APP-00040465','BASELINE_V2','How a policy resolves an unsuccessful counteroffer','4f0299fa2b482242c87be02f37b0e0e24432e61352e5c76f110786fd39ee6116'),
    'SELECTIVE_VS_AGGRESSIVE_COUNTEROFFER_CASE.csv':('APP-00028510','BASELINE_V2','When a reduced offer becomes feasible','ed47d8cae04b94a9090eb4871d216ec758687083ac48084fad38e127d7d8c6c7'),
}
SRC={'product':'product_type','band':'score_band','score':'credit_score','income':'annual_income','dti':'debt_to_income_ratio','request':'requested_amount','pti':'requested_payment_to_income_ratio','pd':'estimated_pd','lgd':'estimated_lgd','requestEL':'requested_expected_loss_amount'}
M1_KEYS={'requested_payment_to_income_ratio':'payment_to_income_ratio','requested_expected_loss_amount':'expected_loss_amount'}
SIDE={'outcome':'decision_outcome','primary':'primary_reason_code','secondary':'secondary_reason_code','tertiary':'tertiary_reason_code','path':'decision_path','approved':'approved_amount','approvedEL':'approved_expected_loss_amount','pti':'approved_payment_to_income_ratio'}

def comparable(a,b):
    if a==b:return True
    try:return Decimal(a)==Decimal(b)
    except: return False

def value(k,x):
    if not x:return None
    if k in ('product','band','outcome','primary','secondary','tertiary','path'):return x
    if k=='score':return int(x)
    return float(x)

def add_june(data,folder,repo):
    ids={v[0] for v in CASES.values()}
    copied={}
    m1=next(repo.glob('Module_1*/v2.0/outputs/*OUTPUT_synthetic_applications.csv'))
    original='https://github.com/andrew-goad/credit_decisioning_strategy/blob/65e7cc84528008ea40c6f9bb70a02745df592f4c/'+quote(m1.relative_to(repo).as_posix())
    with m1.open(encoding='utf-8-sig',newline='') as f:
        reader=csv.DictReader(f)
        for r in reader:
            if r['application_id'] in ids:
                copied[r['application_id'],r['scenario_set_name'],r['scenario_name'],r['population_id']]=(reader.line_num,r)
    data['juneSources']={}
    for filename,(app,scenario,study,digest) in CASES.items():
        path=folder/filename
        raw=path.read_bytes()
        if hashlib.sha256(raw).hexdigest()!=digest:raise ValueError('June source checksum changed: '+filename)
        source='june-'+app
        data['juneSources'][source]={'filename':filename,'href':'data:text/csv;base64,'+base64.b64encode(raw).decode(),'sha256':digest}
        with path.open(encoding='utf-8-sig',newline='') as f:
            reader=csv.DictReader(f);rows={}
            for r in reader:
                run=r['module2_run_id']
                if r['application_id']!=app or r['module1_scenario_name']!=scenario or run in rows:
                    raise ValueError('Unexpected study identity in '+filename)
                rows[run]=(reader.line_num,r)
        if len(rows)!=(4 if scenario=='NEAR_PRIME_EXPANSION_MIX' else 8):
            raise ValueError('Incomplete source policy records for '+app)
        for group in data['groups'].values():
            a,b=group['baseRun'],group['challengeRun']
            if group['scenario']!=scenario or a not in rows or b not in rows: continue
            if any(c['id']==app for c in group['cases']):raise ValueError('Resolve duplicate original evidence for '+app)
            ra,rb=rows[a][1],rows[b][1]
            fixed=tuple(SRC.values())+('module1_scenario_set_name','module1_scenario_name','population_id','application_id')
            if any(not comparable(ra[k],rb[k]) for k in fixed):raise ValueError('Application inputs differ across June records: '+app)
            def side(run):
                r=rows[run][1]
                return {**{k:value(k,r[v]) for k,v in SIDE.items()},'resolution':None,'payment':None,'paymentUnavailable':True,'source':source,'line':rows[run][0]}
            case={**{k:value(k,ra[v]) for k,v in SRC.items()},'id':app,'payment':None,'base':side(a),'challenge':side(b),'sourceStudy':study}
            match=copied.get((app,ra['module1_scenario_set_name'],scenario,ra['population_id']))
            if match:
                n,full=match
                if any(not comparable(ra[k],full[M1_KEYS.get(k,k)]) for k in SRC.values()):raise ValueError('Module 1 source values differ for '+app)
                case['payment']=float(full['monthly_payment_proxy'])
                case['paymentProof']=original+'#L'+str(n)
            group['cases'].append(case)
    return data
