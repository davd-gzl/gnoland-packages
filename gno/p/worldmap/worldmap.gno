// Package worldmap draws a world map with a flag on each point and the
// countries of those points shaded, as a markdown image gnoweb shows inline.
// It also answers a country's name, continent and whether it counts among the
// world's 195. It stores nothing: the caller passes the points on every call.
//
// The map shows every country's outline from Natural Earth's 1:110m data, from
// 84N to 58S, in the Robinson projection, whole or framed on one continent.
package worldmap

import (
	"encoding/base64"
	"strconv"
	"strings"
)

// Point is one place, in hundredths of a degree: Paris is {4886, 235, "FR"}.
type Point struct {
	Lat int    // -9000 at the south pole to 9000 at the north pole
	Lon int    // -18000 to 18000, east positive
	CC  string // two-letter country code, drawn as its flag; a red dot when not one
}

type view struct{ x, y, w, h int }

type continent struct {
	key, name string
	countries int // how many count toward the world's
	view      view
}

const (
	oceanFill    = "#eef2f7"
	landFill     = "#cbd5e1"
	visitedFill  = "#93c5fd"
	borderLine   = "#ffffff"
	dotFill      = "#ef4444"
	dotEdge      = "#ffffff"
	dotRadius    = 9  // on the whole world; a continent scales it with its width
	flagSize     = 26 // the same
	displayWidth = 960
)

// SVG returns the map as an SVG document, framed on the continent keyed
// region, or on the whole world when region is "" or unknown. A point outside
// 84N to 58S or past 180 degrees is left out. A flag is an emoji the viewer's
// font draws, so a system with no flag emoji shows the two letters.
func SVG(points []Point, region string) string {
	v := view{0, 0, width, height}
	if i := continentIndex(region); i >= 0 {
		v = continents[i].view
	}
	stroke := `" stroke="` + borderLine + `" stroke-width="0.5" vector-effect="non-scaling-stroke" stroke-linejoin="round" d="`

	var b strings.Builder
	b.WriteString(`<svg xmlns="http://www.w3.org/2000/svg" viewBox="` + strconv.Itoa(v.x) + " " + strconv.Itoa(v.y) +
		" " + strconv.Itoa(v.w) + " " + strconv.Itoa(v.h) + `" width="` + strconv.Itoa(displayWidth) +
		`" height="` + strconv.Itoa(displayWidth*v.h/v.w) + `">`)
	b.WriteString(`<clipPath id="ocean"><path d="` + oceanPath + `"/></clipPath>`)
	b.WriteString(`<path fill="` + oceanFill + `" d="` + oceanPath + `"/>`)
	// The clip trims the copies of shapes crossing the date line.
	b.WriteString(`<g clip-path="url(#ocean)"><path fill="` + landFill + stroke + countriesPath + `"/>`)
	shaded := map[string]bool{}
	var visited strings.Builder
	for _, p := range points {
		if !shaded[p.CC] {
			shaded[p.CC] = true
			visited.WriteString(shape(p.CC))
		}
	}
	if visited.Len() > 0 {
		b.WriteString(`<path fill="` + visitedFill + stroke + visited.String() + `"/>`)
	}
	b.WriteString(`</g>`)

	var dots, flags strings.Builder
	for _, p := range points {
		if p.Lat < minLat || p.Lat > maxLat || p.Lon < -18000 || p.Lon > 18000 {
			continue
		}
		x, y := project(p)
		if f := Flag(p.CC); f != "" {
			flags.WriteString(`<text x="` + strconv.Itoa(x) + `" y="` + strconv.Itoa(y) + `">` + f + `</text>`)
		} else {
			dots.WriteString(`<circle cx="` + strconv.Itoa(x) + `" cy="` + strconv.Itoa(y) + `" r="` +
				strconv.Itoa(scaled(dotRadius, v)) + `"/>`)
		}
	}
	if dots.Len() > 0 {
		b.WriteString(`<g fill="` + dotFill + `" stroke="` + dotEdge +
			`" stroke-width="1.5" vector-effect="non-scaling-stroke">` + dots.String() + `</g>`)
	}
	if flags.Len() > 0 {
		b.WriteString(`<g font-size="` + strconv.Itoa(scaled(flagSize, v)) +
			`" text-anchor="middle" dominant-baseline="central">` + flags.String() + `</g>`)
	}
	b.WriteString(`</svg>`)
	return b.String()
}

// Markdown returns the map as a markdown image, alt being its description for
// screen readers.
func Markdown(alt string, points []Point, region string) string {
	alt = strings.NewReplacer("[", "(", "]", ")").Replace(alt)
	return "![" + alt + "](data:image/svg+xml;base64," +
		base64.StdEncoding.EncodeToString([]byte(SVG(points, region))) + ")"
}

// Flag returns the flag emoji of a two-letter country code, "FR" giving 🇫🇷,
// or "" when cc is not two ASCII letters.
func Flag(cc string) string {
	if len(cc) != 2 {
		return ""
	}
	var r [2]rune
	for i := 0; i < 2; i++ {
		c := cc[i]
		if c >= 'a' && c <= 'z' {
			c -= 'a' - 'A'
		}
		if c < 'A' || c > 'Z' {
			return ""
		}
		r[i] = 0x1F1E6 + rune(c-'A')
	}
	return string(r[:])
}

// CountryName returns the common English name of a country, "France" for
// "FR", or "" for a code no country has.
func CountryName(cc string) string {
	name, _, _ := countryInfo(cc)
	return name
}

// Continent returns the key of a country's continent, such as "europe", or
// "" for Antarctica and for a code no country has.
func Continent(cc string) string {
	if _, i, _ := countryInfo(cc); i >= 0 {
		return continents[i].key
	}
	return ""
}

// Counts reports whether a country counts among the world's 195: a UN member,
// the Vatican or Palestine. Hong Kong or Greenland, for two, do not.
func Counts(cc string) bool {
	_, _, counts := countryInfo(cc)
	return counts
}

// Continents returns the continent keys in the order to list them, each also
// the region SVG frames.
func Continents() []string {
	keys := make([]string, len(continents))
	for i, c := range continents {
		keys[i] = c.key
	}
	return keys
}

// ContinentName returns the name of a continent key, "North America" for
// "north-america", or "" for an unknown key.
func ContinentName(key string) string {
	if i := continentIndex(key); i >= 0 {
		return continents[i].name
	}
	return ""
}

// ContinentCountries returns how many countries on a continent count among the
// world's, 0 for an unknown key.
func ContinentCountries(key string) int {
	if i := continentIndex(key); i >= 0 {
		return continents[i].countries
	}
	return 0
}

// WorldCountries returns how many countries count among the world's.
func WorldCountries() int {
	n := 0
	for _, c := range continents {
		n += c.countries
	}
	return n
}

func continentIndex(key string) int {
	for i, c := range continents {
		if c.key == key {
			return i
		}
	}
	return -1
}

// shape returns the path of a country's outline, "" when the map has none.
func shape(cc string) string {
	for i := 0; i+2 <= len(shapeCodes); i += 2 {
		if shapeCodes[i:i+2] == cc {
			start := 0
			if i > 0 {
				start = shapeEnds[i/2-1]
			}
			return countriesPath[start:shapeEnds[i/2]]
		}
	}
	return ""
}

// scaled returns a size given for the whole world, kept the same on screen
// in view v.
func scaled(size int, v view) int {
	if s := divRound(size*v.w, width); s > 0 {
		return s
	}
	return 1
}

// project returns where p sits on the map in path units, reading Robinson's
// table between its 5-degree rows.
func project(p Point) (x, y int) {
	a := p.Lat
	if a < 0 {
		a = -a
	}
	i, f := a/500, a%500
	if i >= len(robinsonX)-1 {
		i, f = len(robinsonX)-2, 500
	}
	shrink := robinsonX[i] + (robinsonX[i+1]-robinsonX[i])*f/500
	height := robinsonY[i] + (robinsonY[i+1]-robinsonY[i])*f/500
	dy := divRound(height*yScale, 10000000)
	if p.Lat < 0 {
		dy = -dy
	}
	return 180*unit + divRound(shrink*p.Lon*unit, 1000000), originY - dy
}

// divRound returns a/b rounded half away from zero, b being positive.
func divRound(a, b int) int {
	if a < 0 {
		return -((-a + b/2) / b)
	}
	return (a + b/2) / b
}
