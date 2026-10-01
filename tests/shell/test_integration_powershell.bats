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
# $env: references). pwsh -File loads the profile, then runs the script.
# The repo is mounted read-only at /dotfiles. An optional second argument is
# bash run before pwsh starts, e.g. to seed PATH. Sets $output/$status.
ps_startup() {
  run docker run --rm -v "$(dotfiles_root):/dotfiles:ro" -e PSCMD="$1" \
    -e PREP="${2:-}" "$PS_IMAGE" bash -c '
      eval "$PREP"
      mkdir -p ~/.config/powershell
      printf "%s\n" ". /dotfiles/ps-startup.ps1" \
        > ~/.config/powershell/Microsoft.PowerShell_profile.ps1
      printf "%s" "$PSCMD" > /tmp/cmd.ps1
      pwsh -File /tmp/cmd.ps1
    '
}

@test "pwsh profile comes up with DOTFILES and startup modules loaded" {
  ps_startup '
    Write-Output "DOTFILES=$env:DOTFILES"
    Write-Output "hasAlias=$([bool](Get-Alias c -ErrorAction SilentlyContinue))"
    Write-Output "hasFunc=$([bool](Get-Command Set-ParentDirectory -ErrorAction SilentlyContinue))"
  '
  assert_success
  assert_output --partial 'DOTFILES=/dotfiles'
  assert_output --partial 'hasAlias=True'
  assert_output --partial 'hasFunc=True'
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
