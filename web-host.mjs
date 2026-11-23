import { readFileSync, writeFileSync } from 'node:fs';

const output = 'dist/index.html';
const html = readFileSync(output, 'utf8');
if (!html.includes('</canvas>') || !html.includes('</head>')) {
  throw new Error('Structure inattendue de la page Godot');
}

const head = `
<style>
html, body { height: 100%; background: #0b1820; overscroll-behavior: none; }
#nin-viewport {
  position: fixed;
  inset: 0;
  width: 100%;
  height: 100%;
  height: 100dvh;
  box-sizing: border-box;
  padding: env(safe-area-inset-top, 0px) env(safe-area-inset-right, 0px)
           env(safe-area-inset-bottom, 0px) env(safe-area-inset-left, 0px);
}
#canvas, #canvas:fullscreen {
  display: block;
  width: 100% !important;
  height: 100% !important;
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
    const { width, height } = canvas.getBoundingClientRect();
    if (width <= 0 || height <= 0) return;
    const ratio = window.devicePixelRatio || 1;
    const scale = touch ? Math.min(ratio, 1.75, Math.sqrt(1050000 / (width * height))) : Math.min(ratio, 1.5);
    const pixelsX = Math.round(width * scale);
    const pixelsY = Math.round(height * scale);
    if (canvas.width !== pixelsX) canvas.width = pixelsX;
    if (canvas.height !== pixelsY) canvas.height = pixelsY;
  }
  new ResizeObserver(resize).observe(canvas);
  document.addEventListener('fullscreenchange', resize);
  resize();
})();
</script>
`;

writeFileSync(output, html
  .replace('<html lang="en">', '<html lang="fr">')
  .replace('initial-scale=1.0', 'initial-scale=1.0, viewport-fit=cover')
  .replace('</head>', head + '</head>')
  .replace('<canvas id="canvas">', '<div id="nin-viewport"><canvas id="canvas">')
  .replace('</canvas>', '</canvas></div>' + body));
