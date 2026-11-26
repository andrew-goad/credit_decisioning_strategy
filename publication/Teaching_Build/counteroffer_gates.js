(() => {
  'use strict';
  let dataset;
  const money = value => value.toLocaleString('en-US', {style:'currency', currency:'USD'});
  const pct = value => (100*value).toLocaleString('en-US', {maximumFractionDigits:4})+'%';
  const plain = value => (value || '').toLowerCase().replaceAll('_',' ');
  const labels = {
    APPROVE_AS_REQUESTED:'approved the full request', HARD_POLICY_STOP:'stopped the application at a hard policy rule',
    MANUAL_REVIEW_CANDIDATE:'sent the application directly to manual review',
    SEVERE_DTI_CAPACITY:'declined the application at the severe debt-to-income threshold',
    SEVERE_SYNTHETIC_RISK:'declined the application at the severe modeled-risk threshold',
    SEVERE_REQUESTED_STRUCTURE_REVIEW:'sent the requested structure directly to manual review'
  };
  const channels = {ordinary:'an ordinary counteroffer candidate',override:'a requested-structure override candidate',
    both:'both an ordinary and an override candidate',neither:'neither candidate flag',unknown:'candidate flags unavailable in the case extract'};
  const failures = ['the product disallows counteroffers','the rounded amount is zero or negative',
    'the amount does not reduce the request','the amount is below the product minimum',
    'the amount retains too little of the request','the reduction exceeds the maximum allowed',
    'the amount exceeds the product maximum','the test payment exceeds the income-share target',
    'the modeled loss exceeds the approved loss budget'];
  const provenance = {route:'The saved final path identifies whether the engine sized an offer. Amounts and checks were reproduced from the historical inputs and policy snapshot.',
    june:'The June study records the evaluation, its result and its first failed rule when applicable. The amounts were reproduced from the historical inputs and policy snapshot.',
    'baseline-diagnostics':'The saved baseline decision provides an independent check on the sizing calculation.',
    'june-diagnostics':'The calculations were also checked against the detailed June archive extract for this applicant.'};
  function el(tag, text, cls) {
    const node=document.createElement(tag);
    if(text!==undefined && text!==null) node.textContent=text;
    if(cls) node.className=cls;
    return node;
  }
  function table(rows) {
    const wrap=el('div',null,'bm-table'), t=el('table'),head=el('thead'),headers=el('tr'),body=el('tbody');
    for (const label of ['Sizing rule','Calculation for this application','Amount or rate']) {
      const th=el('th',label);th.scope='col';headers.append(th);
    }
    head.append(headers);
    for(const [label,how,amount] of rows) {
      const row=el('tr'),th=el('th',label);th.scope='row';row.append(th,el('td',how),el('td',amount));body.append(row);
    }
    t.append(head,body);wrap.append(t);return wrap;
  }
  function detail(label) {
    const node=el('details',null,'bm-detail');node.append(el('summary',label));return node;
  }
  function sources(holder,run,kind,skipped=false) {
    const note=el('p',skipped ? 'The archived decision path identifies the route for this policy.' : provenance[kind],'bm-note');
    const sql=el('a','Sizing code'),snap=el('a',run+' policy settings');
    sql.href=dataset.sources.sql;window.CreditSourceTrace?.link(sql,sql.href);snap.href=dataset.sources.snapshot+'#L'+dataset.policies[run][1];
    note.append(' ',sql,' · ',snap);holder.append(note);
  }
  function sideProof(box,title,run,record,side) {
    const saved=dataset.records[run]?.[record.id], path=side?.path;
    if(!path)return;
    if(!saved){
      if(labels[path])box.append(el('p',title+' '+labels[path]+'. The counteroffer sizing stage was skipped.'));
      else box.append(el('p',title+' recorded '+plain(path)+'. A checked sizing calculation is unavailable for this application in the saved examples.'));
      return;
    }
    const [status,channel,evidence,failed,v]=saved;
    if(status==='N'){
      box.append(el('p',title+' '+labels[path]+'. This route skipped counteroffer sizing.'));
      const route=detail(title+' · inspect the recorded route');
      route.append(el('p','Saved decision path: '+plain(path)+'. Primary reason: '+plain(side.primary)+'.'));
      if(channel!=='unknown')route.append(el('p','Candidate flags at this stage: '+channels[channel]+'. A flag alone does not show that a different amount was tested.'));
      sources(route,run,evidence,true);box.append(route);return;
    }
    const [perm,max,target,budget,min,fraction,cut,inc]=dataset.profiles[dataset.policies[run][0]][record.product];
    const [cap,byPTI,byLoss,raw,rounded,minimum,shareMin,cutMin,pay,pti,eloss]=v;
    const limits=[cap,byPTI,byLoss],names=['the request and product ceiling','the payment-to-income target','the expected-loss budget'];
    const bind=names.filter((_,i)=>limits[i]===raw).join(' and ');
    let line=title+' tested '+money(rounded)+'. ';
    if(status==='P')line+='It passed and became the counteroffer. '+(bind.charAt(0).toUpperCase()+bind.slice(1))+' set the upper limit before rounding.';
    else line+='It failed because '+failures[failed[0]]+'. The recorded decision was '+plain(side.outcome)+'.';
    box.append(el('p',line));
    const proof=detail(title+' · trace the limits and checks');
    proof.append(el('p','The engine took the lowest of three ceilings, rounded down to the product increment, then tested the result against every floor and limit.'));
    const request=record.request;
    proof.append(table([
      ['Product ceiling','Lower of the request ('+money(request)+') and product maximum ('+money(max)+').',money(cap)],
      ['Payment ceiling',record.pti>0?money(request)+' × '+pct(target)+' policy target ÷ '+pct(record.pti)+' requested payment-to-income.':'Requested payment-to-income is zero; the request supplies this ceiling.',money(byPTI)],
      ['Loss ceiling',record.pd*record.lgd>0?money(budget)+' loss budget ÷ ('+pct(record.pd)+' default probability × '+pct(record.lgd)+' severity).':'Modeled loss is zero; the product ceiling supplies this limit.',money(byLoss)],
      ['Rounded test amount','Lowest ceiling '+money(raw)+', rounded down by '+money(inc)+' increments.',money(rounded)],
      ['Smallest viable offer','Highest of product minimum '+money(min)+', '+pct(fraction)+' of request ('+money(shareMin)+'), and the '+pct(cut)+' maximum-cut rule ('+money(cutMin)+').',money(minimum)],
      ['Test payment','Requested monthly payment × tested amount ÷ request.',money(pay)],
      ['Test payment-to-income','Requested payment-to-income × tested amount ÷ request. Policy target '+pct(target)+'.',pct(pti)],
      ['Test expected loss','Tested amount × default probability × loss severity. Budget '+money(budget)+'.',money(eloss)]
    ]));
    const checks=status==='P'?'All feasibility checks passed.':'Failed checks in SQL order: '+failed.map(i=>failures[i]).join(' and ')+'.';
    proof.append(el('p',checks+' The product '+(perm?'permits':'disallows')+' counteroffers.'));
    if(status==='F')proof.append(el('p','The active policy routes failed counteroffers to '+plain(dataset.policies[run][2])+'.'));
    if(channel!=='unknown')proof.append(el('p','The strategy recorded '+channels[channel]+'.'));
    sources(proof,run,evidence);box.append(proof);
  }
  window.renderCounterofferGates=(container,groupKey,caseId,record)=>{
    if(!container || !record)return;
    if(!dataset){
      const source=document.getElementById('counteroffer-gate-data');if(!source)return;
      dataset=JSON.parse(source.textContent);
    }
    const runs=dataset.groups[groupKey];if(!runs || caseId!==record.id)return;
    const box=el('div',null,'bm-part');box.append(el('h4','Did either policy test a smaller offer?'));
    sideProof(box,'Baseline',runs[0],record,record.base);
    sideProof(box,'Challenger',runs[1],record,record.challenge);
    container.append(box);
  };
})();
