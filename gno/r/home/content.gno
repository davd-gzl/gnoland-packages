package home

// defaultSlots seeds the page at deploy time. Later edits go through Set.
var defaultSlots = []struct{ name, body string }{
	{"order", "header,gno,projects,peerdev,game,hearts"},
	{"header", `# David G.

Developer engineer at Samouraï Coop.

[GitHub](https://github.com/davd-gzl) · [Peer Dev on YouTube](https://www.youtube.com/@peerdevlearning)`},
	{"gno", `## Gno core

Contributing to gno.land since June 2025, with 70 pull requests merged into gnolang/gno as of 24 September 2026. [All of them are on GitHub](https://github.com/gnolang/gno/pulls?q=is%3Apr+author%3Adavd-gzl+is%3Amerged).

| Field | Merged pull requests |
| --- | --- |
| Docs | 26 |
| GnoVM | 17 |
| Examples and realms | 14 |
| Chain: tm2, consensus, package loading | 9 |
| Tools: gnoweb, gnokey, gnodev | 4 |

### Highlights

| Pull request | Area | What it does |
| --- | --- | --- |
| [#5592](https://github.com/gnolang/gno/pull/5592) | Docs | Adds the getting started guide |
| [#5016](https://github.com/gnolang/gno/pull/5016) | Docs | Adds new r/docs examples: realms that teach gno.land by running |
| [#5950](https://github.com/gnolang/gno/pull/5950) | Docs | Adds READMEs for the p/nt packages |
| [#5656](https://github.com/gnolang/gno/pull/5656) | Docs | Consolidates and cleans up the builder documentation |
| [#4990](https://github.com/gnolang/gno/pull/4990) | Docs | Explains when to use a map and when an AVL tree |
| [#5385](https://github.com/gnolang/gno/pull/5385) | Stdlib | Adds errors.Unwrap, errors.Is and errors.Join |
| [#5314](https://github.com/gnolang/gno/pull/5314) | avl | Makes Get return nil for a missing key, across 94 files |
| [#4717](https://github.com/gnolang/gno/pull/4717) | GovDAO | Requires voters to hold a registered username |
| [#5217](https://github.com/gnolang/gno/pull/5217) | GnoVM | Meters gas correctly for switch cases |`},
	{"projects", `## Projects

| Project | What I did |
| --- | --- |
| [gnodaokit](https://github.com/samouraiworld/gnodaokit) | A toolkit for building DAOs on gno.land. [I contributed](https://github.com/samouraiworld/gnodaokit/pulls?q=is%3Apr+author%3Adavd-gzl+is%3Amerged) documentation, contributor instructions and a guided setup for the demo DAO. |
| [awesome-gno](https://github.com/gnoverse/awesome-gno) | The curated list of gno.land resources. [I contributed](https://github.com/gnoverse/awesome-gno/pulls?q=is%3Apr+author%3Adavd-gzl+is%3Amerged) new entries, Peer Dev, r/docs and tx-exports among them, and a cleanup of moved links and outdated tutorials. |`},
	{"peerdev", `## Peer Dev

I teach gno.land on [Peer Dev](https://www.youtube.com/@peerdevlearning), a YouTube channel of developer tutorials, from an empty machine to GovDAO. [Watch the gno.land playlist](https://www.youtube.com/playlist?list=PLJZrQikyfMc-kBojXgAojOz4UQPuq4DiY).

The videos date from 2025, so some commands and screens are out of date. The main ideas still hold.

- [Deploying Gno Packages](https://www.youtube.com/watch?v=B7bSreCwIls)
- [Create your first dApp](https://www.youtube.com/watch?v=z5Qtc0Nuyqg)
- [Governance DAO (GovDAO)](https://www.youtube.com/watch?v=jM-6ezyn_v4)
- [Interrealm specification](https://www.youtube.com/watch?v=JJju7-GeRbA)
- [Gno VS Solidity](https://www.youtube.com/watch?v=Oi77hvJCVbU)`},
}
