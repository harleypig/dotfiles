#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0' }

# Tests for powershell/bin/Remove-StaleGitBranch.ps1, against a throwaway
# bare "remote" and clone under $TestDrive.

[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
  'PSUseDeclaredVarsMoreThanAssignments', '',
  Justification = 'Pester shares BeforeAll/BeforeEach variables with It blocks, which PSScriptAnalyzer cannot see.')]
param ()

Describe 'Remove-StaleGitBranch.ps1' {
  BeforeAll {
    $script:tool = [IO.Path]::GetFullPath((Join-Path -Path $PSScriptRoot -ChildPath '../../powershell/bin/Remove-StaleGitBranch.ps1'))
    $env:GIT_CONFIG_GLOBAL = Join-Path -Path $TestDrive -ChildPath 'gitconfig'
    $env:GIT_CONFIG_SYSTEM = [IO.Path]::GetTempFileName()
    git config --global user.email t@example.com
    git config --global user.name Test
    git config --global init.defaultBranch main
    git config --global protocol.file.allow always
  }

  BeforeEach {
    $script:origin = Join-Path -Path $TestDrive -ChildPath 'origin.git'
    $script:clone = Join-Path -Path $TestDrive -ChildPath 'clone'
    Remove-Item -LiteralPath $script:origin, $script:clone -Recurse -Force -ErrorAction SilentlyContinue

    git init -q --bare $script:origin
    git clone -q $script:origin $script:clone 2>$null
    Push-Location -LiteralPath $script:clone
    git commit -q --allow-empty -m init
    git push -q origin main 2>$null

    # 'merged' is pushed, then deleted on the remote, so its upstream is
    # gone; 'local' was never pushed.
    git branch merged
    git push -q origin merged 2>$null
    git branch --set-upstream-to=origin/merged merged 2>$null | Out-Null
    git branch local
    git push -q origin --delete merged 2>$null
  }

  AfterEach {
    Pop-Location
  }

  AfterAll {
    Remove-Item -Path Env:GIT_CONFIG_GLOBAL, Env:GIT_CONFIG_SYSTEM -ErrorAction SilentlyContinue
  }

  It 'lists a branch whose remote is gone with -DryRun, and deletes nothing' {
    $out = & $script:tool -DryRun | Out-String

    $out | Should -Match 'Would delete branch: merged \(remote branch gone\)'
    $out | Should -Not -Match 'local'
    git branch --list merged | Should -Not -BeNullOrEmpty
  }

  It 'deletes the gone branch with -Force and keeps the others' {
    & $script:tool -Force | Out-Null

    git branch --list merged | Should -BeNullOrEmpty
    git branch --list local | Should -Not -BeNullOrEmpty
    git branch --list main | Should -Not -BeNullOrEmpty
  }

  It 'includes never-pushed branches with -All' {
    $out = & $script:tool -n -a | Out-String

    $out | Should -Match 'Would delete branch: local \(never pushed\)'
  }

  It 'never touches the checked-out branch' {
    git checkout -q merged

    $out = & $script:tool -f | Out-String

    $out | Should -Not -Match 'Deleting branch: merged'
    git branch --list merged | Should -Not -BeNullOrEmpty
  }

  It 'requires exactly one of -DryRun and -Force' {
    { & $script:tool } | Should -Throw
    { & $script:tool -DryRun -Force } | Should -Throw
  }

  It 'fails outside a git repository' {
    Push-Location -LiteralPath $TestDrive
    try {
      & $script:tool -n 2>$null
      $LASTEXITCODE | Should -Be 1
    } finally {
      Pop-Location
    }
  }
}
