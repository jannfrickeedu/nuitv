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
<script src="/static/likes-page.js"></script>
