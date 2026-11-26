"""Replay Section 8 only on recorded candidate routes; reconcile archived decisions and diagnostics."""
import argparse
import csv
import hashlib
import json
from collections import Counter, defaultdict
from decimal import Decimal as D
from pathlib import Path
from urllib.parse import quote

from bridge_intake import add_returned_cases
from bridge_june import add_june, CASES
from build_worked_decision_math import constraints

ROOT=Path(__file__).resolve().parent
SQL_HASH='833c075d8194a46cb0dc7a92acf32ab2eeddba9238569d57919c7f943d8e39ec'
SNAP_HASH='c7f2cd63513443af4ba683ffac84061df296694e084bec955c7e722961d41f04'
REPO='https://github.com/andrew-goad/credit_decisioning_strategy/blob/65e7cc84528008ea40c6f9bb70a02745df592f4c/'
PATHS={'COUNTEROFFER_FEASIBLE':'P','COUNTEROFFER_NOT_FEASIBLE_REVIEW':'F','COUNTEROFFER_NOT_FEASIBLE_DECLINE':'F'}
DIRECT={'APPROVE_AS_REQUESTED','MANUAL_REVIEW_CANDIDATE','HARD_POLICY_STOP','SEVERE_DTI_CAPACITY','SEVERE_SYNTHETIC_RISK','SEVERE_REQUESTED_STRUCTURE_REVIEW'}
FAIL=['COUNTEROFFER_NOT_ALLOWED_BY_PRODUCT_POLICY','COUNTEROFFER_ROUNDED_AMOUNT_NONPOSITIVE',
      'COUNTEROFFER_NOT_BELOW_REQUESTED_AMOUNT','COUNTEROFFER_BELOW_PRODUCT_MINIMUM',
      'COUNTEROFFER_BELOW_MINIMUM_REQUESTED_PERCENT','COUNTEROFFER_EXCEEDS_MAX_REDUCTION',
      'COUNTEROFFER_EXCEEDS_PRODUCT_CAP','COUNTEROFFER_PTI_STILL_ABOVE_TARGET','COUNTEROFFER_APPROVED_EL_ABOVE_CAP']
PFIELDS=('counteroffer_allowed_flag','product_max_approved_amount','counteroffer_target_pti','product_approved_el_cap',
         'product_min_approved_amount','product_min_counteroffer_pct','product_max_exposure_reduction_pct','approved_amount_rounding_increment')
FIELDS=['productCap','ptiLimit','lossLimit','raw','rounded','minimum','minimumShare','retainedFloor','testPayment','testPTI','testEL']
COLUMN=['counteroffer_product_cap_amount','counteroffer_pti_target_amount','counteroffer_el_cap_amount','counteroffer_raw_max_feasible_amount',
        'counteroffer_rounded_amount','counteroffer_min_viable_amount',None,None,'counteroffer_test_monthly_payment_proxy',
        'counteroffer_test_payment_to_income_ratio','counteroffer_test_expected_loss_amount']


def require(value,msg):
    if not value: raise ValueError(msg)


def load(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def rows(path):
    with path.open(encoding='utf-8-sig',newline='') as f:
        yield from csv.DictReader(f)


def close(a,b):
    return abs(D(str(a))-D(str(b))) <= max(D('.00000001'),abs(D(str(a)))*D('0.000000000000002'))


def truth(v):
    require(v in ('t','f','true','false',True,False), f'Unknown flag {v}')
    return v in ('t','true',True)


def channel(r,ordinary='ordinary_counteroffer_candidate_flag',override='aggressive_counteroffer_requested_structure_override_flag'):
    flags=(truth(r[ordinary]),truth(r[override]))
    return {(False,False):'neither',(True,False):'ordinary',(False,True):'override',(True,True):'both'}[flags]


def source_params(repo):
    sql,=repo.glob('Module_2*/v1.0/src/*.sql')
    snap,=repo.glob('Module_2*/v1.0/outputs/*OUTPUT_strategy_run_parameter_snapshot.csv')
    for file,token in ((sql,SQL_HASH),(snap,SNAP_HASH)):
        require(hashlib.sha256(file.read_bytes().replace(b'\r\n',b'\n')).hexdigest()==token,'Unexpected source '+file.name)
    policies={};profiles={};runs={}
    for i,r in enumerate(rows(snap),2):
        run=r['module2_run_id']; records=json.loads(r['product_policy_params_jsonb'],parse_float=D)
        name=records[0]['product_policy_profile_code']
        values={p['product_type']:p for p in records}
        require(run not in policies and all(p['product_policy_profile_code']==name for p in records),'Mixed/duplicate policy')
        policies[run]=values
        disposition=json.loads(r['strategy_params_jsonb'])['failed_counteroffer_resolution']
        require(disposition in ('DECLINE','MANUAL_REVIEW'),'Unknown failed-offer disposition')
        runs[run]=[name,i,disposition]
        reduced={k:[p[field] for field in PFIELDS] for k,p in values.items()}
        require(profiles.setdefault(name,reduced)==reduced,'Differing product rule sets on '+name)
    return policies,runs,profiles,dict(sql=REPO+quote(sql.relative_to(repo).as_posix())+'#L19660',snapshot=REPO+quote(snap.relative_to(repo).as_posix()))


def replay(source,policy,side):
    case={k:D(str(source[k])) for k in ('request','pti','pd','lgd')}
    path=side['path']
    require(path in PATHS or path in DIRECT, 'Unrecognized decision path: '+path)
    state=PATHS.get(path,'N')
    expected={'COUNTEROFFER_FEASIBLE':'COUNTEROFFER','COUNTEROFFER_NOT_FEASIBLE_REVIEW':'MANUAL_REVIEW',
              'COUNTEROFFER_NOT_FEASIBLE_DECLINE':'DECLINE','APPROVE_AS_REQUESTED':'APPROVE','MANUAL_REVIEW_CANDIDATE':'MANUAL_REVIEW',
              'HARD_POLICY_STOP':'DECLINE','SEVERE_DTI_CAPACITY':'DECLINE','SEVERE_SYNTHETIC_RISK':'DECLINE','SEVERE_REQUESTED_STRUCTURE_REVIEW':'MANUAL_REVIEW'}
    require(side['outcome']==expected[path],f'Path disagrees with outcome: {path}')
    if state=='N':return state,[],[]
    amount=case['request']; require(amount>0,'Non-positive request')
    require(all(policy[k] is not None for k in PFIELDS) and policy['approved_amount_rounding_increment']>0,'Missing product parameters')
    s=constraints(case,policy)
    rounded=s['rounded']; share=amount*policy['product_min_counteroffer_pct']; retained=amount*(1-policy['product_max_exposure_reduction_pct'])
    payment=D(str(source['payment']))*rounded/amount if source.get('payment') is not None else None
    values=[s['limits']['product'],s['limits']['payment'],s['limits']['loss'],s['raw'],rounded,s['minimum'],share,retained,payment,s['rounded_pti'],s['rounded_el']]
    failed=[i for i,v in enumerate([policy['counteroffer_allowed_flag'] is not True, rounded<=0, rounded>=amount,
                                    rounded<policy['product_min_approved_amount'],rounded<share,rounded<retained,
                                    rounded>policy['product_max_approved_amount'],s['rounded_pti']>policy['counteroffer_target_pti'],
                                    s['rounded_el']>policy['product_approved_el_cap']]) if v]
    require(bool(failed)==(state=='F'), f"Calculated checks disagree with {path}, {source}, {failed}")
    if state=='P':
        require(close(side['approved'],rounded) and close(side['approvedEL'],s['rounded_el']), 'Recorded offered principal/EL differs from replay')
        for k,n in (('pti',9),('payment',8)):
            if side.get(k) is not None and values[n] is not None:
                require(close(side[k],values[n]),f'Recorded approved {k} disagrees with replay')
    return state,values,failed


def support(r,state,values,failed):
    """All constraints compared in Decimal with PostgreSQL division/rendering tolerance."""
    if 'counteroffer_feasibility_evaluated_flag' not in r:return
    require(truth(r['counteroffer_feasibility_evaluated_flag'])==(state!='N'),'Archived evaluation flag differs')
    require((r['counteroffer_feasibility_pass_flag']=='' if state=='N' else truth(r['counteroffer_feasibility_pass_flag'])==(state=='P')),'Archived pass flag differs')
    require((r['counteroffer_feasibility_failure_reason'] or '')==(FAIL[failed[0]] if failed else ''),'Archived first failed rule differs')
    if 'counteroffer_feasibility_constraint_count' in r:
        require(r['counteroffer_feasibility_constraint_count']==('' if state=='N' else str(len(failed))), 'Archived failure count differs')
    for i,key in enumerate(COLUMN):
        if not key or key not in r:continue
        if state=='N':
            require(r[key]=='',f'Unexpected diagnostic value for bypassed route: {key}')
        elif values[i] is not None:
            require(r[key]!='' and close(r[key],values[i]),f'Archived diagnostic {key} differs: {r[key]} / {values[i]}')


def original_row(r):
    source={k:r[field] for k,field in dict(request='requested_amount',pti='requested_payment_to_income_ratio',
           pd='estimated_pd',lgd='estimated_lgd').items()}
    source['payment']=r.get('requested_monthly_payment_proxy') or None
    side={'path':r['decision_path'],'outcome':r['decision_outcome'],'approved':r['approved_amount'] or None,
          'approvedEL':r['approved_expected_loss_amount'] or None,'pti':r.get('approved_payment_to_income_ratio') or None,
          'payment':r.get('approved_monthly_payment_proxy') or None}
    return source,side


def build(repo,case_dir,june,returned,borrower):
    policies,runs,profiles,src=source_params(repo)
    cases=add_returned_cases(add_june(load(case_dir/'cases.json'),june,repo),returned)['groups']
    risk=load(borrower)['records']
    panel={}; audits=Counter(); failure_counts=Counter(); groups={}; evidence={}
    public,=repo.glob('Module_2*/v1.0/outputs/*RANDOM_SAMPLE_strategy_decisions_archive.csv')
    detailed,=repo.glob('Module_2*/v1.0/outputs/*RANDOM_SAMPLE_strategy_decisions_m2_01.csv')
    by_key=defaultdict(list)
    for r in rows(public):by_key[r['module2_run_id'],r['application_id']].append(('archive',r))
    for f in CASES:
        for r in rows(june/f):by_key[r['module2_run_id'],r['application_id']].append(('june',r))
    candidates={}
    for r in rows(returned):
        if r['application_id']:
            key=(r['challenger_run'],r['application_id'])
            observed=channel(r,'ordinary_candidate','override_candidate')
            require(candidates.setdefault(key,observed)==observed,'Returned candidate flags differ')
    for r in rows(detailed):
        run='M2-01'
        source,side=original_row(r)
        st,v,bad=replay(source,policies[run][r['product_type']],side)
        support(r,st,v,bad);audits['fullBaselineDiagnostics']+=1;audits['baselineTested']+=st!='N'
        by_key[run,r['application_id']].append(('baseline-diagnostics',r))
    for f in june.glob('strategy_decisions_archive_*.csv'):
        for r in rows(f):
            # The detailed extracts omit run ID. Resolve it against the saved
            # June study with the same application, strategy and product.
            matches={key[0] for key,entries in by_key.items() if key[1]==r['application_id']
                     and any(k=='june' and x['strategy_name']==r['strategy_name'] and x['product_type']==r['product_type'] for k,x in entries)}
            require(len(matches)==1,'Ambiguous June extract identity')
            run=matches.pop()
            s,side=original_row(r); st,v,bad=replay(s,policies[run][r['product_type']],side);support(r,st,v,bad)
            by_key[run,r['application_id']].append(('june-diagnostics',r));audits['fullJuneDiagnostics']+=1
    for pair,group in cases.items():
        groups[pair]=[group['baseRun'],group['challengeRun']]
        for c in group['cases']:
            app=c['id'];audits['pairedCases']+=1
            m=risk[group['scenario']][app]
            require(close(m['request'],c['request']) and close(m['observations']['pti'],c['pti']) and close(m['pd'],c['pd'])
                    and close(m['lgd'],c['lgd']) and m['observations']['product']==c['product'],'Incorrect Module 1 source')
            for run,tag in zip(groups[pair],('base','challenge')):
                key=(run,app);side=c[tag]; st,v,bad=replay(c|{'payment':m['payment']},policies[run][c['product']],side)
                if st=='F':require(side['outcome']==runs[run][2],f'Failed-offer disposition differs from snapshot for {key}')
                audits['pairedSide'+st]+=1; ch=candidates.get(key)
                provenance='route'
                for source,r in by_key[key]:
                    require(r['product_type']==c['product'] and r['decision_path']==side['path'] and
                            close(r['requested_amount'],c['request']) and close(r['estimated_pd'],c['pd'])
                            and close(r['estimated_lgd'],c['lgd']) and close(r['requested_payment_to_income_ratio'],c['pti']),f'Incorrect overlapping row {key}')
                    recorded=channel(r)
                    require(ch in (None,recorded),f'Conflicting candidate flags {key}');ch=recorded
                    support(r,st,v,bad)
                    if 'diagnostics' in source:provenance=source
                    elif source=='june' and provenance=='route':provenance='june'
                codes=(st,ch or 'unknown',provenance,bad)
                packed=[*codes,[float(x) for x in v]] if st!='N' else list(codes[:3])
                table=panel.setdefault(run,{})
                require(table.setdefault(app,packed)==packed,f'Duplicate inconsistent replay for {key}')
                if key not in evidence:
                    evidence[key]=True;audits['uniqueSide'+st]+=1;audits['evidence_'+provenance]+=1
                    if bad:failure_counts[FAIL[bad[0]]]+=1
    return dict(schemaVersion=1,groups=groups,policies=runs,profiles=profiles,profileFields=PFIELDS,fields=FIELDS,
                failedCheckCodes=FAIL,sources=src,records=panel,coverage=audits,firstFailureCounts=failure_counts)


if __name__=='__main__':
    ap=argparse.ArgumentParser(description=__doc__)
    for k in ('repo','returned','june'):ap.add_argument('--'+k,type=Path,required=True)
    ap.add_argument('--case-dir',type=Path,default=ROOT);ap.add_argument('--borrower',type=Path,default=ROOT/'borrower_math.json')
    ap.add_argument('--output',type=Path,default=ROOT/'counteroffer_gate_data.json')
    a=ap.parse_args();obj=build(a.repo,a.case_dir,a.june,a.returned,a.borrower)
    a.output.write_text(json.dumps(obj,default=float,separators=(',',':'))+'\n',encoding='utf-8')
    print(json.dumps(obj['coverage'],indent=2))
