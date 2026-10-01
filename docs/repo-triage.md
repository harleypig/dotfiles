# GitHub repository triage

A proposed disposition for every repository on the `harleypig` GitHub
account, drafted for the operator to mark up ([#373][i373]).

**These are proposals only.** Nothing is archived, deleted, or changed from
this document until the operator has marked it up.

## How to mark it up

Put your decision in the **Operator** column of each row: `ok` to accept the
proposal, or the disposition you want instead. A row left blank is
undecided. The dispositions are:

- **delete** — remove the repository. Cannot be undone.
- **archive** — GitHub's archive: read-only, visibility unchanged.
  Reversible.
- **update** — keep it, but fix its metadata (usually a missing
  description).
- **leave** — no change.

A proposal in **bold** with *(was …)* changed when the repositories' contents
were read; the old value is the metadata-only proposal from the first draft.

## How the current value was measured

Measured 2026-10-01, read-only. For every repository:

```bash
# Inventory and per-repo metadata (stars, forks, watchers, size, Pages,
# homepage, parent)
gh repo list harleypig --limit 200 \
  --json name,description,isArchived,isFork,visibility,pushedAt
gh api repos/harleypig/<name>

# Contents
gh api repos/harleypig/<name>/languages
gh api repos/harleypig/<name>/readme
gh api repos/harleypig/<name>/contents
gh api 'repos/harleypig/<name>/commits?per_page=5'
gh api repos/harleypig/<name>/branches

# Open work, and whether a site is published
gh api 'repos/harleypig/<name>/issues?state=open'
gh api 'repos/harleypig/<name>/pulls?state=open'
gh api repos/harleypig/<name>/pages

# Forks: own work on each branch, and PRs sent upstream
gh api 'repos/<parent>/compare/<base>...harleypig:<branch>'
gh api 'search/issues?q=repo:<parent>+author:harleypig+type:pr'
```

Also: `curl` against every Pages domain and homepage to see whether it is
live; the MetaCPAN API (`fastapi.metacpan.org/v1/release/<dist>`) for each
Perl dist's current author and release; and a grep of `~/projects` (this
repository included, worktrees excluded) for `harleypig/<name>`,
`projects/<name>` and `../<name>`, plus the site domains in harleydev's DNS
and Docker service definitions.

**Recounted:** **76** repositories, **23** archived, **7** forks, **64**
public, **47** last pushed before 2025-01-01 — the same as the first draft.

**Proposed now:** **45** leave (20 of them already archived), **21** archive,
**5** update, **5** delete. Twelve proposals changed from the first draft:

- **5 to delete.** binenv (nothing of yours is left only in the fork),
  newdotfiles (a former employer's code, not your dotfiles), and three
  already-archived repos that are one-commit imports of other authors' CPAN
  modules: Config-Crontab, Template-Alloy, Test-Legal.
- **5 to archive.** ado-pipeline-doc, aider, cff, formike, gollum-config:
  idle, not referenced, or superseded by newer work.
- **1 to update.** bubbaspams.me: the site is live, but its description
  names two domains that no longer resolve.
- **1 to leave.** DateTime-Event-Holiday-US: its `gh-pages` branch serves
  holidays.harleypig.com, which harleydev's DNS still points at.

**Live sites:** bubbaspams.me, flatlinedates.com, xn--ysca.com,
git-cheatsheet.harleypig.com, mail-setup.harleypig.com,
holidays.harleypig.com, and the Pages docs of bw-serve-client and dotfiles.
harleydev itself serves housewiki, scripturestudy and wiki.harleypig.com.
mc.harleypig.com still has a DNS record but returns 404.

**Depended on:** private_dotfiles (this repo's `ghx`, `linx` and rulesets,
plus dotagents and harleydev), dotvim (`bin/check-dotvim`), harleydev,
linode-foundation-fabric (harleydev, methodsprime),
mxroute-foundation-fabric (harleydev), terraform-provider-mxroute (mailctl),
and packwiz (this repo's `.local-claude/packwiz/`).

The **Description** column of the first draft is gone. **Current value**
replaces it, because it says what each repository holds rather than what its
GitHub description claims.

## Repositories

| Name | Archived | Fork | Visibility | Last push | Current value | Proposed | Reason | Operator |
|------|----------|------|------------|-----------|---------------|----------|--------|----------|
| abs | no | no | public | 2015-08-10 | Arch Linux PKGBUILDs (aur/community/core/extra), 27 commits, 14 MB; nothing references it | archive | Untouched since 2015 and unused | |
| ado-pipeline-doc | no | no | public | 2025-01-21 | Python script that documents Azure DevOps pipelines; 240 commits, all in one January 2025 burst; nothing references it | **archive** (was leave) | Idle since the 2025 burst and not referenced anywhere | |
| aider | no | yes | public | 2025-03-06 | Fork of Aider-AI/aider; default branch has no own commits and is 2,465 behind; branch `cvss` holds 4 own commits (2025-03, dependency and path chores); named in two dotagents research docs as a surveyed repo | **archive** (was leave) | Own work is 4 small commits on a side branch; the fork itself is not used | |
| ansible-stuff | no | no | private | 2026-07-24 | Ansible roles and playbooks with molecule tests; 234 commits; cloned in ~/projects | leave | Active | |
| aur-packages | no | no | public | 2012-08-13 | AUR PKGBUILDs, mostly Perl modules; 43 commits, 1 star; nothing references it | archive | Untouched since 2012 and unused | |
| binenv | no | yes | public | 2024-05-04 | Fork of devops-works/binenv; no branch carries a commit upstream lacks; your two upstream PRs (#254, #255) are closed and the git-bug entry was merged. This repo uses the binenv tool (`config/binenv/`), not the fork | **delete** (was archive) | Nothing of yours exists only here | |
| bubbaspams.me | no | no | public | 2022-06-19 | One-page joke site, live at bubbaspams.me (GitHub Pages); its DNS is managed in harleydev `domains/github-vars.tf`. The description's other two domains (bubbaspams.us, bubbaspamsme.com) do not resolve | **update** (was leave) | Live site; the description names two domains that no longer resolve | |
| bw-serve-client | no | no | public | 2026-09-17 | Python client for Bitwarden's `bw serve` API, generated from OpenAPI; docs live on GitHub Pages; 46 commits; named in dotagents docs | leave | Active, with a live docs site | |
| cesa | yes | no | public | 2014-08-19 | Two Perl scripts for CentOS CVE mail, 2 commits; not on CPAN; nothing references it | leave | Already archived; little value, so delete is reasonable if you want it gone | |
| cff | no | no | private | 2024-05-09 | Private copy (not a GitHub fork) of GoogleCloudPlatform/cloud-foundation-fabric, 47 MB and 5,297 upstream commits; your own work is the `tfmod` branch (2024-05 test edits). linode-foundation-fabric is now the CFF-style library you maintain | **archive** (was leave) | Reference copy superseded by linode-foundation-fabric; keep the `tfmod` branch readable | |
| Config-Crontab | yes | no | public | 2013-05-14 | One commit: an import of SCOTTW's Config-Crontab 1.33 from CPAN; SCOTTW still maintains it (1.45) | **delete** (was leave) | No own work; the module lives on CPAN under its author | |
| Config-NameValue | yes | no | public | 2018-11-18 | Your CPAN dist (1.03, 2012); 1 star, 2 forks, 1 open issue, 1 open PR | leave | Already archived; it is the source history of a released dist | |
| DateTime-Event-Holiday-US | no | no | public | 2013-07-23 | Your CPAN dist (0.02, 2011); 4 stars, 2 open issues; its `gh-pages` branch serves holidays.harleypig.com, whose DNS record is in harleydev `domains/yaml/harleypig_com.yml` | **leave** (was archive) | Backs a live, DNS-managed site; decide the site before the repo | |
| DateTimeX-Duration-SkipDays | no | no | public | 2012-07-28 | Your CPAN dist (0.002, 2012); 1 star; nothing references it | archive | Untouched since 2012; matches the other archived Perl dists | |
| Dist-Zilla-Plugin-Test-Kwalitee | yes | no | public | 2013-08-05 | Original repo of a dist now maintained by ETHER on CPAN (2.13, 2026); 5 stars, 5 forks, 1 open issue, 1 open PR | leave | Already archived; historical, since the dist moved on | |
| Dist-Zilla-Plugin-Test-Legal | yes | no | public | 2018-03-01 | Your CPAN dist (0.03, 2018); 1 star, 3 forks | leave | Already archived; source history of a released dist | |
| Dist-Zilla-Plugin-YAPkgVersion | yes | no | public | 2014-09-23 | Dist::Zilla plugin, 5 commits, never released to CPAN; 1 star, 1 fork | leave | Already archived; small, so delete is reasonable if you want it gone | |
| dotfiles | no | no | public | 2026-10-01 | This repository; 3,135 commits, docs on GitHub Pages; referenced from dotagents, harleydev, private_dotfiles | leave | This repository | |
| dotvim | no | no | public | 2026-07-23 | Vim configuration; 713 commits; cloned by this repo's `bin/check-dotvim` and linked from README.md | leave | Active and depended on by this repo | |
| dot_minecraft | no | no | public | 2020-05-11 | Minecraft client options and mod notes, 26 commits, 37 KB; nothing references it | archive | Untouched since 2020; harleycolonies is the current Minecraft work | |
| dot_perltidyrc | no | no | public | 2015-12-21 | One 227-line `.perltidyrc` from 2015; this repo now carries its own, different 76-line `.perltidyrc` | archive | Superseded by this repo's `.perltidyrc`; delete is reasonable too | |
| dump-minecolonies-resources | yes | no | public | 2017-11-16 | Perl scripts that list resources a MineColonies structure needs, 28 commits | leave | Already archived | |
| flatlinedates.com | no | no | public | 2020-02-07 | One-page joke site, live at flatlinedates.com (GitHub Pages); DNS managed in harleydev `domains/github-vars.tf` | leave | Live site | |
| formike | no | no | public | 2025-03-03 | Three commits made on one day (2025-03-03): an AWS Terraform skeleton and a problem statement for someone else's ML workspace; 4 KB; nothing references it | **archive** (was update) | A one-day stub; a description would not make it useful | |
| git-cheatsheet | no | yes | public | 2026-07-09 | Fork of ndp/git-cheatsheet, 2 commits ahead (Pages publishing, tracker tokens stripped); live at git-cheatsheet.harleypig.com, DNS in harleydev | leave | Live site with its own commits | |
| git-plugin-manager | no | no | public | 2023-04-03 | Python CLI for git submodules, 15 commits, version 0.2.4; nothing references it | archive | Untouched since 2023 and unused | |
| gitperms | no | no | public | 2026-07-31 | Git hooks that store and restore file permissions; 15 stars, 4 forks, 12 open issues; 73 commits, worked on 2026-07; cloned in ~/projects | leave | Active; your most-starred repo | |
| GMailBackup | no | no | private | 2011-09-06 | Private Google Takeout dump from 2011 (Buzz, Picasa, Voice, contacts), 79 MB | archive | Personal data; whether to keep it is your call, not the agent's | |
| gollum-config | no | no | public | 2025-10-12 | Notes and a systemd unit for running Gollum; last commit 2021. harleydev now runs Gollum in Docker (`docker/services/wiki-*.yml`); cloned in ~/projects/wikis | **archive** (was update) | Superseded by harleydev's Docker setup | |
| harleycolonies | no | no | public | 2026-09-15 | Minecraft modpack (packwiz) published on CurseForge; 354 commits, 10 open issues; served as a wiki by harleydev | leave | Active | |
| harleydev | no | no | private | 2026-09-02 | Infrastructure for the harleydev.com server: Terraform, Docker services, DNS; 1,860 commits, 14 open issues; harleydev.com is live; referenced from this repo (18 files) and dotagents | leave | Active and depended on | |
| harleypig | no | no | public | 2025-09-20 | GitHub profile README (stats cards) | leave | Profile repository | |
| housewiki | no | no | private | 2025-01-25 | Gollum wiki for getting the house ready for sale; served by harleydev at `house.<domain>` behind Authelia; last content commit 2023-05; cloned in ~/projects/wikis | leave | Still served; archive once the sale no longer needs it | |
| IPC-Run3-Simple | yes | no | public | 2012-04-26 | Your CPAN dist (0.011, 2012); 1 star | leave | Already archived; source history of a released dist | |
| journeymap-waypoint-manager | no | no | public | 2026-05-22 | NeoForge mod for JourneyMap waypoints, Java/Gradle, 38 commits | leave | Active | |
| linode-foundation-fabric | no | no | public | 2026-09-11 | Terraform module library for Linode; 205 commits, 4 open issues; used by harleydev (12 files) and methodsprime (3) | leave | Active and depended on | |
| list-religious-study | no | no | public | 2016-04-08 | README of links for religious study, 7 commits, 1 star; linked from the scripturestudy wiki's resources page | archive | Untouched since 2016; archiving keeps the link working | |
| loginfiles | no | no | public | 2019-12-30 | Docker test rig showing which startup files each login method runs, 35 commits, 1 star | archive | Reference work untouched since 2019 | |
| mail-setup | no | no | public | 2026-07-21 | Mail-client help pages for mailbox owners, live at mail-setup.harleypig.com; DNS and MXroute docs in harleydev point to it | update | Live and current, but has no description | |
| mailctl | no | no | public | 2026-09-30 | Python CLI for MXroute Sieve filters; v0.11.0 released 2026-09-30, 128 commits, 3 open issues | leave | Active | |
| minecolonies-blueprints | no | no | public | 2022-07-12 | MineColonies building blueprints, 7 commits, 1.8 MB | archive | Untouched since 2022; harleycolonies is the current MineColonies work | |
| Minecraft-NBTReader | yes | no | public | 2017-01-16 | Your patches (4 commits, 2017) to CAVAC's Minecraft::NBTReader, never released | leave | Already archived; small, so delete is reasonable if you want it gone | |
| minecraft_server | no | no | private | 2017-02-16 | Private Spigot server config for mc.harleypig.com; 2 open issues. The host still has a DNS record in harleydev, but it serves HTTP 404 | archive | Untouched since 2017; the leftover DNS record is a harleydev cleanup | |
| misc-stuff | no | no | private | 2025-04-06 | Private grab-bag: calibre, imapsync, tutorials, VM setup, an `archive/`; cloned in ~/projects | leave | Review its contents rather than the repo, as its description says | |
| mkplaylist | no | no | public | 2025-04-20 | Python tool that builds Spotify playlists from Last.fm data, 42 commits, last worked on 2025-04; cloned in ~/projects | update | Kept locally but has no description | |
| Mojolicious-Plugin-LogHelper | yes | no | public | 2015-12-17 | Two commits, 3 KB, never released to CPAN | leave | Already archived; trivial, so delete is reasonable if you want it gone | |
| mxroute-foundation-fabric | no | no | public | 2026-07-09 | Terraform module library for MXroute, v1.0.0; used by harleydev (4 files) | leave | Active and depended on | |
| mytask | no | no | public | 2025-12-30 | Perl task manager, milestone 1 done (2025-12), 17 commits; named in dotagents docs | leave | Recently started | |
| NBTTools | no | yes | public | 2020-11-29 | Fork of pdinklag/NBTTools with 4 own commits (mob-spawner waypoints, 2020) | archive | Fork with a little own work; archive keeps it | |
| net-cloudstack-api | yes | no | public | 2015-07-10 | Your CPAN dist Net::CloudStack::API (0.02, 2012); 1 star, 1 fork | leave | Already archived; source history of a released dist | |
| Net-Gitlab | yes | no | public | 2015-08-07 | Original repo of a dist now maintained by BLUEFEET on CPAN (0.09, 2019); 5 stars, 2 forks | leave | Already archived; historical, since the dist moved on | |
| Net-Google-GData | yes | no | public | 2014-09-08 | Your CPAN dist (0.03, 2012); 1 fork | leave | Already archived; source history of a released dist | |
| newdotfiles | no | no | private | 2020-06-28 | Not personal dotfiles: a former employer's EDW/ETL environment code ("CommonCode", host UTLXA350), 425 MB; 9 of its last 10 commits are by "ETL Admin" | **delete** (was archive) | Holds an employer's code rather than yours; confirm nothing personal is in it first | |
| ofx2ledger | no | no | public | 2024-03-24 | Python OFX-to-hledger converter, 138 commits (many by aider) in March 2024; nothing references it | archive | Untouched since early 2024 and unused | |
| OpenVZ | yes | no | public | 2014-09-08 | Your CPAN dist (0.01, 2012); 1 star, 2 forks | leave | Already archived; source history of a released dist | |
| packwiz | no | yes | public | 2026-05-16 | Fork of packwiz/packwiz with real own work: branch `mine` is 75 commits ahead, and three PRs are open upstream (#306, #359, #402); this repo carries agent config for it in `.local-claude/packwiz/` | leave | Active fork with open upstream PRs | |
| ParseParams | no | no | public | 2020-09-13 | Bash parameter-parsing library, 16 commits; this repo's `bin/parse_params` is a Perl rewrite of it | archive | Superseded by this repo's `bin/parse_params` | |
| perl-check | yes | no | public | 2015-08-11 | `perl -c` wrapper, 3 commits, never released | leave | Already archived | |
| perl-package-tests | yes | no | public | 2015-09-17 | Author tests for Perl packages, 16 commits | leave | Already archived | |
| perl-taskwarrior | yes | no | public | 2015-11-15 | Perl Taskwarrior interface, 12 commits, never released; 9 open issues | leave | Already archived | |
| pigify | no | no | public | 2026-09-07 | Spotify web app (Python backend, TypeScript frontend), 213 commits, 6 open PRs; named in dotagents and harleydev | update | Active, but has no description | |
| Pod-PseudoPod-XHTML | yes | no | public | 2011-08-22 | Your CPAN dist (1.02, 2011); 1 star | leave | Already archived; source history of a released dist | |
| Pod-Weaver-PluginBundle-AYOUNG | yes | no | public | 2010-12-10 | Your CPAN dist (0.14, 2010); 1 star, 1 fork | leave | Already archived; source history of a released dist | |
| PPIx-IndexLines | yes | no | public | 2014-05-07 | Your CPAN dist (0.05, 2011); 1 star | leave | Already archived; source history of a released dist | |
| private_dotfiles | no | no | private | 2026-09-25 | Private tokens, rulesets and site secrets; this repo's `ghx`, `linx` and ruleset workflow read from it (`../private_dotfiles`), as do dotagents and harleydev | update | Depended on, but has no description; keep it private | |
| scripturestudy | no | no | private | 2026-06-21 | Scripture study wiki (Gollum), 270 commits; served by harleydev; cloned in ~/projects/wikis | leave | Active and served | |
| scripturestudy-app | no | no | private | 2026-08-07 | Scripture study web app, 54 commits, 8 open PRs; named in dotagents docs | leave | Active | |
| swarm | no | yes | public | 2025-09-15 | Fork of swarmsim/swarm, 53 own commits ahead (energy calculations, 2025-09) | leave | Fork with substantial own work | |
| Template-Alloy | yes | no | public | 2013-07-22 | One commit: an import of RHANDOM's Template::Alloy 1.016 from CPAN; RHANDOM still releases it (1.022) | **delete** (was leave) | No own work; the module lives on CPAN under its author | |
| terraform-provider-mxroute | no | no | public | 2026-07-27 | Terraform provider for MXroute, 1.0.0; mailctl and dotagents refer to it; 1 open PR | leave | Active and depended on | |
| Test-Legal | yes | no | public | 2018-03-05 | One commit: an import of IOANNIS's Test::Legal from CPAN | **delete** (was leave) | No own work; the module lives on CPAN under its author | |
| User-Times | yes | no | public | 2012-06-25 | utmp login-time reader, 3 commits, never released; 1 star | leave | Already archived | |
| utahcode | no | yes | public | 2016-01-28 | Fork of divegeek/utahcode (Utah legal code); `master` matches upstream, branch `HB0225` holds 4 own commits from 2016 | archive | Fork with a little own work on a side branch | |
| where | no | no | public | 2018-07-28 | An improved `which`; this repo's `bin/where` is the same script, since extended and tested | archive | Superseded by this repo's `bin/where` | |
| wiki.harleypig.com | no | no | private | 2024-10-21 | Personal Gollum wiki, 786 commits; harleydev serves it at `wiki.<domain>` behind Authelia (live); cloned in ~/projects/wikis | leave | Still served | |
| xn--ysca.com | no | no | public | 2014-05-04 | One-page joke site (the punycode for ಠಠ.com), live (GitHub Pages); DNS managed in harleydev `domains/github-vars.tf` | leave | Live site | |

[i373]: https://github.com/harleypig/dotfiles/issues/373
