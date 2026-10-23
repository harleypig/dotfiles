#!/usr/bin/env bats

# Integration test for the PowerShell startup (ps-startup.ps1 + the
# powershell/startup/*.ps1 modules), run in a pwsh container. Deploys
# ps-startup.ps1 as the profile and asserts it comes up with DOTFILES set,
# the startup modules loaded, and no parser errors. Skips when docker is
# unavailable.

# shellcheck disable=SC2016  # PowerShell $env: refs are evaluated by pwsh.

load ../helpers/common

# The PowerShell team's own mcr.microsoft.com/powershell images are
# deprecated and frozen (latest is pwsh 7.4.2); Microsoft now ships pwsh in
# the .NET SDK image. 10.0.402-noble carries pwsh 7.6.7 (LTS) on Ubuntu
# 24.04. Dependabot cannot see this pin, so bump it by hand.
PS_IMAGE='mcr.microsoft.com/dotnet/sdk:10.0.402-noble@sha256:747cbade5bfd918a175ac32f8f1d931edec2c7d0d5397a3de72eaef1ac1f66d2'

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

# A non-interactive run whose stderr comes back with each line prefixed
# "stderr: ", so a test can tell the two streams apart. Arguments: script,
# prep.
ps_startup_split() {
  ps_run '' '-File /tmp/cmd.ps1' "$1" "${2:-}
    pwsh() { { command pwsh \"\$@\" 2>&1 1>&3 | sed 's/^/stderr: /'; } 3>&1; }"
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

@test "interactive pwsh applies the PSReadLine history settings" {
  # XDG_STATE_HOME is seeded so the save path is checkable; the handler is
  # probed directly with a leading-space line, a HISTIGNORE word and a line
  # that must be kept.
  ps_startup_interactive '
    $o = Get-PSReadLineOption
    Write-Output "noDups=$($o.HistoryNoDuplicates)"
    Write-Output "maxCount=$($o.MaximumHistoryCount)"
    Write-Output "savePath=$($o.HistorySavePath)"
    Write-Output "dirExists=$(Test-Path /tmp/state/powershell)"
    $h = $o.AddToHistoryHandler
    Write-Output "space=$($h.Invoke(" Get-Date"))"
    Write-Output "ignored=$($h.Invoke("exit"))"
    Write-Output "kept=$($h.Invoke("Get-Date"))"
  ' 'export XDG_STATE_HOME=/tmp/state'
  assert_success
  assert_output --partial 'noDups=True'
  assert_output --partial 'maxCount=100000'
  assert_output --partial 'savePath=/tmp/state/powershell/history'
  assert_output --partial 'dirExists=True'
  assert_output --partial 'space=False'
  assert_output --partial 'ignored=False'
  assert_output --partial 'kept=True'
  refute_output --partial 'Exception'
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

@test "pwsh debug is silent unless DEBUG is a non-zero integer" {
  local script='debug "trace-msg"; "piped-msg" | debug; Write-Output done'

  ps_startup_split "$script"
  assert_success
  assert_line 'done'
  refute_output --partial 'msg'
  refute_output --partial 'stderr:'

  ps_startup_split "$script" 'export DEBUG=0'
  assert_success
  assert_line 'done'
  refute_output --partial 'stderr:'
}

@test "pwsh debug writes a call-stack-prefixed line to stderr" {
  ps_startup_split '
    function Invoke-Outer { Invoke-Inner }
    function Invoke-Inner { debug "trace-msg" }
    Invoke-Outer
    Write-Output done
  ' 'export DEBUG=1'
  assert_success
  assert_line 'done'
  assert_line --regexp \
    '^stderr: \[i\+[0-9]+ms\]\[cmd\.ps1:[0-9]{3}\]\[cmd\.ps1:Invoke-Outer:[0-9]{3}\]\[cmd\.ps1:Invoke-Inner:[0-9]{3}\] trace-msg$'
  refute_line 'stderr: done'
}

@test "pwsh debug traces each line of pipeline input" {
  ps_startup_split '"one", "two" | debug' 'export DEBUG=1'
  assert_success
  assert_line --regexp '^stderr: \[i\+[0-9]+ms\]\[cmd\.ps1:[0-9]{3}\] one$'
  assert_line --regexp '^stderr: \[i\+[0-9]+ms\]\[cmd\.ps1:[0-9]{3}\] two$'
}
