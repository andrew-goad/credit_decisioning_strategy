(() => {
  const form = document.querySelector('.parameter-finder');
  if (!form) return;
  const search = document.getElementById('find-parameter');
  const results = document.getElementById('parameter-matches');
  const status = document.getElementById('parameter-status');
  const clean = text => text.toLowerCase().replace(/[^a-z0-9]+/g, ' ').trim();
  const entries = [];
  const seen = new Set();
  for (const node of document.querySelectorAll('.parameter-module [data-parameter]')) {
    const module = node.closest('.parameter-module').id === 'm1-settings' ? 1 : 2;
    const key = node.dataset.parameter;
    const keyId = 'param-m' + module + '-' + key;
    if (seen.has(keyId)) continue;
    seen.add(keyId);
    if (!node.id) node.id = keyId;
    const row = node.closest('tr,li,dl') || node;
    entries.push({name:key, module, id:node.id, label:clean(key), text:clean(row.textContent)});
  }
  if (!entries.length) return;
  form.hidden = false;
  search.addEventListener('input', () => {
    const query = clean(search.value);
    results.replaceChildren();
    status.textContent = '';
    if (!query) return;
    const tokens = query.split(' ');
    const matches = [];
    for (const entry of entries) {
      const words = entry.label + ' ' + entry.text;
      if (tokens.every(token => words.includes(token))) {
        const rank = entry.label === query ? 0 : entry.label.includes(query) ? 1 : tokens.every(token=>entry.label.includes(token)) ? 2 : 3;
        matches.push({entry, rank});
      }
    }
    matches.sort((a,b)=>a.rank-b.rank);
    const limit = 10;
    status.textContent = matches.length === 0 ? 'No matching settings. Try a shorter term.' :
      matches.length > limit ? 'Showing '+limit+' of '+matches.length+' matching settings. Type more to narrow the list.' :
      matches.length+' matching setting'+(matches.length === 1 ? '.' : 's.');
    for (const {entry} of matches.slice(0,limit)) {
      const item = document.createElement('li');
      const link = document.createElement('a');
      const key = document.createElement('code');
      const group = document.createElement('span');
      key.textContent = entry.name;
      group.textContent = 'Module ' + entry.module;
      link.href = '#' + entry.id;
      link.append(key, group);
      item.append(link);
      results.append(item);
    }
  });
})();
