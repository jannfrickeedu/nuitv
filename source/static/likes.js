(function () {
  const LIKES_KEY = 'nuitv.likes.v1';

  function normalizeState(raw) {
    if (!raw || typeof raw !== 'object') return { schema: 1, items: {} };
    const items = raw.items && typeof raw.items === 'object' ? raw.items : {};
    return { schema: 1, items };
  }

  function readState() {
    try {
      const parsed = JSON.parse(localStorage.getItem(LIKES_KEY) || '{"schema":1,"items":{}}');
      return normalizeState(parsed);
    } catch {
      return { schema: 1, items: {} };
    }
  }

  function writeState(state) {
    localStorage.setItem(LIKES_KEY, JSON.stringify(normalizeState(state)));
  }

  function getCount() {
    return Object.keys(readState().items).length;
  }

  function getIds() {
    return Object.keys(readState().items)
      .map((id) => Number(id))
      .filter((id) => Number.isInteger(id) && id > 0);
  }

  function isLiked(movieId) {
    return Boolean(readState().items[String(movieId)]);
  }

  function setLiked(movie, options = {}) {
    if (!movie || !movie.id) return;

    const state = readState();
    const source = options.source || 'manual';
    const id = String(movie.id);

    state.items[id] = {
      movie_id: movie.id,
      name: movie.name || '',
      kind: movie.kind || '',
      year: movie.year || null,
      vote_average: movie.vote_average || null,
      text: movie.text || '',
      liked: true,
      updated_at: new Date().toISOString(),
      source,
    };

    writeState(state);
  }

  function remove(movieId) {
    const state = readState();
    delete state.items[String(movieId)];
    writeState(state);
  }

  window.NuiLikes = {
    readState,
    writeState,
    getCount,
    getIds,
    isLiked,
    setLiked,
    remove,
  };
})();
