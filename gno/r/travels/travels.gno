// Package travels is David G.'s map of the cities visited.
//
// Each city is one short line of text: its coordinates, its country code, the
// year of the visit and its name. The map, the flags and the counts are drawn
// from those lines on every page view, so nothing else is stored.
package travels

import (
	"sort"
	"strconv"
	"strings"

	"gno.land/p/g1rayfgklwl0aspz488wvrcrvt7t2quy6q06lgk2/worldmap/v0"
)

// admin is the only address allowed to add or remove cities.
const admin = address("g1rayfgklwl0aspz488wvrcrvt7t2quy6q06lgk2")

const (
	page       = "/r/g1rayfgklwl0aspz488wvrcrvt7t2quy6q06lgk2/travels"
	maxNameLen = 64
	// countries is the count of UN member and observer states the page
	// measures against.
	countries = 195
)

// visits holds one "lat,lon,year,CC,name" line per city, in the order added,
// split by newlines. A name holds no comma, so ",CC,name\n" finds a city with
// one search over the string.
var visits string

type visit struct {
	lat, lon int
	cc       string
	year     int
	name     string
}

// AddMany adds cities in one transaction. Only the admin can call it.
//
// data lists the cities split by ";", each as "lat,lon,year,CC,name":
// latitude and longitude in hundredths of a degree, the year of the visit, 0
// when unknown, the two-letter country code and the name, which holds no
// comma. One invalid city rejects the whole call.
//
// AddMany appends without looking for the city on the map, since that search
// costs gas in proportion to everything stored. web/travels.html reads
// Cities first and sends only the new ones.
//
// Example:
//
//	4886,235,2024,FR,Paris;5237,490,2019,NL,Amsterdam
func AddMany(cur realm, data string) {
	assertAdmin(cur)
	add := strings.Split(data, ";")
	for _, line := range add {
		mustParse(line)
	}
	if visits != "" {
		visits += "\n"
	}
	visits += strings.Join(add, "\n")
}

// RemoveMany removes cities in one transaction. Only the admin can call it.
//
// data lists the cities split by ";", each as "CC,name", such as
// "FR,Paris;NL,Amsterdam". A city that is not on the map rejects the call.
func RemoveMany(cur realm, data string) {
	assertAdmin(cur)
	for _, key := range strings.Split(data, ";") {
		start, end, ok := find(key)
		if !ok {
			panic("not on the map: " + key)
		}
		switch {
		case end < len(visits):
			visits = visits[:start] + visits[end+1:]
		case start > 0:
			visits = visits[:start-1]
		default:
			visits = ""
		}
	}
}

// Cities returns every city on the map, one "lat,lon,year,CC,name" line each.
func Cities() string { return visits }

func assertAdmin(cur realm) {
	if cur.Previous().Address() != admin {
		panic("unauthorized")
	}
}

// lines returns the stored cities, one line each.
func lines() []string {
	if visits == "" {
		return nil
	}
	return strings.Split(visits, "\n")
}

// find returns where the line of the city keyed "CC,name" starts and ends in
// visits, the end excluding its newline. A key of any other shape, "Paris"
// alone for one, would match the tail of another line, so it finds nothing.
func find(key string) (start, end int, ok bool) {
	if len(key) < 4 || key[2] != ',' || strings.Count(key, ",") != 1 || strings.Contains(key, "\n") {
		return 0, 0, false
	}
	s := visits + "\n"
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
	return visit{lat, lon, f[3], year, f[4]}
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
	case worldmap.Flag(f[3]) == "" || strings.ToUpper(f[3]) != f[3]:
		panic("country is not two capital letters: " + line)
	case err3 != nil || (year != 0 && (year < 1900 || year > 2200)):
		panic("year out of range: " + line)
	case f[4] == "" || len(f[4]) > maxNameLen || strings.ContainsAny(f[4], ",;\n[]"):
		panic("invalid name: " + line)
	}
	return visit{lat, lon, f[3], year, f[4]}
}

// Render serves:
//
//	""      every city
//	"2024"  the cities visited that year
func Render(path string) string {
	year := 0
	if path != "" {
		y, err := strconv.Atoi(path)
		if err != nil || y < 1900 || y > 2200 {
			return "# Travels\n\nThere is no such page.\n\n[All cities](" + page + ")\n"
		}
		year = y
	}

	var all, shown []visit
	for _, line := range lines() {
		v := parse(line)
		all = append(all, v)
		if year == 0 || v.year == year {
			shown = append(shown, v)
		}
	}

	var b strings.Builder
	title := "Travels"
	if year != 0 {
		title += " in " + strconv.Itoa(year)
	}
	b.WriteString("# " + title + "\n\n")

	points := make([]worldmap.Point, len(shown))
	for i, v := range shown {
		points[i] = worldmap.Point{Lat: v.lat, Lon: v.lon, CC: v.cc}
	}
	b.WriteString(worldmap.Markdown("World map with a flag on each city visited", points) + "\n\n")

	byCountry := map[string][]visit{}
	var codes []string
	for _, v := range shown {
		if _, ok := byCountry[v.cc]; !ok {
			codes = append(codes, v.cc)
		}
		byCountry[v.cc] = append(byCountry[v.cc], v)
	}
	sort.Strings(codes)

	b.WriteString("**" + strconv.Itoa(len(shown)) + "** " + plural(len(shown), "city", "cities") +
		" in **" + strconv.Itoa(len(codes)) + "** " + plural(len(codes), "country", "countries"))
	if year == 0 {
		b.WriteString(", " + strconv.Itoa(len(codes)*100/countries) + "% of the world's " +
			strconv.Itoa(countries))
	}
	b.WriteString(".\n\n")

	years := yearsOf(all)
	if len(years) > 0 {
		links := []string{link("All", page, year == 0)}
		for _, y := range years {
			s := strconv.Itoa(y)
			links = append(links, link(s, page+":"+s, y == year))
		}
		b.WriteString(strings.Join(links, " · ") + "\n\n")
	}

	for _, cc := range codes {
		var names []string
		for _, v := range byCountry[cc] {
			s := v.name
			if v.year != 0 && year == 0 {
				s += " " + strconv.Itoa(v.year)
			}
			names = append(names, s)
		}
		b.WriteString("- " + worldmap.Flag(cc) + " " + strings.Join(names, ", ") + "\n")
	}
	return b.String()
}

// yearsOf returns every known year among vs, most recent first.
func yearsOf(vs []visit) []int {
	seen := map[int]bool{}
	var years []int
	for _, v := range vs {
		if v.year != 0 && !seen[v.year] {
			seen[v.year] = true
			years = append(years, v.year)
		}
	}
	sort.Sort(sort.Reverse(sort.IntSlice(years)))
	return years
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
