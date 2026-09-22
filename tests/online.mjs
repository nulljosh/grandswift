// Online play tests: hits the real game server (the Durable Object behind /ws) with plain WebSocket clients.
// node tests/online.mjs            (live server)
// ONLINE_URL=ws://localhost:8787/ws node tests/online.mjs   (local wrangler dev)
const URL = process.env.ONLINE_URL || "wss://vancouvervice.heyitsmejosh.com/ws";
let fails = 0; const check = (ok, what) => { console.log(ok ? "PASS" : "FAIL", what); if (!ok) fails++; };
const wait = ms => new Promise(r => setTimeout(r, ms));
function client() {
  return new Promise((resolve, reject) => {
    const ws = new WebSocket(URL), c = { ws, msgs: [], id: null, open: false };
    const t = setTimeout(() => reject(new Error("connect timeout")), 8000);
    ws.onopen = () => { c.open = true; };
    ws.onmessage = e => { const m = JSON.parse(e.data); c.msgs.push(m); if (m.t === "hello") { c.id = m.id; clearTimeout(t); resolve(c); } };
    ws.onerror = e => { clearTimeout(t); reject(e); };
  });
}
const got = (c, pred, ms = 3000) => new Promise(async res => { const end = Date.now() + ms; while (Date.now() < end) { const m = c.msgs.find(pred); if (m) return res(m); await wait(25); } res(null); });
const send = (c, o) => c.ws.send(typeof o === "string" ? o : JSON.stringify(o));

try {
  const a = await client(), b = await client();
  check(!!a.id && !!b.id && a.id !== b.id, "two players connect and get their own ids");

  const t0 = Date.now(); send(a, { x: 12.5, z: -40, a: 1.2, d: false, n: "Joshua" });
  const pb = await got(b, m => m.t === "p" && m.id === a.id);
  check(!!pb && pb.x === 12.5 && pb.z === -40 && pb.n === "Joshua", "a position from one player reaches the other");
  check(!!pb && Date.now() - t0 < 1500, `relay is quick (${pb ? Date.now() - t0 : "-"} ms)`);
  check(!a.msgs.some(m => m.t === "p" && m.id === a.id), "you never get your own position echoed back");

  send(b, { x: 1, z: 2, a: 0, n: "Ben" }); check(!!(await got(a, m => m.t === "p" && m.id === b.id)), "relay works both ways");

  const before = b.msgs.length; send(a, "{not json"); send(a, "x".repeat(400)); await wait(600);
  check(b.msgs.length === before, "garbage and oversized messages are dropped");

  send(a, { x: "NaN", z: null, a: {}, n: "A".repeat(40) }); const pc = await got(b, m => m.t === "p" && m.id === a.id && m.x === 0);
  check(!!pc && pc.z === 0 && pc.n.length <= 16, "bad fields are cleaned (numbers default to 0, names cut to 16)");

  const crowd = await Promise.all([client(), client(), client()]);
  send(a, { x: 99, z: 99, a: 0, n: "Crowd" }); const seen = await Promise.all(crowd.map(c => got(c, m => m.t === "p" && m.x === 99)));
  check(seen.every(Boolean), "one move fans out to every player (5 online)");

  b.ws.close(); const bye = await got(a, m => m.t === "bye" && m.id === b.id);
  check(!!bye, "when a player leaves, the others are told");

  const back = await client(); check(!!back.id, "a dropped player can reconnect");
  for (const c of [a, back, ...crowd]) c.ws.close();
} catch (e) { check(false, "server reachable: " + (e.message || e.type || e)); }
console.log(fails ? `FAILED ${fails}` : "ALL PASS"); process.exit(fails ? 1 : 0);
