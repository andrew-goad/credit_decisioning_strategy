/* Exercise the built offline case renderer and the exact event used by casebook buttons. */
const fs=require('node:fs'),vm=require('node:vm'),path=require('node:path'),assert=require('node:assert/strict'),{createHash}=require('node:crypto');
const page=fs.readFileSync(process.argv[2] || path.join(__dirname,'Credit_Strategy_Explorer.html'),'utf8');
const programs=[...page.matchAll(/<script([^>]*)>([\s\S]*?)<\/script>/gi)];
const app=programs.find(([,attrs,text])=>!attrs.includes('application/json')&&text.includes('/* Load the exact original application'))[2];
class Elem{
 constructor(){this.value='';this.textContent='';this.hidden=false;this.dataset={};this.events={};this.children=[];}
 addEventListener(type,f){(this.events[type]??=[]).push(f);}
 dispatchEvent(e){for(const f of this.events[e.type]||[])f(e);}
 replaceChildren(...x){this.children=x;}
 append(...x){this.children.push(...x);}
 focus(){this.focused=true;}
 scrollIntoView(){this.scrolled=true;}
 setAttribute(k,x){this[k]=x;}removeAttribute(k){delete this[k];}
}
const elements=new Map(), el=id=>{if(!elements.has(id))elements.set(id,new Elem());return elements.get(id);};
for(const [,attrs,text] of programs){const m=attrs.match(/id="(archived-case-(?:settings|data))"/);if(m)el(m[1]).textContent=text;}
const data=JSON.parse(el('archived-case-data').textContent);
el('pf-choice').value='CG02';el('pf-choice').options=Object.keys(data.groups).map(value=>({value,textContent:value}));el('pair-search').dataset.manifest='data/full/manifest.json';
const window=new Elem(),document={baseURI:'file:///tmp/lesson.html',getElementById:el,createElement:()=>new Elem(),createTextNode:s=>s};
vm.runInNewContext(app,{document,window,location:{protocol:'file:'},URL,Event,Option:class{constructor(text,value){this.textContent=text;this.value=value;}},setTimeout,clearTimeout});
const cases=Object.entries(data.groups).flatMap(([group,g])=>g.cases.filter(c=>c.sourceStudy).map(c=>({group,c})));assert.equal(cases.length,24);
const tick=()=>new Promise(r=>setTimeout(r,0));
(async()=>{
 await tick();
 assert.equal(el('pair-name').textContent,'Auto loan · APP-00032476');
 for(const {group,c} of cases) {
   window.dispatchEvent({type:'credit:application', detail:{group,id:c.id}});await tick();
   assert.equal(el('pf-choice').value,group);assert.equal(el('pair-search-id').value,c.id);assert.equal(el('pair-id').value,c.id);
   assert(!el('pair-result').hidden);assert.match(el('pair-name').textContent,new RegExp(c.id));
   assert(el('pair-inputs').textContent.includes(c.sourceStudy));assert(el('paired-title').focused && el('paired-title').scrolled);
   const payment=el('pair-rows').children.find(row=>row.children[0].textContent==='Monthly payment on offer');
   assert.equal(payment.children[1].textContent,'Not recorded in this extract');assert.equal(payment.children[2].textContent,'Not recorded in this extract');
   const requested=el('pair-inputs').textContent;if(c.id==='APP-00010577')assert(requested.includes('Not recorded in this extract'));else assert(!requested.includes('Not recorded in this extract') && !requested.includes('payment of $0.00'));
   const link=el('pair-proof').children[0];const meta=data.juneSources[c.base.source];
   assert.equal(link.download,meta.filename);assert(link.textContent.includes(String(c.base.line)));
   assert.equal(createHash('sha256').update(Buffer.from(link.href.split(',')[1],'base64')).digest('hex'),meta.sha256);
 }
 const keep=el('pair-search-id').value;el('pf-choice').value='CG08';el('pf-choice').dispatchEvent(new Event('change'));await tick();
 assert.equal(el('pair-search-id').value,keep);assert(el('pair-result').hidden);
 const all=Object.values(data.groups).flatMap(g=>g.cases);
 assert.equal(new Set(all.filter(c=>!c.returnedPartial).map(c=>c.id)).size,206);
 if(data.returnedSource){
   const returned=Object.entries(data.groups).flatMap(([group,g])=>g.cases.filter(c=>c.returnedPartial).map(c=>({group,c})));
   assert.equal(returned.length,464);
   assert.equal(new Set(all.map(c=>c.id)).size,665);
   const hash=createHash('sha256').update(Buffer.from(data.returnedSource.href.split(',')[1],'base64')).digest('hex');
   assert.equal(hash,data.returnedSource.sha256);
   for(const {group,c} of returned){
     window.dispatchEvent({type:'credit:application',detail:{group,id:c.id}});await tick();
     assert(!el('pair-result').hidden);assert.equal(el('pair-id').value,c.id);
     assert(el('pair-inputs').textContent.includes('Debt-to-income ratio: Not recorded'));
     assert(el('pair-inputs').textContent.includes('Monthly payment: Not recorded'));
     const amounts=el('pair-rows').children[1].children.map(el=>el.textContent);
     for(const [idx,side] of [[1,c.base],[2,c.challenge]]){
       if(side.outcome==='MANUAL_REVIEW') assert.equal(amounts[idx],'Pending review');
       if(side.outcome==='DECLINE') assert.equal(amounts[idx],'$0.00');
     }
     assert(el('pair-codes').textContent.includes('Recorded primary reasons.'));
     assert(el('pair-codes').textContent.includes('Secondary and tertiary reasons are not included'));
     const elements=el('pair-proof').children;
     assert.equal(elements[0].download,data.returnedSource.filename);
     assert.equal(elements[0].href,data.returnedSource.href);
     assert(elements[0].textContent.includes(String(c.returnedEvidence[0].line)));
     const note=elements.filter(n=>typeof n==='string').join(' ');
     assert.doesNotMatch(note,/May 28|archive refresh/i);
     assert(!el('pair-math').textContent.includes('debt-to-income ratio of 0.00%'));
   }
   console.log('PASS offline navigation to all 464 returned case pairs, 665 searchable IDs, primary-only reasons, omitted DTI/payment, zero decline and unresolved review terms, exact CSV lines and concise evidence labels.');
 }
 console.log('PASS exact casebook-to-portfolio selection and saved file hashes for 24 paired June exhibits, correct missing fields, intact chosen ID when moving out of source scope, 206 initial distinct IDs preserved.');
})().catch(e=>{console.error(e);process.exitCode=1;});
