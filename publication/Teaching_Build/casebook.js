(() => {
  'use strict';
  const links=document.querySelectorAll('#j-choices [data-worked-id]');
  function mark(group,id) {
    for(const link of links) {
      if(link.dataset.workedGroup===group && link.dataset.workedId===id) link.setAttribute('aria-current','true');
      else link.removeAttribute('aria-current');
    }
  }
  window.addEventListener('credit:selection',event=>mark(event.detail.group,event.detail.id));
  mark(document.getElementById('pf-choice').value,document.getElementById('pair-search-id').value);
})();
