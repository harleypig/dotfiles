# System Packages

System-level packages installed via the OS package manager (apt), **outside**
the language version managers. This is the sibling of
[`packages.md`](packages.md) — that file covers tools installed *through* the
version managers (node → npm, python → pipx/uv); this file covers tools that
are native binaries best installed from a distro/vendor apt repo.

## GitHub CLI (`gh`)

**Why a vendor repo and not Ubuntu's:** Ubuntu's `universe` repo pins `gh` at
an old release (e.g. 2.45.0 on noble). That version still queries GitHub's
**sunset "Projects (classic)"** GraphQL field, so `gh pr edit` / `gh issue
view` fail with `Projects (classic) is being deprecated …` ([cli/cli#11983]).
Installing from GitHub's own apt repo tracks current releases and fixes it.

**Install** (writes the source list directly — see the caveat below):

```bash
sudo mkdir -p -m 755 /etc/apt/keyrings && \
wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg \
  | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null && \
sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg && \
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
  | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null && \
sudo apt update && \
sudo apt install gh
```

- **Repo:** `https://cli.github.com/packages`, suite `stable`, component
  `main`. There is **no `ppa:` shorthand** — it is hosted on GitHub's apt
  server, not Launchpad.
- **Caveat — do not use `add-apt-repository`:** on Ubuntu 24.04 (noble) it
  rejects a bracketed `deb [options] …` line with *"Unable to handle
  repository shortcut"*. Write the `.list` file directly with `tee` (above),
  which is also GitHub's officially documented method. `add-apt-repository`
  would not fetch the `signed-by=` key for a raw deb line anyway.

**Verify:**

```bash
gh --version                          # expect a current release, well past 2.45.0
gh pr view <N> --json projectCards    # returns null (not an error) once fixed
```

[cli/cli#11983]: https://github.com/cli/cli/issues/11983
