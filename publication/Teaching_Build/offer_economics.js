/* Compare policy offers with the full request on the same simulated borrower. */
(() => {
  const money = new Intl.NumberFormat('en-US', {
    style: 'currency', currency: 'USD', minimumFractionDigits: 2, maximumFractionDigits: 2
  });
  const percent = new Intl.NumberFormat('en-US', {
    style: 'percent', maximumFractionDigits: 2
  });
  const riskPercent = new Intl.NumberFormat('en-US', {style: 'percent', maximumFractionDigits: 4});
  const element = (tag, text) => {
    const node = document.createElement(tag);
    if (text !== undefined) node.textContent = text;
    return node;
  };
  const nonnegative = value => typeof value === 'number' && Number.isFinite(value) && value >= 0;
  const outcomes = {
    APPROVE: 'approved', COUNTEROFFER: 'counteroffer',
    MANUAL_REVIEW: 'manual review', DECLINE: 'declined'
  };
  function row(name, exposure, expectedLoss) {
    const tr = element('tr');
    const label = element('th', name);
    label.scope = 'row';
    tr.append(label, element('td', exposure), element('td', expectedLoss));
    return tr;
  }
  function recordedCandidateFailed(side) {
    return [side.primary, side.path].some(value =>
      typeof value === 'string' && /FAILED_COUNTEROFFER|COUNTEROFFER_(?:NOT_FEASIBLE|FAILED)/.test(value)
    );
  }
  let runs, settings;
  function policyProducts(comparison, product) {
    if (!runs || !settings) {
      const groupData = document.getElementById?.('offer-flow-data');
      const policyData = document.getElementById?.('archived-case-settings');
      if (!groupData || !policyData) return [];
      runs = JSON.parse(groupData.textContent).groups;
      settings = JSON.parse(policyData.textContent);
    }
    const group = runs[comparison];
    return group ? [group.baseline, group.challenger].map(run => settings[run]?.products[product]) : [];
  }
  function constraint(c, side, product, isOffer) {
    if (!product || !nonnegative(c.pti)) return '';
    const lossRate = c.pd * c.lgd;
    const amount = Math.min(c.request, product.product_max_approved_amount);
    const payment = c.pti > 0 ? c.request * product.counteroffer_target_pti / c.pti : c.request;
    const loss = lossRate > 0 ? product.product_approved_el_cap / lossRate : c.request;
    const ceiling = Math.min(amount, payment, loss);
    if (!Number.isFinite(ceiling)) return '';
    if (!isOffer) {
      const step = product.approved_amount_rounding_increment;
      const minimum = Math.max(product.product_min_approved_amount,
        c.request * product.product_min_counteroffer_pct, c.request * (1 - product.product_max_exposure_reduction_pct));
      const rounded = Math.floor(ceiling / step) * step;
      return Number.isFinite(rounded) && rounded < minimum ?
        ' Its rounded candidate of ' + money.format(rounded) + ' fell below the minimum viable offer of ' + money.format(minimum) + '.' : '';
    }
    if (ceiling === loss && c.requestEL > product.product_approved_el_cap && side.approvedEL <= product.product_approved_el_cap)
      return ' The full request exceeded the ' + money.format(product.product_approved_el_cap) +
        ' loss cap. The smaller offer stayed within it.';
    if (ceiling === amount && c.request > amount && side.approved <= amount)
      return ' The original request exceeded the ' + money.format(amount) + ' product limit. The counteroffer fit within it.';
    if (ceiling === payment && c.pti > product.counteroffer_target_pti)
      return ' The original payment used ' + percent.format(c.pti) + ' of monthly income, above the ' +
        percent.format(product.counteroffer_target_pti) + ' counteroffer target.';
    return '';
  }
  window.renderOfferEconomics = function (container, comparisonKey, caseId, c) {
    container.replaceChildren();
    if (!c || c.id !== caseId || typeof comparisonKey !== 'string' || !c.base || !c.challenge ||
        !nonnegative(c.request) || c.request === 0 || !nonnegative(c.requestEL) ||
        !nonnegative(c.pd) || c.pd > 1 || !nonnegative(c.lgd) || c.lgd > 1) return false;
    const [baseProduct, challengerProduct] = policyProducts(comparisonKey, c.product);
    let sides = [['Baseline', c.base, baseProduct], ['Challenger', c.challenge, challengerProduct]];
    const qualifying = side => side.outcome === 'COUNTEROFFER' &&
      nonnegative(side.approved) && side.approved > 0 && side.approved < c.request &&
      nonnegative(side.approvedEL);
    if (!sides.some(([,side]) => qualifying(side) || recordedCandidateFailed(side))) return false;
    const identical = c.base.outcome === c.challenge.outcome &&
      c.base.approved === c.challenge.approved && c.base.approvedEL === c.challenge.approvedEL;
    if (identical && (baseProduct === challengerProduct || JSON.stringify(baseProduct) === JSON.stringify(challengerProduct))) sides = [['Both policies', c.base, baseProduct]];

    const selected = qualifying(c.challenge) ? c.challenge : qualifying(c.base) ? c.base : null;
    const policyName = selected === c.challenge ? 'challenger' : 'baseline';
    const takeaway = selected
      ? 'The ' + policyName + ' counteroffer keeps ' + money.format(selected.approved) + ' of credit available (' +
        percent.format(selected.approved / c.request) + ' of the request), with ' +
        money.format((c.request - selected.approved) * c.pd * c.lgd) + ' less modeled loss than offering the full amount.'
      : 'The smaller structures tested here failed policy checks. Their projected amounts never became offers.';
    container.append(element('p', takeaway));
    const details = element('details');
    details.className = 'offer-economics';
    details.append(element('summary', 'What does the smaller offer do for the portfolio?'));
    const intro = element('p', 'Compare the full amount requested with the offers the policies actually produced. The full request is a benchmark, even when a policy would reject it.');
    const table = element('table');
    table.append(element('caption', 'Exposure and expected credit loss for this application'));
    const head = element('thead'), header = element('tr');
    for (const name of ['Decision or benchmark', 'Credit offered', 'Modeled credit loss']) {
      const th = element('th', name);
      th.scope = 'col';
      header.append(th);
    }
    head.append(header);
    const body = element('tbody');
    body.append(row('Full request · benchmark', money.format(c.request), money.format(c.requestEL)));
    const explanations = [];
    for (const [policy, side, product] of sides) {
      const displayed = n => nonnegative(n) ? money.format(n) :
        side.outcome === 'MANUAL_REVIEW' ? 'Pending review' : 'Unreported';
      body.append(row(policy + ' · ' + outcomes[side.outcome], displayed(side.approved), displayed(side.approvedEL)));
      if (qualifying(side)) {
        const removed = c.request - side.approved;
        explanations.push(policy + ' retained ' + percent.format(side.approved / c.request) +
          ' of the requested credit. Offering ' + money.format(removed) + ' less reduced modeled loss by ' +
          money.format(removed * c.pd * c.lgd) + ' versus the full request.' + constraint(c, side, product, true));
      } else if (recordedCandidateFailed(side)) {
        explanations.push(policy + ' tested a smaller amount and recorded a failed counteroffer. ' +
          (side.outcome === 'MANUAL_REVIEW' ? 'The review has no final offer amount.' : 'The proposed amount did not become an offer.') + constraint(c, side, product, false));
      }
    }
    if (!sides.some(([,side]) => side.outcome === 'DECLINE')) {
      body.append(row('No offer · benchmark', money.format(0), money.format(0)));
    }
    table.append(head, body);
    const wrap = element('div');
    wrap.className = 'case-scroll';
    wrap.append(table);
    details.append(intro, wrap);
    for (const text of explanations) details.append(element('p', text));
    const lossPerHundred = '$100 × ' + riskPercent.format(c.pd) + ' default probability × ' +
      riskPercent.format(c.lgd) + ' loss severity = ' + money.format(100 * c.pd * c.lgd) + ' of modeled loss.';
    const access = sides.some(([,side]) => qualifying(side))
      ? 'A smaller offer preserves some borrowing capacity and leaves less exposure for the lender to earn revenue on. The modeled loss per dollar stays the same.'
      : 'Neither policy made a smaller offer here. Lower dollar loss alone cannot make a proposal feasible.';
    details.append(element('p', lossPerHundred + ' ' + access));
    details.append(element('p', 'To rank these options by profit, a lender would also need customer take-up, revenue, funding costs and repayment experience.'));
    container.append(details);
    return true;
  };
})();
