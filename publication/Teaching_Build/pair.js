(() => {
  'use strict';
  const data=JSON.parse(document.getElementById('archived-case-data').textContent);
  const settings=JSON.parse(document.getElementById('archived-case-settings').textContent);
  const by=id=>document.getElementById(id), choice=by('pf-choice');
  const groupNames=new Map(Array.from(choice.options,o=>[o.value,o.textContent]));
  const all=data.groups, membership=new Map();
  for(const [groupId,g] of Object.entries(all))for(const c of g.cases) {
    if(!membership.has(c.id))membership.set(c.id,[]);
    membership.get(c.id).push(groupId);
  }
  const most=[...membership].sort((a,b)=>b[1].length-a[1].length||a[0].localeCompare(b[0]))[0];
  const money=n=>Number(n).toLocaleString('en-US',{style:'currency',currency:'USD'});
  const pct=(n,k=2)=>(Number(n)*100).toLocaleString('en-US',{minimumFractionDigits:k,maximumFractionDigits:k})+'%';
  const product={AUTO_LOAN:'Auto loan',MORTGAGE:'Mortgage',HELOC:'Home equity line of credit',REVOLVING_LINE:'Revolving line',UNSECURED_PERSONAL_LOAN:'Unsecured personal loan'};
  const outcome={APPROVE:'Approved as requested',COUNTEROFFER:'Counteroffer',MANUAL_REVIEW:'Manual review',DECLINE:'Declined'};
  const reasons={
    APPROVED_AS_REQUESTED:'the request cleared the approval rules',
    MANUAL_REVIEW_FAILED_COUNTEROFFER:'the engine could not find a smaller feasible offer and referred the application to a reviewer',
    COUNTEROFFER_PRODUCT_EXPOSURE_LIMIT:'a product exposure limit called for a smaller offer',
    COUNTEROFFER_EXPECTED_LOSS_LIMIT:'the modeled loss on the requested structure called for a smaller offer',
    COUNTEROFFER_AFFORDABILITY_ADJUSTMENT:'the borrower’s payment burden called for a smaller offer',
    COUNTEROFFER_ELEVATED_SYNTHETIC_RISK:'the modeled default risk put the request on the counteroffer path',
    MANUAL_REVIEW_SYNTHETIC_RISK_REVIEW:'the modeled default risk called for a reviewer',
    MANUAL_REVIEW_BORDERLINE_PROFILE:'the application was close to a policy threshold and was referred for review',
    MANUAL_REVIEW_DTI_REVIEW:'the borrower’s debt-to-income ratio called for a reviewer',
    MANUAL_REVIEW_SEVERE_REQUESTED_STRUCTURE:'the requested terms triggered a severe-structure review',
    POLICY_STOP_SEVERE_SYNTHETIC_RISK:'the modeled default risk reached a policy stop',
    POLICY_STOP_SEVERE_DTI:'the borrower’s debt-to-income ratio reached a policy stop',
    POLICY_STOP_MAJOR_DEROGATORY:'the policy stopped the application on a major adverse credit-history indicator',
    POLICY_STOP_SEVERE_DELINQUENCY:'the recorded delinquency history reached a policy stop',
    POLICY_STOP_BANKRUPTCY:'the modeled bankruptcy flag triggered a policy stop',
    POLICY_STOP_FAILED_COUNTEROFFER:'no feasible counteroffer cleared the rules and the policy declined the application'
  };
  const pretty=s=>s.toLowerCase().replaceAll('_',' ');
  const reason=s=>reasons[s]||('the recorded reason was '+pretty(s));
  const change=(a,b)=>Math.abs(Number(a)-Number(b))>=.005;
  const offered=s=>s.outcome==='APPROVE'||s.outcome==='COUNTEROFFER';
  const differs=c=>c.base.outcome!==c.challenge.outcome||change(c.base.approved,c.challenge.approved)||change(c.base.approvedEL,c.challenge.approvedEL)||c.base.primary!==c.challenge.primary;
  const pairLabel=c=>outcome[c.base.outcome]===outcome[c.challenge.outcome]?(outcome[c.base.outcome]+(change(c.base.approved,c.challenge.approved)?' · different amounts':' in both')):outcome[c.base.outcome]+' / '+outcome[c.challenge.outcome];
  const empty=(n,s)=>n==null?(s.outcome==='MANUAL_REVIEW'?'Pending review':'Unassigned'):money(n);
  function recordedReduction(c) {
    const first=c.base.outcome==='COUNTEROFFER', second=c.challenge.outcome==='COUNTEROFFER';
    const shortfall=s=>money(c.request-s.approved);
    if(first && second){
      if(c.base.approved===c.challenge.approved)return 'Both counteroffers were '+shortfall(c.base)+' below the request.';
      return 'The baseline counteroffer was '+shortfall(c.base)+' below the request. The challenger counteroffer was '+shortfall(c.challenge)+' below it.';
    }
    if(first || second)return 'The '+(first?'baseline':'challenger')+' counteroffer was '+shortfall(first?c.base:c.challenge)+' below the request.';
    return '';
  }
  function sourceLink(s,label){
    const local=data.juneSources?.[s.source];
    if(local){const a=document.createElement('a');a.href=local.href;a.download=local.filename;a.textContent=label+' · source CSV row '+s.line;return a;}
    const url=data.sources[s.source];if(!url){const em=document.createElement('span');em.textContent=label+' · original panel, record '+s.line;return em;}const a=document.createElement('a');a.textContent=label+' · row '+s.line;a.href=url+'#L'+s.line;window.CreditSourceTrace?.link(a,a.href);return a;}
  function casesFor(g){return [...g.cases].sort((a,b)=>Number(differs(b))-Number(differs(a))||a.id.localeCompare(b.id))}
  function show(g,c) {
    by('pair-name').textContent=(product[c.product]||pretty(c.product))+' · '+c.id;
    by('pair-inputs').textContent='Requested '+money(c.request)+(c.payment==null?'. Monthly payment: Not recorded in this extract.':' with an estimated monthly payment of '+money(c.payment)+'.')+' Annual income was '+money(c.income)+' and credit score was '+c.score+'. The new payment would use '+pct(c.pti)+' of monthly income.'+(c.dti==null?' Debt-to-income ratio: Not recorded in this extract.':' The recorded debt-to-income ratio was '+pct(c.dti)+'.');
    if(c.sourceStudy)by('pair-inputs').textContent+=' Worked example · '+c.sourceStudy+'.';
    by('pair-base').textContent='Baseline · '+g.baseRun;by('pair-chal').textContent='Challenger · '+g.challengeRun;
    const rowData=[['Decision',outcome[c.base.outcome],outcome[c.challenge.outcome]],['Approved amount',empty(c.base.approved,c.base),empty(c.challenge.approved,c.challenge)],['Monthly payment on offer',c.base.paymentUnavailable?'Not recorded in this extract':empty(c.base.payment,c.base),c.challenge.paymentUnavailable?'Not recorded in this extract':empty(c.challenge.payment,c.challenge)],['Expected loss on approved amount',empty(c.base.approvedEL,c.base),empty(c.challenge.approvedEL,c.challenge)]];
    by('pair-rows').replaceChildren(...rowData.map(row=>{const tr=document.createElement('tr');row.forEach((v,i)=>{const cell=document.createElement(i?'td':'th');if(!i)cell.scope='row';cell.textContent=v;tr.append(cell)});return tr}));
    const a=c.base,b=c.challenge, aOffer=offered(a),bOffer=offered(b);
    let why;
    if(a.outcome===b.outcome&&a.primary===b.primary)why='Both policies recorded the same primary reason: '+reason(a.primary)+'.';
    else why='Under baseline, '+reason(a.primary)+'. Under the challenger, '+reason(b.primary)+'.';
    if(c.id==='APP-00032476'&&choice.value==='CG02')why+=' The estimated default probability of 7.9007% was within the baseline 7.60%–8.40% borderline range. It fell below the challenger’s 9.50%–10.50% range.';
    by('pair-reasons').textContent=why;
    // Use recorded amounts for every lookup, including IDs without verified sizing workpapers.
    by('pair-math').textContent=recordedReduction(c);
    const ed=(bOffer?Number(b.approved):0)-(aOffer?Number(a.approved):0),ld=(bOffer?Number(b.approvedEL):0)-(aOffer?Number(a.approvedEL):0);
    let portfolio;
    if(!aOffer&&!bOffer){portfolio='Neither decision contributed an offer to the portfolio. A manual review leaves approval unresolved; a decline closes the request.';}
    else if(Math.abs(ed)<.005&&Math.abs(ld)<.005)portfolio='Both policies carried the same approved dollars and modeled loss for this application.';
    else portfolio='For this application the challenger contributed '+(Math.abs(ed)<.005?'the same exposure':money(Math.abs(ed))+' '+(ed>0?'more':'less')+' exposure')+' and '+(Math.abs(ld)<.005?'the same modeled loss':money(Math.abs(ld))+' '+(ld>0?'more':'less')+' modeled loss')+' to its portfolio.';
    by('pair-economics').textContent='For the original request, '+money(c.request)+' × '+pct(c.pd,4)+' default probability × '+pct(c.lgd,2)+' loss severity gives '+money(c.requestEL)+' in recorded expected loss (rounded). '+portfolio;
    const ab=settings[g.baseRun],bb=settings[g.challengeRun],ap=ab.products[c.product],bp=bb.products[c.product];
    const settingsText='For this product, the baseline and challenger maximum approved amounts were '+money(ap.product_max_approved_amount)+' and '+money(bp.product_max_approved_amount)+'. Their product approval payment-to-income ceilings were '+pct(ap.product_approve_max_pti)+' and '+pct(bp.product_approve_max_pti)+'. Their global approval default-probability cutoffs were '+pct(ab.pd)+' and '+pct(bb.pd)+'. A policy can change several settings at once. The row-level reasons above identify the recorded decision route.';
    by('pair-settings').textContent=settingsText;
    by('pair-codes').textContent=(c.returnedPartial?'Recorded primary reasons.':'Saved reason codes.')+' Baseline — '+[a.primary,a.secondary,a.tertiary].filter(Boolean).join(', ')+'. Challenger — '+[b.primary,b.secondary,b.tertiary].filter(Boolean).join(', ')+'.'+(c.returnedPartial?' Secondary and tertiary reasons are not included in this extract.':'');
    const math=by('pair-borrower-math');
    math.replaceChildren();
    window.renderBorrowerMath?.(math,choice.value,c.id,c);
    // Keep the recorded portfolio comparison available when a specialized lesson has no entry.
    if(math.querySelector?.('.bm-equation'))by('pair-economics').textContent=portfolio;
    if(math.querySelector?.('.bm-policy, .bm-portfolio'))by('pair-math').textContent='';
    const proof=by('pair-proof');
    proof.replaceChildren();
    if(!c.returnedPartial && a.source!=='originalFull')proof.append(sourceLink(a,'Baseline decision'),' · ',sourceLink(b,'Challenger decision'));
    if(c.paymentProof){const link=document.createElement('a');link.href=c.paymentProof;window.CreditSourceTrace?.link(link,link.href);link.textContent='Requested monthly payment · matching Module 1 row';proof.append(' · ',link);}
    if(c.returnedEvidence && a.source!=='originalFull'){
      if(!c.returnedPartial)proof.append(' · ');
      appendReturnedEvidence(proof,c);
    }
  }
  function appendReturnedEvidence(holder,c) {
    const source=data.returnedSource, lines=c.returnedEvidence.map(x=>x.line);
    const link=document.createElement('a');
    link.href=source.href;link.download=source.filename;
    link.textContent='Both decisions · campaign case CSV '+(lines.length===1?'row ':'rows ')+lines.join(', ');
    holder.append(link);
  }
  window.CreditApplicationLookup.mount({
    groups:all,membership,most,names:groupNames,casesFor,pairLabel,
    juneSources:data.juneSources,returnedSource:data.returnedSource,appendReturnedEvidence,draw:show
  });
})();
