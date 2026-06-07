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
# The repo is mounted read-only at /dotfiles. Sets $output/$status.
ps_startup() {
  run docker run --rm -v "$(dotfiles_root):/dotfiles:ro" -e PSCMD="$1" \
    "$PS_IMAGE" bash -c '
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
