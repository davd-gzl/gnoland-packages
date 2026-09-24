package home

import (
	"encoding/base64"
	"strings"
	"testing"

	"gno.land/p/nt/uassert/v0"
)

func TestParseActivity(t *testing.T) {
	a := parseActivity("title reviews; series gnolang/gno,Others; mark Peer Dev\n" +
		"2025-12 3 1 *; 2026-01 0 0; bad; 2026-13 1 1; 2026-02 x 1; 2026-02 5; 2026-02 5 2")
	uassert.Equal(t, "reviews", a.noun)
	uassert.Equal(t, "Peer Dev", a.markLabel)
	uassert.Equal(t, 2, len(a.series))
	uassert.Equal(t, 3, len(a.months))
	uassert.Equal(t, "Dec 25", a.months[0].label)
	uassert.True(t, a.months[0].marked)
	uassert.Equal(t, 1, a.months[0].counts[1])
	uassert.Equal(t, "Jan 26", a.months[1].label)
	uassert.False(t, a.months[1].marked)
	uassert.Equal(t, "Feb", a.months[2].label)
	uassert.Equal(t, 2, a.months[2].counts[1])
}

func decodeChart(t *testing.T, out, alt string) string {
	prefix := "![" + alt + "](data:image/svg+xml;base64,"
	uassert.True(t, strings.HasPrefix(out, prefix), "prefix of "+alt)
	raw, err := base64.StdEncoding.DecodeString(strings.TrimSuffix(out[len(prefix):], ")\n"))
	uassert.NoError(t, err)
	return string(raw)
}

func TestCharts(t *testing.T) {
	prs := decodeChart(t, renderChart(activitySlot), "Merged pull requests per month, by repository")
	for _, want := range []string{
		">104 merged pull requests</text>", ">gnolang/gno 70</text>", ">gnodaokit 6</text>",
		">Others 17</text>", ">Peer Dev commits</text>", ">May 25</text>", ">Jan 26</text>",
		">23</text>", // June 2026: 16 + 6 + 1
	} {
		uassert.True(t, strings.Contains(prs, want), "pull requests chart: "+want)
	}
	// One mark per month with Peer Dev commits, May to November 2025, plus the legend's.
	uassert.Equal(t, 8, strings.Count(prs, `fill="#fbbf24"`))

	revs := decodeChart(t, renderChart(reviewActivitySlot), "Reviews per month, by repository")
	for _, want := range []string{">404 reviews</text>", ">gnolang/gno 357</text>", ">gnolove 14</text>"} {
		uassert.True(t, strings.Contains(revs, want), "reviews chart: "+want)
	}
	uassert.False(t, strings.Contains(revs, "#fbbf24"))

	page := Render("")
	uassert.True(t, strings.Index(page, "Merged pull requests per month") < strings.Index(page, "Reviews per month"))
}

func TestChartEmpty(cur realm, t *testing.T) {
	testing.SetRealm(testing.NewUserRealm(admin))
	old := Get(activitySlot)
	Set(cross(cur), activitySlot, "")
	uassert.Equal(t, "", renderChart(activitySlot))
	Set(cross(cur), activitySlot, old)
	uassert.AbortsWithMessage(t, cur, "reserved section: banner", func() { Set(cross(cur), "banner", "x") })
	uassert.AbortsWithMessage(t, cur, "reserved section: reviews", func() { Set(cross(cur), "reviews", "x") })
}
