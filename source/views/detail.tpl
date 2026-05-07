<!doctype html>
<html lang="de">

<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>{{movie['name'] if movie else 'NuiTV'}}</title>
  <link rel="stylesheet" href="/static/dist/style.css">
</head>

<body class="min-h-screen bg-nui-bg text-white">

  <header class="w-full flex items-center px-6 py-4 shadow bg-gradient-to-r from-nui-bg via-nui-dark to-nui-bg">
    <a href="javascript:history.back()" class="text-nui-light text-2xl mr-4">&#8592;</a>
    <a href="/"><img src="/static/nuitv-logo.svg" alt="Logo" class="h-10 m-2"></a>
  </header>

  <div class="px-4 py-4 space-y-5 max-w-lg mx-auto">
    %if error:
      <p class="text-red-400">Fehler: {{error}}</p>
    %elif not movie:
      <p class="text-nui-light">Nicht gefunden.</p>
    %else:

      <div class="space-y-1">
        <div class="flex items-start justify-between gap-2">
          <h1 class="text-2xl text-white leading-tight">{{movie['name']}}</h1>
          <span class="text-xs px-2 py-1 rounded-full bg-nui-dark text-nui-subtle shrink-0 mt-1">
            {{'Film' if movie['kind'] == 'movie' else 'Serie'}}
          </span>
        </div>

        <div class="flex items-center gap-3 text-sm text-nui-muted">
          %if movie.get('year'):
            <span>{{movie['year']}}</span>
          %end
          %if movie.get('runtime'):
            <span>{{movie['runtime']}} min</span>
          %end
          %if movie.get('vote_average'):
            <span class="text-nui-pink">&#9733; {{movie['vote_average']}}/10</span>
          %end
        </div>
      </div>

      %if movie.get('text'):
        <p class="text-sm text-nui-subtle leading-relaxed font-normal">{{movie['text']}}</p>
      %end

      %if trailer:
        <div class="rounded-xl overflow-hidden border border-nui-border">
          <iframe
            class="w-full aspect-video"
            src="https://www.youtube.com/embed/{{trailer}}"
            allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
            allowfullscreen
          ></iframe>
        </div>
      %end

      %if cast:
        <div>
          <h2 class="text-nui-muted text-xs uppercase tracking-widest mb-2">Besetzung</h2>
          <div class="space-y-2">
            %for person in cast:
              <div class="flex items-center justify-between rounded-lg px-3 py-2 bg-nui-card border border-nui-border">
                <span class="text-white text-sm">{{person['name']}}</span>
                %if person.get('role'):
                  <span class="text-nui-muted text-xs font-normal">{{person['role']}}</span>
                %end
              </div>
            %end
          </div>
        </div>
      %end

    %end
  </div>

</body>

</html>
