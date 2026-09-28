# gnoland-packages

David G.'s packages and realms for [gno.land](https://gno.land).

| Directory | Package path |
| --- | --- |
| [`gno/r/home`](gno/r/home) | `gno.land/r/g1rayfgklwl0aspz488wvrcrvt7t2quy6q06lgk2/home` |
| [`gno/p/worldmap`](gno/p/worldmap) | `gno.land/p/g1rayfgklwl0aspz488wvrcrvt7t2quy6q06lgk2/worldmap/v0` |
| [`gno/p/travellog`](gno/p/travellog) | `gno.land/p/g1rayfgklwl0aspz488wvrcrvt7t2quy6q06lgk2/travellog/v0` |
| [`gno/r/travels`](gno/r/travels) | `gno.land/r/g1rayfgklwl0aspz488wvrcrvt7t2quy6q06lgk2/travels` |

## home

The profile page gnoweb shows for the address. Each section is markdown stored
on chain, so the text changes with one transaction instead of a redeploy. The
realm is `private = true` in its [`gnomod.toml`](gno/r/home/gnomod.toml): no
other package can import it, and its deployer can replace it at the same path.
A redeploy starts from a fresh state: every heart and every section edited
with `Set` is gone, and the deploy pays its storage deposit again.

The page opens on a banner adapted from the one every Samouraï home realm
shares, then the bio and three charts drawn on chain: merged pull requests and
reviews per month, and a ring of merged `gnolang/gno` pull requests by area.
For visitors it also carries:

- **Gnordle**, a five-letter word game at `:wordle`. Everyone gets the same
  word each day, and past guesses travel in the page link, so playing needs no
  wallet.
- **Hearts**: one transaction sends one, one per address, and a wall draws
  them, ten rows at most with a count of the rest.

Edit a section, `header` for example, from the admin key:

```bash
gnokey maketx call -pkgpath gno.land/r/g1rayfgklwl0aspz488wvrcrvt7t2quy6q06lgk2/home \
  -func Set -args header -args "New bio." \
  -gas-fee 5000ugnot -gas-wanted 5000000 -max-deposit 1000000ugnot \
  -chainid gnoland-1 -remote https://rpc.gno.land:443 <key>
```

The `order` section lists which sections show, comma separated. `hero`,
`banner`, `reviews`, `areachart`, `game` and `hearts` are drawn by the realm
and cannot be set. The banner's text is the `herotext` section, `key value`
pairs split by `;`, such as `title David G.; subtitle Developer engineer`.

The monthly charts count public repositories of the gnolang, gnoverse and
samouraiworld organisations. A repository with fewer than five joins Others,
and Peer Dev commits stack on top in amber, drawn one step per ten commits. A
striped green bar beside each month counts the `gnolang/gno` pull requests
opened that month, and each chart shows the day it was counted. A realm cannot
read GitHub, so the numbers are a snapshot in the `activity`, `reviewactivity`
and `areas` sections. `scripts/activity.py` counts them again with `gh` and
prints the one `gnokey` command that stores all three, through `SetActivity`:

```bash
./scripts/activity.py
```

## travels

A travel page: a world map with a flag on each city visited and its country
shaded, the share of the world's 195 countries reached, coverage by continent,
the farthest cities north, south, east and west, and the cities by country.
Each continent has its own zoomed page at `:europe` and so on, and each year
at `:2024`. A flag is the viewer's own emoji font, so it costs nothing stored;
a system without flag emoji shows the two letters of the country instead.

Everything heavy is deployed once, in two packages any realm imports:

- [`worldmap`](gno/p/worldmap) draws the map and knows each country's name,
  continent and outline: Natural Earth's 1:110m shapes in the Robinson
  projection, from 84N to 58S, with the names and continents of
  [world-countries](https://github.com/mledoze/countries). Both are written
  into [`countries.gno`](gno/p/worldmap/countries.gno) by
  `scripts/worldmap.py`.
- [`travellog`](gno/p/travellog) holds a `Log` of cities, one line each,
  `lat,lon,year,CC,name`, about 27 bytes, and renders the whole page from it.
  `Card` gives the map and one line of counts for a profile page.

[`gno/r/travels`](gno/r/travels) is the realm this repository deploys, and the
shape anyone can copy under their own address, with their address as admin:

```go
var log travellog.Log

func AddMany(cur realm, data string)    { assertAdmin(cur); log.AddMany(data) }
func RemoveMany(cur realm, data string) { assertAdmin(cur); log.RemoveMany(data) }
func Cities() string                    { return log.Cities() }
func Render(path string) string         { return log.Render(path, "/r/<address>/travels") }
```

[`web/travels.html`](web/travels.html) builds the transaction. Open it in a
browser, search a city or import a Postcards export, and copy the `gnokey`
command it prints; `?pkg=` points it at another realm. It reads the cities
already on chain first and sends only the new ones, since `AddMany` appends
without checking. City coordinates come from the Postcards reference data on
GitHub.

Measured on a local node at mainnet's prices, 1ugnot per 1,000 gas and
100ugnot per byte stored:

| Action | Gas | Stored | Cost |
| --- | --- | --- | --- |
| Deploy `worldmap`, once | 90M | 79,816 bytes | 8.07 GNOT |
| Deploy `travellog`, once | 25M | 18,196 bytes | 1.84 GNOT |
| Deploy a `travels` realm | 8M | 6,078 bytes | 0.62 GNOT |
| Add 200 cities | 157M | 5,411 bytes | 0.70 GNOT |
| Add 1 city | 5M | 27 bytes | 0.008 GNOT |

A page view costs 178 million gas with no city and 1.41 billion with 1,000,
under the 3 billion a query may use, so a page holds about 2,000 cities.

## Test

Run from the repository root, where `gnowork.toml` marks the workspace:

```bash
gno test ./gno/...
```
