(function () {
  const movieNode = document.getElementById('movie-data');
  if (!movieNode) return;

  let movie = null;
  try {
    movie = JSON.parse(movieNode.textContent || 'null');
  } catch {
    movie = null;
  }

  const likeBtn = document.getElementById('like-toggle');
  if (!likeBtn || !movie || !movie.id || !window.NuiLikes) return;

  function syncLikeButton() {
    const liked = window.NuiLikes.isLiked(movie.id);
    likeBtn.dataset.liked = liked ? 'true' : 'false';
    likeBtn.textContent = liked ? '♥ Gemerkt' : '♡ Merken';
    likeBtn.classList.toggle('border-nui-green', liked);
    likeBtn.classList.toggle('text-nui-green', liked);
  }

  syncLikeButton();

  likeBtn.addEventListener('click', () => {
    const liked = likeBtn.dataset.liked === 'true';
    if (liked) window.NuiLikes.remove(movie.id);
    else window.NuiLikes.setLiked(movie, { source: 'detail' });
    syncLikeButton();
  });
})();
