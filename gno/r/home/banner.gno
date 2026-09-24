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
//	series gnolang/gno,gnodaokit,Others,Peer Dev
//	scale Peer Dev,10,commits
//	outline gnolang/gno pull requests opened
//	updated 2026-09-24
//	2025-07 4 0 1 48 | 3
//
// Each month row carries one count per series. A scaled series counts another
// unit: its bars are drawn at one step per 10, and it stays out of the totals.
// The count after "|" draws a striped bar in the first series' colour beside
// the stack.

const (
	activitySlot       = "activity"
	reviewActivitySlot = "reviewactivity"
	chartWidth         = 720
	chartX             = 24
	maxBar             = 90
	scaledFill         = "#fbbf24"
	othersFill         = "#94a3b8"
)

var (
	monthNames  = []string{"Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"}
	seriesFills = []string{"#3ddc97", "#7aa2ff", "#c084fc", "#f472b6", "#2dd4bf"}
)

type month struct {
	label   string // "Jul", or "Jan 26" where a year starts
	counts  []int
	outline int
}

type activity struct {
	noun      string
	series    []string
	scaled    string // the series counted in another unit, or ""
	scaleDiv  int
	scaleUnit string
	outline   string // the striped bar's legend, or ""
	updated   string // "24 Sep 2026", the day the numbers were counted
	months    []month
}

// parseActivity reads a chart section; a malformed line is skipped.
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
		case strings.HasPrefix(line, "scale "):
			parts := strings.Split(line[6:], ",")
			if len(parts) != 3 {
				continue
			}
			div, err := strconv.Atoi(strings.TrimSpace(parts[1]))
			if err != nil || div < 1 {
				continue
			}
			a.scaled, a.scaleDiv, a.scaleUnit = strings.TrimSpace(parts[0]), div, strings.TrimSpace(parts[2])
		case strings.HasPrefix(line, "outline "):
			a.outline = strings.TrimSpace(line[8:])
		case strings.HasPrefix(line, "updated "):
			a.updated = formatDay(strings.TrimSpace(line[8:]))
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
	counts := fields[1:]
	if n := len(counts); n >= 2 && counts[n-2] == "|" {
		v, err := strconv.Atoi(counts[n-1])
		if err != nil || v < 0 {
			return month{}, false
		}
		out.outline, counts = v, counts[:n-2]
	}
	if len(counts) != width || width == 0 {
		return month{}, false
	}
	for _, f := range counts {
		n, err := strconv.Atoi(f)
		if err != nil || n < 0 {
			return month{}, false
		}
		out.counts = append(out.counts, n)
	}
	return out, true
}

// formatDay turns 2026-09-24 into "24 Sep 2026", or "" when it is not a date.
func formatDay(s string) string {
	if len(s) != 10 || s[4] != '-' || s[7] != '-' {
		return ""
	}
	m, err1 := strconv.Atoi(s[5:7])
	d, err2 := strconv.Atoi(s[8:])
	if err1 != nil || err2 != nil || m < 1 || m > 12 || d < 1 || d > 31 {
		return ""
	}
	return strconv.Itoa(d) + " " + monthNames[m-1] + " " + s[:4]
}

func (a activity) fill(i int) string {
	switch a.series[i] {
	case "Others":
		return othersFill
	case a.scaled:
		return scaledFill
	}
	return seriesFills[i%len(seriesFills)]
}

// drawn returns how many steps series i takes in the bar, rounding a scaled
// count up so a quiet month still shows.
func (a activity) drawn(i, n int) int {
	if a.series[i] == a.scaled {
		return (n + a.scaleDiv - 1) / a.scaleDiv
	}
	return n
}

// renderChart draws a chart section as a markdown image, or "" when it holds
// no month.
func renderChart(slot string) string {
	a := parseActivity(Get(slot))
	if len(a.months) == 0 || a.noun == "" {
		return ""
	}
	totals := make([]int, len(a.series))
	peak, sum, outlined := 1, 0, 0
	for _, m := range a.months {
		outlined += m.outline
		if m.outline > peak {
			peak = m.outline
		}
		steps := 0
		for i, n := range m.counts {
			totals[i] += n
			steps += a.drawn(i, n)
			if a.series[i] != a.scaled {
				sum += n
			}
		}
		if steps > peak {
			peak = steps
		}
	}

	// Legend entries flow left to right and wrap, so the chart sits below them.
	var b, items strings.Builder
	x, y := chartX, 96
	for i, s := range a.series {
		label := s + " " + strconv.Itoa(totals[i])
		if s == a.scaled {
			label += " " + a.scaleUnit + ", drawn 1 per " + strconv.Itoa(a.scaleDiv)
		}
		w := 24 + len(label)*7
		if x+w > chartWidth-chartX {
			x, y = chartX, y+22
		}
		rect(&items, x, y-10, 12, 12, 0, a.fill(i))
		text(&items, x+18, y, "s", "#ffffff", label)
		x += w + 12
	}
	if a.outline != "" {
		label := a.outline + " " + strconv.Itoa(outlined)
		w := 24 + len(label)*7
		if x+w > chartWidth-chartX {
			x, y = chartX, y+22
		}
		rect(&items, x, y-10, 12, 12, 0, "url(#o)")
		text(&items, x+18, y, "s", "#ffffff", label)
	}
	baseline := y + 30 + maxBar
	height := baseline + 34

	sh, sw := strconv.Itoa(height), strconv.Itoa(chartWidth)
	b.WriteString(`<svg xmlns="http://www.w3.org/2000/svg" width="` + sw + `" height="` + sh + `" viewBox="0 0 ` + sw + ` ` + sh + `">`)
	b.WriteString("<style>.h{font:700 26px sans-serif}.s{font:13px sans-serif}" +
		".n{font:600 11px sans-serif;text-anchor:middle}.m{font:11px sans-serif;text-anchor:middle}" +
		".u{font:12px sans-serif;text-anchor:end}</style>")
	b.WriteString(`<defs><pattern id="o" width="5" height="5" patternUnits="userSpaceOnUse" patternTransform="rotate(45)">` +
		`<rect width="2" height="5" fill="` + seriesFills[0] + `"/></pattern></defs>`)
	rect(&b, 0, 0, chartWidth, height, 12, "#10231c")
	text(&b, chartX, 42, "h", "#ffffff", strconv.Itoa(sum)+" "+a.noun)
	text(&b, chartX, 66, "s", "#9fc9b4", "per month, on public gno.land repositories")
	if a.updated != "" {
		text(&b, chartWidth-chartX, 42, "u", "#9fc9b4", "updated "+a.updated)
	}
	b.WriteString(items.String())

	step := (chartWidth - 2*chartX) / len(a.months)
	barW := step * 2 / 3
	stripeW := 0
	if a.outline != "" {
		// The stack and the striped bar share the month's slot side by side.
		barW, stripeW = step*2/5, step/4
	}
	for i, m := range a.months {
		bx := chartX + i*step + (step-barW-stripeW)/2
		mid := bx + (barW+stripeW)/2
		if stripeW > 0 && m.outline > 0 {
			h := m.outline * maxBar / peak
			if h == 0 {
				h = 1
			}
			rect(&b, bx+barW+2, baseline-h, stripeW, h, 0, "url(#o)")
		}
		top, total := baseline, 0
		for j, n := range m.counts {
			d := a.drawn(j, n)
			h := d * maxBar / peak
			if d > 0 && h == 0 {
				h = 1
			}
			if h == 0 {
				continue
			}
			top -= h
			if a.series[j] != a.scaled {
				total += n
			}
			rect(&b, bx, top, barW, h, 0, a.fill(j))
		}
		if top == baseline {
			rect(&b, bx, baseline-2, barW, 2, 0, "#2c4a3e")
		} else if total > 0 {
			text(&b, bx+barW/2, top-5, "n", "#ffffff", strconv.Itoa(total))
		}
		text(&b, mid, baseline+18, "m", "#9fc9b4", m.label)
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

// text writes s as SVG text; callers pass repository names and numbers, so it
// escapes the three characters that could break the markup.
func text(b *strings.Builder, x, y int, class, fill, s string) {
	s = strings.NewReplacer("&", "&amp;", "<", "&lt;", ">", "&gt;").Replace(s)
	b.WriteString(`<text x="` + strconv.Itoa(x) + `" y="` + strconv.Itoa(y) + `" class="` + class + `" fill="` + fill + `">` + s + `</text>`)
}
