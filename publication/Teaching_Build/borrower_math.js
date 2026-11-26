(() => {
  'use strict';
  const read = id => JSON.parse(document.getElementById(id).textContent);
  let models, examples, decisions;
  const money = n => n.toLocaleString('en-US', {style:'currency',currency:'USD'});
  const percent = (n, digits = 4) => (100 * n).toLocaleString('en-US', {maximumFractionDigits:digits}) + '%';
  const multiple = (n, digits = 4) => n.toLocaleString('en-US', {minimumFractionDigits:0,maximumFractionDigits:digits});
  const words = s => s.toLowerCase().replaceAll('_',' ');
  const bands = {SUPER_PRIME:'super-prime',NEAR_PRIME:'near-prime',DEEP_SUBPRIME:'deep subprime'};
  function node(tag, text, cls) {
    const el = document.createElement(tag);
    if (text != null) el.textContent = text;
    if (cls) el.className = cls;
    return el;
  }
  function fold(label) {
    const details = node('details',null,'bm-detail');
    details.append(node('summary',label));
    return details;
  }
  function table(headers, rows) {
    const wrap = node('div',null,'bm-table');
    const t = node('table'), header = node('tr');
    for (const name of headers) {
      const h = node('th',name); h.scope='col'; header.append(h);
    }
    const head = node('thead'); head.append(header); t.append(head);
    const body = node('tbody');
    for (const row of rows) {
      const tr = node('tr');
      row.forEach((v,i) => {
        const cell = node(i ? 'td' : 'th',v);
        if (!i) cell.scope='row';
        tr.append(cell);
      });
      body.append(tr);
    }
    t.append(body);wrap.append(t);return wrap;
  }
  function value(meta, observed) {
    switch (meta.unit) {
      case 'percent': return percent(observed,3);
      case 'flag': return observed ? 'Yes' : 'No';
      case 'months': return observed+' months';
      case 'category': return observed === 'HELOC' ? 'Home equity line' : words(observed);
      default: return String(observed);
    }
  }
  function pdLesson(m) {
    const part = fold('How did the model arrive at '+percent(m.pd)+' default risk?');
    const band = bands[m.band] || words(m.band);
    const nonNeutral = models.factorMeta.filter(f => m.factors[f.key] !== 1);
    const ranked = nonNeutral.slice().sort((a,b) => Math.abs(Math.log(m.factors[b.key])) - Math.abs(Math.log(m.factors[a.key])));
    const f = ranked[0];
    part.append(node('p','Module 1 drew the '+band+' band, then generated a score of '+m.score+' within it. The band set the starting modeled probability of default at '+percent(m.basePD)+'. '+
      (f ? 'One of the largest adjustments came from '+f.label.toLowerCase()+' ('+value(f,m.observations[f.key])+'), which multiplied the estimate by '+multiple(m.factors[f.key])+'. ' : '')+
      'After all adjustments, the model used '+percent(m.pd)+'.'));
    const detail=part;
    detail.append(node('p','Start at '+percent(m.basePD)+' and multiply down the table. Running estimates are rounded for display.'));
    let running = m.basePD;
    const rows = nonNeutral.map(v=>{
      running *= m.factors[v.key];
      return [v.label,value(v,m.observations[v.key]),'× '+multiple(m.factors[v.key]),percent(running)];
    });
    rows.push(['Repeatable variation for this applicant','Same draw in both policies','× '+multiple(m.jitter,6),percent(m.rawPD)]);
    detail.append(table(['Model input','This borrower','Multiplier','Running estimate'],rows));
    const neutral=models.factorMeta.filter(v=>m.factors[v.key]===1);
    if (neutral.length){
      const others=fold('Inputs with a multiplier of 1 ('+neutral.length+')');
      others.append(node('p','These inputs left the estimate unchanged for this applicant.'));
      others.append(table(['Model input','This borrower'],neutral.map(v=>[v.label,value(v,m.observations[v.key])])));
      detail.append(others);
    }
    detail.append(node('p','The simulation makes one repeatable draw for this applicant and population. Here 0.95 + (0.10 × '+multiple(m.u15,6)+') gives '+multiple(m.jitter,6)+'. The model rounds the resulting probability to six decimal places.'));
    let finish = 'The raw estimate of '+percent(m.rawPD)+' was within the range that passes through without compression.';
    if (m.rawPD > .55) finish = 'Above 55%, the model keeps 15% of the excess. Here 42.5% + 0.15 × ('+percent(m.rawPD)+' − 55%) = '+percent(m.afterSaturation)+'.';
    else if (m.rawPD > .30) finish = 'Above 30%, the model keeps half the excess up to 55%. Here 30% + 0.50 × ('+percent(m.rawPD)+' − 30%) = '+percent(m.afterSaturation)+'.';
    if (m.afterSaturation!==m.pd) finish += ' The model then applies its '+(m.afterSaturation>m.pd ? '45% maximum' : '0.5% minimum')+'.';
    detail.append(node('p',finish+' Final modeled default probability: '+percent(m.pd)+'.'));
    const src = node('p',null,'bm-note');
    src.append('These probabilities come from assumptions in the synthetic model. ');
    const code=node('a','Read the risk calculation');code.href=models.sourceFiles.sql+'#L4414';src.append(code);
    if (m.sourceRow && models.sourceFiles[m.source]) {
      const row=node('a','See the saved applicant’s inputs');row.href=models.sourceFiles[m.source]+'#L'+m.sourceRow;window.CreditSourceTrace?.link(row,row.href);
      src.append(' · ',row);
    } else src.append('. Inputs for this scenario were reproduced with the historical settings and checked against the saved decision inputs.');
    detail.append(src);return part;
  }
  function lossLesson(c) {
    const part = fold('Why does the full request carry '+money(c.requestEL)+' of expected loss?');
    part.append(node('p','For this '+(c.product==='HELOC'?'home equity line':words(c.product))+', the scenario assumes a loss of '+percent(c.lgd)+' of the outstanding amount if default occurs. The model applies that severity to the full request and weights the result by the chance of default.'));
    part.append(node('p',money(c.request)+' × '+percent(c.pd)+' × '+percent(c.lgd)+' = '+money(c.requestEL),'bm-equation'));
    part.append(node('p','Amount requested × modeled default probability × loss given default','bm-note'));
    part.append(node('p','For each $100 offered on these terms, the model expects '+money(100*c.pd*c.lgd)+' in credit loss on average. That rate also applies to a smaller offer because this decision engine holds the borrower’s probability and product loss severity fixed when it resizes the amount.'));
    const settingsNote = node('p','Module 1 assigns severity by product and scenario. ','bm-note');
    const settingsLink = node('a','Compare the product loss assumptions');
    settingsLink.href = '#loss-given-default';
    settingsNote.append(settingsLink);
    part.append(settingsNote);
    return part;
  }
  function show(holder, groupKey, id, passedRecord) {
    if (!holder) return;
    holder.replaceChildren();
    if (!models) {
      models=read('borrower-math-data');
      examples=read('archived-case-data');
      const worked=document.getElementById('worked-decision-math');
      decisions=worked ? JSON.parse(worked.textContent) : {};
    }
    const group=examples.groups[groupKey];
    if (!group) return;
    const c=passedRecord || group.cases.find(a=>a.id===id);
    if (!c) return;
    const m=models.records[group.scenario]?.[id];
    const section=node('div',null,'borrower-math');
    if (m) section.append(pdLesson(m));
    else if(c.pd!=null) {
      section.append(node('p','The decision record supplies a default probability of '+percent(c.pd)+'. An input-by-input reconstruction is available for the saved teaching examples.','bm-note'));
    }
    if ([c.request,c.pd,c.lgd,c.requestEL].every(v=>typeof v==='number')) section.append(lossLesson(c));
    const trace=decisions[groupKey+'|'+id];
    const gates=node('div',null,'bm-policy');
    window.renderCounterofferGates?.(gates,groupKey,id,c);
    if (gates.childNodes.length || trace) {
      const tested=[c.base,c.challenge].some(side=>side.path?.startsWith('COUNTEROFFER_'));
      const policy=fold(tested?'Which counteroffer gates determined the outcome?':'Which rule decided the application?');
      if (trace) for (const line of trace.lines) policy.append(node('p',line));
      if(gates.childNodes.length) {
        const gateHeading=gates.querySelector('h4');
        if(gateHeading) gateHeading.remove();
        policy.append(gates);
      }
      if(id==='APP-00040465' && groupKey==='CG18'){
        const record=read('counteroffer-calculation');
        const source=node('a','Download this borrower’s archived counteroffer calculations');
        source.href='data:text/csv;base64,'+record.download;source.download=record.filename;
        const note=node('p',null,'bm-note');note.append(source);policy.append(note);
      }
      section.append(policy);
    }
    const economics=node('div',null,'bm-portfolio');
    window.renderOfferEconomics?.(economics,groupKey,id,c);
    if(economics.childNodes.length) section.append(economics);
    const link=document.querySelector('#j-choices [data-worked-group="'+groupKey+'"][data-worked-id="'+id+'"]');
    if(link){
      const cohort=read('offer-flow-data').groups[groupKey];
      const count=cohort.counts[link.dataset.pattern];
      section.append(node('p','Across all products, '+count.toLocaleString('en-US')+' of '+cohort.denominator.toLocaleString('en-US')+' matched applicants '+link.dataset.finding+'.','bm-note'));
    }
    holder.append(section);
  }
  window.renderBorrowerMath=show;
})();
