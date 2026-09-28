#!/usr/bin/env python3
"""Writes gno/p/worldmap/countries.gno, the shapes, projection and country
facts the map draws from.

    ./scripts/worldmap.py

Reads Natural Earth's 1:110m countries from the world-atlas package and
projects them with Robinson's table, from 84N down to 58S, since the Arctic
sea and Antarctica only take room. Antarctica is left out. The file carries
the table too, so the package places each dot with the same projection.

Country names, continents and UN membership come from the world-countries
package, the classification Postcards uses. A UN member or observer counts
toward the 195 countries of the world.

A shape crossing the date line is drawn twice, once past each edge, and the
map clips the land to the ocean's outline, so no line runs across the map.
"""

import json
import math
import os
import urllib.request

SOURCE = "https://cdn.jsdelivr.net/npm/world-atlas@2/countries-110m.json"
COUNTRIES = "https://cdn.jsdelivr.net/npm/world-countries@5/countries.json"
ANTARCTICA = "010"
# Shapes world-atlas carries with no ISO number, by the country they belong to.
UNNUMBERED = {"N. Cyprus": "CY", "Somaliland": "SO", "Kosovo": "XK"}
UN_OBSERVERS = {"VA", "PS"}

# The continents in the order the page lists them, each with the box its view
# frames: west, east, north and south edges in degrees.
CONTINENTS = [
    ("africa", "Africa", (-20, 55, 38, -36)),
    ("asia", "Asia", (25, 150, 56, -12)),
    ("europe", "Europe", (-25, 45, 72, 34)),
    ("north-america", "North America", (-170, -50, 75, 7)),
    ("south-america", "South America", (-85, -33, 13, -56)),
    ("oceania", "Oceania", (110, 180, 2, -48)),
]
OUT = os.path.join(os.path.dirname(__file__), "..", "gno", "p", "worldmap", "countries.gno")

UNIT = 5  # path units per degree of longitude on the equator
TOP, BOTTOM = 84, -58

# Robinson's table, every 5 degrees of latitude from the equator: how much a
# parallel shrinks, and how far from the equator it sits.
ROBINSON_X = [1.0000, 0.9986, 0.9954, 0.9900, 0.9822, 0.9730, 0.9600, 0.9427, 0.9216, 0.8962,
              0.8679, 0.8350, 0.7986, 0.7597, 0.7186, 0.6732, 0.6213, 0.5722, 0.5322]
ROBINSON_Y = [0.0000, 0.0620, 0.1240, 0.1860, 0.2480, 0.3100, 0.3720, 0.4340, 0.4958, 0.5571,
              0.6176, 0.6769, 0.7346, 0.7903, 0.8435, 0.8936, 0.9394, 0.9761, 1.0000]
Y_SCALE = round(1.3523 / 0.8487 * 180 / math.pi * UNIT * 1000)  # path units per Y, x1000


def interp(table, lat):
    a = min(abs(lat), 89.999) / 5
    i = int(a)
    return table[i] + (table[i + 1] - table[i]) * (a - i)


def project(lon, lat):
    """Returns the Robinson position of a point, x from the map's west edge
    and y from the equator, north positive."""
    x = interp(ROBINSON_X, lat) * lon * UNIT + 180 * UNIT
    y = math.copysign(interp(ROBINSON_Y, lat), lat) * Y_SCALE / 1000
    return x, y


ORIGIN_Y = round(project(0, TOP)[1])
WIDTH = 360 * UNIT
HEIGHT = ORIGIN_Y - round(project(0, BOTTOM)[1])


def continent_of(c):
    """Returns the continent key of a world-countries entry, or "" for the
    Antarctic."""
    if c["region"] == "Americas":
        return "south-america" if c.get("subregion") == "South America" else "north-america"
    return {"Africa": "africa", "Asia": "asia", "Europe": "europe", "Oceania": "oceania"}.get(c["region"], "")


def rings(topo):
    """Yields (country code, ring) for every polygon ring of every country,
    the ring as (lon, lat) points."""
    sx, sy = topo["transform"]["scale"]
    tx, ty = topo["transform"]["translate"]
    arcs = []
    for arc in topo["arcs"]:
        x = y = 0
        pts = []
        for dx, dy in arc:
            x += dx
            y += dy
            pts.append((x * sx + tx, y * sy + ty))
        arcs.append(pts)

    def ring(ids):
        pts = []
        for i in ids:
            a = arcs[i] if i >= 0 else arcs[~i][::-1]
            pts.extend(a if not pts else a[1:])
        return pts

    for geom in topo["objects"]["countries"]["geometries"]:
        if geom.get("id") == ANTARCTICA or geom["type"] not in ("Polygon", "MultiPolygon"):
            continue
        cc = CODES.get(geom.get("id")) or UNNUMBERED[geom["properties"]["name"]]
        polys = geom["arcs"] if geom["type"] == "MultiPolygon" else [geom["arcs"]]
        for poly in polys:
            for r in poly:
                yield cc, ring(r)


def unwrapped(rs):
    """Yields each ring with continuous longitudes, plus a copy shifted by
    360 degrees for a ring that runs past either edge."""
    for r in rs:
        out = [r[0]]
        for lon, lat in r[1:]:
            prev = out[-1][0]
            while lon - prev > 180:
                lon -= 360
            while lon - prev < -180:
                lon += 360
            out.append((lon, lat))
        yield out
        if max(x for x, _ in out) > 180:
            yield [(x - 360, y) for x, y in out]
        if min(x for x, _ in out) < -180:
            yield [(x + 360, y) for x, y in out]


def path(rs):
    parts = []
    for r in rs:
        pts = []
        for lon, lat in r:
            x, y = project(lon, lat)
            pts.append((round(x), ORIGIN_Y - round(y)))
        px, py = pts[0]
        moves = []
        for x, y in pts[1:]:
            if (x, y) != (px, py):
                moves.append((x - px, y - py))
                px, py = x, y
        if len(moves) < 2:
            continue
        d = "l" + " ".join("%d %d" % m for m in moves)
        parts.append("M%d %d%sz" % (pts[0][0], pts[0][1], d.replace(" -", "-")))
    return "".join(parts)


def view_box(west, east, north, south):
    """Returns the smallest x, y, width and height framing the box, which
    Robinson bends, padded by a degree's width."""
    pts = [project(lon, lat) for lon in range(west, east + 1) for lat in (north, south)]
    pts += [project(lon, lat) for lat in range(south, north + 1) for lon in (west, east)]
    xs = [x for x, _ in pts]
    ys = [ORIGIN_Y - y for _, y in pts]
    x0, y0 = math.floor(min(xs)) - UNIT, max(0, math.floor(min(ys)) - UNIT)
    return x0, y0, math.ceil(max(xs)) + UNIT - x0, min(HEIGHT, math.ceil(max(ys)) + UNIT) - y0


def main():
    global CODES
    with urllib.request.urlopen(COUNTRIES) as resp:
        countries = sorted(json.load(resp), key=lambda c: c["cca2"])
    CODES = {c["ccn3"]: c["cca2"] for c in countries if c["ccn3"]}
    with urllib.request.urlopen(SOURCE) as resp:
        topo = json.load(resp)

    # Each country's rings, the copies past the date line included, drawn one
    # country after another so a slice of the path is one country.
    shapes = {}
    for cc, r in rings(topo):
        shapes.setdefault(cc, []).append(r)
    land, codes, ends = "", "", []
    for cc in sorted(shapes):
        land += path(unwrapped(shapes[cc]))
        codes += cc
        ends.append(len(land))

    edge = [(180, lat) for lat in range(TOP, BOTTOM - 1, -1)] + \
        [(-180, lat) for lat in range(BOTTOM, TOP + 1)]
    table = lambda t: ", ".join(str(round(v * 10000)) for v in t)
    keys = [k for k, _, _ in CONTINENTS]
    counted = lambda c: c.get("unMember") or c["cca2"] in UN_OBSERVERS
    with open(OUT, "w") as f:
        f.write("// Code generated by scripts/worldmap.py. DO NOT EDIT.\n\n")
        f.write("package worldmap\n\n")
        f.write("// The map in path units, %d per degree of longitude on the equator.\n" % UNIT)
        f.write("const (\n")
        f.write("\tunit    = %d\n" % UNIT)
        f.write("\twidth   = %d\n" % WIDTH)
        f.write("\theight  = %d\n" % HEIGHT)
        f.write("\toriginY = %d // the equator, from the top edge at %dN\n" % (ORIGIN_Y, TOP))
        f.write("\tminLat  = %d // hundredths of a degree\n" % (BOTTOM * 100))
        f.write("\tmaxLat  = %d\n" % (TOP * 100))
        f.write("\t// yScale is path units per unit of robinsonY, times 1000.\n")
        f.write("\tyScale = %d\n" % Y_SCALE)
        f.write(")\n\n")
        f.write("// robinsonX and robinsonY are Robinson's table every 5 degrees from the\n")
        f.write("// equator, times 10000: how much a parallel shrinks, and its height.\n")
        f.write("var (\n")
        f.write("\trobinsonX = [...]int{%s}\n" % table(ROBINSON_X))
        f.write("\trobinsonY = [...]int{%s}\n" % table(ROBINSON_Y))
        f.write(")\n\n")
        f.write("// continents lists each continent's view and how many of its countries\n")
        f.write("// count toward the world's %d.\n" % sum(1 for c in countries if counted(c)))
        f.write("var continents = [...]continent{\n")
        for key, name, box in CONTINENTS:
            n = sum(1 for c in countries if counted(c) and continent_of(c) == key)
            f.write('\t{"%s", "%s", %d, view{%d, %d, %d, %d}},\n' % ((key, name, n) + view_box(*box)))
        f.write("}\n\n")
        f.write("// countryInfo returns a country's name, the index of its continent in\n")
        f.write("// continents or -1, and whether it counts toward the world's countries.\n")
        f.write("func countryInfo(cc string) (name string, continent int, counts bool) {\n")
        f.write("\tswitch cc {\n")
        for c in countries:
            k = continent_of(c)
            f.write('\tcase "%s":\n\t\treturn "%s", %d, %s\n' % (
                c["cca2"], c["name"]["common"].replace('"', '\\"'), keys.index(k) if k else -1,
                "true" if counted(c) else "false"))
        f.write("\t}\n\treturn \"\", -1, false\n}\n\n")
        f.write("// oceanPath is the map's outline, the curved edge of the world.\n")
        f.write('const oceanPath = "%s"\n\n' % path([edge]))
        f.write("// countriesPath draws every country but Antarctica, one after another in\n")
        f.write("// the order of shapeCodes, two letters each; shapeEnds holds where each\n")
        f.write("// country's shape ends in countriesPath.\n")
        f.write('const countriesPath = "%s"\n\n' % land)
        f.write('const shapeCodes = "%s"\n\n' % codes)
        f.write("var shapeEnds = [...]int{%s}\n" % ", ".join(map(str, ends)))


if __name__ == "__main__":
    main()
