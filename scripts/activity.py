#!/usr/bin/env python3
"""Prints the gnokey commands that refresh the two charts on the home page.

    ./scripts/activity.py [github-login] [gnokey-key]

One chart counts merged pull requests per month, the other pull request
reviews, both on public repositories of the gnolang, gnoverse and samouraiworld
organisations. A repository with fewer than MIN_OWN in a chart joins Others.
A hollow bar beside each month counts the gnolang/gno pull requests opened
that month, merged or not, since a pull request often merges months later.
Peer Dev commits stack on top as their own series, drawn at one step per
SCALE_DIV commits, since a commit is a much smaller unit than a pull request.
"""

import collections
import datetime
import json
import subprocess
import sys

ORGS = ("gnolang", "gnoverse", "samouraiworld")
SKIP = {  # automated workspaces and repositories outside gno.land
    "samouraiworld/gno-agent-workspace",
    "samouraiworld/samourai-visio",
    "samouraiworld/zenao",
}
SCALED_REPO, SCALED_NAME, SCALE_DIV = "samouraiworld/peerdev", "Peer Dev", 10
MIN_OWN = 5
PKG = "gno.land/r/g1rayfgklwl0aspz488wvrcrvt7t2quy6q06lgk2/home"

login = sys.argv[1] if len(sys.argv) > 1 else "davd-gzl"
key = sys.argv[2] if len(sys.argv) > 2 else "davd-samourai-multisig"


def gh(*args):
    return subprocess.check_output(("gh",) + args, text=True)


def counted(repo):
    return repo.split("/")[0] in ORGS and repo not in SKIP


def pull_requests():
    out = []
    for org in ORGS:
        rows = json.loads(gh("search", "prs", "--author", login, "--merged",
                             "--visibility", "public", "--owner", org,
                             "--limit", "1000", "--json", "repository,closedAt"))
        out += [(r["closedAt"][:7], r["repository"]["nameWithOwner"]) for r in rows]
    return [r for r in out if counted(r[1])]


def reviews():
    query = """query($login:String!,$from:DateTime!,$to:DateTime!,$after:String){
      user(login:$login){contributionsCollection(from:$from,to:$to){
        pullRequestReviewContributions(first:100,after:$after){
          pageInfo{hasNextPage endCursor}
          nodes{occurredAt pullRequest{repository{nameWithOwner isPrivate}}}}}}}"""
    out, year, now = [], 2023, datetime.datetime.now(datetime.timezone.utc)
    while year <= now.year:  # the API answers at most one year per query
        after = None
        while True:
            args = ["api", "graphql", "-f", "query=" + query, "-f", "login=" + login,
                    "-f", f"from={year}-01-01T00:00:00Z", "-f", f"to={year}-12-31T23:59:59Z"]
            if after:
                args += ["-f", "after=" + after]
            page = json.loads(gh(*args))["data"]["user"]["contributionsCollection"]["pullRequestReviewContributions"]
            for n in page["nodes"]:
                repo = n["pullRequest"]["repository"]
                if not repo["isPrivate"] and counted(repo["nameWithOwner"]):
                    out.append((n["occurredAt"][:7], repo["nameWithOwner"]))
            if not page["pageInfo"]["hasNextPage"]:
                break
            after = page["pageInfo"]["endCursor"]
        year += 1
    return out


def opened_gno():
    rows = json.loads(gh("search", "prs", "--author", login, "--repo", "gnolang/gno",
                         "--limit", "1000", "--json", "createdAt"))
    return collections.Counter(r["createdAt"][:7] for r in rows)


def scaled_commits():
    dates = gh("api", "--paginate", f"repos/{SCALED_REPO}/commits?author={login}&per_page=100",
               "--jq", ".[].commit.author.date")
    return collections.Counter(d[:7] for d in dates.split())


def months_between(first, last):
    y, m = int(first[:4]), int(first[5:])
    while f"{y:04d}-{m:02d}" <= last:
        yield f"{y:04d}-{m:02d}"
        y, m = (y + 1, 1) if m == 12 else (y, m + 1)


def chart(noun, rows, scaled=None, opened=None):
    per_repo = collections.Counter(repo for _, repo in rows)
    own = [r for r, n in per_repo.most_common() if n >= MIN_OWN]
    series = ["gnolang/gno"] + [r for r in own if r != "gnolang/gno"]
    grid = collections.defaultdict(collections.Counter)
    for month, repo in rows:
        grid[month][repo if repo in series else "Others"] += 1
    names = series + (["Others"] if any("Others" in c for c in grid.values()) else [])
    labels = [n.split("/")[-1] if n != "gnolang/gno" else n for n in names]
    if scaled:
        for month, n in scaled.items():
            grid[month][SCALED_NAME] = n
        names.append(SCALED_NAME)
        labels.append(SCALED_NAME)
    today = datetime.datetime.now(datetime.timezone.utc)
    lines = ["title " + noun, "series " + ",".join(labels)]
    if scaled:
        lines.append(f"scale {SCALED_NAME},{SCALE_DIV},commits")
    if opened:
        lines.append("outline gnolang/gno pull requests opened")
    lines.append("updated " + today.strftime("%Y-%m-%d"))
    for month in months_between(min(list(grid) + list(opened or [])), today.strftime("%Y-%m")):
        line = month + " " + " ".join(str(grid[month][n]) for n in names)
        lines.append(line + (f" | {opened[month]}" if opened else ""))
    return "; ".join(lines), per_repo


prs, pr_repos = chart("merged pull requests", pull_requests(), scaled_commits(), opened_gno())
revs, rev_repos = chart("reviews", reviews())

for title, repos in (("Merged pull requests", pr_repos), ("Reviews", rev_repos)):
    print(f"# {title}: " + ", ".join(f"{r} {n}" for r, n in repos.most_common()))
for slot, data in (("activity", prs), ("reviewactivity", revs)):
    print(f"\ngnokey maketx call -pkgpath {PKG} -func Set -args {slot} -args '{data}' "
          f"-gas-fee 1000000ugnot -gas-wanted 10000000 -broadcast -chainid gnoland-1 "
          f"-remote https://rpc.gno.land:443 {key}")
