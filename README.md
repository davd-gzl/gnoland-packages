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

It also carries two small things for visitors:

- **Gnordle**, a five-letter word game at `:wordle`. Everyone gets the same
  word each day, and past guesses travel in the page link, so playing needs no
  wallet.
- **Hearts**: one transaction sends one, one per address.

Edit a section, `header` for example, from the admin key:

```bash
gnokey maketx call -pkgpath gno.land/r/g1rayfgklwl0aspz488wvrcrvt7t2quy6q06lgk2/home \
  -func Set -args header -args "# David G.

New bio." \
  -gas-fee 1000000ugnot -gas-wanted 5000000 \
  -chainid gnoland-1 -remote https://rpc.gno.land:443 <key>
```

The `order` section lists which sections show, comma separated.

## Test

Run from the repository root, where `gnowork.toml` marks the workspace:

```bash
gno test ./gno/...
```
