# GitHub repository triage

A proposed disposition for every repository on the `harleypig` GitHub
account, drafted for the operator to mark up ([#373][i373]).

**These are proposals only.** Nothing is archived, deleted, or changed from
this document until the operator has marked it up. Each proposal is based on
the inventory metadata alone (name, description, archived and fork flags,
visibility, last push); no repository's contents were read.

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

**No row proposes delete.** Metadata cannot show that a repository is
unused, or that a fork carries no work of its own, so every delete is left
for the operator to mark. Where a row looks like a delete candidate, its
reason says so and proposes archive instead.

## Inventory

Taken 2026-10-01 with:

```bash
gh repo list harleypig --limit 200 \
  --json name,description,isArchived,isFork,visibility,pushedAt
```

It returned **76** repositories: **23** archived, **7** forks, **64**
public, and **47** last pushed before 2025-01-01. Proposed: **19** archive,
**6** update, **51** leave (23 of them already archived), **0** delete.

| Name | Archived | Fork | Visibility | Last push | Description | Proposed | Reason | Operator |
|------|----------|------|------------|-----------|-------------|----------|--------|----------|
| abs | no | no | public | 2015-08-10 | My custom pkgbuilds | archive | Arch PKGBUILDs untouched since 2015 | |
| ado-pipeline-doc | no | no | public | 2025-01-21 | Document Azure DevOps pipelines | leave | Pushed in 2025; may still be in use | |
| aider | no | yes | public | 2025-03-06 | aider is AI pair programming in your terminal | leave | Fork pushed in 2025; cannot tell from metadata whether it carries own work | |
| ansible-stuff | no | no | private | 2026-07-24 | Ansible files for server or workstation setup and configuration | leave | Active (pushed 2026) | |
| aur-packages | no | no | public | 2012-08-13 | aur packages I need that haven't been created yet. | archive | Untouched since 2012; archive is reversible | |
| binenv | no | yes | public | 2024-05-04 | One binary to rule them all. Manage all those pesky binaries (kubectl, helm, terraform, ...) easily. | archive | Fork untouched since 2024; archive rather than delete, own commits unknown | |
| bubbaspams.me | no | no | public | 2022-06-19 | Repository for bubbaspams.me, bubbaspams.us and bubbaspamsme.com | leave | Named for a domain; may back a live site, check before archiving | |
| bw-serve-client | no | no | public | 2026-09-17 | An OpenAPI Generator generated library for Bitwarden's CLI serve command. | leave | Active (pushed 2026) | |
| cesa | yes | no | public | 2014-08-19 | CentOS CVE programs and stuff. | leave | Already archived | |
| cff | no | no | private | 2024-05-09 | — | leave | No description, pushed 2024; name may relate to the CFF-style Terraform libraries, needs a look | |
| Config-Crontab | yes | no | public | 2013-05-14 | Read/Write Vixie compatible crontab(5) files | leave | Already archived | |
| Config-NameValue | yes | no | public | 2018-11-18 | Round trip simple name/value config file handling. | leave | Already archived | |
| DateTime-Event-Holiday-US | no | no | public | 2013-07-23 | Return requested holiday's as DateTime::Set::ICal objects | archive | Perl dist untouched since 2013; matches the other archived Perl dists | |
| DateTimeX-Duration-SkipDays | no | no | public | 2012-07-28 | Given a starting date, a number of days and a list of days to be skipped, returns the date X number of days away. | archive | Perl dist untouched since 2012; matches the other archived Perl dists | |
| Dist-Zilla-Plugin-Test-Kwalitee | yes | no | public | 2013-08-05 | Test your distribution with Kwalitee | leave | Already archived | |
| Dist-Zilla-Plugin-Test-Legal | yes | no | public | 2018-03-01 | common tests to check for copyright and license notices | leave | Already archived | |
| Dist-Zilla-Plugin-YAPkgVersion | yes | no | public | 2014-09-23 | None of the existing modules did what I wanted, so I did it myself | leave | Already archived | |
| dotfiles | no | no | public | 2026-10-01 | My dot files | leave | This repository | |
| dotvim | no | no | public | 2026-07-23 | My vim configuration | leave | Active (pushed 2026) | |
| dot_minecraft | no | no | public | 2020-05-11 | — | archive | No description, untouched since 2020 | |
| dot_perltidyrc | no | no | public | 2015-12-21 | My perl tidy rc file | archive | Untouched since 2015; perltidy config may now live in this repo, check first | |
| dump-minecolonies-resources | yes | no | public | 2017-11-16 | Dump required resources for a minecolonies structure | leave | Already archived | |
| flatlinedates.com | no | no | public | 2020-02-07 | Just ... no ... | leave | Named for a domain; may back a live site, check before archiving | |
| formike | no | no | public | 2025-03-03 | — | update | Pushed in 2025 but has no description | |
| git-cheatsheet | no | yes | public | 2026-07-09 | Interactive cheatsheet, visualization of git. | leave | Fork pushed in 2026 | |
| git-plugin-manager | no | no | public | 2023-04-03 | An intuitive Python CLI tool for streamlined Git submodule management, enabling users to add, move, and rename submodules with ease. | archive | Untouched since 2023 | |
| gitperms | no | no | public | 2026-07-31 | Handle permissions in a git repository. | leave | Active (pushed 2026) | |
| GMailBackup | no | no | private | 2011-09-06 | My GMail Backup | archive | Private, untouched since 2011; may hold mail data, so archive rather than delete | |
| gollum-config | no | no | public | 2025-10-12 | — | update | Pushed in 2025 but has no description | |
| harleycolonies | no | no | public | 2026-09-15 | HarleyColonies: A Minecraft modpack designed to reduce grinding and enhance gameplay with mods like Minecolonies, JourneyMap, and more. | leave | Active (pushed 2026) | |
| harleydev | no | no | private | 2026-09-02 | Sites being run under my harleydev.com server | leave | Active (pushed 2026) | |
| harleypig | no | no | public | 2025-09-20 | a ✨special ✨ repository | leave | Profile repository; pushed in 2025 | |
| housewiki | no | no | private | 2025-01-25 | What we need to do to get the house ready for sale. | leave | Pushed in 2025; description suggests current use | |
| IPC-Run3-Simple | yes | no | public | 2012-04-26 | Simple utility module to make the easy to use IPC::Run3 even more easy to use. | leave | Already archived | |
| journeymap-waypoint-manager | no | no | public | 2026-05-22 | NeoForge 1.21.1 mod for bulk import/export of JourneyMap waypoints via the JourneyMap API | leave | Active (pushed 2026) | |
| linode-foundation-fabric | no | no | public | 2026-09-11 | CFF-style Terraform module library for Linode, extracted from harleydev/tfmods | leave | Active (pushed 2026) | |
| list-religious-study | no | no | public | 2016-04-08 | A list of sites related to religious and spiritual study and discussion | archive | Untouched since 2016 | |
| loginfiles | no | no | public | 2019-12-30 | Detailed list of which startup files are executed with various login methods. | archive | Reference list untouched since 2019 | |
| mail-setup | no | no | public | 2026-07-21 | — | update | Active (pushed 2026) but has no description | |
| mailctl | no | no | public | 2026-09-30 | Manage MXRoute email filters from the command line: create server-side Sieve rules over ManageSieve, and apply the same criteria to mail already delivered over IMAP. | leave | Active (pushed 2026) | |
| minecolonies-blueprints | no | no | public | 2022-07-12 | — | archive | No description, untouched since 2022 | |
| Minecraft-NBTReader | yes | no | public | 2017-01-16 | A simple nbt file reader. | leave | Already archived | |
| minecraft_server | no | no | private | 2017-02-16 | Configuration and related files for mc.harleypig.com | archive | Private server config untouched since 2017 | |
| misc-stuff | no | no | private | 2025-04-06 | Stuff that doesn't yet fit anywhere or is archived and eligble for removal | leave | Description says it holds items eligible for removal; review its contents, not the repo | |
| mkplaylist | no | no | public | 2025-04-20 | — | update | Pushed in 2025 but has no description | |
| Mojolicious-Plugin-LogHelper | yes | no | public | 2015-12-17 | Helper methods for making logging a little easier | leave | Already archived | |
| mxroute-foundation-fabric | no | no | public | 2026-07-09 | CFF-style Terraform module library for MXroute email hosting, built on terraform-provider-mxroute | leave | Active (pushed 2026) | |
| mytask | no | no | public | 2025-12-30 | mytasks - Yet another task manager | leave | Pushed in 2025 | |
| NBTTools | no | yes | public | 2020-11-29 | Python API and tools related to Minecraft's Named Binary Tags (NBT) | archive | Fork untouched since 2020; archive rather than delete, own commits unknown | |
| net-cloudstack-api | yes | no | public | 2015-07-10 | api specific libraries for cloudstack | leave | Already archived | |
| Net-Gitlab | yes | no | public | 2015-08-07 | Talk to a Gitlab installation via its API | leave | Already archived | |
| Net-Google-GData | yes | no | public | 2014-09-08 | Release history of Net-Google-GData | leave | Already archived | |
| newdotfiles | no | no | private | 2020-06-28 | — | archive | Private, no description, untouched since 2020; name suggests superseded by dotfiles, delete if confirmed | |
| ofx2ledger | no | no | public | 2024-03-24 | Simple tool to convert an ofx file to hledger transactions | archive | Untouched since early 2024 | |
| OpenVZ | yes | no | public | 2014-09-08 | Call the various OpenVZ tools (vzctl, etc.) from your program | leave | Already archived | |
| packwiz | no | yes | public | 2026-05-16 | A command line tool for editing and distributing Minecraft modpacks, using a git-friendly TOML format. Supports CurseForge and Modrinth mods with automated updates! | leave | Fork pushed in 2026 | |
| ParseParams | no | no | public | 2020-09-13 | Bash library to parse parameters | archive | Untouched since 2020; parse_params is now carried in this repo | |
| perl-check | yes | no | public | 2015-08-11 | Check your perl file (or files) for problems using an advanced form of 'perl -c' | leave | Already archived | |
| perl-package-tests | yes | no | public | 2015-09-17 | Tests for perl packages I'm always creating in some way or other. | leave | Already archived | |
| perl-taskwarrior | yes | no | public | 2015-11-15 | A perl package for interacting with the Taskwarrior ( <http://taskwarrior.com> ) to-do application. | leave | Already archived | |
| pigify | no | no | public | 2026-09-07 | — | update | Active (pushed 2026) but has no description | |
| Pod-PseudoPod-XHTML | yes | no | public | 2011-08-22 | Make Pod::PseudoPod dump out valid XHTML. | leave | Already archived | |
| Pod-Weaver-PluginBundle-AYOUNG | yes | no | public | 2010-12-10 | My pod weaver stuff | leave | Already archived | |
| PPIx-IndexLines | yes | no | public | 2014-05-07 | Given a line number, returns some basic information about where in the perl document you are. | leave | Already archived | |
| private_dotfiles | no | no | private | 2026-09-25 | — | update | Active (pushed 2026) but has no description | |
| scripturestudy | no | no | private | 2026-06-21 | My scripture study wiki | leave | Active (pushed 2026) | |
| scripturestudy-app | no | no | private | 2026-08-07 | Scripture study app data | leave | Active (pushed 2026) | |
| swarm | no | yes | public | 2025-09-15 | Swarm Simulator, an idle game with lots of bugs. | leave | Fork pushed in 2025 | |
| Template-Alloy | yes | no | public | 2013-07-22 | My fork of RHANDOM's Template::Alloy -- <https://metacpan.org/release/Template-Alloy> | leave | Already archived | |
| terraform-provider-mxroute | no | no | public | 2026-07-27 | Terraform provider for MXroute email hosting (terraform-plugin-framework) | leave | Active (pushed 2026) | |
| Test-Legal | yes | no | public | 2018-03-05 | Test and (optionally) fix copyright notices, LICENSE file, and relevant field of META file | leave | Already archived | |
| User-Times | yes | no | public | 2012-06-25 | Return user login info from utmp files in a hash suitable for determining how long and when people have been logged in. | leave | Already archived | |
| utahcode | no | yes | public | 2016-01-28 | Legal Code for the State of Utah | archive | Fork untouched since 2016; archive rather than delete, own commits unknown | |
| where | no | no | public | 2018-07-28 | An improved which | archive | Untouched since 2018 | |
| wiki.harleypig.com | no | no | private | 2024-10-21 | My wiki | leave | Named for a domain; may back a live site, check before archiving | |
| xn--ysca.com | no | no | public | 2014-05-04 | For when you need to give a disapproving stare on the web ... | leave | Named for a domain; may back a live site, check before archiving | |

[i373]: https://github.com/harleypig/dotfiles/issues/373
