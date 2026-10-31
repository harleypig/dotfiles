# Powershell Setup and Configuration

This was developed using Powershell 7+.

## Windows prerequisites: `install-prereqs`

Run this first on a fresh Windows machine, before the profile is wired. It
checks, and installs where needed, the packages a repo or a host needs:

```powershell
install-prereqs dotagents   # one repo's needs, on whatever machine
install-prereqs sweetums    # a host: its repos' lists plus its own extras
install-prereqs             # the repo the current directory is in
```

`install-prereqs` is [`bin/Install-Prereqs.ps1`][script], found by name
because `ps-startup.ps1` puts this `bin` directory on `PATH`. Before the
profile is wired, run it by its path:
`pwsh -File powershell\bin\Install-Prereqs.ps1 <name>`.

* `-WhatIf` reports what would change, without changing anything.
* `-Host` or `-Repo` settles a name that is both a host and a repo.
* Everything that needs admin runs in one elevated window, behind one UAC
  prompt, and only when something needs it.
* Each item reports `ok`, `fixed`, `would fix`, `skipped`,
  `FAILED: <reason>` or `PENDING: <action>`; the script exits 1 on any
  `FAILED` or `PENDING`.

The packages are not in the script. They are in JSON lists, checked against
[`win-prereqs.schema.json`][schema] before anything runs:

* `<repo>/win-prereqs.json`: a repo's own Windows needs. It stands alone,
  independent of any host. This repo's is [`win-prereqs.json`][own].
* `hosts/win-<hostname>.json`: `{ "repos": [...], "packages": [...] }`, the
  repos' lists plus packages for that host only, as in
  [`hosts/win-sweetums.json`][sweetums].

A host name wins if `hosts/win-<name>.json` exists; otherwise a repo of that
name under `$PROJECTS_DIR` (or, when it is unset, the parent of this
checkout) with a `win-prereqs.json`. The `win-` prefix keeps these apart
from the bash/Linux setup.

Each package has a `name`, a `why` (evidence of use: a file and a string
quoted from it in backticks, ``file:`text` ``, rather than a line number that
drifts), and an ordered `install` list of manager specs: `choco`, `winget`,
`npm`, `pip` (into the Python `python3` runs), `uv` (uv tool) or `psgallery`.
A spec may pin a `version`; an npm spec may name a GitHub `source`. Managers
are tried in order; installed by any tool counts as ok; nothing is
uninstalled, and nothing is upgraded unless a pin differs. A `checkOnly` entry
(git) is only looked for. Chocolatey itself is bootstrapped if it is missing.

When dotfiles is part of the target, three built-in steps run as well: the
`~\.local\bin\python3.exe` link to the newest Python, ahead of WindowsApps in
the User `PATH`; `MSYS=winsymlinks:nativestrict`; and removing repeated
entries, and those whose directory is missing, from the User and the Machine
`PATH` (the Machine one in the elevated window).

[script]: bin/Install-Prereqs.ps1
[schema]: win-prereqs.schema.json
[own]: ../win-prereqs.json
[sweetums]: ../hosts/win-sweetums.json

## First Steps

I am assuming `git` and `powershell 7+` have been installed and that the
repositories (currently dotfiles, dotvim, and private_dotfiles) have been cloned
in the appropriate locations.

* Set the profile for powershell using the `ps-profile.ps1` script. Use
  `ps-profile -h` for details.

* Update your modules and scripts. See `Update-All -h` for details.

* Set the execution policy to `RemoteSigned` (unless you have a different use
  case, in which case you'll know what you need to do).

  Run `Elevate Set-ExecutionPolicy RemoteSigned`. `Elevate` is a script in the
  bin directory this document is stored in. If the command fails, its
  elevated window stays open, with the output readable, until you press
  Enter.

* Install the modules listed in `ps-packages.txt` in this directory.
