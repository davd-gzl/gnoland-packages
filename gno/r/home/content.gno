package home

// defaultSlots seeds the page at deploy time. Later edits go through Set.
var defaultSlots = []struct{ name, body string }{
	{"order", "header,banner,reviews,gno,projects,peerdev,game,hearts"},
	{"activity", "title merged pull requests; series gnolang/gno,gno-onboarding-bot,gnodaokit,awesome-gno,Others; mark Peer Dev commits; 2025-05 0 0 0 0 0 *; 2025-06 0 0 0 0 0 *; 2025-07 4 0 0 0 1 *; 2025-08 0 0 5 0 3 *; 2025-09 4 0 0 0 0 *; 2025-10 1 0 0 0 5 *; 2025-11 1 0 1 0 1 *; 2025-12 1 0 0 0 0; 2026-01 1 0 0 0 0; 2026-02 6 0 0 0 0; 2026-03 5 0 0 0 0; 2026-04 12 0 0 0 2; 2026-05 7 0 0 0 1; 2026-06 16 6 0 0 1; 2026-07 8 0 0 5 0; 2026-08 2 0 0 0 0; 2026-09 2 0 0 0 3"},
	{"reviewactivity", "title reviews; series gnolang/gno,gnolove,gnodaokit,community,gno-onboarding-bot,Others; 2025-05 0 0 0 0 0 1; 2025-06 0 0 0 0 0 0; 2025-07 0 0 0 0 0 0; 2025-08 0 0 11 0 0 0; 2025-09 11 2 2 2 0 1; 2025-10 2 10 0 3 0 0; 2025-11 5 1 0 0 0 0; 2025-12 13 0 0 0 0 0; 2026-01 24 0 0 0 0 0; 2026-02 32 1 0 0 0 1; 2026-03 47 0 0 0 0 0; 2026-04 30 0 0 0 0 1; 2026-05 34 0 0 0 0 0; 2026-06 49 0 0 0 5 0; 2026-07 51 0 1 0 0 0; 2026-08 35 0 0 0 0 0; 2026-09 24 0 0 0 0 5"},
	{"header", `# David G.

Developer engineer at Samouraï Coop.

[GitHub](https://github.com/davd-gzl) · [samcrew](/u/samcrew) · [Peer Dev on YouTube](https://www.youtube.com/@peerdevlearning)`},
	{"gno", `## Gno core

Contributing to gno.land since May 2025, with 70 pull requests merged into gnolang/gno as of 24 September 2026. [All of them are on GitHub](https://github.com/gnolang/gno/pulls?q=is%3Apr+author%3Adavd-gzl+is%3Amerged).

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
