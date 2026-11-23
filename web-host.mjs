import { readFileSync, writeFileSync } from 'node:fs';

const output = 'dist/index.html';
const html = readFileSync(output, 'utf8');
if (!html.includes('</canvas>') || !html.includes('</head>')) {
  throw new Error('Structure inattendue de la page Godot');
}

const head = `
<style>
html, body { height: 100%; overflow: hidden; background: #0b1820; overscroll-behavior: none; }
#canvas, #nin-rotate {
  position: fixed;
  top: var(--nin-visible-top, 0px);
  left: var(--nin-visible-left, 0px);
  width: 100%;
  height: 100%;
  height: 100dvh;
  width: var(--nin-visible-width, 100%);
  height: var(--nin-visible-height, 100dvh);
}
#nin-safe-area {
  position: fixed;
  inset: 0;
  pointer-events: none;
  visibility: hidden;
  padding: var(--nin-safe-top, env(safe-area-inset-top, 0px))
           var(--nin-safe-right, env(safe-area-inset-right, 0px))
           var(--nin-safe-bottom, env(safe-area-inset-bottom, 0px))
           var(--nin-safe-left, env(safe-area-inset-left, 0px));
}
#canvas {
  display: block;
  position: fixed !important;
  top: var(--nin-visible-top, 0px) !important;
  left: var(--nin-visible-left, 0px) !important;
  width: var(--nin-visible-width, 100%) !important;
  height: var(--nin-visible-height, 100%) !important;
  touch-action: none;
}
#canvas:fullscreen { inset: 0 !important; width: 100% !important; height: 100% !important; }
#nin-rotate {
  display: none; z-index: 2; box-sizing: border-box;
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
<div id="nin-safe-area" aria-hidden="true"></div>
<div id="nin-rotate" role="status">
  <strong>Nin Survie</strong>
  <span>Tourne ton téléphone en mode paysage pour jouer.</span>
</div>
<script>
(() => {
  const canvas = document.getElementById('canvas');
  canvas.setAttribute('aria-label', 'Nin Survie');
  canvas.style.setProperty('position', 'fixed', 'important');
  const probe = document.getElementById('nin-safe-area');
  const safe = window.ninSafeArea = { left: 0, top: 0, right: 0, bottom: 0 };
  const viewport = window.visualViewport;
  const style = document.documentElement.style;
  let frame = 0;
  function resize() {
    frame = 0;
    if (viewport && viewport.width > 0 && viewport.height > 0) {
      const zoomed = Math.abs(viewport.scale - 1) > .01;
      if (!zoomed) {
        const layout = { top: Math.max(0, viewport.offsetTop), left: Math.max(0, viewport.offsetLeft),
          width: viewport.width, height: viewport.height };
        for (const [property, value] of Object.entries(layout)) {
          const pixels = value + 'px';
          style.setProperty('--nin-visible-' + property, pixels);
          if (document.fullscreenElement !== canvas) canvas.style.setProperty(property, pixels, 'important');
        }
      }
    }
    if (document.fullscreenElement === canvas) {
      for (const key of ['top', 'left', 'width', 'height']) canvas.style.removeProperty(key);
    }
    const { width, height } = canvas.getBoundingClientRect();
    if (width <= 0 || height <= 0) return;
    const ratio = window.devicePixelRatio || 1;
    const pixelsX = Math.round(width * ratio);
    const pixelsY = Math.round(height * ratio);
    if (canvas.width !== pixelsX) canvas.width = pixelsX;
    if (canvas.height !== pixelsY) canvas.height = pixelsY;
    const padding = getComputedStyle(probe);
    safe.left = (parseFloat(padding.paddingLeft) || 0) / width;
    safe.right = (parseFloat(padding.paddingRight) || 0) / width;
    safe.top = (parseFloat(padding.paddingTop) || 0) / height;
    safe.bottom = (parseFloat(padding.paddingBottom) || 0) / height;
    window.dispatchEvent(new Event('nin-viewport-resize'));
  }
  function requestResize() {
    if (!frame) frame = requestAnimationFrame(resize);
  }
  new ResizeObserver(requestResize).observe(canvas);
  addEventListener('resize', requestResize);
  addEventListener('pageshow', requestResize);
  viewport?.addEventListener('resize', requestResize);
  viewport?.addEventListener('scroll', requestResize);
  screen.orientation?.addEventListener('change', requestResize);
  document.addEventListener('fullscreenchange', requestResize);
  resize();
})();
</script>
`;

writeFileSync(output, html
  .replace('<html lang="en">', '<html lang="fr">')
  .replace('initial-scale=1.0', 'initial-scale=1.0, viewport-fit=cover')
  .replace('</head>', head + '</head>')
  .replace('</canvas>', '</canvas>' + body));
