package travellog

import (
	"strings"
	"testing"

	"gno.land/p/nt/uassert/v0"
)

const page = "/r/test/travels"

// panicsWith fails t unless f panics with a message containing substr.
func panicsWith(t *testing.T, substr string, f func(), msgs ...string) {
	t.Helper()
	defer func() {
		r := recover()
		uassert.True(t, r != nil && strings.Contains(r.(string), substr), msgs...)
	}()
	f()
}

func sample() *Log {
	l := &Log{}
	l.AddMany("4886,235,2024,FR,Paris;5237,490,2019,NL,Amsterdam;4576,483,0,FR,Lyon;" +
		"-3387,15121,2024,AU,Sydney;6414,-2190,2022,IS,Reykjavík;4071,-7401,0,US,New York")
	return l
}

func TestAddMany(t *testing.T) {
	l := &Log{}
	uassert.Equal(t, 0, l.Len())
	l.AddMany("4886,235,2024,FR,Paris")
	l.AddMany("5237,490,2019,NL,Amsterdam;4576,483,0,FR,Lyon")
	uassert.Equal(t, "4886,235,2024,FR,Paris\n5237,490,2019,NL,Amsterdam\n4576,483,0,FR,Lyon", l.Cities())
	uassert.Equal(t, 3, l.Len())
}

func TestAddManyRejects(t *testing.T) {
	l := &Log{}
	for _, bad := range []string{
		"4886,235,2024,FR",
		"9100,235,2024,FR,Paris",
		"4886,18100,2024,FR,Paris",
		"4886,235,2024,fr,Paris",
		"4886,235,2024,F1,Paris",
		"4886,235,1800,FR,Paris",
		"4886,235,2024,FR,",
		"4886,235,2024,FR,[x](evil)",
		"4886,235,2024,FR,Paris, France",
		"4886,235,2024,FR,Paris;bad",
	} {
		panicsWith(t, "", func() { l.AddMany(bad) }, bad)
	}
	uassert.Equal(t, 0, l.Len())
}

func TestRemoveMany(t *testing.T) {
	l := &Log{}
	l.AddMany("4886,235,2024,FR,Paris;5237,490,2019,NL,Amsterdam;4576,483,0,FR,Lyon;5250,1340,0,DE,Berlin")
	l.RemoveMany("NL,Amsterdam")
	uassert.Equal(t, "4886,235,2024,FR,Paris\n4576,483,0,FR,Lyon\n5250,1340,0,DE,Berlin", l.Cities())
	l.RemoveMany("DE,Berlin;FR,Paris")
	uassert.Equal(t, "4576,483,0,FR,Lyon", l.Cities())
	l.RemoveMany("FR,Lyon")
	uassert.Equal(t, "", l.Cities())
	panicsWith(t, "not on the map: FR,Paris", func() { l.RemoveMany("FR,Paris") })
}

func TestRemoveManyNeedsWholeKey(t *testing.T) {
	l := &Log{}
	l.AddMany("4886,235,2024,FR,Paris;5237,490,2019,NL,Amsterdam")
	for _, key := range []string{"R,Paris", "FR,Pari", "Paris", "FR,Paris\n5237,490,2019,NL,Amsterdam", "", "5,2019,NL,Amsterdam"} {
		panicsWith(t, "not on the map", func() { l.RemoveMany(key) }, key)
	}
	uassert.Equal(t, 2, l.Len())
}

func TestRenderWorld(t *testing.T) {
	out := sample().Render("", page)
	for _, want := range []string{
		"# Travels\n", "data:image/svg+xml;base64,",
		"**6** cities in **5** countries, 2% of the world's 195, on **3** of 6 continents.",
		"**World** · [Africa](" + page + ":africa) · [Asia](" + page + ":asia)",
		"**All years** · [2024](" + page + ":2024) (2) · [2022](" + page + ":2022) (1) · [2019](" + page + ":2019) (1)",
		"| [Europe](" + page + ":europe) | ▰▱▱▱▱▱▱▱▱▱ 3 of 45 | 4 |",
		"| [Oceania](" + page + ":oceania) | ▰▱▱▱▱▱▱▱▱▱ 1 of 14 | 1 |",
		"| [Africa](" + page + ":africa) | ▱▱▱▱▱▱▱▱▱▱ 0 of 54 | 0 |",
		"- Northernmost: 🇮🇸 Reykjavík, 64.14°N\n",
		"- Southernmost: 🇦🇺 Sydney, 33.87°S\n",
		"- Easternmost: 🇦🇺 Sydney, 151.21°E\n",
		"- Westernmost: 🇺🇸 New York, 74.01°W\n",
		"- Hemispheres: 5 north, 1 south, 4 east, 2 west\n",
		// Countries by name: Australia, France, Iceland, Netherlands, United States.
		"- 🇦🇺 **Australia**: Sydney 2024\n- 🇫🇷 **France**: Paris 2024, Lyon\n- 🇮🇸 **Iceland**: Reykjavík 2022\n",
		"- 🇺🇸 **United States**: New York\n",
	} {
		uassert.True(t, strings.Contains(out, want), "missing: "+want)
	}
}

func TestRenderContinent(t *testing.T) {
	out := sample().Render("europe", page)
	uassert.True(t, strings.Contains(out, "# Travels in Europe\n"))
	uassert.True(t, strings.Contains(out, "**4** cities in **3** of Europe's 45 countries."))
	uassert.True(t, strings.Contains(out, "[World](/r/test/travels) · [Africa]"))
	uassert.True(t, strings.Contains(out, "**Europe**"))
	uassert.False(t, strings.Contains(out, "Sydney"))
}

func TestRenderYear(t *testing.T) {
	out := sample().Render("2024", page)
	uassert.True(t, strings.Contains(out, "# Travels in 2024\n"))
	uassert.True(t, strings.Contains(out, "**2** cities in **2** countries."))
	uassert.True(t, strings.Contains(out, "- 🇫🇷 **France**: Paris\n"))
	uassert.False(t, strings.Contains(out, "Amsterdam"))
}

func TestRenderEmptyAndBadPath(t *testing.T) {
	l := &Log{}
	out := l.Render("", page)
	uassert.True(t, strings.Contains(out, "**0** cities in **0** countries"))
	uassert.False(t, strings.Contains(out, "## Records"))
	uassert.True(t, strings.Contains(l.Render("nope", page), "There is no such page."))
	uassert.True(t, strings.Contains(l.Render("1800", page), "There is no such page."))
}

func TestCard(t *testing.T) {
	out := sample().Card(page)
	uassert.True(t, strings.HasPrefix(out, "![World map with a flag on each city visited](data:image/svg+xml;base64,"))
	uassert.True(t, strings.HasSuffix(out, "on **3** of 6 continents. [See the travels](/r/test/travels)\n"))
}

func TestDegrees(t *testing.T) {
	uassert.Equal(t, "64.14°N", degrees(6414, "N", "S"))
	uassert.Equal(t, "0.05°W", degrees(-5, "E", "W"))
}
