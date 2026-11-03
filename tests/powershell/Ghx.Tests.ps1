#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0' }

# Tests for powershell/bin/ghx.ps1. A global `gh` function stands in for the
# real CLI: it answers ghx's command-list probe and records what it was run
# with. Tokens are dummies in a temp token directory, and the stub reports
# only whether a token variable is set and how long it is, never its value.

[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
  'PSUseDeclaredVarsMoreThanAssignments', '',
  Justification = 'Pester shares BeforeAll/BeforeEach variables with It blocks, which PSScriptAnalyzer cannot see.')]
param ()

Describe 'ghx.ps1' {
  BeforeAll {
    $script:ghx = [IO.Path]::GetFullPath((Join-Path -Path $PSScriptRoot -ChildPath '../../powershell/bin/ghx.ps1'))

    $script:saved = @{}
    foreach ($name in 'PROJECTS_DIR', 'GH_TOKEN', 'GITHUB_TOKEN') {
      $script:saved[$name] = [Environment]::GetEnvironmentVariable($name)
    }

    $script:tokenDir = Join-Path -Path $TestDrive -ChildPath 'private_dotfiles/github/tokens'

    function global:gh {
      if ($args[0] -eq '__ghx_probe_unknown_command__') {
        'Usage: gh <command> <subcommand> [flags]'
        ''
        'CORE COMMANDS'
        '  auth:          Authenticate gh and git with GitHub'
        '  pr:            Manage pull requests'
        ''
        'HELP TOPICS'
        '  environment:   Environment variables that can be used with gh'
        return
      }

      $global:GhStubCall = [pscustomobject]@{
        Args        = @($args | ForEach-Object { [string]$_ })
        TokenLength = if ($env:GH_TOKEN) { $env:GH_TOKEN.Length } else { 0 }
        GithubToken = [bool]$env:GITHUB_TOKEN
      }
      $global:LASTEXITCODE = $global:GhStubExit
    }

    function Write-Token {
      param ([string]$Scope, [string]$Content)
      New-Item -ItemType Directory -Path $script:tokenDir -Force | Out-Null
      [IO.File]::WriteAllText((Join-Path -Path $script:tokenDir -ChildPath $Scope), $Content)
    }

    function Invoke-Ghx {
      $global:GhStubCall = $null
      $output = & $script:ghx @args *>&1 | ForEach-Object { "$_" }
      [pscustomobject]@{ Output = ($output -join "`n"); Code = $LASTEXITCODE; Call = $global:GhStubCall }
    }
  }

  BeforeEach {
    $env:PROJECTS_DIR = $TestDrive
    $env:GH_TOKEN = $null
    $env:GITHUB_TOKEN = 'ambient-dummy'
    $global:GhStubExit = 0
    Remove-Item -LiteralPath $script:tokenDir -Recurse -Force -ErrorAction SilentlyContinue
    Write-Token -Scope 'acme' -Content "acme-dummy-token`n"
    Write-Token -Scope 'plain' -Content ''
  }

  AfterAll {
    foreach ($name in $script:saved.Keys) {
      [Environment]::SetEnvironmentVariable($name, $script:saved[$name])
    }
    Remove-Item -Path Function:\gh -ErrorAction SilentlyContinue
    Remove-Variable -Name GhStubCall, GhStubExit -Scope Global -ErrorAction SilentlyContinue
  }

  It 'runs gh under the scope token, dropping the scope from the arguments' {
    $r = Invoke-Ghx acme pr list --limit 3

    $r.Call.Args | Should -Be @('pr', 'list', '--limit', '3')
    $r.Call.TokenLength | Should -Be 'acme-dummy-token'.Length
    $r.Call.GithubToken | Should -BeFalse
  }

  It 'restores the caller environment after the run' {
    $env:GH_TOKEN = 'before'
    Invoke-Ghx acme pr list | Out-Null

    $env:GH_TOKEN | Should -Be 'before'
    $env:GITHUB_TOKEN | Should -Be 'ambient-dummy'
  }

  It 'passes a gh command straight through with no token injected' {
    $r = Invoke-Ghx pr list

    $r.Call.Args | Should -Be @('pr', 'list')
    $r.Call.TokenLength | Should -Be 0
    $r.Call.GithubToken | Should -BeTrue
  }

  It 'passes through when no argument is a non-option' {
    $r = Invoke-Ghx --version

    $r.Call.Args | Should -Be @('--version')
    $r.Call.TokenLength | Should -Be 0
  }

  It 'passes through a bare invocation' {
    $r = Invoke-Ghx

    $r.Call.Args.Count | Should -Be 0
  }

  It 'defers to the stored credential for an empty scope file' {
    $r = Invoke-Ghx plain pr list

    $r.Call.Args | Should -Be @('pr', 'list')
    $r.Call.TokenLength | Should -Be 0
    $r.Call.GithubToken | Should -BeFalse
  }

  It 'passes on gh''s exit code' {
    $global:GhStubExit = 7

    (Invoke-Ghx acme pr list).Code | Should -Be 7
  }

  It 'rejects an unknown scope, lists the known ones and never runs gh' {
    $r = Invoke-Ghx nosuch pr list

    $r.Code | Should -Be 1
    $r.Output | Should -Match "no token defined for 'nosuch'"
    $r.Output | Should -Match 'acme'
    $r.Call | Should -BeNullOrEmpty
  }

  It 'refuses an App-backed scope rather than running unauthenticated' {
    Write-Token -Scope 'bot' -Content 'app:my-slug'
    $r = Invoke-Ghx bot pr list

    $r.Code | Should -Be 1
    $r.Output | Should -Match 'App-backed'
    $r.Call | Should -BeNullOrEmpty
  }

  It 'refuses an option ghx does not port' -ForEach '--expiry', '--rotate', '--test', '--refresh' {
    $r = Invoke-Ghx $_

    $r.Code | Should -Be 2
    $r.Output | Should -Match 'not ported'
    $r.Call | Should -BeNullOrEmpty
  }

  Context 'aliases' {
    BeforeEach {
      $script:aliasOk = $true
      try {
        New-Item -ItemType SymbolicLink -Path (Join-Path $script:tokenDir 'a') -Target (Join-Path $script:tokenDir 'acme') -ErrorAction Stop | Out-Null
        New-Item -ItemType SymbolicLink -Path (Join-Path $script:tokenDir 'dead') -Target (Join-Path $script:tokenDir 'gone') -ErrorAction Stop | Out-Null
      } catch {
        $script:aliasOk = $false
      }
    }

    It 'follows an alias to its scope' {
      if (-not $script:aliasOk) { Set-ItResult -Skipped -Because 'symlinks need privilege on this host'; return }

      $r = Invoke-Ghx a pr list

      $r.Call.TokenLength | Should -Be 'acme-dummy-token'.Length
    }

    It 'errors on an alias to a missing scope' {
      if (-not $script:aliasOk) { Set-ItResult -Skipped -Because 'symlinks need privilege on this host'; return }

      $r = Invoke-Ghx dead pr list

      $r.Code | Should -Be 1
      $r.Output | Should -Match 'points at a missing scope'
      $r.Call | Should -BeNullOrEmpty
    }
  }

  Context '--list' {
    It 'shows each scope by kind and never a token' {
      Write-Token -Scope 'bot' -Content 'app:my-slug'
      $r = Invoke-Ghx --list

      $r.Code | Should -Be 0
      $r.Output | Should -Match 'acme\s+token'
      $r.Output | Should -Match 'plain\s+declared; uses the stored credential'
      $r.Output | Should -Match 'bot\s+App \(my-slug\)'
      $r.Output | Should -Not -Match 'acme-dummy-token'
      $r.Call | Should -BeNullOrEmpty
    }

    It 'reports a missing token directory' {
      Remove-Item -LiteralPath $script:tokenDir -Recurse -Force

      (Invoke-Ghx --list).Output | Should -Match 'No scopes configured'
    }
  }
}
