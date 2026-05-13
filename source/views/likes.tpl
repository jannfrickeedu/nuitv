% rebase('layout', title='NuiTV — Meine Likes', body_class='min-h-screen bg-nui-bg text-white')

<header class="w-full flex items-center justify-between px-6 py-4 shadow bg-gradient-to-r from-nui-bg via-nui-dark to-nui-bg">
  <a href="javascript:history.back()" class="text-nui-light text-2xl mr-4">&#8592;</a>
  <a href="/"><img src="/static/nuitv-logo.svg" alt="Logo" class="h-10 m-2"></a>
  <a href="/swipe" class="px-4 py-2 rounded-full bg-nui-card border border-nui-border text-nui-subtle text-sm">Entdecken</a>
</header>

<main class="px-4 py-4 max-w-lg mx-auto">
  <div class="flex items-center justify-between mb-3">
    <h1 class="text-xl">Meine Likes</h1>
    <span id="likes-total" class="text-sm text-nui-muted">0</span>
  </div>

  <div id="empty" class="hidden rounded-xl p-4 bg-nui-card border border-nui-border text-nui-light text-sm">
    Noch keine Likes. Wische nach rechts oder merke Titel im Detail.
  </div>

  <div id="likes-list" class="space-y-2"></div>
</main>

<script src="/static/likes.js"></script>
<script>
  function escapeHtml(value) {
    return String(value ?? '')
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;');
  }

  async function fetchMoviesByIds(ids) {
    if (!ids.length) return [];
    try {
      const response = await fetch('/api/movies/by-ids', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ ids })
      });
      if (!response.ok) return [];
      return await response.json();
    } catch {
      return [];
    }
  }

  function card(movie) {
    const kind = movie.kind === 'movie' ? 'Film' : 'Serie';
    const year = movie.year ? String(movie.year) : '';
    const rating = movie.vote_average ? ` · ★ ${movie.vote_average}` : '';
    const desc = movie.text ? `<p class="text-sm mt-1 text-nui-subtle">${escapeHtml(movie.text)}</p>` : '';

    return `
      <div class="rounded-xl p-4 bg-nui-card border border-nui-border">
        <div class="flex items-start justify-between gap-3">
          <a href="/movie/${movie.id}" class="flex-1 min-w-0">
            <div class="flex items-center justify-between gap-3">
              <span class="font-semibold text-white truncate">${escapeHtml(movie.name || 'Unbekannt')}</span>
              <span class="text-xs px-2 py-0.5 rounded-full bg-nui-dark text-nui-subtle shrink-0">${kind}</span>
            </div>
            <span class="text-sm text-nui-muted">${escapeHtml(year)}${escapeHtml(rating)}</span>
            ${desc}
          </a>
          <button data-remove-id="${movie.id}" class="px-3 py-1.5 rounded-full border border-nui-border text-nui-muted text-xs active:opacity-70">Entfernen</button>
        </div>
      </div>
    `;
  }

  async function render() {
    const ids = window.NuiLikes.getIds();
    const state = window.NuiLikes.readState();

    const list = document.getElementById('likes-list');
    const empty = document.getElementById('empty');
    const total = document.getElementById('likes-total');

    total.textContent = `${ids.length} Titel`;

    if (ids.length === 0) {
      list.innerHTML = '';
      empty.classList.remove('hidden');
      return;
    }

    empty.classList.add('hidden');

    const apiMovies = await fetchMoviesByIds(ids);
    const byId = Object.fromEntries(apiMovies.map((m) => [String(m.id), m]));
    const merged = ids.map((id) => byId[String(id)] || state.items[String(id)] || { id });

    list.innerHTML = merged.map(card).join('');

    list.querySelectorAll('[data-remove-id]').forEach((btn) => {
      btn.addEventListener('click', () => {
        window.NuiLikes.remove(btn.dataset.removeId);
        render();
      });
    });
  }

  render();
</script>
