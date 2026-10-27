#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0' }

# Tests for powershell/bin/Install-Prereqs.ps1. Every command that could
# change the machine is mocked at the root, so no test reaches the registry,
# choco, winget, npm, uv, pip, PowerShellGet, UAC or a real Python. Package
# lists are written to TestDrive with .NET calls, since New-Item and
# Remove-Item are mocked.

[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
  'PSUseDeclaredVarsMoreThanAssignments', '',
  Justification = 'Pester shares BeforeAll/BeforeEach variables with It blocks, which PSScriptAnalyzer cannot see.')]
param ()

Describe 'Install-Prereqs.ps1' {
  BeforeAll {
    $script:scriptFile = Join-Path -Path $PSScriptRoot -ChildPath '..\..\powershell\bin\Install-Prereqs.ps1'
    $script:schema = [IO.Path]::GetFullPath((Join-Path -Path $PSScriptRoot -ChildPath '..\..\powershell\win-prereqs.schema.json'))
    $script:checkout = [IO.Path]::GetFullPath((Join-Path -Path $PSScriptRoot -ChildPath '..\..'))
    . $script:scriptFile

    # Mock binds only to a command that exists, and these are Windows-only.
    # A stub stands in for each one missing, so the suite runs on Linux pwsh
    # too; on Windows the real command is there and is mocked as it is.
    foreach ($missing in 'py') {
      if (-not (Get-Command -Name $missing -ErrorAction SilentlyContinue)) {
        New-Item -Path "Function:\$missing" -Value { } | Out-Null
      }
    }

    # The first line of a test whose fixtures or expectations are Windows
    # paths, written with \ and drive letters, or the ;-separated Machine and
    # User PATH. Off Windows it is skipped, with the reason, not failed.
    function Skip-OffWindows {
      if (-not $IsWindows) {
        Set-ItResult -Skipped -Because 'it needs Windows path semantics (\ separators, drive letters, the Machine/User PATH)'
      }
    }

    # Safety net: inner blocks override these with the behaviour they test.
    Mock New-Item { }
    Mock Remove-Item { }
    Mock New-ItemProperty { }
    Mock Set-Content { }
    Mock Send-EnvironmentChange { }
    Mock Sync-ProcessPath { }
    Mock Invoke-Choco { $global:LASTEXITCODE = 0 }
    Mock Invoke-Winget { $global:LASTEXITCODE = 0 }
    # npm is npm.ps1, which Pester cannot mock by name; the script calls it
    # through Invoke-Npm.
    Mock Invoke-Npm { $global:LASTEXITCODE = 0 }
    Mock Invoke-Python3 { $global:LASTEXITCODE = 0 }
    Mock Invoke-Uv { $global:LASTEXITCODE = 0 }
    Mock Invoke-Installer { 0 }
    Mock py { }
    Mock Invoke-ChocolateyBootstrap { }
    Mock Invoke-WebRequest { }
    Mock Install-Module { }
    Mock Get-InstalledModule { }
    Mock Start-Process { }
    Mock Start-Sleep { }
    Mock Read-Host { '' }
    Mock Test-Elevated { $false }
    Mock Test-Choco { $true }
    Mock Find-Executable { $null }
    Mock Get-WingetVersion { $null }
    Mock Write-Report { $script:report.Add($Message) }

    $script:fakeCommand = { param($Source) [pscustomobject]@{ Source = $Source } }

    function Write-TestFile {
      param ([string]$Path, $Content)
      [IO.Directory]::CreateDirectory((Split-Path -Parent $Path)) | Out-Null
      $text = if ($Content -is [string]) { $Content } else { $Content | ConvertTo-Json -Depth 10 }
      [IO.File]::WriteAllText($Path, $text)
    }

    function Build-TestPackage {
      param ([string]$Name, [object[]]$Install, [string]$Command, [string]$Why = 'bin/x:1')
      $p = [ordered]@{ name = $Name; why = $Why }
      if ($Command) { $p['command'] = $Command }
      $p['install'] = @($Install)
      $p
    }

    function Build-TestSpec {
      param ([string]$Manager, [string]$Id, [string]$Version, [string]$Source)
      $s = [ordered]@{ manager = $Manager; id = $Id }
      if ($Version) { $s['version'] = $Version }
      if ($Source) { $s['source'] = $Source }
      $s
    }
  }

  BeforeEach {
    $script:report = [Collections.Generic.List[string]]::new()
    Clear-PackageInventory
  }

  Describe 'Format-StepResult' {
    It 'formats an ok result with its detail' {
      Format-StepResult -Name jq -Result (New-StepResult -Status ok -Detail 'C:\jq.exe') |
        Should -Be 'jq: ok (C:\jq.exe)'
    }

    It 'formats a failure as FAILED: reason' {
      Format-StepResult -Name jq -Result (New-StepResult -Status FAILED -Detail 'no choco') |
        Should -Be 'jq: FAILED: no choco'
    }

    It 'formats an operator action as PENDING: action' {
      Format-StepResult -Name docker -Result (New-StepResult -Status PENDING -Detail 'reboot') |
        Should -Be 'docker: PENDING: reboot'
    }

    It 'indents extra lines under the item' {
      $lines = Format-StepResult -Name jq -Result (New-StepResult -Status fixed -Detail 'd' -Line 'a', 'b')
      $lines | Should -Be @('jq: fixed (d)', '  a', '  b')
    }
  }

  Describe 'Invoke-PrereqStep' {
    It 'turns an exception into a failure' {
      $result = Invoke-PrereqStep -Step { throw 'boom' }
      $result.Status | Should -Be 'FAILED'
      $result.Detail | Should -Be 'boom'
    }
  }

  Describe 'Write-Summary' {
    It 'says nothing to change when every item was ok' {
      Write-Summary -Results ([ordered]@{ jq = (New-StepResult -Status ok); gh = (New-StepResult -Status ok) })
      $script:report | Should -Contain '  jq: ok'
      $script:report[-1] | Should -Be 'nothing to change'
    }

    It 'counts the statuses otherwise' {
      Write-Summary -Results ([ordered]@{ jq = (New-StepResult -Status ok); gh = (New-StepResult -Status fixed) })
      $script:report[-1] | Should -Be 'ok 1, fixed 1'
    }
  }

  Describe 'Sync-ProcessPath' {
    # The root mock stands in for it by name; this runs the real one.
    It 'keeps the session''s own entries first and adds what it lacks' {
      Skip-OffWindows

      $saved = $env:Path
      try {
        $env:Path = 'C:\session-only'
        & ${function:Sync-ProcessPath}
        $env:Path | Should -BeLike 'C:\session-only;*'
        ($env:Path -split ';').Count | Should -BeGreaterThan 1
      } finally {
        $env:Path = $saved
      }
    }
  }

  Describe 'Get-ProjectsDir' {
    BeforeEach { $saved = $env:PROJECTS_DIR }
    AfterEach { $env:PROJECTS_DIR = $saved }

    It 'uses PROJECTS_DIR when it is set' {
      $env:PROJECTS_DIR = 'D:\work'
      $p = Get-ProjectsDir -DotfilesRoot 'C:\p\dotfiles'
      $p.Path | Should -Be 'D:\work'
      $p.How | Should -Be 'from PROJECTS_DIR'
    }

    It 'falls back to the parent of the dotfiles checkout, and says so' {
      Skip-OffWindows

      $env:PROJECTS_DIR = $null
      $p = Get-ProjectsDir -DotfilesRoot 'C:\p\dotfiles'
      $p.Path | Should -Be 'C:\p'
      $p.How | Should -BeLike '*PROJECTS_DIR is unset*parent of this dotfiles checkout*'
    }
  }

  Describe 'Read-PrereqFile (schema)' {
    BeforeAll {
      $file = Join-Path -Path $TestDrive -ChildPath 'schema\win-prereqs.json'
      $read = { param($Text, $Kind = 'repo') Write-TestFile -Path $file -Content $Text; Read-PrereqFile -Path $file -SchemaPath $script:schema -Kind $Kind }
    }

    It 'accepts an install entry and a check-only entry' {
      $data = & $read '{"packages":[{"name":"jq","why":"bin/a:1","command":"jq","install":[{"manager":"choco","id":"jq","version":"1.8.2"}]},{"name":"git","why":"bin/b:2","checkOnly":true,"command":"git"}]}'
      $data['packages'].Count | Should -Be 2
    }

    It 'rejects <case>' -ForEach @(
      @{ case = 'an entry with no why'; json = '{"packages":[{"name":"jq","install":[{"manager":"choco","id":"jq"}]}]}' }
      @{ case = 'a why with no file:line evidence'; json = '{"packages":[{"name":"jq","why":"because","install":[{"manager":"choco","id":"jq"}]}]}' }
      @{ case = 'an unknown manager'; json = '{"packages":[{"name":"jq","why":"a:1","install":[{"manager":"apt","id":"jq"}]}]}' }
      @{ case = 'a source on a non-npm spec'; json = '{"packages":[{"name":"x","why":"a:1","install":[{"manager":"pip","id":"x","source":"github:a/b"}]}]}' }
      @{ case = 'a check-only entry that also installs'; json = '{"packages":[{"name":"git","why":"a:1","checkOnly":true,"command":"git","install":[{"manager":"choco","id":"git"}]}]}' }
      @{ case = 'a check-only entry with no command'; json = '{"packages":[{"name":"git","why":"a:1","checkOnly":true}]}' }
      @{ case = 'an empty install list'; json = '{"packages":[{"name":"jq","why":"a:1","install":[]}]}' }
      @{ case = 'an unknown top-level key'; json = '{"packages":[],"extra":1}' }
      @{ case = 'no packages'; json = '{"repos":["a"]}' }
    ) {
      { & $read $json } | Should -Throw "*does not match win-prereqs.schema.json*"
    }

    It 'rejects repos in a repo''s list' {
      { & $read '{"repos":["a"],"packages":[]}' 'repo' } | Should -Throw '*repos belongs only in a hosts/win-<host>.json*'
    }

    It 'rejects a host list with no repos' {
      { & $read '{"packages":[]}' 'host' } | Should -Throw '*host''s list and has no repos*'
    }

    It 'accepts every list in this checkout' {
      Read-PrereqFile -Path (Join-Path -Path $script:checkout -ChildPath 'win-prereqs.json') -SchemaPath $script:schema -Kind repo | Should -Not -BeNullOrEmpty
      foreach ($h in Get-ChildItem -Path (Join-Path -Path $script:checkout -ChildPath 'hosts') -Filter 'win-*.json') {
        Read-PrereqFile -Path $h.FullName -SchemaPath $script:schema -Kind host | Should -Not -BeNullOrEmpty
      }
    }
  }

  Describe 'Resolve-PrereqTarget' {
    BeforeAll {
      $root = Join-Path -Path $TestDrive -ChildPath 'resolve'
      $dotfiles = Join-Path -Path $root -ChildPath 'p\dotfiles'
      $projects = Join-Path -Path $root -ChildPath 'p'
      $list = @{ packages = @() }
      Write-TestFile -Path "$dotfiles\win-prereqs.json" -Content $list
      Write-TestFile -Path "$projects\alpha\win-prereqs.json" -Content $list
      Write-TestFile -Path "$projects\both\win-prereqs.json" -Content $list
      Write-TestFile -Path "$projects\nolist\README" -Content 'x'
      Write-TestFile -Path "$dotfiles\hosts\win-box.json" -Content @{ repos = @('dotfiles', 'alpha'); packages = @() }
      Write-TestFile -Path "$dotfiles\hosts\win-both.json" -Content @{ repos = @('alpha'); packages = @() }
      Write-TestFile -Path "$dotfiles\hosts\win-broken.json" -Content @{ repos = @('ghost'); packages = @() }

      $resolve = {
        param([hashtable]$Extra = @{})
        Resolve-PrereqTarget -DotfilesRoot $dotfiles -ProjectsDir $projects -CurrentDirectory 'C:\nowhere' -SchemaPath $script:schema @Extra
      }
    }

    It 'resolves a host to its repos'' lists, then its own' {
      Skip-OffWindows

      $t = & $resolve @{ Name = 'box' }
      $t.Kind | Should -Be 'host'
      $t.Repos.Name | Should -Be @('dotfiles', 'alpha')
      $t.Documents.Path | Should -Be @("$dotfiles\win-prereqs.json", "$projects\alpha\win-prereqs.json", "$dotfiles\hosts\win-box.json")
    }

    It 'resolves a repo under the projects directory' {
      Skip-OffWindows

      $t = & $resolve @{ Name = 'alpha' }
      $t.Kind | Should -Be 'repo'
      $t.Documents.Path | Should -Be @("$projects\alpha\win-prereqs.json")
    }

    It 'resolves dotfiles to this checkout, whatever the projects directory is' {
      Skip-OffWindows

      $t = Resolve-PrereqTarget -Name dotfiles -DotfilesRoot $dotfiles -ProjectsDir 'C:\stale' -CurrentDirectory 'C:\nowhere' -SchemaPath $script:schema
      $t.Repos[0].Root | Should -Be $dotfiles
    }

    It 'resolves no name to the repo the current directory is in' {
      Skip-OffWindows

      Mock Get-RepoTopLevel { "$projects\alpha" }
      $t = & $resolve
      $t.Label | Should -Be 'alpha'
      $t.Kind | Should -Be 'repo'
      Should -Invoke Get-RepoTopLevel -Times 1 -ParameterFilter { $Path -eq 'C:\nowhere' }
    }

    It 'fails when no name is given outside a git repository' {
      Mock Get-RepoTopLevel { $null }
      { & $resolve } | Should -Throw '*not in a git repository*valid names*'
    }

    It 'fails when the current repo has no win-prereqs.json' {
      Mock Get-RepoTopLevel { "$projects\nolist" }
      { & $resolve } | Should -Throw '*has no win-prereqs.json*'
    }

    It 'fails on a name that is both a host and a repo, asking for -Host or -Repo' {
      Skip-OffWindows

      { & $resolve @{ Name = 'both' } } | Should -Throw '*both a host*and a repo*pass -Host or -Repo*'
    }

    It 'takes -Host and -Repo to settle a collision' {
      Skip-OffWindows

      (& $resolve @{ Name = 'both'; AsHost = $true }).Kind | Should -Be 'host'
      (& $resolve @{ Name = 'both'; Repo = $true }).Kind | Should -Be 'repo'
    }

    It 'fails on an unknown name, listing the valid ones' {
      Skip-OffWindows

      { & $resolve @{ Name = 'nope' } } | Should -Throw '*neither a host*nor a repo*hosts: both, box, broken; repos: alpha, both, dotfiles*'
    }

    It 'fails when a host lists a repo with no list' {
      Skip-OffWindows

      { & $resolve @{ Name = 'broken' } } | Should -Throw "*lists the repo 'ghost'*"
    }

    It 'validates every list before returning' {
      Skip-OffWindows

      Write-TestFile -Path "$projects\bad\win-prereqs.json" -Content '{"packages":[{"name":"x"}]}'
      { & $resolve @{ Name = 'bad' } } | Should -Throw '*does not match*'
    }
  }

  Describe 'Merge-PrereqPackage' {
    BeforeAll {
      $doc = { param($Path, [object[]]$Packages) [pscustomobject]@{ Path = $Path; Data = @{ packages = $Packages } } }
      $jq = { param($Why) Build-TestPackage -Name jq -Why $Why -Command jq -Install (Build-TestSpec choco jq), (Build-TestSpec winget jqlang.jq) }
    }

    It 'installs a package listed twice once, whatever each why says' {
      $merged = @(Merge-PrereqPackage -Document (& $doc 'a.json' (& $jq 'a:1')), (& $doc 'b.json' (& $jq 'b:2')))
      $merged.Count | Should -Be 1
      $merged[0].Sources | Should -Be @('a.json', 'b.json')
    }

    It 'treats the same entry with its keys in another order as the same' {
      $reordered = [ordered]@{
        install = @([ordered]@{ id = 'jq'; manager = 'choco' }, [ordered]@{ id = 'jqlang.jq'; manager = 'winget' })
        command = 'jq'; why = 'c:3'; name = 'jq'
      }
      @(Merge-PrereqPackage -Document (& $doc 'a.json' (& $jq 'a:1')), (& $doc 'c.json' $reordered)).Count | Should -Be 1
    }

    It 'fails when two entries with one name differ, naming both files' {
      $other = Build-TestPackage -Name jq -Command jq -Install (Build-TestSpec winget jqlang.jq)
      { Merge-PrereqPackage -Document (& $doc 'C:\a\win-prereqs.json' (& $jq 'a:1')), (& $doc 'C:\b\win-prereqs.json' $other) } |
        Should -Throw "*package 'jq' differs between C:\a\win-prereqs.json and C:\b\win-prereqs.json*"
    }

    It 'keeps first-seen order across documents' {
      $gh = Build-TestPackage -Name gh -Install (Build-TestSpec choco gh)
      $merged = Merge-PrereqPackage -Document (& $doc 'a.json' $gh), (& $doc 'b.json' (& $jq 'b:1'), $gh)
      $merged.Name | Should -Be @('gh', 'jq')
    }
  }

  Describe 'Get-PackagePhase' {
    It 'puts choco, winget and check-only packages in the system phase, the rest in user' {
      Get-PackagePhase -Package (Build-TestPackage -Name a -Install (Build-TestSpec winget a)) | Should -Be 'system'
      Get-PackagePhase -Package @{ name = 'git'; checkOnly = $true; command = 'git' } | Should -Be 'system'
      Get-PackagePhase -Package (Build-TestPackage -Name b -Install (Build-TestSpec uv b), (Build-TestSpec choco b)) | Should -Be 'user'
    }
  }

  Describe 'Find-Executable' {
    It 'does not count a Microsoft Store stub' {
      Mock Get-Command -ParameterFilter { $Name -eq 'python3' } { & $script:fakeCommand 'C:\Users\u\AppData\Local\Microsoft\WindowsApps\python3.exe' }
      & ${function:Find-Executable} -Name python3 | Should -BeNullOrEmpty
    }

    It 'returns a real executable''s path' {
      Mock Get-Command -ParameterFilter { $Name -eq 'jq' } { & $script:fakeCommand 'C:\ProgramData\chocolatey\bin\jq.exe' }
      & ${function:Find-Executable} -Name jq | Should -Be 'C:\ProgramData\chocolatey\bin\jq.exe'
    }
  }

  Describe 'Read-ManagerInventory' {
    It 'reads choco''s local list' {
      Mock Invoke-Choco { 'jq|1.8.2'; 'gh|2.103.2' }
      $inv = Read-ManagerInventory -Manager choco
      $inv['jq'] | Should -Be '1.8.2'
      $inv['JQ'] | Should -Be '1.8.2'
    }

    It 'reads npm''s global packages' {
      Mock Find-Executable -ParameterFilter { $Name -eq 'npm' } { 'C:\nodejs\npm.cmd' }
      Mock Invoke-Npm { '{"dependencies":{"bats":{"version":"1.13.0"},"bats-file":{"version":"0.2.0"}}}' }
      (Read-ManagerInventory -Manager npm)['bats-file'] | Should -Be '0.2.0'
    }

    It 'reads pip''s list for python3, normalizing names' {
      Mock Get-Python3Prefix { 'C:\Python315' }
      Mock Invoke-Python3 { '[{"name": "PyYAML", "version": "6.0.3"}, {"name": "zope.interface", "version": "1"}]' }
      $inv = Read-ManagerInventory -Manager pip
      $inv['pyyaml'] | Should -Be '6.0.3'
      $inv['zope-interface'] | Should -Be '1'
    }

    It 'reads uv''s tools, not their executables' {
      Mock Find-Executable -ParameterFilter { $Name -eq 'uv' } { 'C:\bin\uv.exe' }
      Mock Invoke-Uv { 'pre-commit v4.7.0'; '- pre-commit.exe'; 'linode-cli v5.69.0'; '- lin.exe' }
      $inv = Read-ManagerInventory -Manager uv
      $inv.Keys | Sort-Object | Should -Be @('linode-cli', 'pre-commit')
    }

    It 'is empty when the manager is missing' {
      Mock Test-Choco { $false }
      (Read-ManagerInventory -Manager choco).Count | Should -Be 0
      Should -Invoke Invoke-Choco -Times 0
    }
  }

  Describe 'Get-WingetVersion' {
    BeforeEach {
      Mock Get-Command -ParameterFilter { $Name -eq 'winget' } { & $script:fakeCommand 'C:\w\winget.exe' }
    }

    It 'returns the version winget lists for the id' {
      Mock Invoke-Winget { 'Name  Id         Version  Source'; '----------------------'; 'jq    jqlang.jq  1.7.1    winget' }
      & ${function:Get-WingetVersion} -Id jqlang.jq | Should -Be '1.7.1'
    }

    It 'returns $null when winget has no such package' {
      Mock Invoke-Winget { 'No installed package found matching input criteria.' }
      & ${function:Get-WingetVersion} -Id jqlang.jq | Should -BeNullOrEmpty
    }
  }

  Describe 'Get-PackageState' {
    BeforeEach {
      $script:have = @{}
      Mock Get-InstalledVersion { @($script:have["$($Spec['manager']):$($Spec['id'])"] | Where-Object { $_ }) }
      $jq = Build-TestPackage -Name jq -Command jq -Install (Build-TestSpec choco jq), (Build-TestSpec winget jqlang.jq)
    }

    It 'counts the command on PATH as installed, by whatever tool, without asking a manager' {
      Mock Find-Executable -ParameterFilter { $Name -eq 'jq' } { 'C:\WinGet\Links\jq.exe' }
      $s = Get-PackageState -Package $jq
      $s.Status | Should -Be 'ok'
      $s.Detail | Should -Be 'C:\WinGet\Links\jq.exe'
      Should -Invoke Get-InstalledVersion -Times 0
    }

    It 'counts a later manager''s install as installed' {
      $script:have['winget:jqlang.jq'] = '1.7.1'
      $s = Get-PackageState -Package $jq
      $s.Status | Should -Be 'ok'
      $s.Detail | Should -Be 'winget jqlang.jq 1.7.1'
    }

    It 'is missing when no manager has it' {
      (Get-PackageState -Package $jq).Status | Should -Be 'missing'
    }

    It 'is ok when a pinned version matches' {
      $script:have['choco:jq'] = '1.8.2'
      $pinned = Build-TestPackage -Name jq -Install (Build-TestSpec choco jq -Version 1.8.2)
      (Get-PackageState -Package $pinned).Status | Should -Be 'ok'
    }

    It 'reports a differing pin, with the spec to move, and ignores the command on PATH' {
      Mock Find-Executable { 'C:\x\jq.exe' }
      $script:have['choco:jq'] = '1.7.0'
      $pinned = Build-TestPackage -Name jq -Command jq -Install (Build-TestSpec choco jq -Version 1.8.2)
      $s = Get-PackageState -Package $pinned
      $s.Status | Should -Be 'pin differs'
      $s.Spec['version'] | Should -Be '1.8.2'
      $s.Detail | Should -Be 'choco has jq 1.7.0; pinned 1.8.2'
    }

    It 'finds a check-only package by its command' {
      Mock Find-Executable -ParameterFilter { $Name -eq 'git' } { 'C:\Git\cmd\git.exe' }
      $s = Get-PackageState -Package @{ name = 'git'; checkOnly = $true; command = 'git' }
      $s.Status | Should -Be 'ok'
      $s.Detail | Should -BeLike '*check-only, never installed or upgraded*'
    }

    It 'fails a missing check-only package rather than installing it' {
      $s = Get-PackageState -Package @{ name = 'git'; checkOnly = $true; command = 'git' }
      $s.Status | Should -Be 'FAILED'
      $s.Detail | Should -BeLike '*install it by hand*'
    }
  }

  Describe 'Get-InstalledVersion' {
    It 'does not count npm''s security placeholder for a spec with a source' {
      Mock Read-ManagerInventory { @{ 'bats-file' = @('0.0.1-security') } }
      @(Get-InstalledVersion -Spec (Build-TestSpec npm bats-file -Source 'github:bats-core/bats-file')).Count | Should -Be 0
    }

    It 'asks each manager once per run' {
      Mock Read-ManagerInventory { @{ jq = @('1.8.2'); gh = @('2.1') } }
      Get-InstalledVersion -Spec (Build-TestSpec choco jq) | Should -Be '1.8.2'
      Get-InstalledVersion -Spec (Build-TestSpec choco gh) | Should -Be '2.1'
      Should -Invoke Read-ManagerInventory -Times 1
    }

    It 'normalizes Python package names' {
      Mock Read-ManagerInventory { @{ pyyaml = @('6.0.3') } }
      Get-InstalledVersion -Spec (Build-TestSpec pip PyYAML) | Should -Be '6.0.3'
    }
  }

  Describe 'Invoke-SpecInstall' {
    BeforeEach {
      Mock Find-Executable { "C:\bin\$Name.exe" }
      Mock Get-Python3Prefix { 'C:\Python315' }
      Mock Get-Command -ParameterFilter { $Name -eq 'winget' } { & $script:fakeCommand 'C:\w\winget.exe' }
    }

    It 'runs <manager> as: <expected>' -ForEach @(
      @{ manager = 'choco'; spec = @{ manager = 'choco'; id = 'jq' }; expected = 'install jq -y' }
      @{ manager = 'choco'; spec = @{ manager = 'choco'; id = 'jq'; version = '1.8.1' }; expected = 'upgrade jq --version 1.8.1 --allow-downgrade -y' }
      @{ manager = 'winget'; spec = @{ manager = 'winget'; id = 'jqlang.jq' }; expected = 'install --id jqlang.jq --exact --source winget --accept-package-agreements --accept-source-agreements --disable-interactivity' }
      @{ manager = 'npm'; spec = @{ manager = 'npm'; id = 'bats' }; expected = 'install -g bats' }
      @{ manager = 'npm'; spec = @{ manager = 'npm'; id = 'bats'; version = '1.13.0' }; expected = 'install -g bats@1.13.0' }
      @{ manager = 'npm'; spec = @{ manager = 'npm'; id = 'bats-file'; source = 'github:bats-core/bats-file' }; expected = 'install -g github:bats-core/bats-file' }
      @{ manager = 'pip'; spec = @{ manager = 'pip'; id = 'pytest'; version = '8.4.2' }; expected = '-m pip install --user --disable-pip-version-check pytest==8.4.2' }
      @{ manager = 'uv'; spec = @{ manager = 'uv'; id = 'pre-commit' }; expected = 'tool install pre-commit' }
    ) {
      Invoke-SpecInstall -Spec $spec | Should -Be ''
      Should -Invoke Invoke-Installer -Times 1 -ParameterFilter { "$ArgumentList" -eq $expected }
    }

    It 'moves a winget package to its pin with --version and --force' {
      Invoke-SpecInstall -Spec @{ manager = 'winget'; id = 'jqlang.jq'; version = '1.7.1' } -Reinstall | Out-Null
      Should -Invoke Invoke-Installer -Times 1 -ParameterFilter { "$ArgumentList" -like '*--version 1.7.1 --force' }
    }

    It 'never uninstalls' {
      foreach ($m in 'choco', 'winget', 'npm', 'pip', 'uv') {
        Invoke-SpecInstall -Spec @{ manager = $m; id = 'x'; version = '1' } -Reinstall | Out-Null
      }

      Should -Invoke Invoke-Installer -Times 0 -ParameterFilter { "$ArgumentList" -match 'uninstall|remove' }
    }

    It 'installs a gallery module for the current user, beside the in-box one' {
      Invoke-SpecInstall -Spec @{ manager = 'psgallery'; id = 'Pester' } | Should -Be ''
      Should -Invoke Install-Module -Times 1 -ParameterFilter { $Name -eq 'Pester' -and $Scope -eq 'CurrentUser' -and $SkipPublisherCheck }
    }

    It 'reports a requested reboot' {
      Mock Invoke-Installer { 3010 }
      Invoke-SpecInstall -Spec @{ manager = 'choco'; id = 'docker-desktop' } | Should -Be 'reboot'
    }

    It 'reports any other exit code as the reason' {
      Mock Invoke-Installer { 1 }
      Invoke-SpecInstall -Spec @{ manager = 'choco'; id = 'jq' } | Should -Be 'choco.exe install jq -y exited 1'
    }

    It 'fails a pip spec when python3 is not a real Python' {
      Mock Get-Python3Prefix { $null }
      Invoke-SpecInstall -Spec @{ manager = 'pip'; id = 'pytest' } | Should -Be 'python3 does not run a real Python'
      Should -Invoke Invoke-Installer -Times 0
    }
  }

  Describe 'Invoke-Installer' {
    It 'runs installers in this console, so their progress shows' {
      Mock Start-Process { [pscustomobject]@{ ExitCode = 0 } }
      & ${function:Invoke-Installer} -FilePath 'C:\c\choco.exe' -ArgumentList 'install', 'jq', '-y' | Should -Be 0
      Should -Invoke Start-Process -Times 1 -ParameterFilter { $NoNewWindow -and $Wait -and $PassThru }
    }
  }

  Describe 'Install-PackageSpec' {
    BeforeEach {
      $script:calls = [Collections.Generic.List[string]]::new()
      $script:fail = @()
      $script:have = @{}
      Mock Invoke-SpecInstall {
        $script:calls.Add($Spec['manager'])
        if ($script:fail -contains $Spec['manager']) { return "$($Spec['manager']) exited 1" }
        $script:have[$Spec['manager']] = if ($Spec['version']) { $Spec['version'] } else { '1.0' }
        ''
      }
      Mock Get-InstalledVersion { @($script:have[$Spec['manager']] | Where-Object { $_ }) }
      $pkg = Build-TestPackage -Name jq -Install (Build-TestSpec choco jq), (Build-TestSpec winget jqlang.jq)
    }

    It 'tries the managers in order and stops at the first that works' {
      Mock Test-Elevated { $true }
      $r = Install-PackageSpec -Package $pkg -Spec $pkg['install']
      $r.Status | Should -Be 'fixed'
      $script:calls | Should -Be @('choco')
    }

    It 'falls back to the next manager on failure' {
      Mock Test-Elevated { $true }
      $script:fail = @('choco')
      $r = Install-PackageSpec -Package $pkg -Spec $pkg['install']
      $r.Status | Should -Be 'fixed'
      $script:calls | Should -Be @('choco', 'winget')
      $r.Lines | Should -Be @('tried first: choco exited 1')
    }

    It 'falls back when a manager says it worked but does not list the package' {
      Mock Test-Elevated { $true }
      Mock Get-InstalledVersion { if ($Spec['manager'] -eq 'winget') { '1.7.1' } }
      $r = Install-PackageSpec -Package $pkg -Spec $pkg['install']
      $r.Status | Should -Be 'fixed'
      $script:calls | Should -Be @('choco', 'winget')
    }

    It 'fails, naming each manager''s failure, when none works' {
      Mock Test-Elevated { $true }
      $script:fail = @('choco', 'winget')
      $r = Install-PackageSpec -Package $pkg -Spec $pkg['install']
      $r.Status | Should -Be 'FAILED'
      $r.Detail | Should -Be 'every manager failed: choco exited 1; winget exited 1'
    }

    It 'stops at an admin manager when unelevated, carrying what is left for the elevated pass' {
      $mixed = Build-TestPackage -Name x -Install (Build-TestSpec npm x), (Build-TestSpec choco x), (Build-TestSpec winget x)
      $script:fail = @('npm')
      $r = Install-PackageSpec -Package $mixed -Spec $mixed['install']
      $r.Status | Should -Be 'needs admin'
      $script:calls | Should -Be @('npm')
      @($r.Plan.Specs | ForEach-Object { $_['manager'] }) | Should -Be @('choco', 'winget')
      $r.Plan.Failures | Should -Be @('npm exited 1')
    }

    It 'announces each attempt, with the package''s slow warning' {
      Mock Test-Elevated { $true }
      $slow = Build-TestPackage -Name docker-desktop -Install (Build-TestSpec choco docker-desktop)
      $slow['slow'] = 'about 1 GB to download'
      Install-PackageSpec -Package $slow -Spec $slow['install'] | Out-Null
      $script:report | Should -Contain '[docker-desktop] installing via choco docker-desktop - about 1 GB to download...'
    }

    It 'reports a reboot request as pending' {
      Mock Test-Elevated { $true }
      Mock Invoke-SpecInstall { 'reboot' }
      (Install-PackageSpec -Package $pkg -Spec $pkg['install']).Status | Should -Be 'PENDING'
    }

    It 'changes nothing under -WhatIf' {
      $r = Install-PackageSpec -Package $pkg -Spec $pkg['install'] -WhatIf
      $r.Status | Should -Be 'would fix'
      $r.Detail | Should -Be 'install via choco jq, else winget jqlang.jq (choco and winget need admin)'
      Should -Invoke Invoke-SpecInstall -Times 0
    }
  }

  Describe 'Invoke-Package' {
    BeforeEach {
      Mock Install-PackageSpec { New-StepResult -Status fixed }
    }

    It 'leaves an installed package alone' {
      Mock Get-PackageState { [pscustomobject]@{ Status = 'ok'; Detail = 'choco jq 1.8.2'; Spec = $null } }
      (Invoke-Package -Package (Build-TestPackage -Name jq -Install (Build-TestSpec choco jq))).Status | Should -Be 'ok'
      Should -Invoke Install-PackageSpec -Times 0
    }

    It 'installs a missing package from all its specs' {
      Mock Get-PackageState { [pscustomobject]@{ Status = 'missing'; Detail = ''; Spec = $null } }
      Invoke-Package -Package (Build-TestPackage -Name jq -Install (Build-TestSpec choco jq), (Build-TestSpec winget jqlang.jq)) | Out-Null
      Should -Invoke Install-PackageSpec -Times 1 -ParameterFilter { $Spec.Count -eq 2 -and -not $Reinstall }
    }

    It 'moves a differing pin with only the spec that has it' {
      $spec = Build-TestSpec winget jqlang.jq -Version 1.7.1
      Mock Get-PackageState { [pscustomobject]@{ Status = 'pin differs'; Detail = ''; Spec = $spec } }
      Invoke-Package -Package (Build-TestPackage -Name jq -Install (Build-TestSpec choco jq), $spec) | Out-Null
      Should -Invoke Install-PackageSpec -Times 1 -ParameterFilter { $Spec.Count -eq 1 -and $Spec[0]['manager'] -eq 'winget' -and $Reinstall }
    }

    It 'never installs a check-only package' {
      Mock Get-PackageState { [pscustomobject]@{ Status = 'FAILED'; Detail = 'git not found'; Spec = $null } }
      (Invoke-Package -Package @{ name = 'git'; checkOnly = $true; command = 'git' }).Status | Should -Be 'FAILED'
      Should -Invoke Install-PackageSpec -Times 0
    }
  }

  Describe 'Install-Chocolatey' {
    BeforeEach {
      $script:chocoPresent = $false
      Mock Test-Choco { $script:chocoPresent }
      Mock Invoke-ChocolateyBootstrap { $script:chocoPresent = $true }
      Mock Invoke-Choco { '2.7.4' }
    }

    It 'is ok when choco is on PATH' {
      $script:chocoPresent = $true
      (Install-Chocolatey).Status | Should -Be 'ok'
      Should -Invoke Invoke-ChocolateyBootstrap -Times 0
    }

    It 'asks for admin rather than bootstrapping unelevated' {
      (Install-Chocolatey).Status | Should -Be 'needs admin'
      Should -Invoke Invoke-ChocolateyBootstrap -Times 0
    }

    It 'bootstraps when elevated' {
      Mock Test-Elevated { $true }
      (Install-Chocolatey).Status | Should -Be 'fixed'
      Should -Invoke Invoke-ChocolateyBootstrap -Times 1
    }

    It 'changes nothing under -WhatIf' {
      (Install-Chocolatey -WhatIf).Status | Should -Be 'would fix'
      Should -Invoke Invoke-ChocolateyBootstrap -Times 0
    }
  }

  Describe 'Invoke-ElevatedRun' {
    BeforeEach {
      Mock Get-CurrentUserSid { 'S-1-5-21-1' }
      $plan = @{ Chocolatey = $false; Packages = @(@{ Name = 'jq'; Package = @{ name = 'jq' }; Specs = @(@{ manager = 'choco'; id = 'jq' }); Reinstall = $false }) }
    }

    It 'fails every item when UAC is declined' {
      Mock Start-Process { throw 'The operation was canceled by the user.' }
      $plan.Chocolatey = $true
      $run = Invoke-ElevatedRun -Plan $plan
      $run.Results['chocolatey'].Status | Should -Be 'FAILED'
      $run.Results['jq'].Detail | Should -BeLike 'elevation declined*canceled by the user*'
    }

    It 'passes the plan over, starts one elevated copy, and reads back its results and account' {
      Mock Set-Content { } -ParameterFilter { $LiteralPath -like '*-plan.json' }
      Mock Start-Process {
        $resultFile = ($ArgumentList[$ArgumentList.IndexOf('-ResultPath') + 1]).Trim('"')
        $sid = $ArgumentList[$ArgumentList.IndexOf('-ExpectedSid') + 1]
        $json = @{ Sid = $sid; Results = @{ jq = @{ Status = 'fixed'; Detail = 'choco jq'; Lines = @() } } } | ConvertTo-Json -Depth 5
        [IO.File]::WriteAllText($resultFile, $json)
        [pscustomobject]@{ ExitCode = 0 }
      }
      Mock Remove-Item { [IO.File]::Delete($LiteralPath) } -ParameterFilter { $LiteralPath -like '*-results.json' }

      $run = Invoke-ElevatedRun -Plan $plan
      $run.Results['jq'].Status | Should -Be 'fixed'
      $run.Note | Should -BeLike '*same account (SID verified)*'
      Should -Invoke Start-Process -Times 1 -ParameterFilter { $Verb -eq 'RunAs' -and $Wait -and ($ArgumentList -contains '-PlanPath') }
      Should -Invoke Set-Content -Times 1 -ParameterFilter { $LiteralPath -like '*-plan.json' }
    }

    It 'fails the items when the elevated copy writes no results' {
      Mock Start-Process { [pscustomobject]@{ ExitCode = 1 } }
      $run = Invoke-ElevatedRun -Plan $plan
      $run.Results['jq'].Detail | Should -BeLike '*wrote no results (exit 1)*'
    }
  }

  Describe 'Invoke-ElevatedPlan' {
    BeforeEach {
      Mock Get-CurrentUserSid { 'S-1-5-21-1' }
      Mock Test-Elevated { $true }
      Mock Wait-ElevatedWindowClose { }
      Mock Install-Chocolatey { New-StepResult -Status fixed -Detail 'choco 2.7.4' }
      Mock Install-PackageSpec {
        if ($Package['name'] -eq 'docker-desktop') { New-StepResult -Status FAILED -Detail 'choco exited 1' } else { New-StepResult -Status fixed -Detail 'choco jq' }
      }
      $plan = @{
        Chocolatey = $true
        Packages   = @(
          @{ Name = 'jq'; Package = @{ name = 'jq' }; Specs = @(@{ manager = 'choco'; id = 'jq' }); Reinstall = $false }
          @{ Name = 'docker-desktop'; Package = @{ name = 'docker-desktop' }; Specs = @(@{ manager = 'choco'; id = 'docker-desktop' }); Reinstall = $false }
        )
      }
      # A real directory, so Set-Content's -Encoding binds on any platform;
      # the root mock means nothing is written there.
      $resultPath = Join-Path -Path $TestDrive -ChildPath 'r.json'
    }

    It 'lists its steps, runs each, ends with a summary and writes the results' {
      Invoke-ElevatedPlan -Plan $plan -ExpectedSid 'S-1-5-21-1' -ResultPath $resultPath
      $script:report[0] | Should -Be 'Admin steps: chocolatey, jq, docker-desktop'
      $script:report | Should -Contain '[chocolatey] installing Chocolatey from community.chocolatey.org...'
      $script:report | Should -Contain 'docker-desktop: FAILED: choco exited 1'
      $script:report | Should -Contain '  jq: fixed'
      Should -Invoke Set-Content -Times 1 -ParameterFilter { $LiteralPath -eq $resultPath }
      Should -Invoke Wait-ElevatedWindowClose -Times 1 -ParameterFilter { $Failed }
    }

    It 'lets the window close on its own when every step worked' {
      $plan.Packages = @($plan.Packages[0])
      Invoke-ElevatedPlan -Plan $plan -ExpectedSid 'S-1-5-21-1' -ResultPath $resultPath
      Should -Invoke Wait-ElevatedWindowClose -Times 1 -ParameterFilter { -not $Failed }
    }

    It 'cleans the Machine PATH when the plan asks, after the packages' {
      Mock Repair-PathValue { New-StepResult -Status fixed -Detail 'removed 1 repeated, 0 missing' }
      $plan.MachinePath = $true
      Invoke-ElevatedPlan -Plan $plan -ExpectedSid 'S-1-5-21-1' -ResultPath $resultPath
      $script:report[0] | Should -Be 'Admin steps: chocolatey, jq, docker-desktop, machine PATH'
      $script:report | Should -Contain 'machine PATH: fixed (removed 1 repeated, 0 missing)'
      Should -Invoke Repair-PathValue -Times 1 -Exactly -ParameterFilter { $Scope -eq 'Machine' }
    }

    It 'changes nothing when elevated as a different account' {
      Mock Repair-PathValue { New-StepResult -Status fixed }
      $plan.MachinePath = $true
      Invoke-ElevatedPlan -Plan $plan -ExpectedSid 'S-1-5-21-2' -ResultPath $resultPath
      Should -Invoke Install-Chocolatey -Times 0
      Should -Invoke Install-PackageSpec -Times 0
      Should -Invoke Repair-PathValue -Times 0
      $script:report | Should -Contain 'jq: FAILED: elevated as a different account; nothing changed'
    }
  }

  Describe 'Wait-ElevatedWindowClose' {
    It 'closes after a pause when everything worked' {
      Wait-ElevatedWindowClose
      $script:report | Should -Contain 'done - this window will close in 10 seconds'
      Should -Invoke Start-Sleep -Times 1 -ParameterFilter { $Seconds -eq 10 }
      Should -Invoke Read-Host -Times 0
    }

    It 'waits for Enter when a step failed' {
      Wait-ElevatedWindowClose -Failed
      Should -Invoke Read-Host -Times 1 -ParameterFilter { $Prompt -like '*FAILED*press Enter*' }
      Should -Invoke Start-Sleep -Times 0
    }
  }

  Describe 'Invoke-PrereqRun' {
    BeforeAll {
      $root = Join-Path -Path $TestDrive -ChildPath 'run'
      $dotfiles = Join-Path -Path $root -ChildPath 'dotfiles'
      $projects = Join-Path -Path $root -ChildPath 'projects'
      [IO.Directory]::CreateDirectory("$dotfiles\powershell") | Out-Null
      [IO.File]::Copy($script:schema, "$dotfiles\powershell\win-prereqs.schema.json", $true)

      $writeRepo = {
        param($Repo, [object[]]$Packages)
        Write-TestFile -Path "$projects\$Repo\win-prereqs.json" -Content @{ packages = $Packages }
      }

      & $writeRepo 'admin' @(
        (Build-TestPackage -Name jq -Install (Build-TestSpec choco jq), (Build-TestSpec winget jqlang.jq))
        (Build-TestPackage -Name gh -Install (Build-TestSpec choco gh))
        (Build-TestPackage -Name bats -Install (Build-TestSpec npm bats))
      )
      & $writeRepo 'user' @((Build-TestPackage -Name bats -Install (Build-TestSpec npm bats)))
      # The npm package is listed before the Node.js it needs, on purpose.
      & $writeRepo 'order' @(
        (Build-TestPackage -Name bats -Install (Build-TestSpec npm bats))
        (Build-TestPackage -Name nodejs -Command node -Install (Build-TestSpec choco nodejs-lts), (Build-TestSpec winget OpenJS.NodeJS.LTS))
        (Build-TestPackage -Name pre-commit -Install (Build-TestSpec uv pre-commit))
        (Build-TestPackage -Name uv -Command uv -Install (Build-TestSpec choco uv), (Build-TestSpec winget astral-sh.uv))
      )
      & $writeRepo 'late' @((Build-TestPackage -Name late -Install (Build-TestSpec npm late), (Build-TestSpec choco late)))
      & $writeRepo 'mixed' @(
        (Build-TestPackage -Name jq -Install (Build-TestSpec choco jq))
        (Build-TestPackage -Name late -Install (Build-TestSpec npm late), (Build-TestSpec choco late))
      )
      Write-TestFile -Path "$dotfiles\win-prereqs.json" -Content @{ packages = @() }

      $run = { param($Name) Invoke-PrereqRun -Name $Name -DotfilesRoot $dotfiles -CurrentDirectory 'C:\nowhere' }
    }

    BeforeEach {
      $saved = $env:PROJECTS_DIR
      $env:PROJECTS_DIR = $projects
      $script:installed = @{}
      $script:failing = @()
      Mock Get-InstalledVersion { @($script:installed["$($Spec['manager']):$($Spec['id'])"] | Where-Object { $_ }) }
      Mock Invoke-SpecInstall {
        if ($script:failing -contains $Spec['manager']) { return "$($Spec['manager']) exited 1" }
        $script:installed["$($Spec['manager']):$($Spec['id'])"] = '1.0'
        ''
      }
      Mock Invoke-ElevatedRun {
        $results = @{}
        foreach ($p in @($Plan['Packages'])) {
          $script:installed["$($p['Specs'][0]['manager']):$($p['Specs'][0]['id'])"] = '1.0'
          $results[$p['Name']] = New-StepResult -Status fixed -Detail 'elevated'
        }
        [pscustomobject]@{ Note = 'UAC accepted'; Results = $results }
      }
      Mock Repair-Python3 { New-StepResult -Status ok }
      Mock Set-MsysSymlinkMode { New-StepResult -Status ok }
      Mock Repair-PathValue { New-StepResult -Status ok }
      Mock Test-S3cmdWrapper { New-StepResult -Status ok }
    }

    AfterEach {
      $env:PROJECTS_DIR = $saved
    }

    It 'batches several admin packages into one UAC prompt, then installs the rest unelevated' {
      Skip-OffWindows

      $code = & $run 'admin'
      $code | Should -Be 0
      Should -Invoke Invoke-ElevatedRun -Times 1 -Exactly -ParameterFilter {
        (@($Plan['Packages'] | ForEach-Object { $_['Name'] }) -join ',') -eq 'jq,gh'
      }
      Should -Invoke Invoke-SpecInstall -Times 1 -Exactly -ParameterFilter { $Spec['manager'] -eq 'npm' }
      Should -Invoke Invoke-SpecInstall -Times 0 -ParameterFilter { $Spec['manager'] -eq 'choco' }
      $script:report | Should -Contain 'jq: fixed (elevated)'
    }

    It 'sends only the admin specs to the elevated copy' {
      Skip-OffWindows

      & $run 'admin' | Out-Null
      Should -Invoke Invoke-ElevatedRun -Times 1 -ParameterFilter {
        $jq = @($Plan['Packages'] | Where-Object { $_['Name'] -eq 'jq' })[0]
        (@($jq['Specs'] | ForEach-Object { $_['manager'] }) -join ',') -eq 'choco,winget'
      }
    }

    It 'installs Node.js and uv in the one elevation before the npm and uv packages, whatever the list order' {
      Skip-OffWindows

      $script:sequence = [Collections.Generic.List[string]]::new()
      Mock Invoke-ElevatedRun {
        $script:sequence.Add('elevate:' + (@($Plan['Packages'] | ForEach-Object { $_['Name'] }) -join ','))
        $results = @{}
        foreach ($p in @($Plan['Packages'])) {
          $script:installed["$($p['Specs'][0]['manager']):$($p['Specs'][0]['id'])"] = '1.0'
          $results[$p['Name']] = New-StepResult -Status fixed -Detail 'elevated'
        }
        [pscustomobject]@{ Note = 'UAC accepted'; Results = $results }
      }
      Mock Invoke-SpecInstall {
        $script:sequence.Add("$($Spec['manager']):$($Spec['id'])")
        $script:installed["$($Spec['manager']):$($Spec['id'])"] = '1.0'
        ''
      }

      & $run 'order' | Should -Be 0
      $script:sequence | Should -Be @('elevate:nodejs,uv', 'npm:bats', 'uv:pre-commit')
      Should -Invoke Invoke-ElevatedRun -Times 1 -Exactly
    }

    It 'raises no UAC prompt when nothing needs admin' {
      Skip-OffWindows

      & $run 'user' | Should -Be 0
      Should -Invoke Invoke-ElevatedRun -Times 0
    }

    It 'raises no UAC prompt, and says nothing to change, when everything is installed' {
      Skip-OffWindows

      $script:installed = @{ 'choco:jq' = '1'; 'choco:gh' = '1'; 'npm:bats' = '1' }
      & $run 'admin' | Should -Be 0
      Should -Invoke Invoke-ElevatedRun -Times 0
      Should -Invoke Invoke-SpecInstall -Times 0
      $script:report[-1] | Should -Be 'nothing to change'
    }

    It 'raises its one prompt for a user-scope package''s admin fallback when no other elevation happened' {
      Skip-OffWindows

      $script:failing = @('npm')
      & $run 'late' | Should -Be 0
      Should -Invoke Invoke-ElevatedRun -Times 1
    }

    It 'never raises a second prompt: a later admin need fails instead' {
      Skip-OffWindows

      $script:failing = @('npm')
      & $run 'mixed' | Should -Be 1
      Should -Invoke Invoke-ElevatedRun -Times 1
      $script:report | Should -Contain "late: FAILED: needs admin (install via choco late) after this run's one elevated pass; rerun"
    }

    It 'changes nothing, and never elevates, under -WhatIf' {
      Skip-OffWindows

      $WhatIfPreference = $true
      & $run 'admin' | Should -Be 0
      Should -Invoke Invoke-ElevatedRun -Times 0
      Should -Invoke Invoke-SpecInstall -Times 0
      $script:report | Should -Contain 'jq: would fix (install via choco jq, else winget jqlang.jq (choco and winget need admin))'
    }

    It 'exits 1 when an item fails' {
      Mock Invoke-ElevatedRun { [pscustomobject]@{ Note = 'declined'; Results = @{ jq = (New-StepResult -Status FAILED -Detail 'declined'); gh = (New-StepResult -Status FAILED -Detail 'declined') } } }
      & $run 'admin' | Should -Be 1
    }

    It 'exits 1 when an item is pending' {
      Mock Invoke-ElevatedRun { [pscustomobject]@{ Note = 'ok'; Results = @{ jq = (New-StepResult -Status PENDING -Detail 'reboot'); gh = (New-StepResult -Status fixed) } } }
      $script:installed['choco:gh'] = '1'
      & $run 'admin' | Should -Be 1
    }

    It 'runs the dotfiles setup steps only when dotfiles is in the target' {
      Skip-OffWindows

      & $run 'user' | Out-Null
      Should -Invoke Repair-Python3 -Times 0
      Should -Invoke Repair-PathValue -Times 0
      & $run 'dotfiles' | Should -Be 0
      Should -Invoke Repair-Python3 -Times 1
      Should -Invoke Set-MsysSymlinkMode -Times 1
      Should -Invoke Repair-PathValue -Times 1 -Exactly -ParameterFilter { $Scope -eq 'Machine' }
      Should -Invoke Repair-PathValue -Times 1 -Exactly -ParameterFilter { $Scope -eq 'User' }
      Should -Invoke Test-S3cmdWrapper -Times 1
    }

    It 'fails before doing anything when a name does not resolve' {
      & $run 'nope' | Should -Be 1
      $script:report | Where-Object { $_ -like 'FAILED: *neither a host*' } | Should -Not -BeNullOrEmpty
      Should -Invoke Invoke-SpecInstall -Times 0
    }

    It 'returns only the exit code' {
      $out = @(& $run 'user')
      $out.Count | Should -Be 1
    }
  }

  Describe 'Get-NewestPython' {
    BeforeEach {
      Mock Get-Command -ParameterFilter { $Name -eq 'py' } { & $script:fakeCommand 'C:\Windows\py.exe' }
    }

    It 'picks the highest X.Y version, not the default' {
      Mock py {
        ' -V:3.13          C:\Python313\python.exe'
        ' -V:3.15          C:\Python315\python.exe'
        ' -V:3.14 *        C:\Python314\python.exe'
      }

      Get-NewestPython | Should -Be 'C:\Python315\python.exe'
    }

    It 'passes over free-threaded and 32-bit tags' {
      Mock py {
        ' -V:3.16t         C:\Python316\python3.16t.exe'
        ' -V:3.16-32       C:\Python316-32\python.exe'
        ' -V:3.14 *        C:\Python314\python.exe'
      }

      Get-NewestPython | Should -Be 'C:\Python314\python.exe'
    }

    It 'compares versions numerically' {
      Mock py {
        ' -V:3.9           C:\Python39\python.exe'
        ' -V:3.10          C:\Python310\python.exe'
      }

      Get-NewestPython | Should -Be 'C:\Python310\python.exe'
    }

    It 'returns $null when the py launcher is missing' {
      Mock Get-Command -ParameterFilter { $Name -eq 'py' } { }
      Get-NewestPython | Should -BeNullOrEmpty
    }
  }

  Describe 'Get-ReorderedUserPath' {
    BeforeAll {
      $bin = 'C:\Users\u\.local\bin'
      $apps = 'C:\Users\u\AppData\Local\Microsoft\WindowsApps'
    }

    It 'returns $null when the directory already precedes WindowsApps' {
      Get-ReorderedUserPath -UserPath "$bin;$apps;C:\other" -Directory $bin | Should -BeNullOrEmpty
    }

    It 'moves the directory to the front when it follows WindowsApps' {
      Get-ReorderedUserPath -UserPath "$apps;$bin;C:\other" -Directory $bin |
        Should -Be "$bin;$apps;C:\other"
    }

    It 'prepends the directory when it is missing' {
      Get-ReorderedUserPath -UserPath "$apps;C:\other;" -Directory $bin |
        Should -Be "$bin;$apps;C:\other"
    }

    It 'prepends the directory to an empty PATH' {
      Get-ReorderedUserPath -UserPath '' -Directory $bin | Should -Be $bin
    }

    It 'recognises the directory written with %VARS% and a trailing slash' {
      $env:PREREQ_TEST_HOME = 'C:\Users\u'
      try {
        Get-ReorderedUserPath -UserPath "%PREREQ_TEST_HOME%\.local\bin\;$apps" -Directory $bin |
          Should -BeNullOrEmpty
      } finally {
        [Environment]::SetEnvironmentVariable('PREREQ_TEST_HOME', $null)
      }
    }
  }

  Describe 'Write-UserEnvironmentValue' {
    BeforeAll {
      $fakeKey = [pscustomobject]@{}
      $fakeKey | Add-Member -MemberType ScriptMethod -Name GetValueNames -Value { @('Path') }
      $fakeKey | Add-Member -MemberType ScriptMethod -Name GetValueKind -Value { [Microsoft.Win32.RegistryValueKind]::ExpandString }
    }

    BeforeEach {
      Mock Get-Item -ParameterFilter { $Path -eq 'HKCU:\Environment' } { $fakeKey }
    }

    It 'keeps an existing value''s registry kind' {
      Write-UserEnvironmentValue -Name Path -Value 'C:\x'
      Should -Invoke New-ItemProperty -Times 1 -ParameterFilter { $Name -eq 'Path' -and $PropertyType -eq 'ExpandString' }
      Should -Invoke Send-EnvironmentChange -Times 1
    }

    It 'writes a new value as REG_SZ' {
      Write-UserEnvironmentValue -Name MSYS -Value 'winsymlinks:nativestrict'
      Should -Invoke New-ItemProperty -Times 1 -ParameterFilter { $Name -eq 'MSYS' -and $PropertyType -eq 'String' }
    }

    It 'writes the Machine environment, keeping its kind, with -Scope Machine' {
      $machine = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment'
      Mock Get-Item -ParameterFilter { $Path -eq $machine } { $fakeKey }
      Write-UserEnvironmentValue -Name Path -Value 'C:\x' -Scope Machine
      Should -Invoke New-ItemProperty -Times 1 -ParameterFilter {
        $Path -eq $machine -and $Name -eq 'Path' -and $PropertyType -eq 'ExpandString'
      }
    }
  }

  Describe 'PATH clean-up' {
    BeforeAll {
      $a = Join-Path -Path $TestDrive -ChildPath 'a'
      $b = Join-Path -Path $TestDrive -ChildPath 'b'
      $gone = Join-Path -Path $TestDrive -ChildPath 'gone'
      [IO.Directory]::CreateDirectory($a) | Out-Null
      [IO.Directory]::CreateDirectory($b) | Out-Null
      $sep = [IO.Path]::DirectorySeparatorChar
    }

    Describe 'Get-CleanPath' {
      It 'leaves a clean PATH as it is' {
        $r = Get-CleanPath -Value "$a;$b"
        $r.Value | Should -Be "$a;$b"
        $r.Repeated | Should -BeNullOrEmpty
        $r.Missing | Should -BeNullOrEmpty
      }

      It 'removes a repeat, keeping the first in its place' {
        $r = Get-CleanPath -Value "$a;$b;$a"
        $r.Value | Should -Be "$a;$b"
        $r.Repeated | Should -Be @($a)
      }

      It 'counts an entry differing only in case or a trailing \ as a repeat' {
        $r = Get-CleanPath -Value "$a;$($a.ToUpperInvariant())\"
        $r.Value | Should -Be $a
        $r.Repeated | Should -Be @("$($a.ToUpperInvariant())\")
      }

      It 'drops an entry whose directory is missing' {
        $r = Get-CleanPath -Value "$a;$gone;$b"
        $r.Value | Should -Be "$a;$b"
        $r.Missing | Should -Be @($gone)
      }

      It 'keeps an entry on a drive or share that is not there' {
        $root = [IO.Path]::GetPathRoot($gone)
        Mock Test-Path -ParameterFilter { $LiteralPath -eq $root } { $false }
        (Get-CleanPath -Value "$a;$gone").Value | Should -Be "$a;$gone"
      }

      It 'compares %VARS% expanded, and keeps them as written' {
        $env:PREREQ_TEST_DRIVE = $TestDrive
        try {
          $r = Get-CleanPath -Value "$a;%PREREQ_TEST_DRIVE%${sep}a;%PREREQ_TEST_DRIVE%${sep}b"
          $r.Value | Should -Be "$a;%PREREQ_TEST_DRIVE%${sep}b"
          $r.Repeated | Should -Be @("%PREREQ_TEST_DRIVE%${sep}a")
        } finally {
          Remove-Item -Path Env:PREREQ_TEST_DRIVE
        }
      }

      It 'drops empty entries and takes an unset PATH' {
        (Get-CleanPath -Value ";$a;;").Value | Should -Be $a
        (Get-CleanPath -Value $null).Value | Should -Be ''
      }
    }

    Describe 'Test-MissingDirectory' {
      It 'is false for an entry that is not a rooted path' {
        Test-MissingDirectory -Path 'relative' | Should -BeFalse
      }
    }

    Describe 'Repair-PathValue' {
      BeforeEach {
        # The PATH lives in $script:pathValue; writing it changes what the
        # next read returns, so a rerun sees the first run's fix.
        $script:pathValue = "$a;$gone;$b;$a"
        Mock Get-UserEnvironmentValue { $script:pathValue }
        Mock Write-UserEnvironmentValue { $script:pathValue = $Value }
      }

      It 'is ok, and writes nothing, when the PATH is clean' {
        $script:pathValue = "$a;$b"
        (Repair-PathValue).Status | Should -Be 'ok'
        Should -Invoke Write-UserEnvironmentValue -Times 0
      }

      It 'removes the repeated and missing entries from the User PATH, keeping its order' {
        $r = Repair-PathValue -Scope User
        $r.Status | Should -Be 'fixed'
        $r.Detail | Should -Be 'removed 1 repeated, 1 missing'
        $r.Lines | Should -Be @("repeated: $a", "missing: $gone")
        Should -Invoke Get-UserEnvironmentValue -ParameterFilter { $Name -eq 'Path' -and $Scope -eq 'User' }
        Should -Invoke Write-UserEnvironmentValue -Times 1 -Exactly -ParameterFilter {
          $Name -eq 'Path' -and $Value -eq "$a;$b" -and $Scope -eq 'User'
        }
      }

      It 'is safe to rerun: the second run finds nothing to fix' {
        (Repair-PathValue).Status | Should -Be 'fixed'
        (Repair-PathValue).Status | Should -Be 'ok'
        Should -Invoke Write-UserEnvironmentValue -Times 1 -Exactly
      }

      It 'says what it would remove under -WhatIf, writing nothing' {
        $r = Repair-PathValue -Scope Machine -WhatIf
        $r.Status | Should -Be 'would fix'
        $r.Detail | Should -Be 'remove 1 repeated, 1 missing (needs admin)'
        Should -Invoke Write-UserEnvironmentValue -Times 0
      }

      It 'leaves the Machine PATH to the elevated pass when unelevated' {
        $r = Repair-PathValue -Scope Machine
        $r.Status | Should -Be 'needs admin'
        Should -Invoke Write-UserEnvironmentValue -Times 0
      }

      It 'fixes the Machine PATH when elevated' {
        Mock Test-Elevated { $true }
        (Repair-PathValue -Scope Machine).Status | Should -Be 'fixed'
        Should -Invoke Write-UserEnvironmentValue -Times 1 -Exactly -ParameterFilter {
          $Value -eq "$a;$b" -and $Scope -eq 'Machine'
        }
      }
    }

    Describe 'Invoke-AdminPass with the Machine PATH' {
      BeforeEach {
        Mock Invoke-ElevatedRun {
          [pscustomobject]@{ Note = 'UAC accepted'; Results = @{ 'machine PATH' = (New-StepResult -Status fixed -Detail 'removed 1 repeated, 0 missing') } }
        }
        $results = [ordered]@{ 'machine PATH' = (New-StepResult -Status 'needs admin' -Detail 'remove 1 repeated, 0 missing from the Machine PATH' -Plan @{}) }
      }

      It 'cleans it in the one elevated pass and checks the result unelevated' {
        Mock Get-UserEnvironmentValue -ParameterFilter { $Scope -eq 'Machine' } { "$a;$b" }
        Invoke-AdminPass -Results $results -Packages @{}
        Should -Invoke Invoke-ElevatedRun -Times 1 -Exactly -ParameterFilter {
          $Plan['MachinePath'] -and @($Plan['Packages']).Count -eq 0
        }
        $results['machine PATH'].Status | Should -Be 'fixed'
      }

      It 'fails the item when the Machine PATH still needs cleaning afterwards' {
        Mock Get-UserEnvironmentValue -ParameterFilter { $Scope -eq 'Machine' } { "$a;$a" }
        Invoke-AdminPass -Results $results -Packages @{}
        $results['machine PATH'].Status | Should -Be 'FAILED'
      }
    }
  }

  Describe 'Test-DeveloperMode' {
    It 'is true when AllowDevelopmentWithoutDevLicense is 1' {
      Mock Get-ItemProperty { [pscustomobject]@{ AllowDevelopmentWithoutDevLicense = 1 } }
      Test-DeveloperMode | Should -BeTrue
    }

    It 'is false when the value is absent' {
      Mock Get-ItemProperty { }
      Test-DeveloperMode | Should -BeFalse
    }
  }

  Describe 'Get-Python3Prefix' {
    BeforeEach {
      Mock Find-Executable -ParameterFilter { $Name -eq 'python3' } { 'C:\x\python3.exe' }
    }

    It 'returns sys.prefix for a real Python' {
      Mock Invoke-Python3 { 'C:\Python315' }
      Get-Python3Prefix | Should -Be 'C:\Python315'
    }

    It 'returns $null for the Store stub, which prints nothing to stdout' {
      Mock Invoke-Python3 { }
      Get-Python3Prefix | Should -BeNullOrEmpty
    }

    It 'returns $null for a WindowsApps prefix' {
      Mock Invoke-Python3 { 'C:\Users\u\AppData\Local\Microsoft\WindowsApps' }
      Get-Python3Prefix | Should -BeNullOrEmpty
    }

    It 'returns $null when python3 is not found' {
      Mock Find-Executable { $null }
      Get-Python3Prefix | Should -BeNullOrEmpty
    }
  }

  Describe 'Repair-Python3' {
    BeforeAll {
      $bin = Join-Path -Path $HOME -ChildPath '.local\bin'
      $link = Join-Path -Path $bin -ChildPath 'python3.exe'
    }

    BeforeEach {
      Mock Get-NewestPython { 'C:\Python315\python.exe' }
      Mock Test-DeveloperMode { $true }
      Mock Get-UserEnvironmentValue -ParameterFilter { $Name -eq 'Path' } { "$bin;C:\Users\u\AppData\Local\Microsoft\WindowsApps" }
      Mock Get-Python3Prefix { 'C:\Python315' }
      Mock Get-Item -ParameterFilter { $LiteralPath -eq $link } { }
      Mock Write-UserEnvironmentValue { }
    }

    It 'is ok when the link and PATH are already right' {
      Mock Get-Item -ParameterFilter { $LiteralPath -eq $link } {
        [pscustomobject]@{ LinkType = 'SymbolicLink'; Target = 'C:\Python315\python.exe' }
      }

      $result = Repair-Python3
      $result.Status | Should -Be 'ok'
      $result.Detail | Should -Be 'sys.prefix C:\Python315'
      Should -Invoke New-Item -Times 0
      Should -Invoke Write-UserEnvironmentValue -Times 0
    }

    It 'creates a missing link to the newest Python' {
      (Repair-Python3).Status | Should -Be 'fixed'
      Should -Invoke New-Item -Times 1 -ParameterFilter {
        $ItemType -eq 'SymbolicLink' -and $Path -eq $link -and $Target -eq 'C:\Python315\python.exe'
      }
    }

    It 'repoints a link at an older Python' {
      Mock Get-Item -ParameterFilter { $LiteralPath -eq $link } {
        [pscustomobject]@{ LinkType = 'SymbolicLink'; Target = 'C:\Python314\python.exe' }
      }

      (Repair-Python3).Status | Should -Be 'fixed'
      Should -Invoke Remove-Item -Times 1 -ParameterFilter { $LiteralPath -eq $link }
    }

    It 'refuses to replace a regular file' {
      Mock Get-Item -ParameterFilter { $LiteralPath -eq $link } {
        [pscustomobject]@{ LinkType = $null; Target = $null }
      }

      (Repair-Python3).Detail | Should -BeLike '*not a symlink*'
      Should -Invoke Remove-Item -Times 0
    }

    It 'fails with the manual step when Developer Mode is off' {
      Mock Test-DeveloperMode { $false }
      (Repair-Python3).Detail | Should -BeLike '*Developer Mode*For developers*'
    }

    It 'puts ~\.local\bin ahead of WindowsApps' {
      Mock Get-Item -ParameterFilter { $LiteralPath -eq $link } {
        [pscustomobject]@{ LinkType = 'SymbolicLink'; Target = 'C:\Python315\python.exe' }
      }
      Mock Get-UserEnvironmentValue -ParameterFilter { $Name -eq 'Path' } { "C:\Users\u\AppData\Local\Microsoft\WindowsApps;$bin" }

      (Repair-Python3).Status | Should -Be 'fixed'
      Should -Invoke Write-UserEnvironmentValue -Times 1 -ParameterFilter {
        $Name -eq 'Path' -and $Value -eq "$bin;C:\Users\u\AppData\Local\Microsoft\WindowsApps"
      }
    }

    It 'changes nothing under -WhatIf' {
      Mock Get-UserEnvironmentValue -ParameterFilter { $Name -eq 'Path' } { 'C:\other' }
      $result = Repair-Python3 -WhatIf
      $result.Status | Should -Be 'would fix'
      $result.Detail | Should -BeLike "*$link*User PATH*"
      Should -Invoke New-Item -Times 0
      Should -Invoke Write-UserEnvironmentValue -Times 0
    }
  }

  Describe 'Set-MsysSymlinkMode' {
    BeforeEach {
      $savedMsys = $env:MSYS
      Mock Write-UserEnvironmentValue { }
    }

    AfterEach {
      $env:MSYS = $savedMsys
    }

    It 'is ok when the token is already present' {
      Mock Get-UserEnvironmentValue { 'enable_pcon winsymlinks:nativestrict' }
      (Set-MsysSymlinkMode).Status | Should -Be 'ok'
      Should -Invoke Write-UserEnvironmentValue -Times 0
    }

    It 'keeps other tokens and replaces a conflicting winsymlinks mode' {
      Mock Get-UserEnvironmentValue { 'enable_pcon  winsymlinks:lnk' }
      (Set-MsysSymlinkMode).Status | Should -Be 'fixed'
      Should -Invoke Write-UserEnvironmentValue -Times 1 -ParameterFilter {
        $Value -eq 'enable_pcon winsymlinks:nativestrict'
      }
    }

    It 'changes nothing under -WhatIf' {
      Mock Get-UserEnvironmentValue { $null }
      (Set-MsysSymlinkMode -WhatIf).Status | Should -Be 'would fix'
      Should -Invoke Write-UserEnvironmentValue -Times 0
    }
  }

  Describe 'Test-S3cmdWrapper' {
    BeforeEach {
      Mock Get-GitBash { 'C:\Git\bin\bash.exe' }
    }

    It 'checks s3cmd through dotfiles'' bin/s3cmd in Git Bash' {
      Skip-OffWindows

      Mock Get-S3cmdWrapperVersion { 's3cmd version 2.4.0' }
      (Test-S3cmdWrapper -DotfilesRoot 'C:\p\dotfiles').Status | Should -Be 'ok'
      Should -Invoke Get-S3cmdWrapperVersion -Times 1 -ParameterFilter { $Wrapper -eq 'C:\p\dotfiles\bin\s3cmd' }
    }

    It 'fails when bin/s3cmd cannot run s3cmd' {
      Skip-OffWindows

      Mock Get-S3cmdWrapperVersion { }
      (Test-S3cmdWrapper -DotfilesRoot 'C:\p\dotfiles').Status | Should -Be 'FAILED'
    }

    It 'fails when Git Bash is missing' {
      Mock Get-GitBash { $null }
      (Test-S3cmdWrapper -DotfilesRoot 'C:\p\dotfiles').Status | Should -Be 'FAILED'
    }
  }

  Describe 'Get-GitBash' {
    It 'finds bin\bash.exe beside git.exe in cmd\' {
      Skip-OffWindows

      Mock Get-Command -ParameterFilter { $Name -eq 'git' } { & $script:fakeCommand 'C:\Program Files\Git\cmd\git.exe' }
      Mock Test-Path { $true }
      Get-GitBash | Should -Be 'C:\Program Files\Git\bin\bash.exe'
    }

    It 'returns $null when bash.exe is not there' {
      Mock Get-Command -ParameterFilter { $Name -eq 'git' } { & $script:fakeCommand 'C:\Git\cmd\git.exe' }
      Mock Test-Path { $false }
      Get-GitBash | Should -BeNullOrEmpty
    }
  }
}
