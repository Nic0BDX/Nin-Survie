import { readFileSync, writeFileSync } from 'node:fs';

const output = 'dist/index.html';
const html = readFileSync(output, 'utf8');
if (!html.includes('</canvas>') || !html.includes('</head>')) {
  throw new Error('Structure inattendue de la page Godot');
}

const head = `
<style>
html, body { height: 100%; background: #0b1820; overscroll-behavior: none; }
#canvas {
  position: absolute;
  inset: env(safe-area-inset-top) env(safe-area-inset-right) env(safe-area-inset-bottom) env(safe-area-inset-left);
  touch-action: none;
}
#nin-rotate {
  display: none; position: fixed; inset: 0; z-index: 2;
  place-content: center; gap: 12px; padding: 28px;
  text-align: center; background: #0b1820; color: #efe7ce;
  font: 18px/1.4 system-ui, sans-serif;
}
#nin-rotate strong { color: #e5c389; font-size: 32px; }
@media (pointer: coarse) and (orientation: portrait) {
  #nin-rotate { display: grid; }
}
</style>
`;

const body = `
<div id="nin-rotate" role="status">
  <strong>Nin Survie</strong>
  <span>Tourne ton téléphone en mode paysage pour jouer.</span>
</div>
<script>
(() => {
  const canvas = document.getElementById('canvas');
  canvas.setAttribute('aria-label', 'Nin Survie');
  const touch = matchMedia('(pointer: coarse)').matches || navigator.maxTouchPoints > 0;
  function resize() {
    const style = getComputedStyle(canvas);
    const width = Math.max(1, innerWidth - parseFloat(style.left) - parseFloat(style.right));
    const height = Math.max(1, innerHeight - parseFloat(style.top) - parseFloat(style.bottom));
    const scale = touch ? Math.min(1, 1000 / width, 600 / height) : Math.min(devicePixelRatio, 1.5);
    canvas.style.width = width + 'px';
    canvas.style.height = height + 'px';
    const pixelsX = Math.round(width * scale);
    const pixelsY = Math.round(height * scale);
    if (canvas.width !== pixelsX) canvas.width = pixelsX;
    if (canvas.height !== pixelsY) canvas.height = pixelsY;
  }
  addEventListener('resize', resize);
  resize();
})();
</script>
`;

writeFileSync(output, html
  .replace('<html lang="en">', '<html lang="fr">')
  .replace('initial-scale=1.0', 'initial-scale=1.0, viewport-fit=cover')
  .replace('</head>', head + '</head>')
  .replace('</canvas>', '</canvas>' + body));
