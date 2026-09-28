package worldmap

import (
	"strings"
	"testing"

	"gno.land/p/nt/uassert/v0"
)

func TestFlag(t *testing.T) {
	uassert.Equal(t, "🇫🇷", Flag("FR"))
	uassert.Equal(t, "🇳🇱", Flag("nl"))
	uassert.Equal(t, "", Flag("F"))
	uassert.Equal(t, "", Flag("F1"))
}

func TestSVG(t *testing.T) {
	svg := SVG([]Point{
		{Lat: 4886, Lon: 235, CC: "FR"},
		{Lat: -3387, Lon: 15121},
		{Lat: -8000, Lon: 0, CC: "AQ"},
		{Lat: 8500, Lon: 0, CC: "NO"},
		{Lat: 0, Lon: 20000, CC: "FJ"},
	})
	uassert.True(t, strings.HasPrefix(svg, `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1800 767" width="960" height="409">`))
	uassert.True(t, strings.Contains(svg, `<text x="910" y="166">🇫🇷</text>`))
	uassert.True(t, strings.Contains(svg, `<circle cx="1616" cy="634" r="9"/>`))
	// Below 58S, above 84N and past 180E fall outside the map.
	uassert.Equal(t, 1, strings.Count(svg, "<text "))
	uassert.Equal(t, 1, strings.Count(svg, "<circle "))
}

func TestProject(t *testing.T) {
	// The same points scripts/worldmap.py projects: the equator's middle and
	// the map's top left corner.
	x, y := project(Point{Lat: 0, Lon: 0})
	uassert.Equal(t, 900, x)
	uassert.Equal(t, 442, y)
	x, y = project(Point{Lat: 8400, Lon: -18000})
	uassert.Equal(t, 376, x)
	uassert.Equal(t, 0, y)
}

func TestMarkdown(t *testing.T) {
	md := Markdown("a [map]", nil)
	uassert.True(t, strings.HasPrefix(md, "![a (map)](data:image/svg+xml;base64,"))
}
