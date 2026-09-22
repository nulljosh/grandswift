// Rainjack: static site plus one shared online world (/ws), a single Durable Object everyone joins.
export default {
  async fetch(req, env) {
    const url = new URL(req.url);
    if (url.pathname === "/ws") {
      if (req.headers.get("Upgrade") !== "websocket") return new Response("websocket only", { status: 426 });
      return env.WORLD.get(env.WORLD.idFromName("vancouver")).fetch(req);
    }
    return env.ASSETS.fetch(req);
  },
};

export class World {
  constructor(state) { this.state = state; }
  async fetch() {
    const [client, server] = Object.values(new WebSocketPair());
    const id = crypto.randomUUID().slice(0, 8);
    this.state.acceptWebSocket(server, [id]);
    server.send(JSON.stringify({ t: "hello", id, players: this.state.getWebSockets().length }));
    return new Response(null, { status: 101, webSocket: client });
  }
  // ponytail: relay-only, no server-side validation of positions; add sanity checks if people start cheating
  webSocketMessage(ws, msg) {
    if (typeof msg !== "string" || msg.length > 300) return;
    let s; try { s = JSON.parse(msg); } catch { return; }
    const [id] = this.state.getTags(ws);
    const out = JSON.stringify({ t: "p", id, x: +s.x || 0, z: +s.z || 0, a: +s.a || 0, d: !!s.d, n: String(s.n || "").slice(0, 16) });
    for (const other of this.state.getWebSockets()) if (other !== ws) try { other.send(out); } catch {}
  }
  webSocketClose(ws) { this.leave(ws); }
  webSocketError(ws) { this.leave(ws); }
  leave(ws) { const [id] = this.state.getTags(ws); const out = JSON.stringify({ t: "bye", id }); for (const o of this.state.getWebSockets()) if (o !== ws) try { o.send(out); } catch {} }
}
