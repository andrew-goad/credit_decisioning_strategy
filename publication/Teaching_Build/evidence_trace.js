(() => {
  const {commit, files} = JSON.parse(document.getElementById('source-trace-data').textContent);
  const by = id => document.getElementById(id);
  const dialog = by('source-trace-dialog');
  const content = by('trace-content');
  const pathOf = url => decodeURIComponent(new URL(url).pathname);
  const paths = new Map(Object.entries(files).map(([key, file]) => [pathOf(file.url), key]));
  let invoker, downloadUrl;

  function part(tag, text) {
    const el = document.createElement(tag);
    if (text !== undefined) el.textContent = text;
    return el;
  }
  function permalink(token, region) {
    const url = new URL(location.href);
    url.searchParams.set('trace', token);
    if (region) url.hash = region;
    return url.href;
  }
  function match(url) {
    const link = new URL(url, document.baseURI);
    const key = link.hostname === 'github.com' && paths.get(pathOf(link));
    const bounds = /^#L(\d+)(?:-L(\d+))?$/.exec(link.hash);
    if (!key || !bounds) return null;
    if (key === 'sql' && bounds[1] === '19660') return 'sql.19675-19929';
    return key + '.' + bounds[1] + (bounds[2] ? '-' + bounds[2] : '');
  }
  function locate(token) {
    const bounds = /^(input|scenario|decisions|sql)\.(\d+)(?:-(\d+))?$/.exec(token);
    if (!bounds) return null;
    const [, key, first, last] = bounds;
    const file = files[key], lo = Number(first), hi = Number(last || first);
    if (key === 'sql') {
      const title = file.ranges[lo + '-' + hi];
      const block = file.blocks.find(([start, lines]) => start <= lo && start + lines.length > hi);
      if (!title || !block) return null;
      const [start, lines] = block;
      const end = lo === hi ? Math.min(lo + 17, start + lines.length - 1) : hi;
      return {key, file, lo, hi:end, title, lines:lines.slice(lo-start,end-start+1)};
    }
    const record = file.records[lo];
    return record && lo === hi ? {key,file,lo,hi,record} : null;
  }
  window.CreditSourceTrace = {
    link(anchor, url) {
      const token = match(url);
      if (token && locate(token)) {
        anchor.dataset.creditTrace = token;
        anchor.href = permalink(token,'paired-case');
      }
    }
  };
  function assignDownload(text, type, filename) {
    if (downloadUrl) URL.revokeObjectURL(downloadUrl);
    downloadUrl = URL.createObjectURL(new Blob([text], {type}));
    const link = by('trace-download');
    link.href = downloadUrl;
    link.download = filename;
    link.textContent = type.startsWith('text/csv') ? 'Download header and row (CSV)' : 'Download these SQL lines';
  }
  function renderRecord({file, lo, record}) {
    const values = Object.fromEntries(file.fields.map((field, i) => [field,record.values[i]]));
    by('trace-title').textContent = file.title + ' · ' + values.application_id;
    by('trace-location').textContent = (values.module2_run_id || values.scenario_name) + ' · CSV row ' + lo.toLocaleString('en-US') + ' (header is row 1) · Git ' + commit.slice(0,7);
    const table = part('table');
    table.className = 'trace-record';
    table.append(part('caption','Selected fields as stored'));
    const tbody = part('tbody');
    for (const [field,value] of Object.entries(values)) {
      const tr = part('tr'), th = part('th');
      th.scope = 'row';
      th.append(part('code',field));
      tr.append(th,part('td',value === '' ? 'Empty in source' : value));
      tbody.append(tr);
    }
    table.append(tbody);
    const raw = part('details');
    raw.append(part('summary','Read the complete header and original CSV row'),part('pre',file.header+record.csv));
    content.append(table,raw);
    assignDownload(file.header+record.csv,'text/csv;charset=utf-8',values.application_id+'-'+(values.module2_run_id || values.scenario_name)+'-row-'+lo+'.csv');
  }
  function renderSql({lo,hi,title,lines}) {
    by('trace-title').textContent = title;
    by('trace-location').textContent = 'Module 2 SQL · lines ' + lo.toLocaleString('en-US') + '–' + hi.toLocaleString('en-US') + ' · Git ' + commit.slice(0,7);
    const pre = part('pre');
    pre.className = 'source-code';
    lines.forEach((line,i) => {
      const row = part('span'), number = part('span',String(lo+i));
      row.className = 'trace-line';
      number.setAttribute('aria-label','Line '+(lo+i));
      row.append(number,part('code',line));
      pre.append(row);
    });
    content.append(pre);
    assignDownload(lines.join('\n')+'\n','text/plain;charset=utf-8','module2-lines-'+lo+'-'+hi+'.sql');
  }
  function open(token, url, from) {
    const target = locate(token);
    if (!target) return false;
    invoker = from || invoker;
    content.replaceChildren();
    by('trace-path').textContent = target.file.path;
    by('trace-commit').textContent = commit;
    by('trace-hash').textContent = target.file.sha256;
    by('trace-original').href = target.file.url+'#L'+target.lo+(target.hi > target.lo ? '-L'+target.hi : '');
    by('trace-raw').href = target.file.raw;
    by('trace-permalink').href = url;
    dialog.querySelector('.trace-origin').open = false;
    if (target.key === 'sql') renderSql(target); else renderRecord(target);
    if (!dialog.open) dialog.showModal();
    dialog.scrollTop = 0;
    by('trace-close').focus({preventScroll:true});
    return true;
  }
  by('trace-close').addEventListener('click', () => dialog.close());
  dialog.addEventListener('close', () => {
    const url = new URL(location.href);
    if (url.searchParams.has('trace')) {
      url.searchParams.delete('trace');
      try { history.replaceState(history.state,'',url); } catch (_) { /* A local file may restrict history changes. */ }
    }
    if (invoker && invoker.isConnected) invoker.focus({preventScroll:true});
    invoker = undefined;
  });
  document.addEventListener('click', event => {
    const anchor = event.target.closest('a[data-credit-trace]');
    if (!anchor || event.button !== 0 || event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return;
    if (open(anchor.dataset.creditTrace,anchor.href,anchor)) event.preventDefault();
  });
  const fullSql = document.querySelector('a[data-full-sql]');
  if (fullSql) fullSql.addEventListener('click', async event => {
    if (event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return;
    event.preventDefault();
    const status = fullSql.parentElement.querySelector('[aria-live]');
    if (fullSql.getAttribute('aria-busy') === 'true') return;
    fullSql.setAttribute('aria-busy','true');
    status.textContent = 'Preparing the SQL download…';
    try {
      const response = await fetch(fullSql.href);
      if (!response.ok) throw new Error('Source unavailable');
      const blob = await response.blob(), url = URL.createObjectURL(blob);
      const link = part('a');
      link.href = url;
      link.download = files.sql.path.split('/').pop();
      document.body.append(link);
      link.click();
      link.remove();
      setTimeout(() => URL.revokeObjectURL(url),60000);
      status.textContent = 'Download started.';
    } catch (_) {
      const raw = part('a','Open the complete raw SQL in GitHub');
      raw.href = fullSql.href;
      status.replaceChildren('The download needs a connection to GitHub. ',raw);
    } finally {
      fullSql.removeAttribute('aria-busy');
    }
  });
  function fromLocation() {
    const token = new URL(location.href).searchParams.get('trace');
    if (token) open(token,location.href,null);
    else if (dialog.open) dialog.close();
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded',fromLocation);
  else fromLocation();
  window.addEventListener('popstate',fromLocation);
})();
