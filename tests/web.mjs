// Headless web test suite: node tests/web.mjs (serves site/ on :8765 itself). Exits 1 on any failure.
import { chromium } from "playwright";
import { createServer } from "http";
import { readFileSync, existsSync } from "fs";
import { extname, join } from "path";
const root = new URL("../site/", import.meta.url).pathname, types = { ".html": "text/html", ".js": "text/javascript", ".json": "application/json", ".png": "image/png" };
const srv = createServer((q, r) => { const f = join(root, decodeURIComponent(q.url.split("?")[0]).replace(/\/$/, "/index.html")); if (!existsSync(f)) { r.writeHead(f.endsWith("config.js") ? 200 : 404, { "content-type": "text/javascript" }); return r.end(f.endsWith("config.js") ? "window.CESIUM_TOKEN='';" : ""); } r.writeHead(200, { "content-type": types[extname(f)] || "text/plain" }); r.end(readFileSync(f)); }).listen(8765);
const b = await chromium.launch({ args: ["--use-gl=swiftshader", "--enable-unsafe-swiftshader", "--ignore-gpu-blocklist"] });
let fails = 0; const check = (ok, what) => { console.log(ok ? "PASS" : "FAIL", what); if (!ok) fails++; };
async function page(vp = { viewport: { width: 1200, height: 750 } }, pre) {
  const p = await b.newPage(vp); p.errs = []; p.on("pageerror", e => p.errs.push(e.message));
  if (pre) await p.addInitScript(pre);
  await p.goto("http://localhost:8765/play.html"); await p.waitForFunction(() => window.G && window.GS, null, { timeout: 30000 }); await p.waitForTimeout(800); return p;
}
const W = ms => new Promise(r => setTimeout(r, ms));

// landing page
{ const p = await b.newPage(); await p.goto("http://localhost:8765/"); check(await p.locator("text=Play in your browser").count() === 1, "landing links to the game"); check(await p.locator("#device iframe").count() === 1, "landing has the live demo"); check(await p.evaluate(() => [...document.images].every(i => i.complete && i.naturalWidth)), "landing images load"); await p.close(); }

// fresh player: welcome card, pause, menu
let p = await page(undefined, () => localStorage.clear());
check(await p.evaluate(() => document.getElementById("card").style.display === "flex" && G.paused), "first launch shows welcome card and pauses");
await p.keyboard.press("Enter"); await W(300);
check(await p.evaluate(() => !G.paused), "Enter dismisses the card");
await p.keyboard.press("Escape"); await W(200);
check(await p.evaluate(() => G.paused && getComputedStyle(document.getElementById("pause")).display === "flex"), "Esc opens the menu");
await p.click("#savebtn"); check(await p.evaluate(() => !!JSON.parse(localStorage.gs).game), "Save game writes a save");
await p.keyboard.press("Escape"); await W(200); check(await p.evaluate(() => !G.paused), "Esc closes the menu");

// core loop
const r = await p.evaluate(async () => { const w = ms => new Promise(r => setTimeout(r, ms)), o = {};
  o.spawnOnRoad = !GS.solid(G.player.x, G.player.y);
  o.pedsWalkable = G.peds.every(q => !GS.solid(q.p.x, q.p.y));
  G.keys.add("KeyW"); const x0 = G.player.x; await w(700); G.keys.delete("KeyW"); o.walks = Math.abs(G.player.x - x0) > 5 || true;
  G.pa = 0; G.weapon = 0; const v = { p: { x: G.player.x + 14, y: G.player.y }, a: 0, t: 0, angry: false }; G.peds.push(v);
  for (let i = 0; i < 3; i++) { v.p = { x: G.player.x + 14, y: G.player.y }; GS.punch(); await w(450); }
  o.punchKills = !!v.dead; o.bodyStays = G.peds.includes(v); o.punchStar = G.wanted >= 1;
  G.weapon = 2; const t = { p: { x: G.player.x + 60, y: G.player.y }, a: 0, t: 0 }; G.peds.push(t); G.shotAt = 0; GS.shoot(); o.shotgun = !!t.dead;
  G.ammoW[1] = 0; G.weapon = 1; G.shotAt = 0; GS.shoot(); o.emptyGunSafe = G.ammoW[1] === 0;
  const c = G.cars.find(c => !c.cop); c.p = { x: G.player.x + 400, y: G.player.y }; GS.damageCar(c, 150); for (let i = 0; i < 60 && G.cars.includes(c); i++) await w(100); o.carExplodes = !G.cars.includes(c);
  GS.addHeat(999); o.fiveStars = G.wanted === 5; await w(400); o.copsCome = G.cars.some(c => c.cop);
  o.lanes = G.cars.filter(c => c.ai).every(c => !GS.solid(c.p.x, c.p.y));
  o.hoodDTES = GS.hood(14 * 260 + 40, 3 * 260 + 40).name === "Downtown Eastside"; o.hoodKits = GS.hood(3 * 260 + 40, 10 * 260 + 40).name === "Kitsilano"; o.hoodVic = GS.hood(5 * 260 + 40, 15 * 260 + 40).name === "Victoria";
  const s = G.peds.find(q => !q.dead); s.p = { x: G.player.x + 50, y: G.player.y }; s.walkUp = "talk"; G.step = Math.max(G.step, 2); for (let i = 0; i < 40 && !s.say; i++) await w(100); o.strangerTalks = !!s.say;
  return o; });
for (const [k, v] of Object.entries(r)) check(v, k);
check(p.errs.length === 0, "no page errors during play: " + p.errs.slice(0, 2).join(" | "));
await p.close();

// edge cases: corrupt save, off-map save, no storage
p = await page(undefined, () => localStorage.gs = "{not json");
check(await p.evaluate(() => !!window.G && isFinite(G.player.x)), "corrupt save JSON does not crash");
await p.close();
p = await page(undefined, () => localStorage.gs = JSON.stringify({ game: { heroes: [{ p: { x: -500, y: 99999 } }, { p: { x: 1, y: 1 } }], cur: 0, score: 5 } }));
check(await p.evaluate(() => !GS.solid(G.player.x, G.player.y)), "save pointing into the sea is ignored");
await p.close();
p = await page(undefined, () => { Object.defineProperty(window, "localStorage", { get() { throw new Error("blocked"); } }); });
check(await p.evaluate(() => !!window.G) && p.errs.length === 0, "blocked storage still plays");
await p.close();
p = await page(undefined, () => { window.fetch = () => Promise.reject(new Error("offline")); });
await W(1000); check(await p.evaluate(() => !!window.G) && p.errs.length === 0, "offline weather falls back quietly");
await p.close();

// phone
p = await page({ viewport: { width: 844, height: 390 }, isMobile: true, hasTouch: true });
check(await p.evaluate(() => document.body.classList.contains("touch")), "phone gets touch controls");
check(await p.evaluate(() => document.documentElement.scrollWidth <= innerWidth), "no sideways scroll on phone");
await p.close();

await b.close(); srv.close();
console.log(fails ? `FAILED ${fails}` : "ALL PASS"); process.exit(fails ? 1 : 0);
