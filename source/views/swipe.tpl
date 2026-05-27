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
<script src="/static/swipe-page.js"></script>
