import assert from 'node:assert/strict';
import { createServer } from 'node:http';
import { readFile } from 'node:fs/promises';
import { createRequire } from 'node:module';
import { resolve } from 'node:path';

const require = createRequire(resolve(process.argv[2], 'package.json'));
const chromium = require('@sparticuz/chromium');
const puppeteer = require('puppeteer-core');
const types = { html: 'text/html; charset=utf-8', js: 'text/javascript', wasm: 'application/wasm',
  pck: 'application/octet-stream', png: 'image/png' };
const server = createServer(async (request, response) => {
  const file = request.url === '/' ? 'index.html' : request.url.slice(1);
  if (!/^index\.[\w.]+$/.test(file)) return response.writeHead(404).end();
  try {
    let content = await readFile(resolve('dist', file));
    if (file === 'index.html') {
      content = content.toString()
        .replace('</head>', '<style>:root{--nin-safe-left:47px;--nin-safe-right:47px;--nin-safe-bottom:20px}</style></head>')
        .replace('const engine = new Engine(GODOT_CONFIG);',
          "GODOT_CONFIG.args = ['--', '--qa']; const engine = new Engine(GODOT_CONFIG);");
    }
    response.writeHead(200, { 'Content-Type': types[file.split('.').at(-1)] }).end(content);
  } catch {
    response.writeHead(404).end();
  }
});

await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
let browser;
try {
  browser = await puppeteer.launch({
    args: chromium.args,
    executablePath: await chromium.executablePath(),
    headless: 'shell',
    protocolTimeout: 300000,
  });
  const page = await browser.newPage();
  const faults = [];
  page.on('requestfailed', request => console.log('Requête navigateur', request.url(), request.failure()?.errorText));
  page.on('pageerror', error => faults.push(error.message));
  page.on('console', message => {
    if (message.type() === 'error') console.log('Console navigateur', message.text());
    if (message.type() === 'error' && /SCRIPT ERROR|Parse Error|WebGL context lost/.test(message.text())) {
      faults.push(message.text());
    }
  });
  await page.evaluateOnNewDocument(() => {
    window.ninTest = { update: (state, x, y, yaw, width, height, left, top, right, bottom) => {
      window.ninState = { state, x, y, yaw, width, height, left, top, right, bottom };
    } };
  });
  const orient = (width, height) => page.setViewport({
    width, height, deviceScaleFactor: 3, isMobile: true, hasTouch: true, isLandscape: width > height,
  });
  const dimensions = () => page.evaluate(() => {
    const canvas = document.querySelector('#canvas');
    const rect = canvas.getBoundingClientRect();
    return { width: rect.width, height: rect.height, pixels: [canvas.width, canvas.height],
      rotate: getComputedStyle(document.querySelector('#nin-rotate')).display,
      window: [innerWidth, innerHeight] };
  });
  await orient(390, 844);
  await page.goto('http://127.0.0.1:' + server.address().port, { waitUntil: 'domcontentloaded', timeout: 90000 });
  console.log('Page Web chargée dans Chromium.');
  await page.waitForFunction(() => window.ninState?.state === 'menu', { timeout: 120000, polling: 250 });
  assert.equal((await dimensions()).rotate, 'grid');
  for (const [width, height] of [[667, 375], [844, 390]]) {
    await orient(width, height);
    await page.waitForFunction((w, h) => Math.abs(innerWidth - w) < 2 && Math.abs(innerHeight - h) < 2
      && Math.abs(document.querySelector('#canvas').getBoundingClientRect().height - h) < 2, {}, width, height);
    const screen = await dimensions();
    assert.equal(screen.rotate, 'none');
    assert.ok(Math.abs(screen.width - width) < 2);
    assert.ok(Math.abs(screen.height - height) < 2);
    assert.deepEqual(screen.pixels, [3 * width, 3 * height]);
    console.log('Paysage', width, height, 'CSS', screen.width, screen.height, 'rendu', ...screen.pixels);
  }
  const state = () => page.evaluate(() => window.ninState);
  const screen = await dimensions();
  console.log('Zones de sécurité', JSON.stringify(await page.evaluate(() => ({
    browser: window.ninSafeArea, game: window.ninState,
  }))));
  const coords = (game, x, y) => [
    screen.width * (game.left + x / game.width * (1 - game.left - game.right)),
    screen.height * (game.top + y / game.height * (1 - game.top - game.bottom)),
  ];
  await page.waitForFunction(() => Math.abs(window.ninState?.left * innerWidth - 47) < .5
    && Math.abs(window.ninState?.bottom * innerHeight - 20) < .5, { timeout: 90000, polling: 250 });
  let game = await state();
  const startButton = coords(game, 200, game.height * .35 + 265);
  console.log('Menu Godot', JSON.stringify(game), 'toucher', startButton);
  await page.touchscreen.tap(...startButton);
  await page.waitForFunction(() => window.ninState?.state === 'play');
  console.log('Nouvelle partie démarrée.');
  const image = await page.screenshot({ encoding: 'base64' });
  const edgeSamples = await page.evaluate(async png => {
    const binary = Uint8Array.from(atob(png), byte => byte.charCodeAt(0));
    const frame = await createImageBitmap(new Blob([binary], { type: 'image/png' }));
    const sample = new OffscreenCanvas(frame.width, frame.height).getContext('2d');
    sample.drawImage(frame, 0, 0);
    return [.01, .99].flatMap(x => [.01, .99].map(y =>
      Array.from(sample.getImageData(Math.floor(frame.width * x), Math.floor(frame.height * y), 1, 1).data.slice(0, 3))));
  }, image);
  assert.ok(edgeSamples.every(rgb => rgb.join() !== '11,24,32' && rgb.join() !== '0,0,0'));
  console.log('Capture en jeu, pixels aux quatre coins', JSON.stringify(edgeSamples));
  game = await state();
  const start = await page.touchscreen.touchStart(...coords(game, 150, game.height - 146));
  await start.move(...coords(game, 150, game.height - 230));
  await page.waitForFunction((x, y) => Math.hypot(window.ninState.x - x, window.ninState.y - y) > .25,
    {}, game.x, game.y);
  await start.end();
  console.log('Déplacement tactile validé.');
  game = await state();
  const look = await page.touchscreen.touchStart(...coords(game, game.width * .61, game.height * .4));
  await look.move(...coords(game, game.width * .67, game.height * .4));
  await look.end();
  await page.waitForFunction(yaw => Math.abs(window.ninState.yaw - yaw) > .04, {}, game.yaw);
  console.log('Rotation tactile validée.');
  await page.touchscreen.tap(...coords(game, game.width - 89, game.height - 192));
  await page.waitForFunction(() => window.ninState?.state === 'map');
  assert.deepEqual(faults, []);
  console.log('Chromium mobile : menu, partie, joystick, caméra et carte validés.');
} finally {
  await browser?.close();
  server.close();
}
