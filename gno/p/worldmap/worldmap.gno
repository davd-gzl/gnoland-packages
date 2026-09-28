// Package worldmap draws a world map with a flag or a dot on each point, as a
// markdown image gnoweb shows inline. It stores nothing: the caller passes the
// points on every call.
//
// The map shows every country's outline from Natural Earth's 1:110m data, from
// 84N to 58S, in the Robinson projection.
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

const (
	oceanFill  = "#eef2f7"
	landFill   = "#cbd5e1"
	borderLine = "#ffffff"
	dotFill    = "#ef4444"
	dotEdge    = "#ffffff"
	dotRadius  = 9
	flagSize   = 26
)

// SVG returns the map with each point on it, as an SVG document. A point
// outside 84N to 58S or past 180 degrees is left out. A flag is an emoji the
// viewer's font draws, so a system with no flag emoji shows the two letters.
func SVG(points []Point) string {
	var b strings.Builder
	b.WriteString(`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ` + strconv.Itoa(width) + " " +
		strconv.Itoa(height) + `" width="960" height="` + strconv.Itoa(960*height/width) + `">`)
	b.WriteString(`<clipPath id="ocean"><path d="` + oceanPath + `"/></clipPath>`)
	b.WriteString(`<path fill="` + oceanFill + `" d="` + oceanPath + `"/>`)
	// The clip trims the copies of shapes crossing the date line.
	b.WriteString(`<path clip-path="url(#ocean)" fill="` + landFill + `" stroke="` + borderLine +
		`" stroke-width="0.6" stroke-linejoin="round" d="` + countriesPath + `"/>`)
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
				strconv.Itoa(dotRadius) + `"/>`)
		}
	}
	if dots.Len() > 0 {
		b.WriteString(`<g fill="` + dotFill + `" stroke="` + dotEdge + `" stroke-width="2.5">` + dots.String() + `</g>`)
	}
	if flags.Len() > 0 {
		b.WriteString(`<g font-size="` + strconv.Itoa(flagSize) + `" text-anchor="middle" dominant-baseline="central">` +
			flags.String() + `</g>`)
	}
	b.WriteString(`</svg>`)
	return b.String()
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

// Markdown returns the map as a markdown image, alt being its description for
// screen readers.
func Markdown(alt string, points []Point) string {
	alt = strings.NewReplacer("[", "(", "]", ")").Replace(alt)
	return "![" + alt + "](data:image/svg+xml;base64," +
		base64.StdEncoding.EncodeToString([]byte(SVG(points))) + ")"
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
