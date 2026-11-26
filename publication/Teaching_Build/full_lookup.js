/* Load the exact original application for the selected comparison, using one release shard. */
(() => {
  'use strict';
  const sourceFields = ['product','band','score','income','dti','request','payment','pti','pd','lgd','requestEL'];
  const outcomeFields = ['outcome','approved','approvedEL','payment','pti','primary','secondary','tertiary','path','resolution'];
  const symbolFields = ['product','band','outcome','primary','secondary','tertiary','path','resolution'];
  const symbols = new Set(symbolFields);
  const same = (a,b) => Array.isArray(a) && a.length === b.length && a.every((v,i)=>v===b[i]);
  const outcomes = new Set(['APPROVE','COUNTEROFFER','MANUAL_REVIEW','DECLINE']);
  const products = new Set(['MORTGAGE','HELOC','AUTO_LOAN','UNSECURED_PERSONAL_LOAN','REVOLVING_LINE']);
  const isIndex = (n,a) => Number.isInteger(n) && n >= 0 && n < a.length;
  function normalize(value) {
    const m = /^(?:APP-)?(\d{1,8})$/i.exec(String(value).trim());
    if (!m) return null;
    const n=Number(m[1]);
    return n>=1 && n<=50000 ? 'APP-'+String(n).padStart(8,'0') : null;
  }
  function assert(ok) {
    if(!ok) throw new Error('The original campaign file could not be verified.');
  }
  function verifyManifest(m, groups) {
    assert(m && m.kind==='original-full-dbeaver' && m.schemaVersion===1 && m.applications===50000 && m.shardSize===100);
    assert(same(m.sourceFields,sourceFields) && same(m.outcomeFields,outcomeFields));
    assert(Array.isArray(m.symbolFields) && m.symbolFields.length===symbols.size && [...symbols].every(s=>m.symbolFields.includes(s)));
    assert(Array.isArray(m.sources) && m.sources.length===19 && new Set(m.sources).size===19);
    assert(Array.isArray(m.runs) && m.runs.length===39 && new Set(m.runs).size===39 && m.runs.every(run=>/^M2-(?:0[1-9]|[12]\d|3[0-9])$/.test(run)));
    assert(Array.isArray(m.runSource) && m.runSource.length===m.runs.length && m.runSource.every(n=>isIndex(n,m.sources)));
    if(m.executionProvenance!==undefined) {
      const entries=m.executionProvenance;
      assert(entries && typeof entries==='object' && !Array.isArray(entries) && Object.keys(entries).length===m.runs.length);
      const utc=/^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d\.\d{6}\+00:00$/;
      for(const run of m.runs) {
        const entry=entries[run];
        assert(entry && utc.test(entry.authorityUTC) && utc.test(entry.observedUTC));
        if(entry.basis==='original-snapshot')assert(entry.observedUTC===entry.authorityUTC);
        else assert(entry.basis==='may-28-archive-refresh' && run==='M2-01' &&
          entry.observedUTC.startsWith('2026-05-28T12:40:03.698') && entry.observedUTC!==entry.authorityUTC);
      }
    }
    assert(m.groups && Object.keys(m.groups).length===Object.keys(groups).length);
    for(const [key,g] of Object.entries(groups)) {
      const a=m.groups[key];assert(Array.isArray(a) && a.length===2 && a.every(n=>isIndex(n,m.runs)));
      assert(m.runs[a[0]]===g.baseRun && m.runs[a[1]]===g.challengeRun && m.runSource[a[0]]===m.runSource[a[1]]);
    }
    assert(Array.isArray(m.shards) && m.shards.length===500);
    m.shards.forEach((s,i)=>{
      assert(s.first===i*100+1 && s.last===(i+1)*100 && s.file==='shards/'+String(s.first).padStart(5,'0')+'-'+String(s.last).padStart(5,'0')+'.json.gz');
      assert(Number.isSafeInteger(s.bytes) && s.bytes>0 && /^[0-9a-f]{64}$/.test(s.sha256));
      if(s.uncompressedBytes!==undefined)assert(Number.isSafeInteger(s.uncompressedBytes) && s.uncompressedBytes>0 && /^[0-9a-f]{64}$/.test(s.uncompressedSha256));
    });
    return m;
  }
  const sha256 = async bytes => Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256',bytes)),b=>b.toString(16).padStart(2,'0')).join('');
  async function unpack(bytes,s) {
    const compressed=bytes[0]===31 && bytes[1]===139;
    const length=compressed?s.bytes:s.uncompressedBytes, digest=compressed?s.sha256:s.uncompressedSha256;
    assert(bytes.length===length && typeof digest==='string' && await sha256(bytes)===digest);
    const text=compressed?await new Response(new Blob([bytes]).stream().pipeThrough(new DecompressionStream('gzip'))).text():new TextDecoder().decode(bytes);
    const shard=JSON.parse(text);
    assert(shard.first===s.first && Array.isArray(shard.words) && Array.isArray(shard.rows) && shard.rows.length===s.last-s.first+1);
    return shard;
  }
  function applicationRecords(m,s,app) {
    const row=s.rows[Number(app.slice(4))-s.first];assert(Array.isArray(row) && row.length===4);
    const [sources,sourceRef,decisions,outcomeRef]=row;
    assert([sources,sourceRef,decisions,outcomeRef].every(Array.isArray) && sourceRef.length===m.sources.length && outcomeRef.length===m.runs.length);
    function record(fields,rows,index) {
      assert(isIndex(index,rows));const values=rows[index];assert(Array.isArray(values) && values.length===fields.length);
      const out={};
      fields.forEach((k,i)=>{
        const v=values[i];
        if(v===null)out[k]=null;
        else if(symbols.has(k)){assert(isIndex(v,s.words) && typeof s.words[v]==='string');out[k]=s.words[v];}
        else{assert(Number.isFinite(v));out[k]=v;}
      });
      return out;
    }
    function source(i){
      const c=record(sourceFields,sources,sourceRef[m.runSource[i]]);
      assert(products.has(c.product) && sourceFields.filter(k=>!symbols.has(k)).every(k=>Number.isFinite(c[k])));
      return c;
    }
    function side(i) {
      const d=record(outcomeFields,decisions,outcomeRef[i]);assert(outcomes.has(d.outcome) && typeof d.primary==='string');
      d.source='originalFull';d.run=m.runs[i];d.line=null;return d;
    }
    return {source,side};
  }
  function decode(m,s,app,group) {
    const records=applicationRecords(m,s,app),[a,b]=m.groups[group];
    return {...records.source(a),id:app,base:records.side(a),challenge:records.side(b)};
  }
  async function download(url) {
    const controller=new AbortController(),timer=setTimeout(()=>controller.abort(),15000);
    try {
      const res=await fetch(url,{credentials:'same-origin',mode:'same-origin',signal:controller.signal});
      if(!res.ok){const e=new Error('Archive unavailable');e.status=res.status;throw e;}
      return new Uint8Array(await res.arrayBuffer());
    } finally {clearTimeout(timer);}
  }
  function store(groups,manifestPath) {
    const uri=new URL(manifestPath,document.baseURI);
    let state=location.protocol==='file:'?'absent':'unknown', manifest=null, pending=null;
    const cache=new Map();
    async function getManifest() {
      if(state==='ready')return manifest;
      if(state==='absent')return null;
      if(!pending)pending=download(uri).then(bytes=>{
        manifest=verifyManifest(JSON.parse(new TextDecoder().decode(bytes)),groups);state='ready';return manifest;
      }).catch(err=>{
        if(err.status===404 || err.status===410){state='absent';return null;}
        state='error';throw err;
      }).finally(()=>{pending=null;});
      return pending;
    }
    async function loadShard(m,app) {
      const i=Math.floor((Number(app.slice(4))-1)/m.shardSize), f=m.shards[i];
      if(!cache.has(i)) {
        if(cache.size>=4)cache.delete(cache.keys().next().value);
        const task=download(new URL(f.file,uri)).then(bytes=>unpack(bytes,f));
        cache.set(i,task);
        task.catch(()=>{if(cache.get(i)===task)cache.delete(i);});
      }
      return {shard:await cache.get(i),url:new URL(f.file,uri).href};
    }
    async function lookup(app,group) {
      const m=await getManifest();if(!m)return null;
      const {shard,url}=await loadShard(m,app),c=decode(m,shard,app,group);
      return {c,url};
    }
    async function allDecisions(app) {
      const m=await getManifest();if(!m)return null;
      const {shard}=await loadShard(m,app),records=applicationRecords(m,shard,app);
      return m.runs.map((run,i)=>({run,source:m.sources[m.runSource[i]],request:records.source(i).request,decision:records.side(i)}));
    }
    return {getManifest,lookup,allDecisions,state:()=>state,reset:()=>{if(state==='error')state='unknown';}};
  }
  function mount({groups,membership,most,names,casesFor,pairLabel,draw,juneSources={},returnedSource,appendReturnedEvidence}) {
    const el=id=>document.getElementById(id);
    const form=el('pair-search'), input=el('pair-search-id'), feedback=el('pair-feedback');
    const choice=el('pf-choice'), examples=el('pair-id'), cross=el('pair-cross'), result=el('pair-result'), retry=el('pair-retry');
    const data=store(groups,form.dataset.manifest);
    const options=(select,items,value)=>{select.replaceChildren(...items.map(([v,t])=>new Option(t,v)));select.value=value;};
    const groupKeys=[...names.keys()];
    const coverageNote=el('pair-coverage'), returnButton=el('pair-return'), mostButton=el('pair-long');
    const defaultApplicant=()=>choice.value==='CG02'?'APP-00032476':casesFor(groups[choice.value])[0].id;
    function urlApplicant() {
      return location.href ? normalize(new URL(location.href).searchParams.get('app')||'') : null;
    }
    function rememberApplicant() {
      if(!location.href || typeof history==='undefined')return;
      try {
        const url=new URL(location.href);
        url.searchParams.set('app',selected);
        history.replaceState(history.state,'',url);
      } catch { /* File viewers may restrict local history. The in-page selection remains active. */ }
    }
    const fallbackText='Teaching edition · '+membership.size+' saved applicants. The complete campaign evaluated 50,000 IDs in all 39 runs.';
    const coverage=()=>{
      const state=data.state();
      el('pair-release-status').textContent=state==='ready'?'Full campaign · 50,000 IDs across 39 runs and '+groupKeys.length+' policy comparisons.':
        state==='error'?'The full archive could not be verified. Saved examples are available below.':
        state==='unknown'?'Checking availability of the full campaign…':fallbackText;
    };
    let selected=urlApplicant() || defaultApplicant();
    let epoch=0;
    const runPanel=el('pair-all-runs'), runBody=el('pair-run-rows'), runTable=el('pair-run-table');
    const runMessage=el('pair-run-status'), runRetry=el('pair-run-retry');
    const catalog=JSON.parse(el('pair-run-catalog').textContent || '{}');
    const labels={APPROVE:'Approved',COUNTEROFFER:'Counteroffer',MANUAL_REVIEW:'Manual review',DECLINE:'Declined'};
    const dollars = new Intl.NumberFormat('en-US',{style:'currency',currency:'USD'});
    let runRequest=0;
    async function showRuns() {
      const token=++runRequest,id=selected;
      runBody.replaceChildren();runTable.hidden=true;runRetry.hidden=true;runMessage.textContent='';
      if(!runPanel.open)return;
      runMessage.textContent='Looking up all recorded decisions for '+id+'…';
      try{
        const rows=await data.allDecisions(id);
        if(token!==runRequest || !runPanel.open)return;
        if(!rows){
          runMessage.textContent='The complete campaign has 39 decisions for '+id+'. Open the full archive to see them together, including the eight runs outside the registered policy comparisons.';
          return;
        }
        const nodes=rows.map(({run,source,request,decision})=>{
          const entry=catalog[run];if(entry)assert(entry[0]===source);
          const row=document.createElement('tr'), name=document.createElement('th');
          name.scope='row';name.textContent=run;row.append(name);
          const amount=decision.approved===null?(decision.outcome==='MANUAL_REVIEW'?'Pending review':'Unassigned'):dollars.format(decision.approved);
          for(const text of [entry?.[1] || source,entry?.[2] || run,labels[decision.outcome],dollars.format(request),amount]){
            const cell=document.createElement('td');cell.textContent=text;row.append(cell);
          }
          return row;
        });
        runBody.replaceChildren(...nodes);runTable.hidden=false;
        el('pair-run-caption').textContent='Decisions for '+id+' across all 39 runs';
        runMessage.textContent='The ID follows the same synthetic applicant through all 39 runs. Check the source scenario and amount requested. A new source scenario can change the request. Within each registered policy comparison, both policies saw identical inputs.';
      } catch {
        if(token!==runRequest || !runPanel.open)return;
        runMessage.textContent='The complete decision records for '+id+' could not be retrieved and verified.';
        runRetry.hidden=false;
      }
    }
    runPanel.addEventListener('toggle',showRuns);
    runRetry.addEventListener('click',()=>{data.reset();showRuns();});
    function controls() {
      coverage();
      const g=groups[choice.value],rows=casesFor(g), ids=membership.get(selected)||[];
      const opts=[['','Choose a saved example'],...rows.map(r=>[r.id,r.id+' · '+pairLabel(r)])];
      options(examples,opts,rows.some(r=>r.id===selected)?selected:'');
      const complete=data.state()==='ready', sampleOnly=data.state()==='absent' || data.state()==='error';
      options(cross,groupKeys.map(k=>{
        const label=sampleOnly?(ids.includes(k)?'Saved · ':'Full archive · '):'';
        return [k,label+names.get(k)];
      }),choice.value);
      coverageNote.textContent=complete?'':sampleOnly?selected+' has saved decisions in '+ids.length+' of '+groupKeys.length+' comparisons.':'';
      coverageNote.hidden=!coverageNote.textContent;
      mostButton.hidden=complete || !ids.includes(choice.value) || most[0]===selected;
      returnButton.hidden=true;
    }
    function paint(group,c,source) {
      draw(group,c);controls();
      if(source) {
        const a=document.createElement('a');a.href=source;a.textContent='Archive file for '+selected+' (compressed JSON)';
        el('pair-proof').replaceChildren(a,document.createTextNode(' · '+group.baseRun+' and '+group.challengeRun));
        if(c.juneReference){const original=juneSources[c.juneReference.base.source];const link=document.createElement('a');link.href=original.href;link.download=original.filename;link.textContent='Case CSV · rows '+c.juneReference.base.line+' and '+c.juneReference.challenge.line;el('pair-proof').append(' · ',link);}
        if(c.returnedEvidence){el('pair-proof').append(' · ');appendReturnedEvidence(el('pair-proof'),c);}
      }
      result.hidden=false;
    }
    async function update() {
      const token=++epoch,key=choice.value,g=groups[key],id=selected;
      const sample=g.cases.find(c=>c.id===id);
      showRuns();
      if(typeof CustomEvent==='function')window.dispatchEvent(new CustomEvent('credit:selection',{detail:{group:key,id}}));
      retry.hidden=true;result.hidden=true;feedback.textContent='';input.value=id;input.removeAttribute('aria-invalid');
      controls();
      if(sample)paint(g,sample,null);
      if(!sample)feedback.textContent='Looking for '+id+' in '+key+'…';
      try {
        const m=await data.getManifest();
        if(token!==epoch)return;
        controls();
        if(!m) {
          if(!sample){
            const available=membership.get(id)||[];
            feedback.textContent=id+' has no paired example in '+key+' in this download. Both policies evaluated this ID. Open the complete campaign to see their recorded decisions here.';
            returnButton.hidden=false;
            returnButton.textContent=available.length?'Show '+id+' in '+available[0]:'Show a saved applicant in '+key;
          }
          return;
        }
        if(sample && !sample.sourceStudy && !sample.returnedPartial){feedback.textContent='Showing the two published example records for '+id+' in '+key+'.';return;}
        const record=await data.lookup(id,key);
        if(token!==epoch)return;
        if(sample?.sourceStudy || sample?.returnedPartial){
          // Reconcile only fields present in the extract, including reported nulls on review.
          // A complete archive with a different baseline remains a separate cited observation.
          const baseline=m.executionProvenance?.['M2-01'];
          const sameIntakeSource=!sample.returnedPartial || ![g.baseRun,g.challengeRun].includes('M2-01') ||
            (returnedSource?.refreshUTC ? baseline?.observedUTC===returnedSource.refreshUTC :
             !baseline || baseline.basis==='original-snapshot');
          if(sameIntakeSource){
            const eq=(x,y)=>typeof x==='number' && typeof y==='number'?Math.abs(x-y)<1e-7:x===y;
            const common=sourceFields.filter(k=>sample[k]!=null);
            const recorded=sample.returnedPartial?['outcome','approved','approvedEL','primary','path']:
              outcomeFields.filter(k=>k!=='payment'&&k!=='resolution');
            if(!common.every(k=>eq(sample[k],record.c[k])) ||
                !['base','challenge'].every(side=>recorded.every(k=>eq(sample[side][k],record.c[side][k])))){
              feedback.textContent='Showing the saved example. Its shared fields disagree with the full archive for '+id+' in '+key+'.';
              return;
            }
          }
          if(sample.sourceStudy){record.c.sourceStudy=sample.sourceStudy;record.c.juneReference=sample;}
          if(sample.returnedEvidence)record.c.returnedEvidence=sample.returnedEvidence;
        }
        paint(g,record.c,record.url);feedback.textContent='Showing archived decisions for '+id+' in '+key+'.';
      } catch {
        if(token!==epoch)return;
        controls();retry.hidden=false;
        feedback.textContent=sample?'Showing the saved example for '+id+'. Full archive access is temporarily unavailable.':'The original archive for '+id+' in '+key+' could not be loaded or verified. Retry, or choose a saved example.';
      }
    }
    function select(id) {selected=id;rememberApplicant();return update();}
    form.addEventListener('submit',e=>{e.preventDefault();const id=normalize(input.value);
      if(!id){epoch++;retry.hidden=true;input.setAttribute('aria-invalid','true');feedback.textContent='Enter a whole application number from 1 to 50,000, such as 32476 or APP-00032476.';input.focus();return;}
      select(id);
    });
    examples.addEventListener('change',()=>{if(examples.value)select(examples.value);});
    cross.addEventListener('change',()=>{choice.value=cross.value;choice.dispatchEvent(new Event('change',{bubbles:true}));});
    mostButton.addEventListener('click',()=>{
      selected=most[0];rememberApplicant();
      if(!most[1].includes(choice.value))choice.value=[...most[1]].sort()[0];
      choice.dispatchEvent(new Event('change',{bubbles:true}));
    });
    returnButton.addEventListener('click',()=>{
      const saved=membership.get(selected)||[];
      if(!saved.length){select(casesFor(groups[choice.value])[0].id);return;}
      choice.value=saved[0];choice.dispatchEvent(new Event('change',{bubbles:true}));
    });
    window.addEventListener('credit:application',e=>{
      const key=e.detail?.group,app=normalize(e.detail?.id);
      if(!Object.hasOwn(groups,key)||!app)return;
      selected=app;rememberApplicant();choice.value=key;choice.dispatchEvent(new Event('change',{bubbles:true}));
      const title=el('paired-title');title.tabIndex=-1;title.focus({preventScroll:true});title.scrollIntoView({block:'start'});
    });
    choice.addEventListener('change',()=>{rememberApplicant();update();});
    window.addEventListener('popstate',()=>{
      selected=urlApplicant() || defaultApplicant();
      update();
    });
    window.addEventListener('hashchange',update);
    retry.addEventListener('click',()=>{data.reset();update();});
    update();
  }
  window.CreditApplicationLookup={mount,normalize,verifyManifest,unpack,decode};
})();
