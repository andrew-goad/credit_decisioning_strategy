(() => {
  const panel = document.getElementById('offer-flow');
  const select = document.getElementById('pf-choice');
  if (!panel || !select) return;
  const data = JSON.parse(document.getElementById('offer-flow-data').textContent);
  const integer = new Intl.NumberFormat('en-US');
  const percent = new Intl.NumberFormat('en-US', {style:'percent', maximumFractionDigits:3});
  const labels = [
    'Gained an offer under the challenger',
    'Lost an offer under the challenger',
    'Both policies made a counteroffer for different amounts',
    'The challenger made a smaller offer through its standard counteroffer rules',
    'A challenger override opened a counteroffer test that ended in manual review',
    'Same outcome, different primary reason',
    'Both policies approved the full requested amount'
  ];
  function render() {
    const group = data.groups[select.value];
    panel.hidden = !group;
    if (!group) return;
    const {counts, denominator} = group;
    const gain = counts[1], loss = counts[2], delta = gain - loss;
    const sign = delta < 0 ? '−' : delta > 0 ? '+' : '';
    const signed = sign + integer.format(Math.abs(delta));
    const ending = Math.abs(delta) === 1 ? ' net offer.' : ' net offers.';
    document.getElementById('offer-flow-equation').textContent =
      integer.format(gain) + ' gained − ' + integer.format(loss) + ' lost = ' + signed + ending;
    document.getElementById('offer-flow-denominator').textContent =
      'Each share uses all ' + integer.format(denominator) + ' matched applicants. An applicant can appear in more than one row.';
    const body = document.getElementById('offer-flow-patterns');
    body.replaceChildren();
    labels.forEach((label, index) => {
      const tr = document.createElement('tr');
      const th = document.createElement('th');
      th.scope = 'row';
      th.textContent = label;
      tr.appendChild(th);
      [integer.format(counts[index + 1]),percent.format(counts[index + 1] / denominator)].forEach(value => {
        const td = document.createElement('td');
        td.textContent = value;
        tr.appendChild(td);
      });
      body.appendChild(tr);
    });
  }
  panel.querySelector('details').addEventListener('toggle', function () {
    const link = document.getElementById('offer-flow-source');
    if (!this.open || !link.hidden) return;
    const raw = document.getElementById('archived-case-data');
    const source = raw && JSON.parse(raw.textContent).returnedSource;
    if (source?.href) {
      link.href = source.href;
      link.download = source.filename;
      link.hidden = false;
    }
  });
  select.addEventListener('change',render);
  window.addEventListener('hashchange',render);
  window.addEventListener('popstate',render);
  render();
})();
