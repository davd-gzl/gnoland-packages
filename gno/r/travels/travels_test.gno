package travels

import (
	"strings"
	"testing"

	"gno.land/p/nt/testutils/v0"
	"gno.land/p/nt/uassert/v0"
)

var mallory = testutils.TestAddress("mallory")

func reset() { visits = "" }

func TestAddManyAndRender(cur realm, t *testing.T) {
	reset()
	testing.SetRealm(testing.NewUserRealm(admin))
	AddMany(cross(cur), "4886,235,2024,FR,Paris;5237,490,2019,NL,Amsterdam;4576,483,0,FR,Lyon")
	uassert.Equal(t, 3, len(lines()))

	out := Render("")
	for _, want := range []string{
		"# Travels\n", "data:image/svg+xml;base64,",
		"**3** cities in **2** countries, 1% of the world's 195.",
		"**All** · [2024](" + page + ":2024) · [2019](" + page + ":2019)",
		"- 🇫🇷 Paris 2024, Lyon\n", "- 🇳🇱 Amsterdam 2019\n",
	} {
		uassert.True(t, strings.Contains(out, want), "missing: "+want)
	}

	year := Render("2024")
	uassert.True(t, strings.Contains(year, "# Travels in 2024"))
	uassert.True(t, strings.Contains(year, "**1** city in **1** country."))
	uassert.True(t, strings.Contains(year, "- 🇫🇷 Paris\n"))
	uassert.False(t, strings.Contains(year, "Amsterdam"))
}

func TestAddManyAppends(cur realm, t *testing.T) {
	reset()
	testing.SetRealm(testing.NewUserRealm(admin))
	AddMany(cross(cur), "4886,235,2024,FR,Paris")
	AddMany(cross(cur), "5237,490,2019,NL,Amsterdam;4576,483,0,FR,Lyon")
	uassert.Equal(t, "4886,235,2024,FR,Paris\n5237,490,2019,NL,Amsterdam\n4576,483,0,FR,Lyon", Cities())
}

func TestAddManyRejects(cur realm, t *testing.T) {
	reset()
	testing.SetRealm(testing.NewUserRealm(admin))
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
		uassert.AbortsContains(t, cur, "", func() { AddMany(cross(cur), bad) }, bad)
	}
	uassert.Equal(t, 0, len(lines()))
}

func TestRemoveMany(cur realm, t *testing.T) {
	reset()
	testing.SetRealm(testing.NewUserRealm(admin))
	AddMany(cross(cur), "4886,235,2024,FR,Paris;5237,490,2019,NL,Amsterdam;4576,483,0,FR,Lyon;5250,1340,0,DE,Berlin")
	RemoveMany(cross(cur), "NL,Amsterdam")
	uassert.Equal(t, "4886,235,2024,FR,Paris\n4576,483,0,FR,Lyon\n5250,1340,0,DE,Berlin", visits)
	RemoveMany(cross(cur), "DE,Berlin;FR,Paris")
	uassert.Equal(t, "4576,483,0,FR,Lyon", visits)
	RemoveMany(cross(cur), "FR,Lyon")
	uassert.Equal(t, "", visits)
	uassert.AbortsContains(t, cur, "not on the map: FR,Paris", func() { RemoveMany(cross(cur), "FR,Paris") })
}

func TestRemoveManyNeedsWholeKey(cur realm, t *testing.T) {
	reset()
	testing.SetRealm(testing.NewUserRealm(admin))
	AddMany(cross(cur), "4886,235,2024,FR,Paris;5237,490,2019,NL,Amsterdam")
	for _, key := range []string{"R,Paris", "FR,Pari", "Paris", "FR,Paris\n5237,490,2019,NL,Amsterdam", "", "5,2019,NL,Amsterdam"} {
		uassert.AbortsContains(t, cur, "not on the map", func() { RemoveMany(cross(cur), key) }, key)
	}
	uassert.Equal(t, 2, len(lines()))
}

func TestOnlyAdmin(cur realm, t *testing.T) {
	reset()
	testing.SetRealm(testing.NewUserRealm(mallory))
	uassert.AbortsContains(t, cur, "unauthorized", func() { AddMany(cross(cur), "4886,235,2024,FR,Paris") })
	uassert.AbortsContains(t, cur, "unauthorized", func() { RemoveMany(cross(cur), "FR,Paris") })
}

func TestRenderBadPath(t *testing.T) {
	uassert.True(t, strings.Contains(Render("nope"), "There is no such page."))
}
