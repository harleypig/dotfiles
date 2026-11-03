#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0' }

# Tests for powershell/bin/Invoke-GitAll.ps1, against throwaway repositories
# under $TestDrive, found through $env:REPOHOME.

[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
  'PSUseDeclaredVarsMoreThanAssignments', '',
  Justification = 'Pester shares BeforeAll/BeforeEach variables with It blocks, which PSScriptAnalyzer cannot see.')]
param ()

Describe 'Invoke-GitAll.ps1' {
  BeforeAll {
    $script:tool = [IO.Path]::GetFullPath((Join-Path -Path $PSScriptRoot -ChildPath '../../powershell/bin/Invoke-GitAll.ps1'))
    $env:GIT_CONFIG_GLOBAL = Join-Path -Path $TestDrive -ChildPath 'gitconfig'
    $env:GIT_CONFIG_SYSTEM = [IO.Path]::GetTempFileName()
    git config --global user.email t@example.com
    git config --global user.name Test
    git config --global init.defaultBranch main

    $script:repoRoot = Join-Path -Path $TestDrive -ChildPath 'repos'
    $script:a = Join-Path -Path $script:repoRoot -ChildPath 'a'
    $script:b = Join-Path -Path $script:repoRoot -ChildPath 'nested/b'
    foreach ($repo in $script:a, $script:b) {
      git init -q $repo
      git -C $repo commit -q --allow-empty -m init
    }

    # Only b has a tag, so `git rev-parse v1` passes there and fails in a.
    git -C $script:b tag v1

    $env:REPOHOME = $script:repoRoot
  }

  AfterAll {
    Remove-Item -Path Env:GIT_CONFIG_GLOBAL, Env:GIT_CONFIG_SYSTEM, Env:REPOHOME -ErrorAction SilentlyContinue
  }

  It 'runs the command in every repository, nested ones included, and lists the passes' {
    $out = & $script:tool log --oneline *>&1 | Out-String

    $out | Should -Match 'Job Summary For 2 Repos: git log --oneline'
    $out | Should -Match 'No errors were reported'
    $out | Should -Match ('\[PASS\] ' + [regex]::Escape($script:a))
    $out | Should -Match ('\[PASS\] ' + [regex]::Escape($script:b))
  }

  It 'passes git options through untouched' {
    $out = & $script:tool status -s -b *>&1 | Out-String

    $out | Should -Match 'Job Summary For 2 Repos: git status -s -b'
    $out | Should -Match 'No errors were reported'
  }

  It 'lists failing repositories apart from the passing ones' {
    $out = & $script:tool rev-parse --verify --quiet refs/tags/v1 *>&1 | Out-String

    $out | Should -Match ('\[FAIL\] ' + [regex]::Escape($script:a))
    $out | Should -Match ('\[PASS\] ' + [regex]::Escape($script:b))
    $out | Should -Not -Match 'No errors were reported'
  }

  It 'shows the output of a failed repository with -v' {
    $out = & $script:tool -v checkout no-such-branch *>&1 | Out-String

    $out | Should -Match 'no-such-branch'
    $out | Should -Match '\[FAIL\]'
  }

  It 'lists only repositories with modified tracked files with -S' {
    New-Item -ItemType File -Path (Join-Path $script:a 'new.txt') | Out-Null
    git -C $script:a add new.txt
    New-Item -ItemType File -Path (Join-Path $script:b 'untracked.txt') | Out-Null

    try {
      $out = @(& $script:tool -S)
    } finally {
      git -C $script:a reset -q
      Remove-Item (Join-Path $script:a 'new.txt'), (Join-Path $script:b 'untracked.txt')
    }

    $out | Should -Be @($script:a)
  }

  It 'fails with usage when no command is given' {
    & $script:tool *> $null

    $LASTEXITCODE | Should -Be 1
  }

  It 'fails on an unknown option and on an invalid REPOHOME' {
    & $script:tool -Z status 2>$null
    $LASTEXITCODE | Should -Be 1

    $env:REPOHOME = Join-Path $TestDrive 'nope'
    try {
      & $script:tool status 2>$null
      $LASTEXITCODE | Should -Be 1
    } finally {
      $env:REPOHOME = $script:repoRoot
    }
  }
}
