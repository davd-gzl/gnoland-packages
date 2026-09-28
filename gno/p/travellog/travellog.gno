// Package travellog keeps a list of cities visited and renders it as a
// travel page: a world map with a flag on each city and its country shaded,
// coverage by continent, the farthest cities, and the list by country, with
// a page per continent and per year.
//
// A realm holds a Log in a variable and guards who writes to it:
//
//	var log travellog.Log
//
//	func AddMany(cur realm, data string) {
//		if cur.Previous().Address() != owner {
//			panic("unauthorized")
//		}
//		log.AddMany(data)
//	}
//
//	func Render(path string) string { return log.Render(path, "/r/<you>/travels") }
//
// The Log stores one short line per city, about 27 bytes, and the map, the
// country facts and the page all come from this package and worldmap, deployed
// once for every realm.
package travellog

import (
	"sort"
	"strconv"
	"strings"

	"gno.land/p/g1rayfgklwl0aspz488wvrcrvt7t2quy6q06lgk2/worldmap/v0"
)

const (
	maxNameLen = 64
	// MaxCities keeps the page under the 3 billion gas a page view may use:
	// 1,500 cities render in 2.3 billion, 2,000 in 3.1 billion.
	MaxCities = 1500
)

// Log is a list of cities, one "lat,lon,year,CC,name" line each, in the order
// added, split by newlines. Its zero value is an empty log.
type Log struct {
	lines string
	n     int // cities in lines
}

type visit struct {
	lat, lon int
	year     int
	cc       string
	name     string
}

// AddMany appends cities. data lists them split by ";", each as
// "lat,lon,year,CC,name": latitude and longitude in hundredths of a degree,
// the year of the visit, 0 when unknown, the two-letter country code and the
// name, which holds no comma. One invalid city, or going past MaxCities,
// rejects the whole call.
//
// AddMany does not look for the city in the log, since that search costs gas
// in proportion to everything stored: the caller sends only new cities, as
// web/travels.html does after reading Cities.
//
// Example:
//
//	4886,235,2024,FR,Paris;5237,490,2019,NL,Amsterdam
func (l *Log) AddMany(data string) {
	add := strings.Split(data, ";")
	for _, line := range add {
		mustParse(line)
	}
	if l.n+len(add) > MaxCities {
		panic("the map holds " + strconv.Itoa(MaxCities) + " cities at most")
	}
	l.n += len(add)
	if l.lines != "" {
		l.lines += "\n"
	}
	l.lines += strings.Join(add, "\n")
}

// RemoveMany removes cities. data lists them split by ";", each as
// "CC,name", such as "FR,Paris;NL,Amsterdam". A city that is not in the log
// rejects the call.
func (l *Log) RemoveMany(data string) {
	for _, key := range strings.Split(data, ";") {
		start, end, ok := l.find(key)
		if !ok {
			panic("not on the map: " + key)
		}
		l.n--
		switch {
		case end < len(l.lines):
			l.lines = l.lines[:start] + l.lines[end+1:]
		case start > 0:
			l.lines = l.lines[:start-1]
		default:
			l.lines = ""
		}
	}
}

// Cities returns every city, one "lat,lon,year,CC,name" line each.
func (l *Log) Cities() string { return l.lines }

// Len returns how many cities the log holds.
func (l *Log) Len() int { return l.n }

// Render returns the travel page for path, page being the realm's own path
// the links start from, "/r/<you>/travels" for one. path is "" for the whole
// world, a continent key such as "europe", or a year such as "2024".
func (l *Log) Render(path, page string) string {
	all := l.visits()
	var b strings.Builder
	switch {
	case path == "":
		l.renderWorld(&b, all, page)
	case worldmap.ContinentName(path) != "":
		renderContinent(&b, all, path, page)
	default:
		y, err := strconv.Atoi(path)
		if err != nil || y < 1900 || y > 2200 {
			return "# Travels\n\nThere is no such page.\n\n[The whole world](" + page + ")\n"
		}
		renderYear(&b, all, y, page)
	}
	return b.String()
}

// Card returns the map and one line of counts, with a link to the full page,
// for a profile page to show above its other sections.
func (l *Log) Card(page string) string {
	all := l.visits()
	return worldmap.Markdown("World map with a flag on each city visited", points(all), "") + "\n\n" +
		summary(all, countries(all)) + " [See the travels](" + page + ")\n"
}

func (l *Log) renderWorld(b *strings.Builder, all []visit, page string) {
	b.WriteString("# Travels\n\n")
	b.WriteString(worldmap.Markdown("World map with a flag on each city visited", points(all), "") + "\n\n")
	codes := countries(all)
	b.WriteString(summary(all, codes) + "\n\n")
	b.WriteString(viewLinks("", page) + "\n\n")
	b.WriteString(yearLinks(all, 0, page) + "\n\n")
	if len(all) == 0 {
		return
	}

	b.WriteString("## Continents\n\n| Continent | Countries | Cities |\n| --- | --- | --- |\n")
	for _, key := range worldmap.Continents() {
		n, cities := 0, 0
		for _, cc := range codes {
			if worldmap.Continent(cc) == key && worldmap.Counts(cc) {
				n++
			}
		}
		for _, v := range all {
			if worldmap.Continent(v.cc) == key {
				cities++
			}
		}
		total := worldmap.ContinentCountries(key)
		b.WriteString("| [" + worldmap.ContinentName(key) + "](" + page + ":" + key + ") | " +
			bar(n, total) + " " + strconv.Itoa(n) + " of " + strconv.Itoa(total) + " | " +
			strconv.Itoa(cities) + " |\n")
	}

	b.WriteString("\n## Records\n\n")
	north, south, east, west := all[0], all[0], all[0], all[0]
	var n, s, e, w int
	for _, v := range all {
		if v.lat > north.lat {
			north = v
		}
		if v.lat < south.lat {
			south = v
		}
		if v.lon > east.lon {
			east = v
		}
		if v.lon < west.lon {
			west = v
		}
		if v.lat >= 0 {
			n++
		} else {
			s++
		}
		if v.lon >= 0 {
			e++
		} else {
			w++
		}
	}
	b.WriteString("- Northernmost: " + place(north) + ", " + degrees(north.lat, "N", "S") + "\n")
	b.WriteString("- Southernmost: " + place(south) + ", " + degrees(south.lat, "N", "S") + "\n")
	b.WriteString("- Easternmost: " + place(east) + ", " + degrees(east.lon, "E", "W") + "\n")
	b.WriteString("- Westernmost: " + place(west) + ", " + degrees(west.lon, "E", "W") + "\n")
	b.WriteString("- Hemispheres: " + strconv.Itoa(n) + " north, " + strconv.Itoa(s) + " south, " +
		strconv.Itoa(e) + " east, " + strconv.Itoa(w) + " west\n\n")

	renderCountries(b, all, codes, true)
}

func renderContinent(b *strings.Builder, all []visit, key, page string) {
	var shown []visit
	for _, v := range all {
		if worldmap.Continent(v.cc) == key {
			shown = append(shown, v)
		}
	}
	name := worldmap.ContinentName(key)
	codes := countries(shown)
	n := 0
	for _, cc := range codes {
		if worldmap.Counts(cc) {
			n++
		}
	}
	b.WriteString("# Travels in " + name + "\n\n")
	b.WriteString(worldmap.Markdown("Map of "+name+" with a flag on each city visited", points(shown), key) + "\n\n")
	b.WriteString("**" + strconv.Itoa(len(shown)) + "** " + plural(len(shown), "city", "cities") + " in **" +
		strconv.Itoa(n) + "** of " + name + "'s " + strconv.Itoa(worldmap.ContinentCountries(key)) +
		" countries.\n\n")
	b.WriteString(viewLinks(key, page) + "\n\n")
	renderCountries(b, shown, codes, true)
}

func renderYear(b *strings.Builder, all []visit, year int, page string) {
	var shown []visit
	for _, v := range all {
		if v.year == year {
			shown = append(shown, v)
		}
	}
	codes := countries(shown)
	b.WriteString("# Travels in " + strconv.Itoa(year) + "\n\n")
	b.WriteString(worldmap.Markdown("World map with a flag on each city visited in "+strconv.Itoa(year),
		points(shown), "") + "\n\n")
	b.WriteString("**" + strconv.Itoa(len(shown)) + "** " + plural(len(shown), "city", "cities") + " in **" +
		strconv.Itoa(len(codes)) + "** " + plural(len(codes), "country", "countries") + ".\n\n")
	b.WriteString(yearLinks(all, year, page) + "\n\n")
	renderCountries(b, shown, codes, false)
}

// renderCountries lists the cities by country, countries by name.
func renderCountries(b *strings.Builder, vs []visit, codes []string, years bool) {
	if len(vs) == 0 {
		return
	}
	b.WriteString("## Countries\n\n")
	for _, cc := range codes {
		var names []string
		for _, v := range vs {
			if v.cc != cc {
				continue
			}
			s := v.name
			if years && v.year != 0 {
				s += " " + strconv.Itoa(v.year)
			}
			names = append(names, s)
		}
		b.WriteString("- " + worldmap.Flag(cc) + " **" + countryName(cc) + "**: " + strings.Join(names, ", ") + "\n")
	}
}

// summary returns the headline counts of the whole log.
func summary(all []visit, codes []string) string {
	counted, reached := 0, map[string]bool{}
	for _, cc := range codes {
		if worldmap.Counts(cc) {
			counted++
		}
		if k := worldmap.Continent(cc); k != "" {
			reached[k] = true
		}
	}
	world := worldmap.WorldCountries()
	return "**" + strconv.Itoa(len(all)) + "** " + plural(len(all), "city", "cities") + " in **" +
		strconv.Itoa(len(codes)) + "** " + plural(len(codes), "country", "countries") + ", " +
		strconv.Itoa(counted*100/world) + "% of the world's " + strconv.Itoa(world) + ", on **" +
		strconv.Itoa(len(reached)) + "** of " + strconv.Itoa(len(worldmap.Continents())) + " continents."
}

// viewLinks links the whole world and each continent, current being the one
// shown.
func viewLinks(current, page string) string {
	links := []string{link("World", page, current == "")}
	for _, key := range worldmap.Continents() {
		links = append(links, link(worldmap.ContinentName(key), page+":"+key, current == key))
	}
	return strings.Join(links, " · ")
}

// yearLinks links every known year, most recent first, with its count of
// cities.
func yearLinks(all []visit, current int, page string) string {
	count := map[int]int{}
	var years []int
	for _, v := range all {
		if v.year == 0 {
			continue
		}
		if count[v.year] == 0 {
			years = append(years, v.year)
		}
		count[v.year]++
	}
	if len(years) == 0 {
		return ""
	}
	sort.Sort(sort.Reverse(sort.IntSlice(years)))
	links := []string{link("All years", page, current == 0)}
	for _, y := range years {
		s := strconv.Itoa(y)
		links = append(links, link(s, page+":"+s, y == current)+" ("+strconv.Itoa(count[y])+")")
	}
	return strings.Join(links, " · ")
}

// countries returns the distinct country codes of vs, sorted by country name.
func countries(vs []visit) []string {
	seen := map[string]bool{}
	var codes []string
	for _, v := range vs {
		if !seen[v.cc] {
			seen[v.cc] = true
			codes = append(codes, v.cc)
		}
	}
	pairs := make(byName, len(codes))
	for i, cc := range codes {
		pairs[i] = [2]string{countryName(cc), cc}
	}
	sort.Sort(pairs)
	for i := range pairs {
		codes[i] = pairs[i][1]
	}
	return codes
}

// byName sorts {name, code} pairs by name.
type byName [][2]string

func (s byName) Len() int           { return len(s) }
func (s byName) Less(i, j int) bool { return s[i][0] < s[j][0] }
func (s byName) Swap(i, j int)      { s[i], s[j] = s[j], s[i] }

func points(vs []visit) []worldmap.Point {
	ps := make([]worldmap.Point, len(vs))
	for i, v := range vs {
		ps[i] = worldmap.Point{Lat: v.lat, Lon: v.lon, CC: v.cc}
	}
	return ps
}

// countryName returns the country's name, or its code when it has none.
func countryName(cc string) string {
	if name := worldmap.CountryName(cc); name != "" {
		return name
	}
	return cc
}

func place(v visit) string { return worldmap.Flag(v.cc) + " " + v.name }

// degrees writes hundredths of a degree as "64.14°N", pos and neg naming the
// two directions.
func degrees(v int, pos, neg string) string {
	dir := pos
	if v < 0 {
		v, dir = -v, neg
	}
	frac := strconv.Itoa(v % 100)
	if len(frac) == 1 {
		frac = "0" + frac
	}
	return strconv.Itoa(v/100) + "." + frac + "°" + dir
}

// bar draws n of total as ten cells.
func bar(n, total int) string {
	filled := 0
	if total > 0 {
		filled = (n*10 + total/2) / total
	}
	return strings.Repeat("▰", filled) + strings.Repeat("▱", 10-filled)
}

func link(text, href string, current bool) string {
	if current {
		return "**" + text + "**"
	}
	return "[" + text + "](" + href + ")"
}

func plural(n int, one, many string) string {
	if n == 1 {
		return one
	}
	return many
}

func (l *Log) visits() []visit {
	if l.lines == "" {
		return nil
	}
	lines := strings.Split(l.lines, "\n")
	vs := make([]visit, len(lines))
	for i, line := range lines {
		vs[i] = parse(line)
	}
	return vs
}

// find returns where the line of the city keyed "CC,name" starts and ends,
// the end excluding its newline. A key of any other shape, "Paris" alone for
// one, would match the tail of another line, so it finds nothing.
func (l *Log) find(key string) (start, end int, ok bool) {
	if len(key) < 4 || key[2] != ',' || strings.Count(key, ",") != 1 || strings.Contains(key, "\n") {
		return 0, 0, false
	}
	s := l.lines + "\n"
	i := strings.Index(s, ","+key+"\n")
	if i < 0 {
		return 0, 0, false
	}
	return strings.LastIndex(s[:i], "\n") + 1, i + 1 + len(key), true
}

// parse reads a stored line, which AddMany already checked.
func parse(line string) visit {
	f := strings.SplitN(line, ",", 5)
	lat, _ := strconv.Atoi(f[0])
	lon, _ := strconv.Atoi(f[1])
	year, _ := strconv.Atoi(f[2])
	return visit{lat, lon, year, f[3], f[4]}
}

// mustParse reads one city of AddMany's argument, or panics naming it.
func mustParse(line string) visit {
	f := strings.SplitN(line, ",", 5)
	if len(f) != 5 {
		panic("want lat,lon,year,CC,name: " + line)
	}
	lat, err1 := strconv.Atoi(f[0])
	lon, err2 := strconv.Atoi(f[1])
	year, err3 := strconv.Atoi(f[2])
	switch {
	case err1 != nil || lat < -9000 || lat > 9000:
		panic("latitude out of range: " + line)
	case err2 != nil || lon < -18000 || lon > 18000:
		panic("longitude out of range: " + line)
	case err3 != nil || (year != 0 && (year < 1900 || year > 2200)):
		panic("year out of range: " + line)
	case worldmap.Flag(f[3]) == "" || strings.ToUpper(f[3]) != f[3]:
		panic("country is not two capital letters: " + line)
	case f[4] == "" || len(f[4]) > maxNameLen || strings.ContainsAny(f[4], ",;\n[]"):
		panic("invalid name: " + line)
	}
	return visit{lat, lon, year, f[3], f[4]}
}
