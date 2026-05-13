% rebase('layout', title='NuiTV — Entdecken', body_class='min-h-screen bg-nui-bg overflow-hidden flex flex-col')

<header class="w-full flex items-center justify-between px-4 py-4 shadow bg-gradient-to-r from-nui-bg via-nui-dark to-nui-bg shrink-0 gap-3">
  <a href="/"><img src="/static/nuitv-logo.svg" alt="Logo" class="h-10 m-2"></a>
  <form method="GET" action="/" class="relative flex-1 max-w-md">
    <input
      name="q"
      type="text"
      value=""
      placeholder="Suchen..."
      class="w-full rounded-full px-5 py-2 text-white bg-nui-card border border-nui-border outline-none focus:ring-2 focus:ring-nui-border placeholder:text-nui-light"
      autocomplete="off"
    >
  </form>
  <a href="/likes" class="shrink-0 px-3 py-2 rounded-full bg-nui-card border border-nui-border text-nui-subtle text-sm flex items-center gap-2">
    <span>Likes</span>
    <span id="likes-count" class="min-w-5 h-5 rounded-full bg-nui-dark text-xs text-nui-light flex items-center justify-center px-1">0</span>
  </a>
</header>

<div class="flex-1 flex flex-col items-center justify-center px-4 gap-6">
  <div id="stack" class="relative w-full max-w-sm" style="height: 65vh;"></div>

  <div id="empty" class="hidden flex-col items-center gap-4 py-8">
    <p class="text-nui-light text-center">Keine weiteren Titel.</p>
    <button id="btn-reload" class="px-6 py-2 rounded-full bg-nui-dark text-nui-subtle">Neu laden</button>
  </div>

  <div id="actions" class="flex justify-center gap-16 shrink-0">
    <button id="btn-dislike" class="w-16 h-16 rounded-full bg-nui-card border border-nui-red flex items-center justify-center text-2xl text-nui-red active:opacity-70">✕</button>
    <button id="btn-like" class="w-16 h-16 rounded-full bg-nui-card border border-nui-green flex items-center justify-center text-2xl text-nui-green active:opacity-70">♥</button>
  </div>
</div>

<div id="like-toast" class="fixed bottom-24 left-1/2 -translate-x-1/2 px-4 py-2 rounded-full bg-nui-dark border border-nui-green text-nui-green text-sm opacity-0 pointer-events-none transition-opacity duration-200">
  Zu Likes hinzugefügt ♥
</div>

<script id="initial-movies" type="application/json">{{!initial_movies_json}}</script>
<script src="/static/likes.js"></script>
<script>
  const THRESHOLD = 90;
  const STACK_SIZE = 3;

  const initialMoviesNode = document.getElementById('initial-movies');
  let queue = JSON.parse(initialMoviesNode?.textContent || '[]');
  let topCard = null;
  let startX = 0, deltaX = 0, dragging = false;

  function updateLikesCount() {
    const badge = document.getElementById('likes-count');
    if (badge) badge.textContent = String(window.NuiLikes.getCount());
  }

  function showLikeToast() {
    const toast = document.getElementById('like-toast');
    if (!toast) return;
    toast.style.opacity = '1';
    setTimeout(() => {
      toast.style.opacity = '0';
    }, 800);
  }

  function cardHTML(movie) {
    const kind = movie.kind === 'movie' ? 'Film' : 'Serie';
    const stars = movie.vote_average ? `<span class="text-xs text-nui-yellow">★ ${movie.vote_average}</span>` : '';
    const desc = movie.text ? `<p class="text-sm text-nui-muted leading-relaxed" style="-webkit-line-clamp:6;display:-webkit-box;-webkit-box-orient:vertical;overflow:hidden">${movie.text}</p>` : '';
    const year = movie.year ? `<p class="text-sm text-nui-muted mt-1">${movie.year}</p>` : '';

    return `
      <div class="absolute inset-0 flex flex-col">
        <div class="flex items-center justify-between p-4 shrink-0">
          <span class="text-xs px-2 py-1 rounded-full bg-nui-dark text-nui-subtle">${kind}</span>
          ${stars}
        </div>
        <div class="flex-1 px-4 overflow-hidden">${desc}</div>
        <div class="px-4 pb-4 pt-8" style="background:linear-gradient(to top,var(--color-nui-bg) 60%,transparent)">
          <h2 class="text-xl font-semibold text-white leading-tight">${movie.name}</h2>
          ${year}
        </div>
      </div>
      <div class="abstract-ol absolute inset-0 rounded-2xl opacity-0 pointer-events-none p-6 overflow-hidden" style="background:rgba(18,18,28,0.96);transition:opacity 0.2s ease">
        <p class="text-sm text-nui-light leading-relaxed" style="-webkit-line-clamp:14;display:-webkit-box;-webkit-box-orient:vertical;overflow:hidden">${movie.text}</p>
      </div>
      <div class="like-ol absolute inset-0 rounded-2xl border-4 border-nui-green opacity-0 pointer-events-none flex items-start justify-end p-4">
        <span class="font-semibold text-nui-green text-lg tracking-widest" style="transform:rotate(-15deg)">LIKE</span>
      </div>
      <div class="dislike-ol absolute inset-0 rounded-2xl border-4 border-nui-red opacity-0 pointer-events-none flex items-start justify-start p-4">
        <span class="font-semibold text-nui-red text-lg tracking-widest" style="transform:rotate(15deg)">NOPE</span>
      </div>
    `;
  }

  function makeCard(movie, pos) {
    const el = document.createElement('div');
    el.className = 'absolute inset-0 rounded-2xl overflow-hidden bg-nui-card border border-nui-border select-none cursor-grab';
    el.innerHTML = cardHTML(movie);
    setStackPos(el, pos);
    return el;
  }

  function setStackPos(el, pos, animate = false) {
    el.style.transition = animate ? 'transform 0.3s ease' : 'none';
    if (pos === 0) { el.style.transform = 'translateY(0) scale(1)'; el.style.zIndex = 3; }
    if (pos === 1) { el.style.transform = 'translateY(10px) scale(0.95)'; el.style.zIndex = 2; }
    if (pos === 2) { el.style.transform = 'translateY(20px) scale(0.90)'; el.style.zIndex = 1; }
  }

  function renderStack() {
    const stack = document.getElementById('stack');
    const empty = document.getElementById('empty');
    const actions = document.getElementById('actions');
    stack.innerHTML = '';

    empty.classList.add('hidden');
    empty.classList.remove('flex');
    actions.classList.remove('hidden');

    if (queue.length === 0) {
      empty.classList.remove('hidden');
      empty.classList.add('flex');
      actions.classList.add('hidden');
      return;
    }

    const count = Math.min(STACK_SIZE, queue.length);
    for (let i = count - 1; i >= 0; i--) {
      stack.appendChild(makeCard(queue[i], i));
    }

    topCard = stack.lastElementChild;
    attachDrag(topCard);

    if (queue.length < 5) loadMore();
  }

  function advanceStack() {
    queue.shift();
    const stack = document.getElementById('stack');
    const cards = [...stack.children];
    cards.forEach((card, domIndex) => {
      const currentPos = (cards.length - 1) - domIndex;
      if (currentPos > 0) setStackPos(card, currentPos - 1, true);
    });
    setTimeout(renderStack, 320);
  }

  function attachDrag(card) {
    card.addEventListener('pointerdown', onDown);
  }

  function onDown(e) {
    dragging = true;
    startX = e.clientX;
    deltaX = 0;
    topCard.style.transition = 'none';
    topCard.style.cursor = 'grabbing';
    topCard.setPointerCapture(e.pointerId);
    topCard.addEventListener('pointermove', onMove);
    topCard.addEventListener('pointerup', onUp);
    topCard.addEventListener('pointercancel', onUp);
  }

  function onMove(e) {
    if (!dragging) return;
    deltaX = e.clientX - startX;
    const rot = deltaX * 0.07;
    topCard.style.transform = `translateX(${deltaX}px) rotate(${rot}deg)`;

    const t = Math.min(Math.abs(deltaX) / THRESHOLD, 1);
    topCard.querySelector('.like-ol').style.opacity = deltaX > 0 ? t : 0;
    topCard.querySelector('.dislike-ol').style.opacity = deltaX < 0 ? t : 0;
  }

  function onUp() {
    if (!dragging) return;
    dragging = false;
    topCard.style.cursor = 'grab';
    topCard.removeEventListener('pointermove', onMove);
    topCard.removeEventListener('pointerup', onUp);
    topCard.removeEventListener('pointercancel', onUp);

    if (Math.abs(deltaX) < 8) {
      toggleAbstract(topCard);
    } else if (Math.abs(deltaX) >= THRESHOLD) {
      commitSwipe(deltaX > 0 ? 1 : -1);
    } else {
      snapBack();
    }
  }

  function toggleAbstract(card) {
    const ol = card.querySelector('.abstract-ol');
    const open = ol.style.opacity === '1';
    ol.style.opacity = open ? '0' : '1';
  }

  function commitSwipe(dir) {
    const currentMovie = queue[0];
    if (dir === 1 && currentMovie) {
      window.NuiLikes.setLiked(currentMovie, { source: 'swipe' });
      updateLikesCount();
      showLikeToast();
    }

    const flyX = dir * window.innerWidth * 1.5;
    topCard.style.transition = 'transform 0.35s ease';
    topCard.style.transform = `translateX(${flyX}px) rotate(${dir * 25}deg)`;
    advanceStack();
  }

  function snapBack() {
    topCard.style.transition = 'transform 0.3s ease';
    topCard.style.transform = 'translateX(0) rotate(0deg)';
    topCard.querySelector('.like-ol').style.opacity = 0;
    topCard.querySelector('.dislike-ol').style.opacity = 0;
  }

  document.getElementById('btn-dislike').addEventListener('click', () => { if (topCard) commitSwipe(-1); });
  document.getElementById('btn-like').addEventListener('click', () => { if (topCard) commitSwipe(1); });
  document.getElementById('btn-reload').addEventListener('click', async () => {
    const loaded = await loadMore();
    if (loaded) renderStack();
  });

  async function loadMore() {
    try {
      const response = await fetch('/api/random');
      if (!response.ok) return false;
      const data = await response.json();
      queue.push(...data);
      return true;
    } catch {
      return false;
    }
  }

  updateLikesCount();
  renderStack();
</script>
