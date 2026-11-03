#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0' }

# Tests for the proj function in powershell/startup/proj.ps1. The module is
# dot-sourced as an interactive session would, and Read-Host is mocked for
# the not-found menu.

[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
  'PSUseDeclaredVarsMoreThanAssignments', '',
  Justification = 'Pester shares BeforeAll/BeforeEach variables with It blocks, which PSScriptAnalyzer cannot see.')]
param ()

Describe 'proj' {
  BeforeAll {
    $script:module = [IO.Path]::GetFullPath((Join-Path -Path $PSScriptRoot -ChildPath '../../powershell/startup/proj.ps1'))
    $script:savedProjects = $env:PROJECTS_DIR
    $script:savedLocation = Get-Location
    $script:projects = Join-Path -Path $TestDrive -ChildPath 'projects'
    [IO.Directory]::CreateDirectory((Join-Path $script:projects 'alpha')) | Out-Null

    $DOTFILES_INTERACTIVE = $true
    . $script:module
  }

  BeforeEach {
    $env:PROJECTS_DIR = $script:projects
    Set-Location -LiteralPath $TestDrive
    Mock Write-Host {}
  }

  AfterAll {
    Set-Location -LiteralPath $script:savedLocation
    $env:PROJECTS_DIR = $script:savedProjects
    Remove-Item -Path Function:\proj -ErrorAction SilentlyContinue
  }

  It 'goes to PROJECTS_DIR with no name' {
    proj

    (Get-Location).Path | Should -Be $script:projects
  }

  It 'goes to an existing project' {
    proj alpha

    (Get-Location).Path | Should -Be (Join-Path $script:projects 'alpha')
  }

  It 'creates the project and goes there on choice 1' {
    Mock Read-Host { '1' }

    proj beta

    (Get-Location).Path | Should -Be (Join-Path $script:projects 'beta')
    Test-Path -LiteralPath (Join-Path $script:projects 'beta') -PathType Container | Should -BeTrue
  }

  It 'goes to PROJECTS_DIR on choice 2, creating nothing' {
    Mock Read-Host { '2' }

    proj gamma

    (Get-Location).Path | Should -Be $script:projects
    Test-Path -LiteralPath (Join-Path $script:projects 'gamma') | Should -BeFalse
  }

  It 'stays put on choice 3 and at end of input' {
    Mock Read-Host { '3' }
    proj delta
    (Get-Location).Path | Should -Be $TestDrive.ToString()

    Mock Read-Host { $null }
    proj delta
    (Get-Location).Path | Should -Be $TestDrive.ToString()
    Test-Path -LiteralPath (Join-Path $script:projects 'delta') | Should -BeFalse
  }

  It 'asks again after an answer that is not a choice' {
    $script:answers = [Collections.Generic.Queue[string]]::new([string[]]@('x', '2'))
    Mock Read-Host { $script:answers.Dequeue() }

    proj epsilon

    Should -Invoke Read-Host -Times 2 -Exactly
    (Get-Location).Path | Should -Be $script:projects
  }

  It 'reports an error and stays put when PROJECTS_DIR is unset' {
    $env:PROJECTS_DIR = $null

    proj alpha -ErrorAction SilentlyContinue -ErrorVariable problem

    $problem | Should -Match 'PROJECTS_DIR is not set'
    (Get-Location).Path | Should -Be $TestDrive.ToString()
  }
}
