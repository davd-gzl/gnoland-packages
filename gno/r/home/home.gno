// Package home is David G.'s profile page on gno.land.
//
// gnoweb renders a profile by calling Render("") on the realm at exactly
// /r/<address>/home, so this path carries no /vN suffix.
//
// The page is a list of sections, each a markdown body the owner edits with
// one Set transaction, so changing the text never needs a redeploy. The slot
// named "order" lists the sections to show. Four sections are drawn rather
// than stored: "banner" and "reviews", the activity charts, "game", today's
// Gnordle, and "hearts", the heart count.
package home

import (
	"strconv"
	"strings"

	"chain/runtime"

	"gno.land/p/nt/avl/v0"
)

// admin is the only address allowed to edit sections.
const admin = address("g1rayfgklwl0aspz488wvrcrvt7t2quy6q06lgk2")

const (
	home       = "/r/g1rayfgklwl0aspz488wvrcrvt7t2quy6q06lgk2/home"
	orderSlot  = "order"
	maxNameLen = 32
)

var (
	slots  = avl.NewTree() // section name -> markdown body
	hearts = avl.NewTree() // address -> block height of the heart
)

func init() {
	for _, s := range defaultSlots {
		slots.Set(s.name, s.body)
	}
}

// Set creates or replaces one section. Only the admin can call it.
func Set(cur realm, name, body string) {
	assertAdmin(cur)
	if name == "" || len(name) > maxNameLen || strings.ContainsAny(name, ", \n") {
		panic("invalid section name")
	}
	if name == "banner" || name == "reviews" || name == "game" || name == "hearts" {
		panic("reserved section: " + name)
	}
	slots.Set(name, body)
}

// Delete removes one section. Only the admin can call it.
func Delete(cur realm, name string) {
	assertAdmin(cur)
	if _, ok := slots.Remove(name); !ok {
		panic("no such section: " + name)
	}
}

// Get returns a section's markdown, or "" when it does not exist.
func Get(name string) string {
	if v := slots.Get(name); v != nil {
		return v.(string)
	}
	return ""
}

// Heart records one heart from the caller. Each address can send exactly one.
func Heart(cur realm) {
	from := cur.Previous().Address().String()
	if hearts.Has(from) {
		panic("already sent: one heart per address")
	}
	hearts.Set(from, runtime.ChainHeight())
}

// Hearts returns how many distinct addresses sent a heart.
func Hearts() int { return hearts.Size() }

// HasHeart reports whether addr already sent a heart.
func HasHeart(addr address) bool { return hearts.Has(addr.String()) }

func assertAdmin(cur realm) {
	if cur.Previous().Address() != admin {
		panic("unauthorized")
	}
}

// Render serves:
//
//	""             the profile page
//	"wordle/..."   the Gnordle game
//	"hearts"       every address that sent a heart
func Render(path string) string {
	switch {
	case path == "":
		return renderPage()
	case path == "wordle" || strings.HasPrefix(path, "wordle/") || strings.HasPrefix(path, "wordle?"):
		return renderWordle(path)
	case path == "hearts":
		return renderHearts()
	}
	return "# Not found\n\n[Back home](" + home + ")\n"
}

func renderPage() string {
	var b strings.Builder
	for _, name := range strings.Split(Get(orderSlot), ",") {
		switch name = strings.TrimSpace(name); name {
		case "":
		case "banner":
			b.WriteString(renderChart(activitySlot))
		case "reviews":
			b.WriteString(renderChart(reviewActivitySlot))
		case "game":
			b.WriteString(renderGameTeaser())
		case "hearts":
			b.WriteString(renderHeartsTeaser())
		default:
			b.WriteString(Get(name))
		}
		b.WriteString("\n\n")
	}
	b.WriteString("---\n\nThis page is a contract: [gno.land" + home + "](" + home + "$source).\n")
	return b.String()
}

func renderHeartsTeaser() string {
	return "## Hearts\n\n**" + strconv.Itoa(Hearts()) + "** so far. " +
		"[Send one](" + home + "$help&func=Heart): one transaction, one per address, " +
		"forever on chain. [See who did](" + home + ":hearts).\n"
}

func renderHearts() string {
	var b strings.Builder
	b.WriteString("# Hearts\n\n")
	if hearts.Size() == 0 {
		b.WriteString("Nobody yet. [Be the first](" + home + "$help&func=Heart).\n")
	}
	hearts.Iterate("", "", func(addr string, h any) bool {
		b.WriteString("- " + addr + ", block " + strconv.FormatInt(h.(int64), 10) + "\n")
		return false
	})
	b.WriteString("\n[Back home](" + home + ")\n")
	return b.String()
}
