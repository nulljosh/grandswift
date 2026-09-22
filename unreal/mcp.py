"""Tiny client for the Unreal MCP on :18000. Usage: mcp.py <method> [json-params]"""
import json, sys, urllib.request
U = "http://127.0.0.1:18000/mcp"
H = {"Content-Type": "application/json", "Accept": "application/json, text/event-stream"}

def post(body, sid=None):
    h = dict(H, **({"Mcp-Session-Id": sid} if sid else {}))
    r = urllib.request.urlopen(urllib.request.Request(U, json.dumps(body).encode(), h), timeout=300)
    txt = r.read().decode()
    if "data:" in txt: txt = txt.split("data:")[-1]
    return r.headers.get("Mcp-Session-Id"), (json.loads(txt) if txt.strip() else None)

sid, _ = post({"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {"protocolVersion": "2025-03-26", "capabilities": {}, "clientInfo": {"name": "cc", "version": "1"}}})
post({"jsonrpc": "2.0", "method": "notifications/initialized"}, sid)
_, res = post({"jsonrpc": "2.0", "id": 2, "method": sys.argv[1], "params": json.loads(sys.argv[2]) if len(sys.argv) > 2 else {}}, sid)
res = res.get("result", res)
for c in res.get("content", []) if isinstance(res, dict) else []:
    print(c.get("text", c)); break
else:
    print(json.dumps(res, indent=1)[:6000])
