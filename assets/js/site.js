(() => {
  'use strict';
  const normalize = value => String(value || '').normalize('NFKC').toLocaleLowerCase().trim();
  const matches = (text, query) => normalize(query).split(/\s+/).filter(Boolean).every(word => normalize(text).includes(word));

  document.querySelectorAll('[data-filter-section]').forEach(section => {
    const buttons = [...section.querySelectorAll('[data-filter]')];
    const cards = [...section.querySelectorAll('[data-category]')];
    buttons.forEach(button => button.addEventListener('click', () => {
      const category = button.dataset.filter;
      buttons.forEach(item => {
        const active = item === button;
        item.classList.toggle('is-active', active);
        item.setAttribute('aria-pressed', String(active));
      });
      let count = 0;
      cards.forEach(card => {
        card.hidden = category !== 'all' && card.dataset.category !== category;
        if (!card.hidden) count++;
      });
      section.querySelector('[data-filter-count]').textContent = `${count} 篇文章`;
      section.querySelector('[data-filter-empty]').hidden = count > 0;
    }));
  });

  const archive = document.querySelector('[data-archive]');
  if (archive) {
    const input = archive.querySelector('input');
    const rows = [...archive.querySelectorAll('[data-archive-row]')];
    const filterArchive = () => {
      let count = 0;
      rows.forEach(row => {
        row.hidden = !matches(row.dataset.searchText, input.value);
        if (!row.hidden) count++;
      });
      archive.querySelectorAll('[data-archive-year]').forEach(year => {
        year.hidden = ![...year.querySelectorAll('[data-archive-row]')].some(row => !row.hidden);
      });
      archive.querySelector('[data-archive-count]').textContent = `${count} 篇文章`;
      archive.querySelector('[data-archive-empty]').hidden = count > 0;
    };
    input.value = new URLSearchParams(window.location.search).get('q') || '';
    input.addEventListener('input', filterArchive);
    filterArchive();
  }

  function markCategory() {
    document.querySelectorAll('[data-nav-category]').forEach(link => {
      const target = new URL(link.href);
      const active = window.location.pathname === target.pathname && window.location.hash === target.hash;
      link.classList.toggle('active', active);
      if (active) link.setAttribute('aria-current', 'location');
      else link.removeAttribute('aria-current');
    });
  }
  window.addEventListener('hashchange', markCategory);
  markCategory();

  const dialog = document.querySelector('[data-search-dialog]');
  if (dialog && typeof dialog.showModal === 'function') {
    const input = dialog.querySelector('input');
    const results = dialog.querySelector('[data-search-results]');
    const status = dialog.querySelector('[data-search-status]');
    let index = null;
    let request = null;
    let opener;
    let searchTimer;

    async function loadIndex() {
      if (index) return index;
      if (!request) request = fetch(dialog.dataset.index).then(response => {
        if (!response.ok) throw new Error('Search index unavailable');
        return response.json();
      }).then(data => { index = data; return data; }).catch(error => { request = null; throw error; });
      return request;
    }
    function render() {
      results.replaceChildren();
      const query = normalize(input.value);
      if (!query) { status.textContent = '输入标题、关键词或分类，开始探索。'; return; }
      const found = index.filter(post => matches(`${post.title} ${post.summary} ${post.category} ${(post.tags || []).join(' ')}`, query));
      status.textContent = found.length ? `找到 ${found.length} 篇相关文章${found.length > 30 ? '，显示前 30 篇' : ''}` : '没有找到相关文章，试试更短的关键词。';
      found.slice(0, 30).forEach(post => {
        const link = document.createElement('a');
        link.className = 'search-result';
        link.href = post.url;
        const meta = document.createElement('span');
        meta.textContent = `${post.category} / ${post.date}`;
        const title = document.createElement('h3');
        title.textContent = post.title;
        const summary = document.createElement('p');
        summary.textContent = post.summary;
        link.append(meta, title, summary);
        results.append(link);
      });
    }
    async function search() {
      if (!normalize(input.value)) { results.replaceChildren(); status.textContent = '输入标题、关键词或分类，开始探索。'; return; }
      if (!index) status.textContent = '正在载入文章索引……';
      try { await loadIndex(); render(); }
      catch { status.textContent = '文章索引暂时无法载入，请稍后重试，或前往文章归档。'; }
    }
    function openSearch(source) {
      if (dialog.open) return;
      opener = source || document.activeElement;
      dialog.showModal();
      input.focus();
      if (input.value) search();
    }
    document.querySelectorAll('[data-search-open]').forEach(button => button.addEventListener('click', () => openSearch(button)));
    dialog.querySelector('[data-search-close]').addEventListener('click', () => dialog.close());
    dialog.addEventListener('keydown', event => {
      if (event.key === 'Escape') {
        event.preventDefault();
        dialog.close();
      }
    });
    dialog.addEventListener('click', event => {
      if (event.target !== dialog) return;
      const rect = dialog.getBoundingClientRect();
      if (event.clientX < rect.left || event.clientX > rect.right || event.clientY < rect.top || event.clientY > rect.bottom) dialog.close();
    });
    dialog.addEventListener('close', () => { if (opener && opener.isConnected) opener.focus(); });
    input.addEventListener('input', () => { window.clearTimeout(searchTimer); searchTimer = window.setTimeout(search, 100); });
    document.addEventListener('keydown', event => {
      const element = document.activeElement;
      const typing = element && (element.matches('input, textarea, select') || element.isContentEditable);
      if (event.key === '/' && !typing && !event.ctrlKey && !event.metaKey && !event.altKey) { event.preventDefault(); openSearch(); }
    });
  }

  document.querySelectorAll('[data-share]').forEach(button => {
    let resetTimer;
    button.addEventListener('click', async () => {
      window.clearTimeout(resetTimer);
      try {
        await navigator.clipboard.writeText(window.location.href);
        button.textContent = '链接已复制 ✓';
      } catch {
        button.textContent = '请从地址栏复制链接';
      }
      resetTimer = window.setTimeout(() => { button.textContent = '复制链接 ↗'; }, 3000);
    });
  });
})();
