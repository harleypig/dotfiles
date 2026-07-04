#!/usr/bin/env python3

"""PreToolUse hook: block echoing a secret's value to the terminal.

Enforces the global CLAUDE.md "Secret Handling" rule at command time — the
enforcement layer a rule alone could not provide (the same mistake leaked
live credentials three times across repos/sessions despite the written rule).

Fires on a Bash command that prints a **secret-looking variable's value** to
stdout/stderr via `echo` / `printf` — the "let me just echo it to check it's
set" pattern, whose value then lands in the transcript and must be rotated.
The classic form is `echo "${TOKEN:-unset}"` (the `:-` fallback prints the
value) or a bare `echo "$SECRET"`.

Leak vs legitimate use — the hook blocks only output that reaches the
terminal. A secret whose value is **consumed** is allowed:

  - piped to a command      `echo "$TOKEN" | gh auth login --with-token`
  - redirected to a file    `printf '%s' "$SECRET" > .netrc`
  - captured in `$(...)`     `hash=$(printf '%s' "$KEY" | sha256sum)`

Detection heuristics (deliberately conservative; blocking a legitimate
command is worse than missing an exotic leak, so anything ambiguous is
allowed):

  - Only `echo` / `printf` at a command position are considered.
  - A reference counts only if it is **value-yielding**: `$VAR`, `${VAR}`,
    `${VAR:-…}`, `${VAR:=…}`, substrings, etc. The set/unset markers
    `${VAR:+…}` / `${VAR+…}` and the length `${#VAR}` print no value and are
    allowed.
  - "Secret-looking" is the variable *name* matching TOKEN / SECRET /
    PASSWORD / PASSPHRASE / CREDENTIAL / API[_]KEY / ACCESS[_]KEY /
    PRIVATE_KEY / *_KEY / *_PAT (the rule's `*_TOKEN`, `*_KEY`,
    `AWS_SECRET_*`, `*_PASSWORD` set).

Heredoc bodies (`<<'EOF' … EOF`) are data — a commit message, a PR body — so
they are stripped before scanning; documenting this very pattern inside one
does not trip the hook. It stays quote-blind for INLINE data, so a command
separator inside a one-line quoted arg (`git commit -m "…; echo $X_TOKEN"`)
could still match — rare and rewordable. Other misses (all fail toward
*allowing*): `2>`-only stderr redirects (still leak stdout) and subshell
`( echo $S )`.

Fail-safe: any error exits 0 silently so a hook bug can never block a command.
"""

from __future__ import annotations

import json
import re
import sys

# A variable name that looks like it holds a secret (the rule's coverage set).
SECRET_NAME_RE = re.compile(
  r"(?:TOKEN|SECRET|PASSWORD|PASSWD|PASSPHRASE|CREDENTIAL|PRIVATE_KEY"
  r"|API_?KEY|ACCESS_?KEY|_KEY|_PAT)",
  re.IGNORECASE,
)

# An `echo` / `printf` at a command position, capturing its args and the
# delimiter that follows. `args` stops at the first shell metacharacter; `term`
# is that delimiter (longest alternatives first so `&&` beats `&`, `>>` beats
# `>`). A leak is an echo whose `term` does NOT hand its stdout to a consumer.
ECHO_RE = re.compile(
  r"(?:^|[\n;&|`(]|&&|\|\|)\s*"
  r"(?P<cmd>echo|printf)\b"
  r"(?P<args>[^\n;&|>`)]*)"
  r"(?P<term>&&|\|\||&>|>>|>|\||;|&|`|\)|\n|$)"
)

# Terminators that send the echo's stdout somewhere other than the terminal:
# a pipe, an stdout redirect, or the close of a `$(...)` capture. Everything
# else (`;`, `&&`, `||`, `&`, newline, end of string) leaves it on the
# terminal.
CONSUMED_TERMS = {"|", ">", ">>", "&>", ")"}

# A variable expansion: `${[#]name[op]}` or a bare `$name`.
EXPANSION_RE = re.compile(
  r"\$\{(?P<len>#)?(?P<bname>[A-Za-z_][A-Za-z0-9_]*)(?P<op>[^}]*)\}"
  r"|\$(?P<sname>[A-Za-z_][A-Za-z0-9_]*)"
)

# A heredoc opener `<<[-] [']DELIM[']`. The body between it and the closing
# delimiter line is data (a commit message, a PR body, a config file), never a
# command, so it is stripped before scanning — documenting the very pattern
# this hook blocks must not trip it.
HEREDOC_RE = re.compile(
  r"<<(?P<dash>-?)\s*['\"]?(?P<delim>[A-Za-z_]\w*)['\"]?"
)

DENY_MSG = (
  "Blocked: this command prints a secret-looking variable's VALUE to the "
  "terminal — the leak the global CLAUDE.md \"Secret Handling\" rule forbids. "
  "A secret that reaches stdout/stderr lands in the transcript and must then "
  "be rotated.\n\n"
  "Offending fragment: __SNIPPET__\n\n"
  "Fix:\n"
  "  - To check PRESENCE, test the variable — do not print it:\n"
  "      [[ -n $VAR ]] && echo set || echo unset\n"
  "  - Bare `$VAR` and `${VAR:-…}` print the value; use `${VAR:+set}` if you "
  "only want a set/unset marker.\n"
  "  - If the value is genuinely being CONSUMED (piped to a command, "
  "redirected to a file, or captured in `$(…)`), that is allowed — this hook "
  "blocks only output left on the terminal; re-run with it consumed.\n\n"
  "This hook fails safe (any error allows the command)."
)


def _yields_value(m: re.Match) -> bool:
  """True when a variable expansion emits the variable's value (vs a set/unset
  marker or its length)."""
  # A bare $NAME always yields the value.
  if m.group("sname"):
    return True
  # ${#NAME} is the length, not the value.
  if m.group("len"):
    return False
  # ${NAME:+word} / ${NAME+word} substitute a literal word, not the value.
  op = m.group("op") or ""
  if re.match(r":?\+", op):
    return False
  return True


def _references_secret_value(args: str) -> bool:
  """True when `args` contains a value-yielding expansion of a secret-looking
  variable."""
  for m in EXPANSION_RE.finditer(args):
    name = m.group("bname") or m.group("sname") or ""
    if SECRET_NAME_RE.search(name) and _yields_value(m):
      return True
  return False


def _strip_heredocs(command: str) -> str:
  """Remove heredoc *bodies* so their data content is not scanned. The opener
  line (which may still hold a real command) and the closing delimiter line
  are kept; only the body between them is dropped. Multiple heredocs opened on
  one line are consumed in order. A `<<` with no matching closing delimiter
  (or an arithmetic `<<`) drops the rest of the command — fail-open, since a
  missed scan only ever allows."""
  lines = command.split("\n")
  out: list[str] = []
  i, n = 0, len(lines)
  while i < n:
    line = lines[i]
    out.append(line)
    i += 1
    for m in HEREDOC_RE.finditer(line):
      dash, delim = m.group("dash"), m.group("delim")
      while i < n:
        body = lines[i]
        i += 1
        candidate = body.lstrip("\t") if dash else body
        # The delimiter alone on a line closes the heredoc: keep it and stop.
        # Any other line is body data and is simply not appended (dropped).
        if candidate == delim:
          out.append(body)
          break
  return "\n".join(out)


def _find_leak(command: str) -> str | None:
  """Return the offending `echo`/`printf` fragment (its name, never a value),
  or None when the command prints no secret to the terminal."""
  command = _strip_heredocs(command)
  for m in ECHO_RE.finditer(command):
    if m.group("term") in CONSUMED_TERMS:
      continue     # stdout handed to a pipe / file / capture — allowed
    if _references_secret_value(m.group("args")):
      return f"{m.group('cmd')}{m.group('args')}".strip()
  return None


def main() -> int:
  try:
    event = json.load(sys.stdin)
  except Exception:
    return 0

  if event.get("tool_name") != "Bash":
    return 0

  command = (event.get("tool_input") or {}).get("command") or ""
  try:
    snippet = _find_leak(command)
  except Exception:
    return 0  # parser bug must never block a command

  if snippet:
    print(
      json.dumps({
        "hookSpecificOutput": {
          "hookEventName": "PreToolUse",
          "permissionDecision": "deny",
          "permissionDecisionReason": DENY_MSG.replace("__SNIPPET__", snippet),
        }
      })
    )

  return 0


if __name__ == "__main__":
  sys.exit(main())
