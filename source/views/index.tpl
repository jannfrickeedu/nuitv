<!doctype html>
<html lang="de">

<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>NuiTV</title>
  <script src="https://cdn.jsdelivr.net/npm/@tailwindcss/browser@4"></script>
  <style type="text/tailwindcss">
    @theme {
      --font-sans: Helvetica, sans-serif;
      --color-nui-bg:     #0F172A;
      --color-nui-card:   #1E293B;
      --color-nui-dark:   #581C87;
      --color-nui-purple: #9333EA;
      --color-nui-border: #A855F7;
      --color-nui-muted:  #C084FC;
      --color-nui-light:  #D8B4FE;
      --color-nui-subtle: #E9D5FF;
      --color-nui-pink:   #EC4899;
    }
    body { font-family: Helvetica, sans-serif; font-weight: bold; }
  </style>
</head>

<body class="min-h-screen bg-gradient-to-r from-nui-bg via-nui-dark to-nui-bg">

  <header class="w-full flex items-center justify-between px-6 py-4 shadow bg-gradient-to-r from-nui-bg via-nui-dark to-nui-bg">
    <img src="/static/nuitv-logo.svg" alt="Logo" class="h-10 m-2">

    <form method="GET" action="/" class="relative flex-1 max-w-md mx-4">
      <input
        name="q"
        type="text"
        value="{{query}}"
        placeholder="Suchen..."
        class="w-full rounded-full px-5 py-2 text-white bg-nui-card border border-nui-border outline-none focus:ring-2 focus:ring-nui-border placeholder:text-nui-light"
        autocomplete="off"
      >
    </form>
  </header>

  <div class="px-4 py-2 space-y-2">
    %if error:
      <p class="text-red-400 px-2">Fehler: {{error}}</p>
    %elif results is not None and len(results) == 0:
      <p class="text-nui-light px-2">Keine Ergebnisse gefunden.</p>
    %elif results:
      %for show in results:
        <div class="rounded-xl p-4 flex flex-col gap-1 bg-nui-card border border-nui-border">
          <div class="flex items-center justify-between">
            <span class="font-semibold text-white">{{show['name']}}</span>
            <span class="text-xs px-2 py-0.5 rounded-full bg-nui-dark text-nui-subtle">
              {{'Film' if show['kind'] == 'movie' else 'Serie'}}
            </span>
          </div>
          <span class="text-sm text-nui-muted">
            {{str(show['year']) if show.get('year') else ''}}
            %if show.get('vote_average'):
              {{' · ★ ' + str(show['vote_average'])}}
            %end
          </span>
          %if show.get('text'):
            <p class="text-sm mt-1 text-nui-subtle">{{show['text']}}</p>
          %end
        </div>
      %end
    %end
  </div>

</body>

</html>
