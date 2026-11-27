if (new URLSearchParams(location.search).get('maskable') === '1') {
  document.getElementById('background').removeAttribute('rx');
  document.getElementById('symbol').setAttribute('transform', 'translate(512 512) scale(0.8) translate(-512 -512)');
}
