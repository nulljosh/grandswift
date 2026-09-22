"""Pull real downtown Vancouver from OpenStreetMap into site/data/vancouver.json.

Buildings (footprint + height), roads (centre lines + width), parks. Local metres,
origin at Granville & Georgia, +x east, +z south. Run: python3 tools/osm.py
"""
import json, math, urllib.request, urllib.parse, pathlib

LAT0, LON0 = 49.2833, -123.1187
BBOX = (49.2690, -123.1500, 49.2960, -123.0950)  # south, west, north, east: West End to Main, Coal Harbour to False Creek
Q = f"""[out:json][timeout:120];
(way["building"]({BBOX[0]},{BBOX[1]},{BBOX[2]},{BBOX[3]});
 way["highway"~"^(motorway|trunk|primary|secondary|tertiary|residential|unclassified|living_street|service|pedestrian|footway)$"]({BBOX[0]},{BBOX[1]},{BBOX[2]},{BBOX[3]});
 way["leisure"~"^(park|garden|pitch)$"]({BBOX[0]},{BBOX[1]},{BBOX[2]},{BBOX[3]});
 way["natural"="water"]({BBOX[0]},{BBOX[1]},{BBOX[2]},{BBOX[3]}););
out geom;"""
KX = math.cos(math.radians(LAT0)) * 111320
def xz(p): return [round((p["lon"] - LON0) * KX, 1), round(-(p["lat"] - LAT0) * 110540, 1)]
WIDTH = {"motorway": 18, "trunk": 16, "primary": 14, "secondary": 12, "tertiary": 10, "residential": 8, "unclassified": 8, "living_street": 6, "service": 5, "pedestrian": 6, "footway": 2.5}

req = urllib.request.Request("https://overpass-api.de/api/interpreter", data=urllib.parse.urlencode({"data": Q}).encode(), headers={"User-Agent": "rainjack-game/1.0"})
data = json.load(urllib.request.urlopen(req, timeout=180))
out = {"origin": [LAT0, LON0], "buildings": [], "roads": [], "parks": [], "water": []}
for el in data["elements"]:
    t, g = el.get("tags", {}), el.get("geometry")
    if not g or len(g) < 2: continue
    pts = [xz(p) for p in g]
    if "building" in t and len(pts) >= 4:
        h = t.get("height", "").replace("m", "").strip()
        try: h = float(h)
        except ValueError: h = float(t.get("building:levels", 0) or 0) * 3.3 or (18 if t["building"] in ("commercial", "office", "apartments") else 9)
        out["buildings"].append({"p": pts[:-1], "h": round(max(3, min(h, 330)), 1), "n": t.get("name", "")})
    elif "highway" in t:
        out["roads"].append({"p": pts, "w": WIDTH.get(t["highway"], 6), "n": t.get("name", ""), "k": t["highway"]})
    elif t.get("leisure") or t.get("natural") == "water":
        out["water" if t.get("natural") == "water" else "parks"].append(pts[:-1])
path = pathlib.Path(__file__).resolve().parent.parent / "site/data/vancouver.json"
path.write_text(json.dumps(out, separators=(",", ":")))
print(len(out["buildings"]), "buildings,", len(out["roads"]), "roads,", len(out["parks"]), "parks,", path.stat().st_size // 1024, "KB")
