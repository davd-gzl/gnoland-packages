# gnoland-packages

David G.'s packages and realms for [gno.land](https://gno.land).

| Directory | Package path |
| --- | --- |
| [`gno/r/home`](gno/r/home) | `gno.land/r/g1rayfgklwl0aspz488wvrcrvt7t2quy6q06lgk2/home` |

## home

The profile page gnoweb shows for the address. Each section is markdown stored
on chain, so the text changes with one transaction instead of a redeploy. The
realm is `private = true` in its [`gnomod.toml`](gno/r/home/gnomod.toml): no
other package can import it, and its deployer can replace it at the same path.
A redeploy starts from a fresh state: every heart and every section edited
with `Set` is gone, and the deploy pays its storage deposit again.

The page opens on a banner adapted from the one every Samouraï home realm
shares, then the bio and three charts drawn on chain: merged pull requests and
reviews per month, and a ring of merged `gnolang/gno` pull requests by area.
For visitors it also carries:

- **Gnordle**, a five-letter word game at `:wordle`. Everyone gets the same
  word each day, and past guesses travel in the page link, so playing needs no
  wallet.
- **Hearts**: one transaction sends one, one per address, and a wall draws
  them, ten rows at most with a count of the rest.

Edit a section, `header` for example, from the admin key:

```bash
gnokey maketx call -pkgpath gno.land/r/g1rayfgklwl0aspz488wvrcrvt7t2quy6q06lgk2/home \
  -func Set -args header -args "New bio." \
  -gas-fee 5000ugnot -gas-wanted 5000000 -max-deposit 1000000ugnot \
  -chainid gnoland-1 -remote https://rpc.gno.land:443 <key>
```

The `order` section lists which sections show, comma separated. `hero`,
`banner`, `reviews`, `areachart`, `game` and `hearts` are drawn by the realm
and cannot be set. The banner's text is the `herotext` section, `key value`
pairs split by `;`, such as `title David G.; subtitle Developer engineer`.

The monthly charts count public repositories of the gnolang, gnoverse and
samouraiworld organisations. A repository with fewer than five joins Others,
and Peer Dev commits stack on top in amber, drawn one step per ten commits. A
striped green bar beside each month counts the `gnolang/gno` pull requests
opened that month, and each chart shows the day it was counted. A realm cannot
read GitHub, so the numbers are a snapshot in the `activity`, `reviewactivity`
and `areas` sections. `scripts/activity.py` counts them again with `gh` and
prints the three `gnokey` commands that store them:

```bash
./scripts/activity.py
```

## Test

Run from the repository root, where `gnowork.toml` marks the workspace:

```bash
gno test ./gno/...
```
