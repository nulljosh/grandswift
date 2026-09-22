"""Export OSM buildings, roads, parks, POIs and coastal water in local metres.

Run: python3 tools/osm.py --area downtown|kits|victoria. +x east, +y south.
Downtown also writes vancouver.json for the existing city page.
"""
import argparse, json, math, urllib.request, urllib.parse, pathlib

WIDTH = {"motorway": 18, "trunk": 16, "primary": 14, "secondary": 12, "tertiary": 10, "residential": 8, "unclassified": 8, "living_street": 6, "service": 5, "pedestrian": 6, "footway": 2.5}

AREAS = {
    "downtown": ((49.2833, -123.1187), (49.2690, -123.1500, 49.2960, -123.0950)),
    "kits": ((49.2690, -123.1575), (49.2620, -123.1750, 49.2760, -123.1400)),
    "victoria": ((48.4250, -123.3650), (48.4150, -123.3800, 48.4350, -123.3500)),
}


def coast_water(lines, bounds):
    """Slice directed OSM coasts into water trapezoids; +y points south.

    OSM water is right of each way, hence positive cross product here.
    Horizontal strips preserve islands without holes in the game's ring format.
    """
    xmin, ymin, xmax, ymax = bounds
    segments = [(a, b) for line in lines for a, b in zip(line, line[1:]) if a != b]
    if not segments:
        return []
    levels = sorted({ymin, ymax, *(p[1] for line in lines for p in line if ymin < p[1] < ymax)})
    # Include rectangle intersections so clamping never bends a shoreline.
    crossings = [a[1] + (x-a[0]) * (b[1]-a[1]) / (b[0]-a[0])
                 for a, b in segments if a[0] != b[0] for x in (xmin, xmax)
                 if min(a[0], b[0]) < x < max(a[0], b[0])]
    levels = sorted({*levels, *(y for y in crossings if ymin < y < ymax)})
    water = []
    def at(seg, y):
        a, b = seg
        return a[0] + (y - a[1]) * (b[0] - a[0]) / (b[1] - a[1])
    # ponytail: O(vertices * segments); spatial indexing if regional exports grow.
    for low, high in zip(levels, levels[1:]):
        mid = (low + high) / 2
        cuts = sorted((s for s in segments if min(s[0][1], s[1][1]) < mid < max(s[0][1], s[1][1])), key=lambda s: at(s, mid))
        if not cuts:
            # Outside a closed island's latitude range, choose the nearest shore.
            def distance(s):
                a, b = s
                dx, dy = b[0]-a[0], b[1]-a[1]
                t = max(0, min(1, (((xmin+xmax)/2-a[0])*dx+(mid-a[1])*dy)/(dx*dx+dy*dy)))
                return ((xmin+xmax)/2-a[0]-t*dx)**2+(mid-a[1]-t*dy)**2
            a, b = min(segments, key=distance)
            wet = (b[0]-a[0])*(mid-a[1])-(b[1]-a[1])*((xmin+xmax)/2-a[0]) > 0
        else:
            wet = cuts[0][1][1] > cuts[0][0][1]
        left = None
        for right in [*cuts, None]:
            if wet:
                lx = [max(xmin, min(xmax, at(left, y))) if left else xmin for y in (low, high)]
                rx = [max(xmin, min(xmax, at(right, y))) if right else xmax for y in (low, high)]
                if sum(rx) - sum(lx) > 1e-8:
                    water.append([[lx[0], low], [rx[0], low], [rx[1], high], [lx[1], high]])
            if right:
                wet = right[1][1] < right[0][1]
            left = right
    return water


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--area", choices=AREAS, default="downtown")
    args = parser.parse_args()
    (lat0, lon0), bbox = AREAS[args.area]
    kx = math.cos(math.radians(lat0)) * 111320
    def xz(p): return [round((p["lon"] - lon0) * kx, 1), round(-(p["lat"] - lat0) * 110540, 1)]
    query = f"""[out:json][timeout:120];
(way["building"]({bbox[0]},{bbox[1]},{bbox[2]},{bbox[3]});
 way["highway"~"^(motorway|trunk|primary|secondary|tertiary|residential|unclassified|living_street|service|pedestrian|footway)$"]({bbox[0]},{bbox[1]},{bbox[2]},{bbox[3]});
 way["leisure"~"^(park|garden|pitch)$"]({bbox[0]},{bbox[1]},{bbox[2]},{bbox[3]});
 way["natural"="coastline"]({bbox[0]},{bbox[1]},{bbox[2]},{bbox[3]});
 way["natural"="water"]({bbox[0]},{bbox[1]},{bbox[2]},{bbox[3]});
 node["shop"]["name"]({bbox[0]},{bbox[1]},{bbox[2]},{bbox[3]});
 node["amenity"~"^(cafe|restaurant|bar|pub|fast_food|bank|pharmacy|cinema|nightclub|ice_cream|library)$"]["name"]({bbox[0]},{bbox[1]},{bbox[2]},{bbox[3]});
 node["tourism"~"^(hotel|museum|gallery)$"]["name"]({bbox[0]},{bbox[1]},{bbox[2]},{bbox[3]}););
out geom;"""

    for endpoint in ("https://overpass-api.de/api/interpreter", "https://overpass.kumi.systems/api/interpreter"):
        req = urllib.request.Request(endpoint, data=urllib.parse.urlencode({"data": query}).encode(), headers={"User-Agent": "rainjack-game/1.0"})
        try:
            with urllib.request.urlopen(req, timeout=180) as response:
                data = json.load(response)
            if "remark" in data:
                raise RuntimeError(data["remark"])
            break
        except (urllib.error.URLError, TimeoutError, RuntimeError):
            if "kumi" in endpoint:
                raise

    out = {"origin": [lat0, lon0], "buildings": [], "roads": [], "parks": [], "water": [], "pois": []}
    coasts = []
    for el in data["elements"]:
        t, g = el.get("tags", {}), el.get("geometry")
        if el["type"] == "node":
            kind = t.get("amenity") or t.get("tourism") or ("grocery" if t.get("shop") in ("supermarket", "convenience", "grocery") else "shop")
            out["pois"].append([*xz(el), kind, t["name"]]); continue
        if not g or len(g) < 2: continue
        pts = [xz(p) for p in g]
        if t.get("natural") == "coastline":
            coasts.append(pts)
        elif "building" in t and len(pts) >= 4:
            h = t.get("height", "").replace("m", "").strip()
            try: h = float(h)
            except ValueError: h = float(t.get("building:levels", 0) or 0) * 3.3 or (18 if t["building"] in ("commercial", "office", "apartments") else 9)
            out["buildings"].append({"p": pts[:-1], "h": round(max(3, min(h, 330)), 1), "n": t.get("name", "")})
        elif "highway" in t:
            out["roads"].append({"p": pts, "w": WIDTH.get(t["highway"], 6), "n": t.get("name", ""), "k": t["highway"]})
        elif t.get("leisure") or t.get("natural") == "water":
            if len(pts) >= 4 and pts[0] == pts[-1]:
                out["water" if t.get("natural") == "water" else "parks"].append(pts[:-1])

    northwest = xz({"lat": bbox[2], "lon": bbox[1]})
    southeast = xz({"lat": bbox[0], "lon": bbox[3]})
    out["water"].extend(coast_water(coasts, (*northwest, *southeast)))
    path = pathlib.Path(__file__).resolve().parent.parent / "site/data" / f"{args.area}.json"
    path.parent.mkdir(parents=True, exist_ok=True)
    encoded = json.dumps(out, separators=(",", ":"))
    path.write_text(encoded)
    if args.area == "downtown":
        path.with_name("vancouver.json").write_text(encoded)
    print(args.area, {key: len(out[key]) for key in ("pois", "buildings", "roads", "parks", "water")}, path.stat().st_size // 1024, "KB")


if __name__ == "__main__":
    main()
