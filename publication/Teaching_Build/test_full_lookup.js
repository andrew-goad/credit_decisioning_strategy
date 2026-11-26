/* DOM, fetch, integrity and race tests. Fixtures stay in memory and never enter a release. */
'use strict';
const fs=require('node:fs'), vm=require('node:vm'), z=require('node:zlib'), path=require('node:path'), assert=require('node:assert/strict'), {createHash,webcrypto}=require('node:crypto');
const js=fs.readFileSync(path.join(__dirname,'full_lookup.js'),'utf8');
const data=JSON.parse(fs.readFileSync(path.join(__dirname,'cases.json'),'utf8')), all=data.groups;
const ref=JSON.parse(fs.readFileSync(path.join(__dirname,'full_campaign_reference.json'),'utf8'));
const codes=Object.keys(all), runs=Object.keys(ref.runs).sort(),scenarios=ref.sources;
const runSource=runs.map(r=>scenarios.indexOf(ref.runs[r].source));
const groups=ref.groups;
const sourceFields=['product','band','score','income','dti','request','payment','pti','pd','lgd','requestEL'];
const outcomeFields=['outcome','approved','approvedEL','payment','pti','primary','secondary','tertiary','path','resolution'];
const symbolFields=['product','band','outcome','primary','secondary','tertiary','path','resolution'];
const sum=x=>createHash('sha256').update(x).digest('hex');
const shardMeta=Array.from({length:500},(_,i)=>{const first=i*100+1,last=(i+1)*100;return {first,last,
 file:'shards/'+String(first).padStart(5,'0')+'-'+String(last).padStart(5,'0')+'.json.gz',bytes:42,sha256:'a'.repeat(64)};});
const manifest={schemaVersion:1,kind:'original-full-dbeaver',applications:50000,shardSize:100,sources:scenarios,runs,groups,runSource,sourceFields,outcomeFields,symbolFields,shards:shardMeta};
const originalExecutions=Object.fromEntries(runs.map(r=>[r,{
 authorityUTC:ref.runs[r].exportUTC,observedUTC:ref.runs[r].exportUTC,basis:'original-snapshot'
}]));
const refreshedExecution={...originalExecutions['M2-01'],observedUTC:'2026-05-28T12:40:03.698135+00:00',basis:'may-28-archive-refresh'};
const refreshedManifest={...manifest,executionProvenance:{...originalExecutions,'M2-01':refreshedExecution}};
const payloads=new Map();
for(const i of [0,1,499]) {
 const s=shardMeta[i],words=['AUTO_LOAN','NEAR_PRIME','APPROVE','APPROVED_AS_REQUESTED','APPROVE_AS_REQUESTED','PRELIMINARY_APPROVE_ROUTE','MANUAL_REVIEW','MANUAL_REVIEW_BORDERLINE_PROFILE','DECLINE','POLICY_STOP_SEVERE_SYNTHETIC_RISK','SEVERE_SYNTHETIC_RISK'];
 const rows=Array.from({length:100},(_,j)=>[
   scenarios.map((_,k)=>[0,1,654,121227.52,0.3281,12839.56+j+k,322.14,0.031888,0.079007,0.45,456.49]),
   scenarios.map((_,k)=>k), [[2,12839.56+j,456.49,322.14,0.031888,3,null,null,4,5],[6,null,null,null,null,7,null,null,4,5],[8,0,0,0,0,9,null,null,10,5]],
   runs.map((_,r)=>r===38?2:r%2)
 ]);
 const raw=Buffer.from(JSON.stringify({first:s.first,words,rows}));
 const packed=z.gzipSync(raw);
 Object.assign(s,{sha256:sum(packed),bytes:packed.length,uncompressedSha256:sum(raw),uncompressedBytes:raw.length});
 payloads.set(s.file,{raw,packed});
}
const membership=new Map();
for(const [k,g] of Object.entries(all))for(const c of g.cases){
 if(!membership.has(c.id))membership.set(c.id,[]);membership.get(c.id).push(k);
}
class Element{
 constructor(){this.events={};this.data={};this.dataset={};this.value='';this.textContent='';this.children=[];this.hidden=false;this.attributes={};}
 addEventListener(t,fn){(this.events[t]??=[]).push(fn);}
 dispatchEvent(e){for(const fn of this.events[e.type]||[])fn(e);}
 replaceChildren(...v){this.children=v;}
 append(...v){this.children.push(...v);}
 setAttribute(k,v){this.attributes[k]=v;}
 removeAttribute(k){delete this.attributes[k];}
 focus(){this.focused=true;}
}
const tick=()=>new Promise(r=>setTimeout(r,30));
function run(mode,liveManifest=manifest,startUrl,initialGroup='CG02') {
 const nodes=new Map(), el=id=>{if(!nodes.has(id))nodes.set(id,new Element());return nodes.get(id);};
 const win=new Element(), protocol=mode==='file'?'file:':'https:';
 const req=[],waiting=new Map();let damaged=false;
 const tracks=[];
 async function fetcher(url){
   const str=String(url);req.push(str);
   if(str.endsWith('manifest.json')){
     if(mode==='404')return new Response('',{status:404});
     return new Response(JSON.stringify(liveManifest));
   }
   const file=str.slice(str.indexOf('shards/')),raw=payloads.get(file).packed;
   if(mode==='delayed'&&file===shardMeta[0].file){await new Promise(r=>waiting.set('first',r));}
   return new Response(damaged?Buffer.from('bad bytes'):raw);
 }
 const document={baseURI:protocol==='file:'?'file:///tmp/explorer.html':'https://example.test/portal/',getElementById:el,createElement:()=>new Element(),createTextNode:t=>t};
 const location={protocol,href:startUrl || (mode==='file'?'file:///tmp/explorer.html':'https://example.test/portal/')};
 const history={state:{view:'applicants'},replaceState(state,_,uri){this.state=state;location.href=uri.href;}};
 const context={document,window:win,location,history,Option:class{constructor(text,value){this.textContent=text;this.value=value;}},Event,URL,Response,TextDecoder,crypto:webcrypto,AbortController,Uint8Array,Blob,DecompressionStream,fetch:fetcher,setTimeout,clearTimeout};
 vm.runInNewContext(js,context);
 const api=win.CreditApplicationLookup;el('pair-search').dataset.manifest='data/full/manifest.json';el('pf-choice').value=initialGroup;
 el('pair-run-catalog').textContent=JSON.stringify(Object.fromEntries(runs.map(run=>[run,[ref.runs[run].source,ref.runs[run].module1_scenario_name,ref.runs[run].strategy_name]])));
 api.mount({groups:all,membership,most:[...membership].sort((a,b)=>b[1].length-a[1].length)[0],names:new Map(codes.map(g=>[g,g])),casesFor:g=>g.cases,pairLabel:()=>'',
   returnedSource:{refreshUTC:refreshedExecution.observedUTC},
   appendReturnedEvidence:(holder,c)=>holder.append('case CSV '+c.returnedEvidence[0].line),
   draw:(g,c)=>{tracks.push([g,c]);el('pair-proof').replaceChildren('Source records for '+c.id);}});
 function search(id){el('pair-search-id').value=id;el('pair-search').dispatchEvent({type:'submit',preventDefault(){}});}
 function group(name){el('pf-choice').value=name;el('pf-choice').dispatchEvent(new Event('change'));}
 return {api,el,win,location,history,search,group,req,waiting,tracks,setBad:v=>{damaged=v;}};
}
(async()=>{
 const local=run('file');await tick();
 assert.equal(local.tracks.at(-1)[1].id,'APP-00032476');assert.equal(local.req.length,0);
 for(const candidate of ['1','00000001','APP-1','app-00000001',' 1 '])assert.equal(local.api.normalize(candidate),'APP-00000001');
 for(const bad of ['0','50001','-1','125.5','APP-e','APP-000050000',''])assert.equal(local.api.normalize(bad),null);
 assert.equal(local.api.normalize('APP-00050000'),'APP-00050000');
 // Every campaign comparison remains discoverable in the sample, including those
 // where the draft has neither decision. Switching back preserves the applicant.
 const cross=local.el('pair-cross'), selected='APP-00032476';
 assert.equal(cross.children.length,20);assert(!cross.disabled);
 for(const opt of cross.children)assert.equal(opt.textContent.startsWith('Saved · '), membership.get(selected).includes(opt.value));
 const unavailable=codes.find(code=>!membership.get(selected).includes(code));
 cross.value=unavailable;cross.dispatchEvent(new Event('change'));await tick();
 assert.equal(local.el('pf-choice').value,unavailable);
 assert.equal(local.el('pair-search-id').value,selected);assert(local.el('pair-result').hidden);
 assert.equal(new URL(local.location.href).searchParams.get('app'),selected);
 assert.equal(local.history.state.view,'applicants');
 assert.equal(local.el('pair-return').hidden,false);
 local.el('pair-return').dispatchEvent(new Event('click'));await tick();
 assert.equal(local.el('pair-search-id').value,selected);assert(!local.el('pair-result').hidden);
 assert(membership.get(selected).includes(local.el('pf-choice').value));
 // Landing on a missing local pair from a shared URL must not auto-select another borrower.
 const direct=run('file',manifest,'file:///tmp/explorer.html?app=32476&comparison='+unavailable+'#paired-case',unavailable);
 await tick();assert.equal(direct.el('pair-search-id').value,selected);assert(direct.el('pair-result').hidden);
 const saved=all.CG20.cases[0].id;
 direct.el('pf-choice').value='CG20';
 direct.location.href='file:///tmp/explorer.html?app='+saved+'&comparison=CG20#paired-case';
 direct.win.dispatchEvent(new Event('popstate'));await tick();
 assert.equal(direct.tracks.at(-1)[1].id,saved);assert.equal(direct.el('pair-cross').value,'CG20');
 direct.location.href='file:///tmp/explorer.html?comparison=CG02#portfolio';direct.el('pf-choice').value='CG02';
 direct.win.dispatchEvent(new Event('popstate'));await tick();
 assert.equal(direct.tracks.at(-1)[1].id,selected);

 local.search('1');await tick();assert(local.el('pair-result').hidden);assert.match(local.el('pair-feedback').textContent,/APP-00000001.*no paired example/);
 local.group('CG20');await tick();assert.equal(local.el('pair-search-id').value,'APP-00000001');assert(local.el('pair-result').hidden);
 local.search(all.CG20.cases[0].id);await tick();assert.equal(local.tracks.at(-1)[1].id,all.CG20.cases[0].id);
 const missing=run('404');await tick();missing.search('49999');await tick();assert.equal(missing.req.length,1);assert.match(missing.el('pair-feedback').textContent,/49999.*no paired example/);
 // Inspecting all 39 is opt-in. The sample download explains its bound without rows.
 const openRuns=view=>{view.el('pair-all-runs').open=true;view.el('pair-all-runs').dispatchEvent(new Event('toggle'));};
 openRuns(local);await tick();assert.equal(local.el('pair-run-rows').children.length,0);
 assert(local.el('pair-run-table').hidden);assert.match(local.el('pair-run-status').textContent,/complete campaign has 39/);
 const live=run('live');await tick();assert.match(live.el('pair-release-status').textContent,/50,000/);
 assert.throws(()=>live.api.verifyManifest({...manifest,kind:'untrusted'},all));
 assert.throws(()=>live.api.verifyManifest({...manifest,groups:{...groups,CG02:[0,0]}},all));
 for(const evidence of [null,{}, {...originalExecutions,'M2-02':refreshedExecution},
      {...originalExecutions,'M2-01':{...refreshedExecution,observedUTC:'2026-05-29T12:40:03.698135+00:00'}},
      {...originalExecutions,'M2-01':{...refreshedExecution,basis:'original-snapshot'}}]){
   assert.throws(()=>live.api.verifyManifest({...manifest,executionProvenance:evidence},all));
 }
 let shard=await live.api.unpack(payloads.get(shardMeta[0].file).raw,shardMeta[0]);assert.equal(shard.rows.length,100);
 for(const size of ['1','100','101','50000']) {
   live.search(size);await tick();const c=live.tracks.at(-1)[1];
   assert.equal(c.id,'APP-'+size.padStart(8,'0'));assert.equal(c.product,'AUTO_LOAN');assert.equal(c.base.source,'originalFull');
 }
 assert.equal(live.el('pair-cross').children.length,20);assert(live.el('pair-cross').children.every(o=>!o.textContent.includes('Full archive ·')));
 const cached=live.req.length;openRuns(live);await tick();
 const allRows=live.el('pair-run-rows').children;
 assert.equal(live.req.length,cached);assert.equal(allRows.length,39);
 assert.equal(allRows[13].children[0].textContent,'M2-14'); // outside every paired comparison
 assert.equal(allRows[13].children[1].textContent,'CREDIT_BOX_BASELINE_REFERENCE');
 assert.equal(allRows[13].children[2].textContent,'BASELINE_STRATEGY');
 assert.equal(allRows[13].children[3].textContent,'Manual review');
 assert.equal(allRows[13].children[4].textContent,'$12,942.56');
 assert.equal(allRows[13].children[5].textContent,'Pending review');
 assert.equal(allRows[14].children[3].textContent,'Approved');
 assert.equal(allRows[14].children[4].textContent,'$12,943.56');
 assert.equal(allRows[14].children[5].textContent,'$12,938.56');
 assert.equal(allRows[38].children[3].textContent,'Declined');assert.equal(allRows[38].children[5].textContent,'$0.00');
 assert(!live.el('pair-run-table').hidden);assert.match(live.el('pair-run-caption').textContent,/50000/);
 const badManifest={...manifest,runs:manifest.runs.map(x=>x==='M2-14'?'M2-77':x)};
 assert.throws(()=>live.api.verifyManifest(badManifest,all));
 const count=live.req.length;
 for(const code of codes){live.group(code);await tick();const [g,c]=live.tracks.at(-1);assert.equal(c.id,'APP-00050000');assert.equal(c.base.run,g.baseRun);assert.equal(c.challenge.run,g.challengeRun);assert.equal(c.request,12839.56+99+runSource[runs.indexOf(g.baseRun)]);}
 assert.equal(live.req.length,count);
 const proof=view=>view.el('pair-proof').children.map(v=>typeof v==='string'?v:v.textContent).join(' ');
 for(const candidate of [manifest,{...manifest,executionProvenance:originalExecutions},refreshedManifest]){
   const view=run('live',candidate);await tick();
   assert.doesNotMatch(proof(view),/May 28/); // Default is a saved example from the public sample.
   view.search('1');await tick();
   for(const code of codes){
     view.group(code);await tick();
     assert.doesNotMatch(proof(view),/May 28|archive refresh/i,code);
     assert.match(proof(view),/Archive file for APP-00000001/,code);
   }
   const runsPanel=view.el('pair-all-runs');runsPanel.open=true;runsPanel.dispatchEvent(new Event('toggle'));await tick();
   assert.equal(view.el('pair-run-rows').children.length,39);
   assert.doesNotMatch(view.el('pair-run-status').textContent,/May 28|archive refresh/i);
   view.group('CG02');await tick();view.search('32476');await tick();
   assert.doesNotMatch(proof(view),/May 28/);
   assert.match(view.el('pair-feedback').textContent,/published example records/);
 }
 // Full archive enriches only observed columns from partial cases; unavailable secondary or
 // monthly fields do not create a mismatch, but a different primary reason on the same source does.
 const bootstrap=run('live',refreshedManifest);await tick();bootstrap.search('1');await tick();
 const native=bootstrap.tracks.at(-1)[1];
 const specimen={...native,returnedPartial:true,returnedEvidence:[{line:2}],payment:null,dti:null};
 for(const side of ['base','challenge']){
   specimen[side]=Object.fromEntries(['outcome','approved','approvedEL','primary','path'].map(k=>[k,native[side][k]]));
   Object.assign(specimen[side],{paymentUnavailable:true,source:'returnedCases',line:2});
 }
 all.CG02.cases.push(specimen);membership.set(specimen.id,['CG02']);
 const enriched=run('live',refreshedManifest);await tick();enriched.search('1');await tick();
 let viewed=enriched.tracks.at(-1)[1];assert.equal(viewed.base.source,'originalFull');assert.equal(viewed.dti,native.dti);
 assert.deepEqual(viewed.returnedEvidence,specimen.returnedEvidence);assert.match(proof(enriched),/case CSV 2/);
 specimen.base.primary='DELIBERATE_FIXTURE_DISCREPANCY';
 const conflict=run('live',refreshedManifest);await tick();conflict.search('1');await tick();
 assert.equal(conflict.tracks.at(-1)[1],specimen);assert(!conflict.el('pair-result').hidden);
 assert.match(conflict.el('pair-feedback').textContent,/shared fields disagree/);
 for(const alternateManifest of [manifest,{...manifest,executionProvenance:originalExecutions}]){
   const original=run('live',alternateManifest);await tick();original.search('1');await tick();
   viewed=original.tracks.at(-1)[1];assert.equal(viewed.base.source,'originalFull');
   assert.equal(viewed.base.primary,native.base.primary);assert.match(proof(original),/case CSV 2/);
 }
 all.CG02.cases.pop();membership.delete(specimen.id);
 const race=run('delayed');await tick();race.search('1');openRuns(race);await tick();race.search('50000');await tick();race.waiting.get('first')();await tick();
 assert.equal(race.el('pair-run-rows').children.length,39);
 assert.match(race.el('pair-run-caption').textContent,/50000/);
 assert.equal(race.tracks.at(-1)[1].id,'APP-00050000');assert.match(race.el('pair-feedback').textContent,/APP-00050000/);
 const corrupt=run('live');await tick();corrupt.setBad(true);corrupt.search('1');await tick();assert(corrupt.el('pair-result').hidden);assert(!corrupt.el('pair-retry').hidden);assert.match(corrupt.el('pair-feedback').textContent,/could not be loaded or verified/);
 openRuns(corrupt);await tick();assert.equal(corrupt.el('pair-run-rows').children.length,0);assert(corrupt.el('pair-run-table').hidden);
 assert(!corrupt.el('pair-run-retry').hidden);
 corrupt.setBad(false);corrupt.el('pair-run-retry').dispatchEvent(new Event('click'));await tick();
 assert.equal(corrupt.el('pair-run-rows').children.length,39);
corrupt.el('pair-retry').dispatchEvent(new Event('click'));await tick();assert.equal(corrupt.tracks.at(-1)[1].id,'APP-00000001');
 const invalid=run('delayed');await tick();invalid.search('1');await tick();invalid.search('bad');invalid.waiting.get('first')();await tick();
 assert.match(invalid.el('pair-feedback').textContent,/Enter a whole application/);
 console.log('PASS offline public fallback, exact ID/range, 404 fallback, integrity checks, compressed and predecoded transport, all 20 group transitions, legacy and original and refreshed archive provenance, unchanged public samples, pending fetch race, invalid input race, checksum failure and retry.');
})().catch(err=>{console.error(err);process.exitCode=1;});
