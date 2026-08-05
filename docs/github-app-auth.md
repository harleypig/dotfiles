# GitHub App authentication (`gh-app-token`)

**One GitHub App**, not one per repo. It represents "Claude, in an
operator-directed interactive session" — the same relationship
`private_dotfiles/github/tokens/harleypig` already models for `ghx` (one
credential, many personal repos) — as opposed to
`tokens/responder-dotagents` / `tokens/responder-spotlight`, which are
deliberately per-customer isolation for the *unattended* webhook responder.
Don't conflate the two: this App is for agent-authored issues/comments to
show as `<name>[bot]` in the author field instead of the operator's own
account, on repos the operator explicitly installs it to.

It carries a **narrow** permission grant — `issues: write` (covers issues
and issue comments) — nothing broader, matching the currently-scoped need
of issue/comment authorship.

## Setup — a one-time, manual walkthrough

GitHub gives no API to register an App or mint its first key, so this is a
GUI walkthrough, not something `bin/gh-app-token` can do for you.

1. **Register the App** at
   <https://github.com/settings/apps/new>:
   - **GitHub App name** — `claude-agent` is a reasonable working default;
     rename freely, it does not need to match anything below.
   - **Permissions → Repository permissions → Issues** — Read & write.
     Leave every other permission at "No access".
   - **Webhook** — uncheck Active; this App is never called back into, so no
     webhook URL or secret is needed.
   - **Where can this GitHub App be installed?** — Only on this account.
2. **Generate a private key** from the App's settings page (a "Generate a
   private key" button near the bottom) — downloads a `.pem` file. Place it
   at the credential path below and lock it down immediately:

   ```bash
   mkdir -p private_dotfiles/github/apps/<slug>
   mv ~/Downloads/<app-name>.*.private-key.pem \
     private_dotfiles/github/apps/<slug>/private-key.pem
   chmod 700 private_dotfiles/github/apps
   chmod 700 private_dotfiles/github/apps/<slug>
   chmod 600 private_dotfiles/github/apps/<slug>/private-key.pem
   ```

   `<slug>` is any name you choose for this credential directory — it does
   not have to match the App's display name. It is also what you pass to
   `gh-app-token <slug>` and what a `ghx` scope file's `app:<slug>` marker
   names (see *Wiring into ghx* below).
3. **Install the App** on the account and select repositories — start with
   `dotagents` and `spotlight`; add more later from the same installation
   page (**Settings → Applications → GitHub Apps → your App → Configure**)
   without re-registering the App itself. Permissions are set once, at
   registration; the repo list is a separate, freely-extensible axis.
4. **Record the two IDs**, as plain text, no trailing content beyond the
   number:
   - **App ID** — shown on the App's own settings page
     (`https://github.com/settings/apps/<app-name>`).
   - **Installation ID** — visible in the URL when viewing the installation
     under **Settings → Applications → GitHub Apps → your App → Configure**
     (the numeric path segment), or via `GET /app/installations` using a
     JWT.

   ```bash
   printf '<app id>' > private_dotfiles/github/apps/<slug>/app-id
   printf '<installation id>' > private_dotfiles/github/apps/<slug>/installation-id
   ```

That's every file `gh-app-token` reads:

```text
private_dotfiles/github/apps/<slug>/
  private-key.pem     mode 600 — the App's private key
  app-id               plain text — the App's numeric ID (JWT "iss" claim)
  installation-id       plain text — the installation to mint a token for
```

**Git does not preserve file modes.** As with `private_dotfiles/github/`'s
own PAT store, a fresh clone lands these at `0644`/`0755` under your
umask — re-apply the `chmod`s above after cloning.

## Day-to-day: mint-on-demand, nothing to schedule

```bash
gh-app-token <slug>            # a currently-valid installation token
gh-app-token <slug> --status   # remaining validity — never the token itself
```

`gh-app-token <slug>` prints a token, minting a fresh one only when the
cache is empty, corrupt, or within **5 minutes** of the token's 1-hour
expiry; otherwise it prints the cached one with no network call at all.
Every call is self-refreshing — there is nothing to cron, and no daemon.
The GitHub App JWT itself is rebuilt fresh (RS256, signed with the private
key) each time a new installation token is minted; it is never cached, only
used for the seconds it takes to make that one request.

## Wiring into `ghx`

`bin/ghx` (see its own `--help` and `private_dotfiles/github/README.md`)
already dispatches `gh` under a per-scope credential from a file in
`private_dotfiles/github/tokens/<scope>`. A fourth scope-file kind adds
this App as one of those scopes: a token file whose **sole content** is

```text
app:<slug>
```

names an App-backed scope. `ghx <scope> ...` then calls
`gh-app-token <slug>` for the credential instead of reading the file as a
literal PAT — the file holds a *pointer* to the App identity, not a secret
itself.

```bash
printf 'app:<slug>' > private_dotfiles/github/tokens/bot
ghx bot issue comment 42 --body '...'   # runs under the App's installation token
```

`ghx --list` reports an App-backed scope as `App (<slug>)`, distinctly from
a plain-PAT `token` scope or a `declared; uses the stored credential` empty
scope. `ghx --expiry` delegates an App-backed scope straight to
`gh-app-token <slug> --status`, rather than re-deriving expiry logic that
already lives here.

## Threat model

- **Fails closed.** A missing or unreadable `private-key.pem` / `app-id` /
  `installation-id` stops `gh-app-token` with a clear error. It never falls
  back to an unauthenticated call, and it never silently reuses a stale or
  partial credential.
- **The cache is not a secret store by accident.** `gh-app-token` creates
  `${XDG_CACHE_HOME:-~/.cache}/gh-app-token/` mode `0700` and each
  `<slug>.token` file mode `0600`, and writes are staged through a temp file
  (created with the right mode *before* any content lands in it, then moved
  into place) so an interrupted write can never leave a truncated token
  readable at the final path — the same pattern `ghx --rotate` uses for a
  PAT. Nothing here depends on the machine's umask being sane; both modes
  are set explicitly regardless of it. A cache directory that somehow ended
  up world-readable outside of `gh-app-token`'s own control (a restored
  backup, a misconfigured `$XDG_CACHE_HOME`) is a host-level problem this
  script cannot detect from inside itself — it is not different in that
  respect from any other 0600 credential file on the machine.
- **A corrupt or partial cache is a miss, never a partial trust.** A cache
  file with the wrong number of lines, or a non-numeric expiry, is treated
  exactly like an absent cache: `gh-app-token` remints rather than gambling
  on a malformed value.
- **Nothing here is ever echoed.** The private key is handed to `openssl`
  by file path — it is never read into a shell variable, so there is
  nothing to leak through a stray `set -x` or an error message. The JWT and
  the minted installation token are bearer credentials exactly like a PAT;
  neither is printed anywhere except the deliberate `token` action's own
  stdout. `--status` reports validity — a boolean-ish state plus a
  timestamp — and deliberately never the token value, mirroring `ghx
  --expiry`'s own discipline.
- **The private key has no GitHub-enforced expiry.** Unlike the minted
  installation token (1 hour) or the JWT built from it (≤ 10 minutes), the
  key itself does not expire on GitHub's side — `--status` says so on every
  call as a standing reminder. Rotating it is the same manual dance as
  generating it: **Generate a private key** on the App's settings page
  mints an *additional* key (GitHub allows several live keys per App so a
  rotation has no downtime window), then replace
  `private-key.pem` and revoke the old key from that same settings page
  once the new one is confirmed working.
- **Narrow, explicit blast radius.** The App's only permission is
  `issues: write`; it can be installed on, and therefore only ever reach,
  the repositories the operator has explicitly selected. A leaked
  installation token is bounded by both — it cannot touch a repo the App
  was never installed on, and it cannot do anything beyond issue/comment
  authorship even on a repo it was installed on. It also self-expires
  within an hour regardless of whether anyone notices the leak.

## Sources

- GitHub Apps — generating a JWT: authenticating-with-a-github-app/
  generating-a-json-web-token-jwt-for-a-github-app (the RS256 + `iat`/`exp`/
  `iss` claims, the 10-minute cap, and the bash+openssl signing recipe this
  script adapts).
- GitHub Apps — authenticating as an installation:
  authenticating-with-a-github-app/authenticating-as-a-github-app-
  installation (the `POST /app/installations/{id}/access_tokens` endpoint
  and its 1-hour token lifetime).
- GitHub Apps — managing private keys:
  authenticating-with-a-github-app/managing-private-keys-for-github-apps
  (up to 25 live keys per App for downtime-free rotation; keys do not
  expire and are revoked by hand).

  Grounded against the local `github-docs` clone at commit `d19b6951`.
