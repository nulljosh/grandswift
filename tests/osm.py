"""Offline geometry checks: python3 tests/osm.py."""
import importlib.util
from pathlib import Path
spec = importlib.util.spec_from_file_location('osm', Path(__file__).resolve().parents[1] / 'tools/osm.py')
osm = importlib.util.module_from_spec(spec)
spec.loader.exec_module(osm)

def area(polygons):
    return sum(abs(sum(a[0]*b[1]-b[0]*a[1] for a, b in zip(p, p[1:]+p[:1]))) / 2 for p in polygons)

bounds = (0, 0, 10, 10)
assert area(osm.coast_water([[(5, -1), (5, 11)]], bounds)) == 50
assert area(osm.coast_water([[(5, 11), (5, -1)]], bounds)) == 50
assert area(osm.coast_water([[(-5, -5), (15, 15)]], bounds)) == 50
# Land island: directed counterclockwise in screen coordinates; sea surrounds it.
island = [(3, 3), (3, 7), (7, 7), (7, 3), (3, 3)]
assert area(osm.coast_water([island], bounds)) == 84
assert area(osm.coast_water([list(reversed(island))], bounds)) == 16
assert osm.coast_water([], bounds) == []
# Split ways connect identically to one continuous coast.
assert area(osm.coast_water([[(5, -1), (5, 5)], [(5, 5), (5, 11)]], bounds)) == 50
polys = osm.coast_water([[(-5, 0), (15, 10)]], bounds)
assert area(polys) == 50
assert all(0 <= x <= 10 and 0 <= y <= 10 for p in polys for x, y in p)
print('PASS directed coast, clipping, islands, split ways, empty coast')

# Real exports: city centres stay dry, harbours stay wet.
import json, math
for name, offshore in [('downtown', (49.294, -123.12)), ('kits', (49.2755, -123.16)), ('victoria', (48.423, -123.371))]:
    path = Path(__file__).resolve().parents[1] / 'site/data' / (name + '.json')
    data = json.loads(path.read_text())
    lat, lon = data['origin']
    def wet(x, y):
        def inside(p):
            hit = False
            for a, b in zip(p, p[1:]+p[:1]):
                if (a[1] > y) != (b[1] > y) and x < (b[0]-a[0])*(y-a[1])/(b[1]-a[1])+a[0]:
                    hit = not hit
            return hit
        return any(inside(p) for p in data['water'])
    assert data['buildings'] and data['roads'] and data['pois'], name
    assert not wet(0, 0), name + ' centre flooded'
    assert wet((offshore[1]-lon)*math.cos(math.radians(lat))*111320, -(offshore[0]-lat)*110540), name + ' harbour dry'
    assert all(len(p) >= 3 for p in data['water'])
    print('PASS', name, 'land and sea')
