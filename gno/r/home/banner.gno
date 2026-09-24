package home

import (
	"encoding/base64"
	"strconv"
	"strings"
)

// Two charts, merged pull requests and reviews per month, each stacked by
// repository. A realm cannot read GitHub, so each chart's numbers live in a
// section, "activity" and "reviewactivity", and scripts/activity.py prints the
// Set commands that refresh them. A section reads, lines split by ";":
//
//	title merged pull requests
//	series gnolang/gno,gnodaokit,Others
//	mark Peer Dev commits
//	2025-07 4 0 1 *
//
// Each month row carries one count per series; a trailing "*" draws the mark.

const (
	activitySlot       = "activity"
	reviewActivitySlot = "reviewactivity"
	chartWidth         = 720
	chartX             = 24
	maxBar             = 90
	markFill           = "#fbbf24"
	othersFill         = "#94a3b8"
)

var (
	monthNames  = []string{"Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"}
	seriesFills = []string{"#3ddc97", "#7aa2ff", "#c084fc", "#f472b6", "#2dd4bf"}
)

type month struct {
	label  string // "Jul", or "Jan 26" where a year starts
	counts []int
	marked bool
}

type activity struct {
	noun, markLabel string
	series          []string
	months          []month
}

// parseActivity reads a chart section; a malformed month row is skipped.
func parseActivity(spec string) activity {
	var a activity
	for _, line := range strings.Split(strings.ReplaceAll(spec, "\n", ";"), ";") {
		line = strings.TrimSpace(line)
		switch {
		case strings.HasPrefix(line, "title "):
			a.noun = strings.TrimSpace(line[6:])
		case strings.HasPrefix(line, "series "):
			for _, s := range strings.Split(line[7:], ",") {
				a.series = append(a.series, strings.TrimSpace(s))
			}
		case strings.HasPrefix(line, "mark "):
			a.markLabel = strings.TrimSpace(line[5:])
		default:
			if m, ok := parseMonth(line, len(a.series), len(a.months) == 0); ok {
				a.months = append(a.months, m)
			}
		}
	}
	return a
}

func parseMonth(line string, width int, first bool) (month, bool) {
	fields := strings.Fields(line)
	if len(fields) < 1 || len(fields[0]) != 7 || fields[0][4] != '-' {
		return month{}, false
	}
	m, err := strconv.Atoi(fields[0][5:])
	if err != nil || m < 1 || m > 12 {
		return month{}, false
	}
	out := month{label: monthNames[m-1]}
	if m == 1 || first {
		out.label += " " + fields[0][2:4]
	}
	rest := fields[1:]
	if len(rest) > 0 && rest[len(rest)-1] == "*" {
		out.marked = true
		rest = rest[:len(rest)-1]
	}
	if len(rest) != width || width == 0 {
		return month{}, false
	}
	for _, f := range rest {
		n, err := strconv.Atoi(f)
		if err != nil || n < 0 {
			return month{}, false
		}
		out.counts = append(out.counts, n)
	}
	return out, true
}

func seriesFill(i int, name string) string {
	if name == "Others" {
		return othersFill
	}
	return seriesFills[i%len(seriesFills)]
}

// renderChart draws a chart section as a markdown image, or "" when it holds
// no month.
func renderChart(slot string) string {
	a := parseActivity(Get(slot))
	if len(a.months) == 0 || a.noun == "" {
		return ""
	}
	totals := make([]int, len(a.series))
	peak, sum := 1, 0
	for _, m := range a.months {
		monthSum := 0
		for i, n := range m.counts {
			totals[i] += n
			monthSum += n
		}
		sum += monthSum
		if monthSum > peak {
			peak = monthSum
		}
	}

	// Legend entries flow left to right and wrap, so the chart sits below them.
	type entry struct {
		fill, text string
		dot        bool
	}
	var legend []entry
	for i, s := range a.series {
		legend = append(legend, entry{seriesFill(i, s), s + " " + strconv.Itoa(totals[i]), false})
	}
	if a.markLabel != "" {
		legend = append(legend, entry{markFill, a.markLabel, true})
	}
	var b strings.Builder
	var items strings.Builder
	x, y := chartX, 96
	for _, e := range legend {
		w := 24 + len(e.text)*7
		if x+w > chartWidth-chartX {
			x, y = chartX, y+22
		}
		if e.dot {
			circle(&items, x+6, y-4, 5, e.fill)
		} else {
			rect(&items, x, y-10, 12, 12, 0, e.fill)
		}
		text(&items, x+18, y, "s", "#ffffff", e.text)
		x += w + 12
	}
	baseline := y + 30 + maxBar
	height := baseline + 34
	if a.markLabel != "" {
		height += 14
	}

	sh, sw := strconv.Itoa(height), strconv.Itoa(chartWidth)
	b.WriteString(`<svg xmlns="http://www.w3.org/2000/svg" width="` + sw + `" height="` + sh + `" viewBox="0 0 ` + sw + ` ` + sh + `">`)
	b.WriteString("<style>.h{font:700 26px sans-serif}.s{font:13px sans-serif}" +
		".n{font:600 11px sans-serif;text-anchor:middle}.m{font:11px sans-serif;text-anchor:middle}</style>")
	rect(&b, 0, 0, chartWidth, height, 12, "#10231c")
	text(&b, chartX, 42, "h", "#ffffff", strconv.Itoa(sum)+" "+a.noun)
	text(&b, chartX, 66, "s", "#9fc9b4", "per month, on public gno.land repositories")
	b.WriteString(items.String())

	step := (chartWidth - 2*chartX) / len(a.months)
	barW := step * 2 / 3
	for i, m := range a.months {
		bx := chartX + i*step + (step-barW)/2
		mid := bx + barW/2
		top, total := baseline, 0
		for j, n := range m.counts {
			h := n * maxBar / peak
			if n > 0 && h == 0 {
				h = 1
			}
			if h == 0 {
				continue
			}
			top -= h
			total += n
			rect(&b, bx, top, barW, h, 0, seriesFill(j, a.series[j]))
		}
		if total == 0 {
			rect(&b, bx, baseline-2, barW, 2, 0, "#2c4a3e")
		} else {
			text(&b, mid, top-5, "n", "#ffffff", strconv.Itoa(total))
		}
		text(&b, mid, baseline+18, "m", "#9fc9b4", m.label)
		if m.marked {
			circle(&b, mid, baseline+32, 4, markFill)
		}
	}
	b.WriteString("</svg>")
	alt := strings.ToUpper(a.noun[:1]) + a.noun[1:] + " per month, by repository"
	return "![" + alt + "](data:image/svg+xml;base64," + base64.StdEncoding.EncodeToString([]byte(b.String())) + ")\n"
}

// The chart is written straight into one builder: p/nt/svg formats each
// element with ufmt and appends it to a growing string, which cost this page
// close to a billion gas.

func rect(b *strings.Builder, x, y, w, h, r int, fill string) {
	b.WriteString(`<rect x="` + strconv.Itoa(x) + `" y="` + strconv.Itoa(y) + `" width="` + strconv.Itoa(w) +
		`" height="` + strconv.Itoa(h) + `" rx="` + strconv.Itoa(r) + `" fill="` + fill + `"/>`)
}

func circle(b *strings.Builder, cx, cy, r int, fill string) {
	b.WriteString(`<circle cx="` + strconv.Itoa(cx) + `" cy="` + strconv.Itoa(cy) + `" r="` + strconv.Itoa(r) + `" fill="` + fill + `"/>`)
}

// text writes s as SVG text; callers pass repository names and numbers, so it
// escapes the three characters that could break the markup.
func text(b *strings.Builder, x, y int, class, fill, s string) {
	s = strings.NewReplacer("&", "&amp;", "<", "&lt;", ">", "&gt;").Replace(s)
	b.WriteString(`<text x="` + strconv.Itoa(x) + `" y="` + strconv.Itoa(y) + `" class="` + class + `" fill="` + fill + `">` + s + `</text>`)
}
