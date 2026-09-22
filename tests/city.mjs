// Run: node tests/city.mjs. Serves the real city and assets on an ephemeral port.
import assert from 'node:assert/strict';
import { createServer } from 'node:http';
import { readFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import { chromium } from 'playwright';

const types = { html: 'text/html', js: 'text/javascript', json: 'application/json', png: 'image/png', glb: 'model/gltf-binary' };
const server = createServer(async (req, res) => {
  try {
    const path = new URL(req.url, 'http://localhost').pathname;
    const data = await readFile(fileURLToPath(new URL(`../site${path}`, import.meta.url)));
    res.writeHead(200, { 'content-type': types[path.split('.').pop()] || 'application/octet-stream' });
    res.end(data);
  } catch { res.writeHead(404); res.end(); }
});
await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
let browser;
try {
  browser = await chromium.launch({ headless: true, args: ['--use-gl=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'] });
  const page = await browser.newPage({ viewport: { width: 640, height: 360 } });
  const errors = [];
  page.on('pageerror', error => errors.push(error.message));
  page.on('console', message => { if (message.type() === 'error') errors.push(message.text()); });
  // The static test server has no multiplayer backend.
  await page.routeWebSocket('**/ws', () => {});
  await page.goto(`http://127.0.0.1:${server.address().port}/city.html`);
  await page.waitForFunction(() => !!window.S, null, { timeout: 90000 });
  assert.equal(await page.locator('#load').count(), 0, 'city finishes booting');
  assert(await page.evaluate(() => !solid(S.p.x, S.p.y)), 'spawn is open ground');
  const start = await page.evaluate(() => ({ x: S.p.x, y: S.p.y }));
  await page.keyboard.down('w');
  try {
    await page.waitForFunction(p => Math.hypot(S.p.x - p.x, S.p.y - p.y) > .25, start, { timeout: 15000 });
  } finally { await page.keyboard.up('w'); }
  // All GLTF requests must finish before raising heat (copTick needs its model).
  await page.waitForLoadState('networkidle', { timeout: 90000 });
  assert.deepEqual(errors, [], 'city assets load without errors');
  const result = await page.evaluate(() => {
    const entry = [...poisIn].find(([, places]) => places.some(p => /7[ -]?eleven/i.test(p.name)));
    if (!entry) throw new Error('No building contains a 7-Eleven');
    const [building, places] = entry;
    const poi = places.find(p => /7[ -]?eleven/i.test(p.name));
    // Approach from open ground where this shop is the nearest POI.
    let outside;
    for (let radius = 2; radius <= 100 && !outside; radius += 2) {
      for (let angle = 0; angle < Math.PI * 2; angle += Math.PI / 16) {
        const x = poi.x + Math.cos(angle) * radius, y = poi.z + Math.sin(angle) * radius;
        const nearest = places.reduce((a, b) => Math.hypot(a.x - x, a.z - y) < Math.hypot(b.x - x, b.z - y) ? a : b);
        if (!solid(x, y) && nearest === poi) { outside = { x, y }; break; }
      }
    }
    if (!outside) throw new Error('No open approach to 7-Eleven');
    S.p.set(outside.x, outside.y);
    S.a = Math.atan2(poi.z - outside.y, poi.x - outside.x);
    enter(building);
    const room = inRoomState();
    const entered = !!room && /7[ -]?eleven/i.test(room.name) && S.p.x > 10000;
    if (room.back.x !== outside.x || room.back.y !== outside.y) throw new Error('enter lost the outdoor return position');
    const clerk = actorsNow().find(a => a.role === 'clerk');
    if (!clerk) throw new Error('7-Eleven has no clerk');
    S.p.set(clerk.m.position.x, clerk.m.position.z + 1);
    const cash = P.cash, stars = P.stars;
    rob();
    return { entered, cash: P.cash - cash, stars: P.stars - stars };
  });
  assert(result.entered, 'enter opens the 7-Eleven interior');
  assert(result.cash >= 60 && result.cash <= 299, 'rob adds cash');
  assert.equal(result.stars, 2, 'rob adds two stars');
  await page.waitForFunction(() => P.stars > 0 && cops.length > 0, null, { timeout: 15000 });
  assert(await page.evaluate(() => {
    const back = inRoomState().back.clone();
    leave();
    return inRoomState() === null && S.p.distanceTo(back) < 2 && !solid(S.p.x, S.p.y);
  }), 'leave returns outside on open ground');
  assert.deepEqual(errors, [], 'no boot or gameplay errors');
  console.log('PASS city boot, spawn, walking, enter, rob, cops, leave');
} finally {
  await browser?.close();
  await new Promise(resolve => server.close(resolve));
}
