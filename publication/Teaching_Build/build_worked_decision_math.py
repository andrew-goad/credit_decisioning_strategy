"""Reconcile seven decision examples to original data and named policy snapshots.

Run with --repo PATH_TO_credit_decisioning_strategy --returned teaching_cases.csv
--june PATH_TO_JUNE_CSV_FOLDER. The output is standalone and uses no database.
"""
import argparse
import csv
import hashlib
import json
from decimal import Decimal as D, ROUND_HALF_UP
from pathlib import Path

STUDIES = [
    ('CG03',1004,1,4), ('CG05',1237,1,6), ('CG01',46600,1,2),
    ('CG18',40465,1,37), ('CG18',9153,1,37), ('CG20',547,28,39), ('CG02',32476,1,3),
]
CENT = D('.01')
MILLIONTH = D('.000001')
M1_SECTIONS = 'Module 1 §8 estimated default probability, product severity and requested loss'
M2_SECTIONS = 'Module 2 §§5–7 flags and routing, §8.2 counteroffer sizing and feasibility, §§9–10 decision and reason assignment'

def require(ok, text):
    if not ok:
        raise ValueError(text)

def quant(x, quantum=CENT):
    return x.quantize(quantum, rounding=ROUND_HALF_UP)

def money(x):
    return f'${quant(x):,.2f}'

def pct(x):
    return format((100*x).normalize(), 'f') + '%'

def one(repo, glob):
    match = list(repo.glob(glob))
    require(len(match)==1, f'Expected one {glob}, found {len(match)}')
    return match[0]

def read(path):
    with path.open(encoding='utf-8-sig', newline='') as f:
        for line, row in enumerate(csv.DictReader(f), 2):
            row['_line'] = line
            yield row

def json_decimal(s):
    return json.loads(s, parse_float=D)

def common(row):
    return dict(product=row.get('product') or row['product_type'],
                request=D(row['requested_amount']), pd=D(row['estimated_pd']), lgd=D(row['estimated_lgd']),
                pti=D(row['requested_payment_to_income_ratio']), request_el=D(row['requested_expected_loss_amount']),
                annual_income=D(row['annual_income']), score_band=row['score_band'])

def decision(row, run, prefix=None):
    if prefix:
        keys = (prefix+'_outcome', prefix+'_amount', prefix+'_el', prefix+'_reason', prefix+'_path')
    else:
        keys = ('decision_outcome','approved_amount','approved_expected_loss_amount','primary_reason_code','decision_path')
    o, a, el, reason, path = [row[k] for k in keys]
    data={'run':run,'outcome':o,'approved':D(a) if a else None,'el':D(el) if el else None,'reason':reason,'path':path}
    for key,field in [('ordinary_candidate','ordinary_counteroffer_candidate_flag'),('override_candidate','aggressive_counteroffer_requested_structure_override_flag')]:
        src=key if prefix=="test" else field
        if src in row: data[key]=row[src].lower() in ('true','t')
    if 'counteroffer_feasibility_failure_reason' in row:data['recorded_failure']=row['counteroffer_feasibility_failure_reason']
    return data

def constraints(c,p):
    request, pd, lgd, pti=c['request'],c['pd'],c['lgd'],c['pti']
    limits={'product':min(request,p['product_max_approved_amount']),
            'payment':request*p['counteroffer_target_pti']/pti if pti else request,
            'loss':p['product_approved_el_cap']/(pd*lgd) if pd*lgd else min(request,p['product_max_approved_amount'])}
    which=min(limits,key=limits.get)
    raw=limits[which]
    increment=p['approved_amount_rounding_increment']
    rounded=(raw//increment)*increment
    minimum=max(p['product_min_approved_amount'],request*p['product_min_counteroffer_pct'],
                request*(1-p['product_max_exposure_reduction_pct']))
    return {'limits':limits,'binding':which,'raw':raw,'increment':increment,'rounded':rounded,'minimum':minimum,
            'minimum_margin':rounded-minimum,'rounded_pti':pti*rounded/request,'rounded_el':rounded*pd*lgd,
            'target_pti':p['counteroffer_target_pti'],'loss_budget':p['product_approved_el_cap']}

def risk_source(row):
    factors={k:v for k,v in row.items() if k.startswith('mult_')}
    raw=D(row['base_pd'])
    for v in factors.values():
        raw*=D(v)
    key=row["application_id"]+"|"+row["population_id"]+"|u15"
    u15=D(int(hashlib.md5(key.encode()).hexdigest()[:15],16))/D(16**15)
    jitter=D(".95")+u15*D(".10")
    raw=quant(raw*jitter,MILLIONTH)
    require(raw==D(row['pd_raw_pre_saturation_v2']), f'Raw PD mismatch: {row["application_id"]}')
    adjusted=raw if raw<=D('.30') else (D('.30')+(raw-D('.30'))*D('.50') if raw<=D('.55') else D('.425')+(raw-D('.55'))*D('.15'))
    require(quant(adjusted,MILLIONTH)==D(row['pd_after_saturation_v2'])==D(row['estimated_pd']), 'Unexpected PD saturation/floor/cap')
    return {'score_band_starting_pd':D(row['base_pd']),'multipliers':factors,'seeded_row_jitter':jitter,'raw_pd':raw,
            'saturation_zone':row['pd_saturation_zone_v2'],'assigned_pd':D(row['estimated_pd'])}

def gate_detail(c,d,p,s,size):
    def step(label,status,detail):
        return {'label':label,'status':status,'detail':detail}
    rows=[]
    approved_names={'APPROVE':'Approved as requested','COUNTEROFFER':'Counteroffer','MANUAL_REVIEW':'Manual review','DECLINE':'Decline'}
    entered=size is not None
    amt,pd,pti,lgd=c['request'],c['pd'],c['pti'],c['lgd']
    product_max=p['product_max_approved_amount']; product_min=p['product_min_approved_amount']
    high=product_max*D('1.50')
    if 'hard_stop_inputs' in c:
        f=c['hard_stop_inputs']; cap=s['severe_delinquency_count_threshold']
        hard=(s['bankruptcy_policy_stop_enabled'] and f['bankruptcy']) or (s['major_derogatory_policy_stop_enabled'] and f['major_derogatory']) or (s['severe_delinquency_policy_stop_enabled'] and f['delinquencies']>=cap)
        rows.append(step('Hard policy stops','FAIL' if hard else 'PASS',
              f"Bankruptcy {'yes' if f['bankruptcy'] else 'no'}; major derogatory event {'yes' if f['major_derogatory'] else 'no'}; {f['delinquencies']} recent delinquencies against a stop at {cap}."))
    else:
        rows.append(step('Hard policy stops','ROUTE EVIDENCE','The recorded route cleared this screen. The case extract omits the individual bankruptcy, derogatory-event and delinquency fields.'))
    severe=pd>=s['decline_min_estimated_pd_proxy']
    rows.append(step('Severe default-risk stop','FAIL' if severe else 'PASS',
        f"Modeled default probability {pct(pd)} {'≥' if severe else '<'} decline threshold {pct(s['decline_min_estimated_pd_proxy'])}."))
    if 'dti' in c:
        dti=c['dti'];lim=s['decline_min_dti']
        rows.append(step('Severe debt-to-income stop','PREEMPTED' if severe else ('PASS' if dti<lim else 'FAIL'),
            f"Existing debt-to-income ratio {pct(dti)} {'<' if dti<lim else '≥'} the {pct(lim)} stop."+
            (' Default risk already determined the decline.' if severe else '')))
    else:
        rows.append(step('Severe debt-to-income stop','ROUTE EVIDENCE','The recorded route requires this stop to be clear. The high-balance case extract omits the exact debt-to-income ratio.'))
    evidence=[]
    if s['approve_max_estimated_pd_proxy']<pd<=s['counteroffer_max_estimated_pd_proxy']:evidence.append(f"PD {pct(pd)} in the counteroffer risk band")
    if pti>p['product_approve_max_pti']:evidence.append(f"requested payment burden {pct(pti)} > {pct(p['product_approve_max_pti'])}")
    if product_max<amt<=high:evidence.append(f"request {money(amt)} > product cap {money(product_max)}")
    if c['request_el']>p['product_approve_max_requested_el']:evidence.append(f"requested loss {money(c['request_el'])} > {money(p['product_approve_max_requested_el'])}")
    extreme=amt>high or amt<product_min
    ordinary='eligible' if entered and not d.get('override_candidate',False) else 'ineligible'
    if 'ordinary_candidate' in d:ordinary='eligible' if d['ordinary_candidate'] else 'ineligible'
    entry_detail={'eligible':'Qualification comes from '+', '.join(evidence)+'.','ineligible':('No ordinary counteroffer trigger qualified.' if not evidence else 'Dollar or risk triggers alone did not admit the file.')}
    if extreme:
        entry_detail['ineligible']=f"The {money(amt)} request exceeds 1.5 × the {money(product_max)} maximum ({money(high)}), blocking ordinary entry." if amt>high else f"Request below the {money(product_min)} minimum."
    if severe:entry_detail['ineligible']='The severe default-risk stop takes priority over counteroffer routing.'
    rows.append(step('Ordinary counteroffer eligibility','PASS' if ordinary=='eligible' else ('PREEMPTED' if severe else 'NO ENTRY'),
            entry_detail[ordinary]))
    if d.get('override_candidate',False):
        rows.append(step('Requested-structure exception','EXCEPTION',
            f"The documented exception admitted this extreme request, {money(amt)} versus the {money(high)} boundary, for sizing. The product, PD and debt-to-income protections still applied."))
    else:
        rows.append(step('Requested-structure exception','NO EXCEPTION',
                  'The strategy disabled this exception.' if not s['severe_requested_structure_counteroffer_override_enabled'] else 'The row did not qualify for an exception.'))
    if not entered:
        rows.append(step('Counteroffer sizing and viability','SKIPPED',f"The {d['path']} route did not enter the sizing stage. No candidate amount or counteroffer gate outcome was assigned."))
        rows.append(step('Recorded decision','OUTCOME',f"{approved_names[d['outcome']]}. Primary reason: {d['reason']}." ))
        return {'entered':False,'first_failed':None,'failed_checks':None,'source':'Archived path and Module 2 §§6–8. A blank feasibility result means sizing was skipped.'},rows
    inc=size['increment'];raw=size['raw'];v=size['rounded'];floor=size['minimum'];maxcut=p['product_max_exposure_reduction_pct'];minshare=p['product_min_counteroffer_pct']
    rows.append(step('Three principal limits','CALCULATION',
        f"Product: min({money(amt)}, {money(product_max)}) = {money(size['limits']['product'])}. Payment target: {money(amt)} × {pct(size['target_pti'])} ÷ {pct(pti)} = {money(size['limits']['payment'])}. Loss budget: {money(size['loss_budget'])} ÷ ({pct(pd)} × {pct(lgd)}) = {money(size['limits']['loss'])}."))
    rows.append(step('Binding limit and rounding','CALCULATION',
        f"The {size['binding']} limit is lowest at {money(raw)}. Round down to a permitted multiple of {money(inc)}: {money(v)}."))
    failed=[]
    def check(label,ok,detail,code):
        rows.append(step(label,'PASS' if ok else 'FAIL',detail))
        if not ok:failed.append(code)
    def compare(value,limit,op):
        return f"{money(value)} {op} {money(limit)}."
    check('Product permits counteroffers',p['counteroffer_allowed_flag'],'The saved product policy '+('allows' if p['counteroffer_allowed_flag'] else 'blocks')+' counteroffers.','COUNTEROFFER_NOT_ALLOWED_BY_PRODUCT_POLICY')
    # SQL runs null diagnostics before the numeric gates. These seven examples contain both caps and a rounded result.
    check('Amount computed and positive',v>0,f"Upper bound {money(raw)} and rounded amount {money(v)} are present; the rounded amount must exceed zero.",'COUNTEROFFER_ROUNDED_AMOUNT_NONPOSITIVE')
    check('Below the request',v<amt,compare(v,amt,'<' if v<amt else '≥'),'COUNTEROFFER_NOT_BELOW_REQUESTED_AMOUNT')
    check('Product minimum',v>=product_min,compare(v,product_min,'≥' if v>=product_min else '<'),'COUNTEROFFER_BELOW_PRODUCT_MINIMUM')
    threshold=amt*minshare
    check('Minimum share of the request',v>=threshold,f"Retain at least {pct(minshare)} × {money(amt)} = {money(threshold)}. Rounded candidate {money(v)}.",'COUNTEROFFER_BELOW_MINIMUM_REQUESTED_PERCENT')
    threshold=amt*(1-maxcut)
    check('Maximum reduction',v>=threshold,f"Reduce by at most {pct(maxcut)}; retain at least {money(amt)} × (1 − {pct(maxcut)}) = {money(threshold)}. Rounded candidate {money(v)}.",'COUNTEROFFER_EXCEEDS_MAX_REDUCTION')
    check('At or below product maximum',v<=product_max,compare(v,product_max,'≤' if v<=product_max else '>'),'COUNTEROFFER_EXCEEDS_PRODUCT_CAP')
    actual_pct=pct(quant(size['rounded_pti'],D('.000001')))
    check('Payment on the smaller offer',size['rounded_pti']<=size['target_pti'],f"{pct(pti)} × {money(v)} ÷ {money(amt)} ≈ {actual_pct} of monthly income; maximum {pct(size['target_pti'])}.",'COUNTEROFFER_PTI_STILL_ABOVE_TARGET')
    check('Expected loss on the smaller offer',size['rounded_el']<=size['loss_budget'],f"{money(v)} × {pct(pd)} × {pct(lgd)} = {money(size['rounded_el'])}; maximum {money(size['loss_budget'])}.",'COUNTEROFFER_APPROVED_EL_ABOVE_CAP')
    require(bool(failed)==(d['outcome']!='COUNTEROFFER'),'Feasibility outcome differs from saved record')
    if failed:
        require(s['failed_counteroffer_resolution']==d['outcome'],'Failed candidate did not resolve to expected action')
        if d.get('recorded_failure'):require(failed[0]==d['recorded_failure'],'First failure differs from original')
        details=f"{len(failed)} sizing checks failed. First reported failure: {failed[0]}. The saved strategy sends failed counteroffers to {approved_names[d['outcome']].lower()}. The candidate was not issued."
    else:
        details=f"All sizing checks passed. Recorded offer {money(d['approved'])} and approved-exposure loss {money(d['el'])}."
    rows.append(step('Final feasibility and decision','FAIL' if failed else 'PASS',details))
    return {'entered':True,'first_failed':failed[0] if failed else None,'failed_checks':failed,'source':'Routed path and final outcome are archived. Numeric checks are recomputed from the saved source inputs and exact policy snapshot (Module 2 §8.2).'},rows


def build(repo, returned, june):
    archive=one(repo,'*/v1.0/outputs/*OUTPUT_RANDOM_SAMPLE_strategy_decisions_archive.csv')
    snapshots=one(repo,'*/v1.0/outputs/*OUTPUT_strategy_run_parameter_snapshot.csv')
    m1_path=one(repo,'*/v2.0/outputs/*OUTPUT_synthetic_applications.csv')
    june_file=june/'MANUAL_REVIEW_TO_DECLINE_GOVERNANCE_CASE.csv'
    june_gates=june/'strategy_decisions_archive_202606021650_APP-00040465.csv'
    m1_ids={f'APP-{n:08}' for _,n,_,_ in STUDIES if n!=547}
    m1={r['application_id']:r for r in read(m1_path) if r['application_id'] in m1_ids}
    snap={r['module2_run_id']:r for r in read(snapshots)}
    public={(r['module2_run_id'],r['application_id']):r for r in read(archive)}
    named={r['module2_run_id']:r for r in read(june_file)}
    gates=next(r for r in read(june_gates) if r['strategy_name']=='AGGRESSIVE_COUNTEROFFER_EXPANSION_STRATEGY')
    returned_rows=list(read(returned))
    result={}
    for g,n,b,t in STUDIES:
        app=f'APP-{n:08}'; runs=[f'M2-{j:02}' for j in (b,t)]
        role=['baseline','challenger']; sources=[]
        def cite(file,row):
            sources.append({'file':file.name,'line':row['_line']})
        if n in (1004,32476,40465):
            rows=[named[run] if n==40465 else public[run,app] for run in runs]
            c=common(rows[0]); require(common(rows[1])==c and all(r['application_id']==app for r in rows),'Unmatched inputs')
            decisions=[decision(r,run) for r,run in zip(rows,runs)]
            for r in rows: cite(june_file if n==40465 else archive,r)
        else:
            rows=[r for r in returned_rows if r['pair_id']==g and r['application_id']==app]
            require(len(rows)>=1,'Missing returned teaching case')
            r=rows[0]; require([r['baseline_run'],r['challenger_run']]==runs and r['changed_inputs']=='0','Mismatched pair')
            c=common(r);decisions=[decision(r,run,prefix) for run,prefix in zip(runs,['base','test'])];cite(returned,r)
        c['lgd_basis']='Assigned by product in Module 1; conditional fraction of exposure lost if default occurs.'
        if n!=547:
            row=m1[app];require(row['scenario_name']=='BASELINE_V2' and
                row['product_type']==c['product'] and D(row['requested_amount'])==c['request'] and
                D(row['estimated_pd'])==c['pd'] and D(row['estimated_lgd'])==c['lgd'] and
                D(row['payment_to_income_ratio'])==c['pti'], 'Module 1 source mismatch')
            c['hard_stop_inputs']={'bankruptcy':row['bankruptcy_flag']=='true','major_derogatory':row['major_derogatory_flag']=='true','delinquencies':int(row['delinquency_count_12m'])}
            c['pd_source']=risk_source(row);c['payment']=D(row['monthly_payment_proxy']);c['dti']=D(row['debt_to_income_ratio']);cite(m1_path,row)
        else:
            c['pd_source']='High-balance scenario PD and product LGD are recorded in the returned decision pair. The return omits the individual PD multipliers, DTI and payment dollars.'
        require(quant(c['request']*c['pd']*c['lgd'])==c['request_el'],'Requested EL differs')
        prod=[];strategy=[];sized=[]
        for run,d in zip(runs,decisions):
            raw=snap[run];p=next(v for v in json_decimal(raw['product_policy_params_jsonb']) if v['product_type']==c['product']);s=json_decimal(raw['strategy_params_jsonb'])
            prod.append(p);strategy.append(s);cite(snapshots,raw)
            if d['outcome']=='COUNTEROFFER' or d['path']=='COUNTEROFFER_NOT_FEASIBLE_REVIEW':
                calc=constraints(c,p)
                if d['outcome']=='COUNTEROFFER':
                    require(calc['rounded']==d['approved'] and calc['rounded']<c['request'] and calc['minimum_margin']>=0
                            and calc['rounded_pti']<=p['counteroffer_target_pti'] and calc['rounded_el']<=p['product_approved_el_cap'],f'Mismatch in {run} {app} offer')
                else:
                    require(calc['minimum_margin']<0,'Failed floor expected')
                sized.append(calc)
            else:sized.append(None)
            d['approval_pd_limit']=s['approve_max_estimated_pd_proxy'];d['decline_pd_limit']=s['decline_min_estimated_pd_proxy']
            d['product_full_approval_pti_limit']=p['product_approve_max_pti'];d['product_exposure_limit']=p['product_max_approved_amount']
            if d['outcome']=='APPROVE':require(d['approved']==c['request'] and d['el']==c['request_el'],'Approval economics mismatch')
            elif d['outcome']=='MANUAL_REVIEW':require(d['approved'] is None and d['el'] is None,'Unresolved review economics mismatch')
            else:require(d['el']==d['approved']*c['pd']*c['lgd'],'Approved loss mismatch')
        a,z=decisions;y,w=sized;x,xx=prod;s,ss=strategy
        amount,pd,lgd,pti=c['request'],c['pd'],c['lgd'],c['pti']
        loss_rate=pd*lgd
        if n==1004:
            title='Does the mortgage payment clear both limits?'
            lines=[f"{money(c['payment'])} per month ÷ ({money(c['annual_income'])} annual income ÷ 12) = {pct(pti)} of income. That payment was below both mortgage approval limits: {pct(x['product_approve_max_pti'])} under baseline and {pct(xx['product_approve_max_pti'])} under tighter affordability.",
                   f"Both approved the full {money(amount)}. At a modeled default probability of {pct(pd)} and {pct(lgd)} mortgage loss severity, {money(amount)} × {pct(pd)} × {pct(lgd)} = {money(a['el'])} of expected loss in each portfolio."]
        elif n==1237:
            title='Which limit sets the credit line?'
            require(y['binding']==w['binding']=='product','Product should bind')
            lines=[f"On the {money(amount)} request, the product ceilings set the offers: {money(a['approved'])} for baseline and {money(z['approved'])} under tighter product limits. Both already land on a {money(y['increment'])} increment.",
                   f"The change in expected loss is {money(a['approved']-z['approved'])} less credit × {pct(pd)} probability of default × {pct(lgd)} revolving-line loss severity = {money(a['el']-z['el'])}, from {money(a['el'])} to {money(z['el'])}."]
        elif n==46600:
            title='Where does an offer become a decline?'
            require(y['binding']=='loss' and ss['decline_min_estimated_pd_proxy']<=pd<s['decline_min_estimated_pd_proxy'],'Risk/EL mismatch')
            lines=[f"Baseline’s {money(y['loss_budget'])} loss budget ÷ ({pct(pd)} default probability × {pct(lgd)} personal-loan loss severity) allowed {money(y['raw'])}. Rounding down in {money(y['increment'])} increments produced {money(a['approved'])}, with {money(a['el'])} in expected loss.",
                   f"The modeled default probability remained {pct(pd)}. It exceeded the {pct(ss['decline_min_estimated_pd_proxy'])} threshold for a severe-risk decline under tighter policy, versus {pct(s['decline_min_estimated_pd_proxy'])} under baseline. The decline assigns zero offer and zero approved-exposure loss."]
        elif n==40465:
            title='How can a lower loss budget still produce an offer?'
            require(y['binding']==w['binding']=='loss' and y['minimum_margin']<0<w['minimum_margin'],'June cause mismatch')
            require(all(abs(w[key]-D(gates[field]))<D('.000001') for key,field in [('raw','counteroffer_raw_max_feasible_amount'),('minimum','counteroffer_min_viable_amount'),('rounded','counteroffer_rounded_amount'),('rounded_el','counteroffer_test_expected_loss_amount')]),'June independent export mismatch')
            cite(june_gates,gates)
            lines=[f"Baseline’s {money(y['loss_budget'])} loss budget allowed {money(y['raw'])}. Rounding down to {money(y['rounded'])} fell below the required {pct(x['product_min_counteroffer_pct'])} of the request ({money(y['minimum'])}), so the application went to review.",
                   f"The challenger allowed a smaller minimum ({pct(xx['product_min_counteroffer_pct'])}). Its {money(w['loss_budget'])} loss budget ÷ ({pct(pd)} × {pct(lgd)}) = {money(w['raw'])}. Rounding down in {money(w['increment'])} increments to {money(w['rounded'])} cleared the {money(w['minimum'])} floor by {money(w['minimum_margin'])}. Estimated loss on the offer was {money(z['el'])}."]
        elif n==9153:
            title='What actually sets the two mortgage amounts?'
            require(y['binding']==w['binding']=='payment' and z['reason']=='COUNTEROFFER_PRODUCT_EXPOSURE_LIMIT','Expected PTI sizing and distinct reason')
            lines=[f"The requested mortgage payment used {pct(pti)} of monthly income. Baseline applied a {pct(y['target_pti'])} payment target: {money(amount)} × {pct(y['target_pti'])} ÷ {pct(pti)} = {money(y['raw'])}. Rounding down in {money(y['increment'])} increments produced {money(y['rounded'])}.",
                   f"The challenger recorded the exposure limit as its first reason. Its {pct(w['target_pti'])} payment target set the lower dollar ceiling of {money(w['raw'])}, below the {money(xx['product_max_approved_amount'])} product limit. The result was {money(w['rounded'])}. The {money(y['rounded']-w['rounded'])} reduction × {pct(pd)} × {pct(lgd)} cuts modeled loss by {money(a['el']-z['el'])}."]
        elif n==547:
            title='Why did a large request qualify for a smaller line?'
            boundary=x['product_max_approved_amount']*D('1.50')
            require(amount>boundary and amount>xx['product_max_approved_amount']*D('1.50') and rows[0]['override_candidate']=='t' and rows[0]['ordinary_candidate']=='f' and w['binding']=='product','Expected extreme-exposure override')
            lines=[f"The {money(amount)} home equity line exceeded baseline’s extreme-request boundary: 1.5 × {money(x['product_max_approved_amount'])} = {money(boundary)}. Baseline sent it to review. The challenger’s recorded exception allowed it to test a smaller offer.",
                   f"The challenger capped the line at {money(w['rounded'])}. It cleared the {money(w['minimum'])} minimum. At {pct(pd)} modeled default probability and {pct(lgd)} HELOC loss severity, the approved line carried {money(z['el'])} of expected loss. Baseline review had no assigned exposure or loss."]
        else:
            title='Why did the same auto application move from review to approval?'
            lim=s['approve_max_estimated_pd_proxy'];margin=lim*s['borderline_threshold_buffer_pct'];other=ss['approve_max_estimated_pd_proxy'];margin2=other*ss['borderline_threshold_buffer_pct']
            require(lim-margin <= pd <= lim+margin and pd<other-margin2 and a['reason']=='MANUAL_REVIEW_BORDERLINE_PROFILE' and z['outcome']=='APPROVE','Expected baseline PD adjacency')
            lines=[f"The {pct(pd)} estimated default probability fell inside baseline’s borderline range around its {pct(lim)} approval threshold ({pct(lim-margin)}–{pct(lim+margin)}). The file went to review. Around the growth policy’s {pct(other)} threshold, the same buffer spans {pct(other-margin2)}–{pct(other+margin2)}. This application was below that range.",
                   f"Growth approved {money(amount)} as requested. Multiplying {money(amount)} × {pct(pd)} default probability × {pct(lgd)} auto-loan loss severity gives {money(z['el'])} in modeled loss. The pending baseline review contributed no assigned exposure or loss."]
        for d,p,s,sz in zip(decisions,prod,strategy,sized):
            d['feasibility'],d['gates']=gate_detail(c,d,p,s,sz)
        result[g+'|'+app]={'title':title,'lines':lines, 'source':M1_SECTIONS+'; '+M2_SECTIONS,'sources':sources,
                 'evidence':{'inputs':c,**{k:{**d,'sizing':sz} for k,d,sz in zip(role,decisions,sized)}}}
    return result

if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__)
    for name in ['repo','returned','june']:p.add_argument('--'+name,type=Path,required=True)
    p.add_argument('--output',type=Path,default=Path(__file__).with_name('worked_decision_math.json'))
    args=p.parse_args();cases=build(args.repo,args.returned,args.june)
    args.output.write_text(json.dumps(cases,default=str,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(f'Verified {len(cases)} policy comparisons, {2*len(cases)} decisions, 7 requested-loss values and all exercised sizing paths.')
