package home

// defaultSlots seeds the page at deploy time. Later edits go through Set.
var defaultSlots = []struct{ name, body string }{
	{"order", "header,banner,reviews,gno,projects,peerdev,game,hearts"},
	{"activity", "title merged pull requests; subtitle per month, on public gno.land repositories; series gnolang/gno,gno-onboarding-bot,gnodaokit,awesome-gno,Others,Peer Dev; scale Peer Dev,10,commits; outline gnolang/gno pull requests opened; updated 2026-09-24; 2025-05 0 0 0 0 0 25 | 0; 2025-06 0 0 0 0 0 87 | 2; 2025-07 4 0 0 0 1 48 | 3; 2025-08 0 0 5 0 3 27 | 0; 2025-09 4 0 0 0 0 14 | 9; 2025-10 1 0 0 0 5 15 | 0; 2025-11 1 0 1 0 1 18 | 7; 2025-12 1 0 0 0 0 0 | 7; 2026-01 1 0 0 0 0 0 | 8; 2026-02 6 0 0 0 0 0 | 11; 2026-03 5 0 0 0 0 0 | 21; 2026-04 12 0 0 0 2 0 | 17; 2026-05 7 0 0 0 1 0 | 19; 2026-06 16 6 0 0 1 0 | 7; 2026-07 8 0 0 5 0 0 | 15; 2026-08 2 0 0 0 0 0 | 3; 2026-09 2 0 0 0 3 0 | 2"},
	{"reviewactivity", "title reviews; subtitle per month, on the same repositories; series gnolang/gno,Others; updated 2026-09-24; 2025-05 0 1; 2025-06 0 0; 2025-07 0 0; 2025-08 0 11; 2025-09 11 7; 2025-10 2 13; 2025-11 5 1; 2025-12 13 0; 2026-01 24 0; 2026-02 32 2; 2026-03 47 0; 2026-04 30 1; 2026-05 34 0; 2026-06 49 5; 2026-07 51 1; 2026-08 35 0; 2026-09 24 5"},
	{"header", `# David G.

Developer engineer at [Samouraï Coop](https://www.samourai.world/).

[GitHub](https://github.com/davd-gzl) · [samcrew](/u/samcrew) · [Peer Dev on YouTube](https://www.youtube.com/@peerdevlearning) · [Personal wiki](https://davd-gzl.github.io/personal-wiki/)`},
	{"gno", `## Gno core

Contributing to [gno.land](https://gno.land) since May 2025, with 70 pull requests merged into [gnolang/gno](https://github.com/gnolang/gno) as of 24 September 2026. [All of them are on GitHub](https://github.com/gnolang/gno/pulls?q=is%3Apr+author%3Adavd-gzl+is%3Amerged).

| Field | Merged pull requests |
| --- | --- |
| Docs | 26 |
| GnoVM | 17 |
| Examples and realms | 14 |
| Chain: tm2, consensus, package loading | 9 |
| Tools: gnoweb, gnokey, gnodev | 4 |`},
	{"projects", `## Projects

| Project | What I did |
| --- | --- |
| [GnoVM, explained](https://samouraiworld.github.io/gno-agent-workspace/) | I wrote a guide to how the GnoVM works, for Go developers who have never opened it: parsing, type-checking, the preprocess pass, the stack machine, realm storage and gas. |
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
