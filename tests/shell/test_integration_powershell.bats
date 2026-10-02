#!/usr/bin/env bats

# Integration test for the PowerShell startup (ps-startup.ps1 + the
# powershell/startup/*.ps1 modules), run in a pwsh container. Deploys
# ps-startup.ps1 as the profile and asserts it comes up with DOTFILES set,
# the startup modules loaded, and no parser errors. Skips when docker is
# unavailable.

# shellcheck disable=SC2016  # PowerShell $env: refs are evaluated by pwsh.

load ../helpers/common

PS_IMAGE='mcr.microsoft.com/powershell'

setup() {
  load_bats_libs
  command -v docker > /dev/null 2>&1 || skip "docker not available"
}

# Deploy ps-startup.ps1 as the pwsh profile and run a pwsh script (passed via
# an env var, written to a file so the container's bash never expands its
# $env: references). pwsh loads the profile, then runs the script.
# The repo is mounted read-only at /dotfiles. Arguments: docker's tty flag
# (empty or -t), pwsh's arguments (word-split; the script is /tmp/cmd.ps1),
# the script, and optional bash run before pwsh starts, e.g. to seed PATH.
# Sets $output/$status.
ps_run() {
  # shellcheck disable=SC2086  # $1 is empty or one flag; empty must vanish.
  run docker run --rm $1 -v "$(dotfiles_root):/dotfiles:ro" -e PSARGS="$2" \
    -e PSCMD="$3" -e PREP="${4:-}" "$PS_IMAGE" bash -c '
      eval "$PREP"
      mkdir -p ~/.config/powershell
      printf "%s\n" ". /dotfiles/ps-startup.ps1" \
        > ~/.config/powershell/Microsoft.PowerShell_profile.ps1
      printf "%s" "$PSCMD" > /tmp/cmd.ps1
      pwsh $PSARGS
    '
}

# A non-interactive run: pwsh -File, no tty. Arguments: script, prep.
ps_startup() {
  ps_run '' '-File /tmp/cmd.ps1' "$@"
}

# An interactive run: stdin is a pseudo-tty and -NoExit keeps the session at
# its prompt after the script. The exit ends that session; it has to be in
# -Command, since an exit inside a -File script only ends the script.
ps_startup_interactive() {
  ps_run '-t' '-NoExit -Command . /tmp/cmd.ps1; exit' "$@"
}

# Reports the env and the interactive-only setup a session ended up with.
PS_REPORT='
  Write-Output "DOTFILES=$env:DOTFILES"
  Write-Output "interactive=$DOTFILES_INTERACTIVE"
  Write-Output "hasAlias=$([bool](Get-Alias c -ErrorAction SilentlyContinue))"
  Write-Output "hasFunc=$([bool](Get-Command Set-ParentDirectory -ErrorAction SilentlyContinue))"
  Write-Output "hasS3cmd=$([bool](Get-Command s3cmd -ErrorAction SilentlyContinue))"
  Write-Output "hasPath=$(($env:PATH -split [IO.Path]::PathSeparator) -contains "/dotfiles/powershell/bin")"
'

@test "non-interactive pwsh -File gets the env but not the interactive setup" {
  ps_startup "$PS_REPORT"
  assert_success
  assert_output --partial 'DOTFILES=/dotfiles'
  assert_output --partial 'hasPath=True'
  assert_output --partial 'interactive=False'
  assert_output --partial 'hasAlias=False'
  assert_output --partial 'hasFunc=False'
  assert_output --partial 'hasS3cmd=False'
}

@test "interactive pwsh gets both the env and the interactive setup" {
  ps_startup_interactive "$PS_REPORT"
  assert_success
  assert_output --partial 'DOTFILES=/dotfiles'
  assert_output --partial 'hasPath=True'
  assert_output --partial 'interactive=True'
  assert_output --partial 'hasAlias=True'
  assert_output --partial 'hasFunc=True'
  assert_output --partial 'hasS3cmd=True'
  refute_output --partial 'ParserError'
  refute_output --partial 'is not recognized'
}

@test "pwsh startup classifies each way of starting pwsh" {
  # One container, every invocation on a tty unless it pipes stdin, so only
  # the command line (or the pipe) decides. Each line is label=verdict.
  run docker run --rm -t -v "$(dotfiles_root):/dotfiles:ro" "$PS_IMAGE" \
    bash -c '
      mkdir -p ~/.config/powershell
      printf "%s\n" ". /dotfiles/ps-startup.ps1" \
        > ~/.config/powershell/Microsoft.PowerShell_profile.ps1
      r="Write-Output \"\$DOTFILES_INTERACTIVE\""
      printf "%s\n" "$r" > /tmp/r.ps1
      v() { printf "%s=%s\n" "$1" "$(grep -oE "True|False" | tail -n 1)"; }
      pwsh -Command "$r" | v command
      pwsh -c "$r" | v c-short
      pwsh -comm "$r" | v c-prefix
      pwsh /tmp/r.ps1 | v positional
      pwsh -ExecutionPolicy Bypass -File /tmp/r.ps1 | v value-then-file
      pwsh -NonInteractive -NoExit -Command "$r; exit" | v noninteractive
      printf "%s\nexit\n" "$r" | pwsh -File - | v piped-stdin
      pwsh -NoExit -Command "$r; exit" | v noexit-command
      pwsh -wd /tmp -noe -c "$r; exit" | v value-then-noexit
    '
  assert_success
  assert_line --partial 'command=False'
  assert_line --partial 'c-short=False'
  assert_line --partial 'c-prefix=False'
  assert_line --partial 'positional=False'
  assert_line --partial 'value-then-file=False'
  assert_line --partial 'noninteractive=False'
  assert_line --partial 'piped-stdin=False'
  assert_line --partial 'noexit-command=True'
  assert_line --partial 'value-then-noexit=True'
}

@test "pwsh startup loads the modules without parser errors" {
  ps_startup 'Write-Output started-ok'
  assert_success
  assert_output --partial 'started-ok'
  refute_output --partial 'ParserError'
  refute_output --partial 'is not valid'
}

@test "pwsh startup builds PATH with the platform separators" {
  ps_startup '
    $env:PATH -split [IO.Path]::PathSeparator |
      ForEach-Object { Write-Output "entry=$_" }
  '
  assert_success
  assert_output --partial 'entry=/dotfiles/powershell/bin'
  refute_output --partial "\\"
  refute_output --regexp 'entry=[^[:space:]]*;'
}

@test "pwsh startup leaves no duplicate PATH entries" {
  # Seed an inherited PATH that repeats a system dir and already carries one
  # of the entries the profile prepends, so both dedup cases are exercised.
  ps_startup '
    $entries = $env:PATH -split [IO.Path]::PathSeparator
    $dups = @($entries | Group-Object | Where-Object Count -gt 1)
    Write-Output "dups=$($dups.Count)"
    $dups | ForEach-Object { Write-Output "dup=$($_.Name)" }
  ' 'export PATH="$HOME/.local/bin:$PATH:/usr/bin"'
  assert_success
  assert_output --partial 'dups=0'
}
