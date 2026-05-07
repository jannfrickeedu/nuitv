<!doctype html>
<html lang="de">

<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>NuiTV</title>
  <!-- Built CSS from Vite + Tailwind (source: static/style.css, output: static/dist/style.css) -->
  <link rel="stylesheet" href="/static/dist/style.css">
</head>

<!-- Variables passed from server.py: query (str), results (list|None), error (str|None) -->
<body class="min-h-screen bg-nui-bg">

  <!-- Landing state: no search has been made yet (results is None and no error) -->
  %if results is None and not error:
    <!-- Centered logo + search form -->
    <div class="flex flex-col items-center justify-center min-h-screen px-6 gap-6">
      <img src="/static/nuitv-logo.svg" alt="Logo" class="h-16">
      <form method="GET" action="/" class="w-full max-w-md">
        <input
          name="q"
          type="text"
          value=""
          placeholder="Suchen..."
          autofocus
          class="w-full rounded-full px-5 py-3 text-white bg-nui-card border border-nui-border outline-none focus:ring-2 focus:ring-nui-border placeholder:text-nui-light text-center"
          autocomplete="off"
        >
      </form>
    </div>

  <!-- Results state: a search was made (results is a list, possibly empty, or there's an error) -->
  %else:
    <!-- Header with logo and persistent search bar -->
    <header class="w-full flex items-center justify-between px-6 py-4 shadow bg-gradient-to-r from-nui-bg via-nui-dark to-nui-bg">
      <a href="/"><img src="/static/nuitv-logo.svg" alt="Logo" class="h-10 m-2"></a>
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

    <!-- Results list -->
    <div class="px-4 py-2 space-y-2">
      %if error:
        <!-- DB or server error -->
        <p class="text-red-400 px-2">Fehler: {{error}}</p>
      %elif results is not None and len(results) == 0:
        <!-- Query ran fine but returned nothing -->
        <p class="text-nui-light px-2">Keine Ergebnisse gefunden.</p>
      %elif results:
        <!-- One card per result; links to the detail page -->
        %for show in results:
          <a href="/movie/{{show['id']}}" class="rounded-xl p-4 flex flex-col gap-1 bg-nui-card border border-nui-border active:opacity-70">
            <!-- Title and kind badge (Film / Serie) -->
            <div class="flex items-center justify-between">
              <span class="font-semibold text-white">{{show['name']}}</span>
              <span class="text-xs px-2 py-0.5 rounded-full bg-nui-dark text-nui-subtle">
                {{'Film' if show['kind'] == 'movie' else 'Serie'}}
              </span>
            </div>
            <!-- Year and rating (both optional) -->
            <span class="text-sm text-nui-muted">
              {{str(show['year']) if show.get('year') else ''}}
              %if show.get('vote_average'):
                {{' · ★ ' + str(show['vote_average'])}}
              %end
            </span>
            <!-- Short description from the abstracts table (optional) -->
            %if show.get('text'):
              <p class="text-sm mt-1 text-nui-subtle">{{show['text']}}</p>
            %end
          </a>
        %end
      %end
    </div>
  %end

</body>

</html>
