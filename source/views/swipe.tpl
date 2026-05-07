<!doctype html>
<html lang="de">

<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>NuiTV — Entdecken</title>
  <link rel="stylesheet" href="/static/dist/style.css">
</head>

<!-- initial_movies: JSON array of movie objects, rendered server-side to avoid a loading flash -->
<body class="min-h-screen bg-nui-bg overflow-hidden flex flex-col">

  <header class="flex items-center justify-between px-6 py-4 shrink-0">
    <a href="/"><img src="/static/nuitv-logo.svg" alt="Logo" class="h-8"></a>
  </header>

  <!-- Card stack; cards are absolutely positioned inside and injected by JS -->
  <div class="flex-1 flex flex-col items-center justify-center px-4 gap-6">
    <div id="stack" class="relative w-full max-w-sm" style="height: 65vh;"></div>

    <!-- Empty state, shown when queue is exhausted -->
    <div id="empty" class="hidden flex-col items-center gap-4 py-8">
      <p class="text-nui-light text-center">Keine weiteren Titel.</p>
      <button id="btn-reload" class="px-6 py-2 rounded-full bg-nui-dark text-nui-subtle">Neu laden</button>
    </div>

    <!-- Like / dislike buttons -->
    <div id="actions" class="flex justify-center gap-16 shrink-0">
      <button id="btn-dislike" class="w-16 h-16 rounded-full bg-nui-card border border-nui-red flex items-center justify-center text-2xl text-nui-red active:opacity-70">✕</button>
      <button id="btn-like"    class="w-16 h-16 rounded-full bg-nui-card border border-nui-green flex items-center justify-center text-2xl text-nui-green active:opacity-70">♥</button>
    </div>
  </div>

  <script>
    const THRESHOLD = 90;   // px to commit a swipe
    const STACK_SIZE = 3;   // how many cards to keep in DOM

    let queue = {{!initial_movies}};
    let topCard = null;
    let startX = 0, deltaX = 0, dragging = false;

    // --- card creation ---

    function cardHTML(movie) {
      const kind  = movie.kind === 'movie' ? 'Film' : 'Serie';
      const stars = movie.vote_average ? `<span class="text-xs text-nui-yellow">★ ${movie.vote_average}</span>` : '';
      const desc  = movie.text ? `<p class="text-sm text-nui-muted leading-relaxed" style="-webkit-line-clamp:6;display:-webkit-box;-webkit-box-orient:vertical;overflow:hidden">${movie.text}</p>` : '';
      const year  = movie.year  ? `<p class="text-sm text-nui-muted mt-1">${movie.year}</p>` : '';

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
        <div class="like-ol    absolute inset-0 rounded-2xl border-4 border-nui-green opacity-0 pointer-events-none flex items-start justify-end p-4">
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

    // pos 0 = top (interactive), 1 = middle, 2 = bottom
    function setStackPos(el, pos, animate = false) {
      if (animate) el.style.transition = 'transform 0.3s ease';
      else         el.style.transition = 'none';

      if (pos === 0) { el.style.transform = 'translateY(0) scale(1)';     el.style.zIndex = 3; }
      if (pos === 1) { el.style.transform = 'translateY(10px) scale(0.95)'; el.style.zIndex = 2; }
      if (pos === 2) { el.style.transform = 'translateY(20px) scale(0.90)'; el.style.zIndex = 1; }
    }

    // --- stack management ---

    function renderStack() {
      const stack = document.getElementById('stack');
      stack.innerHTML = '';

      if (queue.length === 0) {
        document.getElementById('empty').classList.remove('hidden');
        document.getElementById('empty').classList.add('flex');
        document.getElementById('actions').classList.add('hidden');
        return;
      }

      // Append bottom cards first so top card is last in DOM (natural stacking)
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
      // Animate remaining cards into their new positions before re-rendering
      const stack = document.getElementById('stack');
      const cards = [...stack.children]; // [pos2, pos1, pos0]
      cards.forEach((card, domIndex) => {
        const currentPos = (cards.length - 1) - domIndex; // 0=top, 1=mid, 2=bot
        if (currentPos > 0) setStackPos(card, currentPos - 1, true);
      });
      setTimeout(renderStack, 320);
    }

    // --- drag handling ---

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
      topCard.addEventListener('pointerup',   onUp);
      topCard.addEventListener('pointercancel', onUp);
    }

    function onMove(e) {
      if (!dragging) return;
      deltaX = e.clientX - startX;
      const rot = deltaX * 0.07;
      topCard.style.transform = `translateX(${deltaX}px) rotate(${rot}deg)`;

      const t = Math.min(Math.abs(deltaX) / THRESHOLD, 1);
      topCard.querySelector('.like-ol').style.opacity    = deltaX > 0 ? t : 0;
      topCard.querySelector('.dislike-ol').style.opacity = deltaX < 0 ? t : 0;
    }

    function onUp() {
      if (!dragging) return;
      dragging = false;
      topCard.style.cursor = 'grab';
      topCard.removeEventListener('pointermove', onMove);
      topCard.removeEventListener('pointerup',   onUp);
      topCard.removeEventListener('pointercancel', onUp);

      Math.abs(deltaX) >= THRESHOLD ? commitSwipe(deltaX > 0 ? 1 : -1) : snapBack();
    }

    function commitSwipe(dir) {
      const flyX = dir * window.innerWidth * 1.5;
      topCard.style.transition = 'transform 0.35s ease';
      topCard.style.transform  = `translateX(${flyX}px) rotate(${dir * 25}deg)`;
      advanceStack();
    }

    function snapBack() {
      topCard.style.transition = 'transform 0.3s ease';
      topCard.style.transform  = 'translateX(0) rotate(0deg)';
      topCard.querySelector('.like-ol').style.opacity    = 0;
      topCard.querySelector('.dislike-ol').style.opacity = 0;
    }

    // --- button actions ---

    document.getElementById('btn-dislike').addEventListener('click', () => { if (topCard) commitSwipe(-1); });
    document.getElementById('btn-like').addEventListener('click',    () => { if (topCard) commitSwipe(1);  });
    document.getElementById('btn-reload').addEventListener('click',  () => loadMore().then(renderStack));

    // --- data loading ---

    async function loadMore() {
      const data = await fetch('/api/random').then(r => r.json());
      queue.push(...data);
    }

    renderStack();
  </script>

</body>
</html>
