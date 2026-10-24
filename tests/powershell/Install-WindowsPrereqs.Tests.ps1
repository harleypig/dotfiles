#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0' }

# Tests for powershell/bin/Install-WindowsPrereqs.ps1. Every command that
# could change the machine is mocked at the root, so no test reaches the
# registry, the filesystem, choco, winget, npm, uv, pip, PowerShellGet,
# docker, WSL, UAC or a real Python.

[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
  'PSUseDeclaredVarsMoreThanAssignments', '',
  Justification = 'Pester shares BeforeAll/BeforeEach variables with It blocks, which PSScriptAnalyzer cannot see.')]
param ()

BeforeAll {
  . (Join-Path -Path $PSScriptRoot -ChildPath '..\..\powershell\bin\Install-WindowsPrereqs.ps1')

  # Safety net: inner blocks override these with the behaviour they test.
  Mock New-Item { }
  Mock Remove-Item { }
  Mock New-ItemProperty { }
  Mock Send-EnvironmentChange { }
  Mock Sync-ProcessPath { }
  Mock winget { $global:LASTEXITCODE = 0 }
  # npm is npm.ps1, which Pester cannot mock by name; the script calls it
  # through Invoke-Npm.
  Mock Invoke-Npm { $global:LASTEXITCODE = 0 }
  Mock py { }
  Mock python3 { $global:LASTEXITCODE = 0 }
  Mock choco { $global:LASTEXITCODE = 0 }
  Mock uv { $global:LASTEXITCODE = 0 }
  Mock Invoke-ChocolateyBootstrap { }
  Mock Invoke-WebRequest { }
  Mock Install-Module { }
  Mock Start-Process { }
  Mock Start-Sleep { }
  Mock Test-Wsl { $true }
  Mock Get-DockerServerVersion { }
  Mock Test-Elevated { $false }

  $script:fakeCommand = { param($Source) [pscustomobject]@{ Source = $Source } }
}

Describe 'Invoke-PrereqStep' {
  It 'returns the step''s result' {
    (Invoke-PrereqStep -Step { New-StepResult -Status ok -Detail 'x' }).Status | Should -Be 'ok'
  }

  It 'turns an exception into a failure' {
    $result = Invoke-PrereqStep -Step { throw 'boom' }
    $result.Status | Should -Be 'FAILED'
    $result.Detail | Should -Be 'boom'
  }
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
    $lines = Format-StepResult -Name winget -Result (New-StepResult -Status ok -Detail 'd' -Line 'a', 'b')
    $lines | Should -Be @('winget: ok (d)', '  a', '  b')
  }
}

Describe 'Invoke-ElevatedRun' {
  BeforeEach {
    Mock Get-CurrentUserSid { 'S-1-5-21-1' }
  }

  It 'fails every item when UAC is declined' {
    Mock Start-Process { throw 'The operation was canceled by the user.' }
    $run = Invoke-ElevatedRun -Name jq, docker
    $run.Results['jq'].Status | Should -Be 'FAILED'
    $run.Results['docker'].Detail | Should -BeLike 'elevation declined*canceled by the user*'
  }

  It 'reads back the elevated copy''s results and checks its account' {
    Mock Start-Process {
      $resultFile = ($ArgumentList[$ArgumentList.IndexOf('-ResultPath') + 1]).Trim('"')
      $sid = $ArgumentList[$ArgumentList.IndexOf('-ExpectedSid') + 1]
      @{ Sid = $sid; Results = @{ jq = @{ Status = 'fixed'; Detail = 'choco jq'; Lines = @() } } } |
        ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $resultFile
      [pscustomobject]@{ ExitCode = 0 }
    }
    Mock Remove-Item { } -ParameterFilter { $LiteralPath -like '*Install-WindowsPrereqs-*.json' }

    $run = Invoke-ElevatedRun -Name jq
    $run.Results['jq'].Status | Should -Be 'fixed'
    $run.Note | Should -BeLike '*same account (SID verified)*'
    Should -Invoke Start-Process -Times 1 -ParameterFilter { $Verb -eq 'RunAs' -and $Wait }

    Get-ChildItem -Path ([IO.Path]::GetTempPath()) -Filter "Install-WindowsPrereqs-$PID.json" |
      ForEach-Object { [IO.File]::Delete($_.FullName) }
  }

  It 'passes -ConvertWinget through' {
    Mock Start-Process { [pscustomobject]@{ ExitCode = 1 } }
    $run = Invoke-ElevatedRun -Name winget -ConvertWinget
    $run.Results['winget'].Detail | Should -BeLike '*wrote no results*'
    Should -Invoke Start-Process -Times 1 -ParameterFilter { $ArgumentList -contains '-ConvertWinget' }
  }
}

Describe 'Install-ChocoPackage' {
  It 'returns nothing on success, with choco writing to the console' {
    Mock Start-Process { [pscustomobject]@{ ExitCode = 0 } }
    Install-ChocoPackage -Id jq | Should -Be ''
    Should -Invoke Start-Process -Times 1 -ParameterFilter {
      $FilePath -eq 'choco' -and "$ArgumentList" -eq 'install jq -y' -and $NoNewWindow -and $Wait
    }
  }

  It 'reports a requested reboot' {
    Mock Start-Process { [pscustomobject]@{ ExitCode = 3010 } }
    Install-ChocoPackage -Id docker-desktop | Should -Be 'reboot'
  }

  It 'reports any other exit code as a failure' {
    Mock Start-Process { [pscustomobject]@{ ExitCode = 1 } }
    Install-ChocoPackage -Id jq | Should -Be 'choco install jq exited 1'
  }
}

Describe 'Invoke-ElevatedItem' {
  BeforeEach {
    Mock Get-CurrentUserSid { 'S-1-5-21-1' }
    Mock Test-Elevated { $true }
    Mock Set-Content { }
    Mock Wait-ElevatedWindowClose { }
    $steps = [ordered]@{
      jq     = { New-StepResult -Status fixed -Detail 'choco jq' }
      docker = { New-StepResult -Status FAILED -Detail 'choco install docker-desktop exited 1' }
    }
  }

  It 'says what it is, announces each step before it runs, and ends with a summary' {
    $out = @(Invoke-ElevatedItem -Name jq, docker -Step $steps -ExpectedSid 'S-1-5-21-1' -ResultPath 'C:\r.json')
    $text = [string[]]@($out | Where-Object { $_ -is [string] })

    $text[0] | Should -Be 'Install-WindowsPrereqs.ps1 - elevated part'
    $text | Should -Contain 'Admin steps: jq, docker'
    $text | Should -Contain '[docker] downloading Docker Desktop (~1 GB) via choco - this can take 20+ minutes...'
    $text | Should -Contain '  docker: FAILED'

    $announce = [array]::IndexOf($text, '[jq] installing jq via choco, then removing the winget copy...')
    $announce | Should -BeGreaterOrEqual 0
    $announce | Should -BeLessThan ([array]::IndexOf($text, 'jq: fixed (choco jq)'))
  }

  It 'writes the results file and holds the window open when a step failed' {
    Invoke-ElevatedItem -Name jq, docker -Step $steps -ExpectedSid 'S-1-5-21-1' -ResultPath 'C:\r.json' | Out-Null
    Should -Invoke Set-Content -Times 1 -ParameterFilter { $LiteralPath -eq 'C:\r.json' }
    Should -Invoke Wait-ElevatedWindowClose -Times 1 -ParameterFilter { $Failed }
  }

  It 'lets the window close on its own when every step worked' {
    Invoke-ElevatedItem -Name jq -Step $steps -ExpectedSid 'S-1-5-21-1' -ResultPath 'C:\r.json' | Out-Null
    Should -Invoke Wait-ElevatedWindowClose -Times 1 -ParameterFilter { -not $Failed }
  }

  It 'changes nothing when elevated as a different account' {
    $script:ran = $false
    $guarded = [ordered]@{ jq = { $script:ran = $true; New-StepResult -Status fixed } }
    $out = @(Invoke-ElevatedItem -Name jq -Step $guarded -ExpectedSid 'S-1-5-21-2' -ResultPath 'C:\r.json')
    $out | Should -Contain 'jq: FAILED: elevated as a different account; nothing changed'
    $script:ran | Should -BeFalse
  }
}

Describe 'Wait-ElevatedWindowClose' {
  BeforeEach {
    Mock Read-Host { '' }
  }

  It 'closes after a pause when everything worked' {
    Wait-ElevatedWindowClose | Should -Be 'done - this window will close in 10 seconds'
    Should -Invoke Start-Sleep -Times 1 -ParameterFilter { $Seconds -eq 10 }
    Should -Invoke Read-Host -Times 0
  }

  It 'waits for Enter when a step failed' {
    Wait-ElevatedWindowClose -Failed
    Should -Invoke Read-Host -Times 1 -ParameterFilter { $Prompt -like '*FAILED*press Enter*' }
    Should -Invoke Start-Sleep -Times 0
  }
}

Describe 'Test-ChocoPackage' {
  It 'finds an exact local package' {
    Mock choco { 'jq|1.8.1' }
    Test-ChocoPackage -Id jq | Should -BeTrue
  }

  It 'does not mistake another package for it' {
    Mock choco { 'jqp|1.0.0' }
    Test-ChocoPackage -Id jq | Should -BeFalse
  }
}

Describe 'Install-Chocolatey' {
  BeforeEach {
    $script:chocoPresent = $false
    Mock Test-Choco { $script:chocoPresent }
    Mock Invoke-ChocolateyBootstrap { $script:chocoPresent = $true }
    Mock choco { '2.7.4' }
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
      Remove-Item -Path Env:PREREQ_TEST_HOME
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
}

Describe 'Test-DeveloperMode' {
  It 'is true when AllowDevelopmentWithoutDevLicense is 1' {
    Mock Get-ItemProperty { [pscustomobject]@{ AllowDevelopmentWithoutDevLicense = 1 } }
    Test-DeveloperMode | Should -BeTrue
  }

  It 'is false when the value is 0' {
    Mock Get-ItemProperty { [pscustomobject]@{ AllowDevelopmentWithoutDevLicense = 0 } }
    Test-DeveloperMode | Should -BeFalse
  }

  It 'is false when the value is absent' {
    Mock Get-ItemProperty { }
    Test-DeveloperMode | Should -BeFalse
  }
}

Describe 'Get-Python3Prefix' {
  BeforeEach {
    Mock Get-Command -ParameterFilter { $Name -eq 'python3' } { & $script:fakeCommand 'C:\x\python3.exe' }
  }

  It 'returns sys.prefix for a real Python' {
    Mock python3 { 'C:\Python315' }
    Get-Python3Prefix | Should -Be 'C:\Python315'
  }

  It 'returns $null for the Store stub, which prints nothing to stdout' {
    Mock python3 { }
    Get-Python3Prefix | Should -BeNullOrEmpty
  }

  It 'returns $null for a WindowsApps prefix' {
    Mock python3 { 'C:\Users\u\AppData\Local\Microsoft\WindowsApps' }
    Get-Python3Prefix | Should -BeNullOrEmpty
  }

  It 'returns $null when python3 is not found' {
    Mock Get-Command -ParameterFilter { $Name -eq 'python3' } { }
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
    Should -Invoke Remove-Item -Times 0
  }

  It 'repoints a link at an older Python' {
    Mock Get-Item -ParameterFilter { $LiteralPath -eq $link } {
      [pscustomobject]@{ LinkType = 'SymbolicLink'; Target = 'C:\Python314\python.exe' }
    }

    (Repair-Python3).Status | Should -Be 'fixed'
    Should -Invoke Remove-Item -Times 1 -ParameterFilter { $LiteralPath -eq $link }
    Should -Invoke New-Item -Times 1 -ParameterFilter { $Target -eq 'C:\Python315\python.exe' }
  }

  It 'refuses to replace a regular file' {
    Mock Get-Item -ParameterFilter { $LiteralPath -eq $link } {
      [pscustomobject]@{ LinkType = $null; Target = $null }
    }

    $result = Repair-Python3
    $result.Status | Should -Be 'FAILED'
    $result.Detail | Should -BeLike '*not a symlink*'
    Should -Invoke Remove-Item -Times 0
  }

  It 'fails with the manual step when Developer Mode is off' {
    Mock Test-DeveloperMode { $false }

    $result = Repair-Python3
    $result.Status | Should -Be 'FAILED'
    $result.Detail | Should -BeLike '*Developer Mode*For developers*'
    Should -Invoke New-Item -Times 0
  }

  It 'fails when the py launcher finds nothing' {
    Mock Get-NewestPython { $null }
    (Repair-Python3).Status | Should -Be 'FAILED'
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

  It 'fails when python3 still is not a real Python afterwards' {
    Mock Get-Python3Prefix { $null }
    (Repair-Python3).Status | Should -Be 'FAILED'
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

Describe 'Install-Jq' {
  BeforeAll {
    $chocoJq = Join-Path -Path $env:ProgramData -ChildPath 'chocolatey\bin\jq.exe'
  }

  BeforeEach {
    $script:chocoJq = $false
    $script:wingetJq = $false
    Mock Test-Choco { $true }
    Mock Test-ChocoPackage -ParameterFilter { $Id -eq 'jq' } { $script:chocoJq }
    Mock Test-WingetPackage -ParameterFilter { $Id -eq 'jqlang.jq' } { $script:wingetJq }
    Mock Install-ChocoPackage { $script:chocoJq = $true; '' }
    Mock winget { $script:wingetJq = $false; $global:LASTEXITCODE = 0 }
    Mock Get-Command -ParameterFilter { $Name -eq 'jq' } {
      if ($script:chocoJq) { & $script:fakeCommand $chocoJq }
      elseif ($script:wingetJq) { & $script:fakeCommand 'C:\WinGet\Links\jq.exe' }
    }
  }

  It 'is ok when choco owns jq and winget has no copy' {
    $script:chocoJq = $true
    $result = Install-Jq
    $result.Status | Should -Be 'ok'
    $result.Detail | Should -Be $chocoJq
    Should -Invoke Install-ChocoPackage -Times 0
    Should -Invoke winget -Times 0
  }

  It 'asks for admin before touching the winget copy' {
    $script:wingetJq = $true
    (Install-Jq).Status | Should -Be 'needs admin'
    Should -Invoke winget -Times 0
  }

  It 'installs with choco, then removes the winget copy, when elevated' {
    Mock Test-Elevated { $true }
    $script:wingetJq = $true

    (Install-Jq).Status | Should -Be 'fixed'
    Should -Invoke Install-ChocoPackage -Times 1 -ParameterFilter { $Id -eq 'jq' }
    Should -Invoke winget -Times 1 -ParameterFilter { "$args" -like 'uninstall --id jqlang.jq --exact --source winget*' }
  }

  It 'removes a leftover winget copy unelevated once choco owns jq' {
    $script:chocoJq = $true
    $script:wingetJq = $true
    (Install-Jq).Status | Should -Be 'fixed'
    Should -Invoke winget -Times 1
  }

  It 'fails when jq resolves somewhere other than Chocolatey' {
    $script:chocoJq = $true
    Mock Get-Command -ParameterFilter { $Name -eq 'jq' } { & $script:fakeCommand 'C:\WinGet\Links\jq.exe' }
    $result = Install-Jq
    $result.Status | Should -Be 'FAILED'
    $result.Detail | Should -BeLike "*not Chocolatey's"
  }

  It 'fails when the choco install fails' {
    Mock Test-Elevated { $true }
    Mock Install-ChocoPackage { 'choco install jq exited 1' }
    (Install-Jq).Detail | Should -Be 'choco install jq exited 1'
  }

  It 'fails without Chocolatey' {
    Mock Test-Choco { $false }
    (Install-Jq).Status | Should -Be 'FAILED'
  }

  It 'changes nothing under -WhatIf' {
    $script:wingetJq = $true
    $result = Install-Jq -WhatIf
    $result.Status | Should -Be 'would fix'
    $result.Detail | Should -BeLike 'choco install jq*winget uninstall jqlang.jq*'
    Should -Invoke Install-ChocoPackage -Times 0
    Should -Invoke winget -Times 0
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

  It 'sets MSYS when it is unset' {
    Mock Get-UserEnvironmentValue { $null }
    (Set-MsysSymlinkMode).Status | Should -Be 'fixed'
    Should -Invoke Write-UserEnvironmentValue -Times 1 -ParameterFilter {
      $Name -eq 'MSYS' -and $Value -eq 'winsymlinks:nativestrict'
    }
  }

  It 'keeps other tokens and replaces a conflicting winsymlinks mode' {
    Mock Get-UserEnvironmentValue { 'enable_pcon  winsymlinks:lnk' }
    Set-MsysSymlinkMode | Out-Null
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

Describe 'Get-GitBash' {
  It 'finds bin\bash.exe beside git.exe in cmd\' {
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

Describe 'Get-BatsVersion' {
  BeforeAll {
    function Invoke-FakeBashWithBat { 'Bats 1.13.0' }
    function Invoke-FakeBashWithoutBat { 'bash: bats: command not found' }
  }

  It 'returns the version line when bats runs' {
    Get-BatsVersion -Bash Invoke-FakeBashWithBat | Should -Be 'Bats 1.13.0'
  }

  It 'returns $null when bats does not run' {
    Get-BatsVersion -Bash Invoke-FakeBashWithoutBat | Should -BeNullOrEmpty
  }
}

Describe 'Install-BatsToolchain' {
  BeforeEach {
    $script:npmInstalled = @()
    Mock Get-Command -ParameterFilter { $Name -eq 'npm' } { & $script:fakeCommand 'C:\nodejs\npm.ps1' }
    Mock Get-GitBash { 'C:\Git\bin\bash.exe' }
    Mock Invoke-Npm {
      if ($ArgumentList[0] -eq 'root') {
        'C:\npm\node_modules'
      } else {
        $script:npmInstalled = @($ArgumentList | Select-Object -Skip 2 | ForEach-Object { $_ -replace '^github:bats-core/', '' })
        $global:LASTEXITCODE = 0
      }
    }
    Mock Get-BatsVersion { if ($script:npmInstalled -contains 'bats') { 'Bats 1.13.0' } }
    Mock Test-Path -ParameterFilter { $LiteralPath -like '*load.bash' } {
      $script:npmInstalled -contains (Split-Path -Path (Split-Path -Path $LiteralPath) -Leaf)
    }
  }

  It 'is ok, with BATS_LIB_PATH, when everything is installed' {
    $script:npmInstalled = @('bats', 'bats-support', 'bats-assert', 'bats-file')
    $result = Install-BatsToolchain
    $result.Status | Should -Be 'ok'
    $result.Detail | Should -Be 'Bats 1.13.0; BATS_LIB_PATH=C:\npm\node_modules'
    Should -Invoke Invoke-Npm -Times 0 -ParameterFilter { $ArgumentList[0] -eq 'install' }
  }

  It 'installs only what is missing' {
    $script:npmInstalled = @('bats', 'bats-support')
    Mock Invoke-Npm {
      if ($ArgumentList[0] -eq 'root') { 'C:\npm\node_modules' }
      else { $script:npmInstalled += @($ArgumentList | Select-Object -Skip 2 | ForEach-Object { $_ -replace '^github:bats-core/', '' }); $global:LASTEXITCODE = 0 }
    }

    (Install-BatsToolchain).Status | Should -Be 'fixed'
    Should -Invoke Invoke-Npm -Times 1 -ParameterFilter { "$ArgumentList" -eq 'install -g bats-assert github:bats-core/bats-file' }
  }

  It 'installs everything on a bare machine' {
    $result = Install-BatsToolchain
    $result.Status | Should -Be 'fixed'
    $result.Detail | Should -BeLike '*BATS_LIB_PATH=C:\npm\node_modules'
    Should -Invoke Invoke-Npm -Times 1 -ParameterFilter { "$ArgumentList" -eq 'install -g bats bats-support bats-assert github:bats-core/bats-file' }
  }

  It 'fails, naming what is missing, when npm install does not take' {
    Mock Invoke-Npm {
      if ($ArgumentList[0] -eq 'root') { 'C:\npm\node_modules' } else { $global:LASTEXITCODE = 1 }
    }

    $result = Install-BatsToolchain
    $result.Status | Should -Be 'FAILED'
    $result.Detail | Should -BeLike '*exit 1*bats, bats-support, bats-assert, bats-file'
  }

  It 'fails when npm is missing' {
    Mock Get-Command -ParameterFilter { $Name -eq 'npm' } { }
    (Install-BatsToolchain).Status | Should -Be 'FAILED'
  }

  It 'fails when Git Bash is missing' {
    Mock Get-GitBash { $null }
    (Install-BatsToolchain).Status | Should -Be 'FAILED'
  }

  It 'changes nothing under -WhatIf' {
    (Install-BatsToolchain -WhatIf).Status | Should -Be 'would fix'
    Should -Invoke Invoke-Npm -Times 0 -ParameterFilter { $ArgumentList[0] -eq 'install' }
  }
}

Describe 'Get-PytestVersion' {
  It 'returns the version line' {
    Mock python3 { 'pytest 8.4.2' }
    Get-PytestVersion | Should -Be 'pytest 8.4.2'
  }

  It 'returns $null when pytest is not importable' {
    Mock python3 { 'C:\Python315\python.exe: No module named pytest' }
    Get-PytestVersion | Should -BeNullOrEmpty
  }
}

Describe 'Install-Pytest' {
  BeforeEach {
    $script:pytestInstalled = $false
    Mock Get-Python3Prefix { 'C:\Python315' }
    Mock Get-PytestVersion { if ($script:pytestInstalled) { 'pytest 8.4.2' } }
    Mock python3 { $script:pytestInstalled = $true; $global:LASTEXITCODE = 0 }
  }

  It 'is ok when pytest is importable' {
    $script:pytestInstalled = $true
    (Install-Pytest).Status | Should -Be 'ok'
    Should -Invoke python3 -Times 0
  }

  It 'installs pytest with pip --user' {
    (Install-Pytest).Status | Should -Be 'fixed'
    Should -Invoke python3 -Times 1 -ParameterFilter { "$args" -eq '-m pip install --user pytest' }
  }

  It 'fails when python3 is not a real Python' {
    Mock Get-Python3Prefix { $null }
    (Install-Pytest).Status | Should -Be 'FAILED'
  }

  It 'skips under -WhatIf when python3 is not yet fixed' {
    Mock Get-Python3Prefix { $null }
    (Install-Pytest -WhatIf).Status | Should -Be 'skipped'
  }

  It 'changes nothing under -WhatIf' {
    (Install-Pytest -WhatIf).Status | Should -Be 'would fix'
    Should -Invoke python3 -Times 0
  }
}

Describe 'Get-ToolVersion' {
  BeforeAll {
    $dir = Join-Path -Path $TestDrive -ChildPath 'bin'
    [IO.Directory]::CreateDirectory($dir) | Out-Null
    $script:pyScript = Join-Path -Path $dir -ChildPath 's3cmd'
    [IO.File]::WriteAllText($script:pyScript, "#!Invoke-FakeInterpreter`nprint('x')`n")
    $script:deadScript = Join-Path -Path $dir -ChildPath 'dead'
    [IO.File]::WriteAllText($script:deadScript, "#!C:\nowhere\python.exe`n")
  }

  It 'returns $null for a missing file' {
    Get-ToolVersion -Path (Join-Path -Path $TestDrive -ChildPath 'nope.exe') | Should -BeNullOrEmpty
  }

  It 'runs a script with the interpreter its #! line names' {
    function Invoke-FakeInterpreter { $global:LASTEXITCODE = 0; 's3cmd version 2.4.0' }
    # The script exists for real; the "interpreter" is the function above.
    Mock Test-Path { $true }

    Get-ToolVersion -Path $script:pyScript | Should -Be 's3cmd version 2.4.0'
  }

  It 'returns $null when the #! interpreter is gone (a dead pipx venv)' {
    Get-ToolVersion -Path $script:deadScript | Should -BeNullOrEmpty
  }
}

Describe 'Repair-UvTool' {
  BeforeEach {
    $script:working = @()
    Mock Get-Command -ParameterFilter { $Name -eq 'uv' } { & $script:fakeCommand 'C:\bin\uv.exe' }
    Mock uv {
      if ($args[0] -eq 'tool' -and $args[1] -eq 'dir') { 'C:\Users\u\.local\bin' }
      elseif ($args[0] -eq 'tool' -and $args[1] -eq 'install') { $script:working += $args[-1]; $global:LASTEXITCODE = 0 }
    }
    Mock Get-ToolVersion {
      $tool = [IO.Path]::GetFileNameWithoutExtension($Path)
      if ($script:working -contains $tool) { "$tool 1.0" }
    }
    Mock Get-ChildItem { }
    Mock Test-Path -ParameterFilter { $LiteralPath -like '*pipx\venvs\*' } { $true }
  }

  It 'is ok when every tool runs' {
    $script:working = @('pre-commit', 'linode-cli', 's3cmd')
    $result = Repair-UvTool
    $result.Status | Should -Be 'ok'
    $result.Detail | Should -Be 'pre-commit 1.0; linode-cli 1.0; s3cmd 1.0'
    Should -Invoke uv -Times 0 -ParameterFilter { $args[1] -eq 'install' }
  }

  It 'reinstalls a dead tool with uv and removes its pipx venv' {
    $script:working = @('linode-cli', 's3cmd')
    (Repair-UvTool).Status | Should -Be 'fixed'
    Should -Invoke uv -Times 1 -ParameterFilter { "$args" -eq 'tool install --force pre-commit' }
    Should -Invoke Remove-Item -Times 1 -ParameterFilter { $LiteralPath -like '*pipx\venvs\pre-commit' -and $Recurse }
  }

  It 'removes only the pipx shims that point into the tool''s venv' {
    $script:working = @('linode-cli', 's3cmd')
    $venv = Join-Path -Path $HOME -ChildPath 'pipx\venvs\pre-commit'
    Mock Get-ChildItem {
      [pscustomobject]@{ FullName = 'C:\b\pre-commit.exe'; LinkType = 'SymbolicLink'; Target = "$venv\Scripts\pre-commit.exe" }
      [pscustomobject]@{ FullName = 'C:\b\aider.exe'; LinkType = $null; Target = $null }
      [pscustomobject]@{ FullName = 'C:\b\python3.exe'; LinkType = 'SymbolicLink'; Target = 'C:\Python315\python.exe' }
    }

    Repair-UvTool | Out-Null
    Should -Invoke Remove-Item -Times 1 -ParameterFilter { $LiteralPath -eq 'C:\b\pre-commit.exe' }
    Should -Invoke Remove-Item -Times 0 -ParameterFilter { $LiteralPath -in 'C:\b\aider.exe', 'C:\b\python3.exe' }
  }

  It 'fails when a tool still does not run' {
    Mock uv { if ($args[1] -eq 'dir') { 'C:\Users\u\.local\bin' } else { $global:LASTEXITCODE = 2 } }
    $result = Repair-UvTool
    $result.Status | Should -Be 'FAILED'
    $result.Detail | Should -BeLike '*pre-commit (uv tool install exit 2)*'
  }

  It 'changes nothing under -WhatIf' {
    (Repair-UvTool -WhatIf).Status | Should -Be 'would fix'
    Should -Invoke uv -Times 0 -ParameterFilter { $args[1] -eq 'install' }
    Should -Invoke Remove-Item -Times 0
  }
}

Describe 'Install-Pester' {
  BeforeEach {
    $script:pester = $null
    Mock Get-Pester5 { $script:pester }
    Mock Install-Module { $script:pester = [pscustomobject]@{ Version = [version]'5.9.1' } }
  }

  It 'is ok when Pester 5 is installed' {
    $script:pester = [pscustomobject]@{ Version = [version]'5.7.1' }
    (Install-Pester).Detail | Should -Be 'Pester 5.7.1'
    Should -Invoke Install-Module -Times 0
  }

  It 'installs Pester for the current user beside the in-box one' {
    (Install-Pester).Status | Should -Be 'fixed'
    Should -Invoke Install-Module -Times 1 -ParameterFilter {
      $Name -eq 'Pester' -and $Scope -eq 'CurrentUser' -and $SkipPublisherCheck -and $MinimumVersion -eq '5.0'
    }
  }

  It 'changes nothing under -WhatIf' {
    (Install-Pester -WhatIf).Status | Should -Be 'would fix'
    Should -Invoke Install-Module -Times 0
  }
}

Describe 'Test-SameSite' {
  It 'matches the same host, ignoring www.' {
    Test-SameSite -Uri 'https://www.videolan.org/vlc/' -OtherUri 'https://videolan.org/' | Should -BeTrue
  }

  It 'rejects different hosts' {
    Test-SameSite -Uri 'https://cli.github.com/' -OtherUri 'https://git-scm.com/' | Should -BeFalse
  }

  It 'needs the same owner/repo on a code host' {
    Test-SameSite -Uri 'https://github.com/cli/cli' -OtherUri 'https://github.com/cli/cli/releases' | Should -BeTrue
    Test-SameSite -Uri 'https://github.com/cli/cli' -OtherUri 'https://github.com/jqlang/jq' | Should -BeFalse
  }

  It 'rejects an empty or relative URL' {
    Test-SameSite -Uri '' -OtherUri 'https://x.org' | Should -BeFalse
  }
}

Describe 'Resolve-ChocoEquivalent' {
  BeforeEach {
    Mock Get-WingetPackageInfo { [pscustomobject]@{ Name = 'GitHub CLI'; Moniker = 'gh'; Homepage = 'https://cli.github.com/' } }
    Mock Test-ChocoRemotePackage { $Id -eq 'gh' }
    Mock Get-ChocoPackageSite { if ($Id -eq 'gh') { 'https://cli.github.com/' } }
    $package = [pscustomobject]@{ Id = 'GitHub.cli'; Source = 'winget' }
  }

  It 'converts one exact id with the same homepage' {
    $row = Resolve-ChocoEquivalent -Package $package -LocalChoco @()
    $row.ChocoId | Should -Be 'gh'
    $row.Confidence | Should -Be 'exact id + same homepage'
    $row.Action | Should -Be 'convert'
  }

  It 'looks up only exact candidate ids from the moniker, id and name' {
    Resolve-ChocoEquivalent -Package $package -LocalChoco @() | Out-Null
    Should -Invoke Test-ChocoRemotePackage -ParameterFilter { $Id -eq 'gh' }
    Should -Invoke Test-ChocoRemotePackage -ParameterFilter { $Id -eq 'cli' }
    Should -Invoke Test-ChocoRemotePackage -ParameterFilter { $Id -eq 'github-cli' }
    Should -Invoke Test-ChocoRemotePackage -ParameterFilter { $Id -eq 'githubcli' }
  }

  It 'skips software Chocolatey already installed' {
    (Resolve-ChocoEquivalent -Package $package -LocalChoco @('gh')).Action | Should -Be 'skip: already installed by choco'
  }

  It 'keeps a name-only hit on winget' {
    Mock Get-ChocoPackageSite { 'https://example.org/' }
    $row = Resolve-ChocoEquivalent -Package $package -LocalChoco @()
    $row.Action | Should -Be 'keep on winget: low confidence'
    $row.Confidence | Should -BeLike 'exact id, name only*'
  }

  It 'keeps an ambiguous match on winget' {
    Mock Test-ChocoRemotePackage { $Id -in 'gh', 'github-cli' }
    Mock Get-ChocoPackageSite { 'https://cli.github.com/' }
    $row = Resolve-ChocoEquivalent -Package $package -LocalChoco @()
    $row.Action | Should -Be 'keep on winget: ambiguous'
    $row.ChocoId | Should -Be 'gh | github-cli'
  }

  It 'reports a package with no choco equivalent' {
    Mock Test-ChocoRemotePackage { $false }
    (Resolve-ChocoEquivalent -Package $package -LocalChoco @()).Action | Should -Be 'keep on winget: no choco equivalent'
  }

  It 'never converts winget itself' {
    $row = Resolve-ChocoEquivalent -Package ([pscustomobject]@{ Id = 'Microsoft.AppInstaller'; Source = 'winget' }) -LocalChoco @()
    $row.Action | Should -Be 'keep: this is winget itself'
    Should -Invoke Test-ChocoRemotePackage -Times 0
  }
}

Describe 'Convert-WingetPackage' {
  BeforeEach {
    $script:calls = [System.Collections.Generic.List[string]]::new()
    Mock Get-Command -ParameterFilter { $Name -eq 'winget' } { & $script:fakeCommand 'C:\winget.exe' }
    Mock Test-Choco { $true }
    Mock choco { 'firefox|1.0' }
    Mock Get-WingetManagedPackage {
      [pscustomobject]@{ Id = 'GitHub.cli'; Source = 'winget' }
      [pscustomobject]@{ Id = 'Mozilla.Firefox'; Source = 'winget' }
    }
    Mock Resolve-ChocoEquivalent {
      if ($Package.Id -eq 'GitHub.cli') {
        [pscustomobject]@{ WingetId = 'GitHub.cli'; Source = 'winget'; ChocoId = 'gh'; Confidence = 'exact id + same homepage'; Action = 'convert' }
      } else {
        [pscustomobject]@{ WingetId = 'Mozilla.Firefox'; Source = 'winget'; ChocoId = 'firefox'; Confidence = 'exact id + same homepage'; Action = 'skip: already installed by choco' }
      }
    }
    Mock winget { $script:calls.Add("winget $($args[0]) $($args[2])"); $global:LASTEXITCODE = 0 }
    Mock Install-ChocoPackage { $script:calls.Add("choco $Id"); '' }
  }

  It 'only counts the packages without -Convert' {
    $result = Convert-WingetPackage
    $result.Status | Should -Be 'skipped'
    $result.Detail | Should -BeLike '2 winget-managed packages*-ConvertWinget'
    Should -Invoke Resolve-ChocoEquivalent -Times 0
  }

  It 'asks for admin before converting anything' {
    (Convert-WingetPackage -Convert).Status | Should -Be 'needs admin'
    Should -Invoke winget -Times 0
  }

  It 'uninstalls the winget copy before the choco install, and only convertible rows' {
    Mock Test-Elevated { $true }
    $result = Convert-WingetPackage -Convert
    $result.Status | Should -Be 'fixed'
    $script:calls | Should -Be @('winget uninstall GitHub.cli', 'choco gh')
    $result.Lines | Should -Contain 'GitHub.cli -> gh [exact id + same homepage] : converted'
    $result.Lines | Should -Contain 'Mozilla.Firefox -> firefox [exact id + same homepage] : skip: already installed by choco'
  }

  It 'puts the winget package back when the choco install fails' {
    Mock Test-Elevated { $true }
    Mock Install-ChocoPackage { $script:calls.Add("choco $Id"); 'choco install gh exited 1' }
    $result = Convert-WingetPackage -Convert
    $result.Status | Should -Be 'FAILED'
    $script:calls | Should -Be @('winget uninstall GitHub.cli', 'choco gh', 'winget install GitHub.cli')
  }

  It 'lists the mapping and changes nothing under -WhatIf' {
    $result = Convert-WingetPackage -Convert -WhatIf
    $result.Status | Should -Be 'would fix'
    $result.Lines.Count | Should -Be 2
    Should -Invoke winget -Times 0
    Should -Invoke Install-ChocoPackage -Times 0
  }

  It 'keeps every winget package that shares a choco id with another' {
    Mock Test-Elevated { $true }
    Mock Get-WingetManagedPackage {
      [pscustomobject]@{ Id = 'Microsoft.WindowsAppRuntime.1.0'; Source = 'winget' }
      [pscustomobject]@{ Id = 'Microsoft.WindowsAppRuntime.1.2'; Source = 'winget' }
    }
    Mock Resolve-ChocoEquivalent {
      [pscustomobject]@{ WingetId = $Package.Id; Source = 'winget'; ChocoId = 'windows-app-sdk'; Confidence = 'exact id + same homepage'; Action = 'convert' }
    }

    $result = Convert-WingetPackage -Convert
    $result.Status | Should -Be 'ok'
    $result.Lines | Should -Contain 'Microsoft.WindowsAppRuntime.1.0 -> windows-app-sdk [ambiguous] : keep on winget: 2 winget packages map to windows-app-sdk'
    Should -Invoke winget -Times 0
    Should -Invoke Install-ChocoPackage -Times 0
  }
}

Describe 'Install-DockerDesktop' {
  BeforeEach {
    $script:engine = $null
    $script:installed = $false
    Mock Get-DockerServerVersion { $script:engine }
    Mock Test-Choco { $true }
    Mock Test-ChocoPackage -ParameterFilter { $Id -eq 'docker-desktop' } { $script:installed }
    Mock Test-Path -ParameterFilter { $LiteralPath -like '*Docker Desktop.exe' } { $script:installed }
    Mock Install-ChocoPackage { $script:installed = $true; '' }
    Mock Get-Process { }
    $script:clock = [datetime]'2026-01-01'
    Mock Get-Date { $script:clock = $script:clock.AddMinutes(1); $script:clock }
  }

  It 'is ok when the engine answers' {
    $script:engine = '29.0.0'
    (Install-DockerDesktop).Detail | Should -Be 'engine 29.0.0'
    Should -Invoke Install-ChocoPackage -Times 0
  }

  It 'asks for admin to install Docker Desktop' {
    (Install-DockerDesktop).Status | Should -Be 'needs admin'
  }

  It 'installs with choco when elevated, leaving the start to the unelevated run' {
    Mock Test-Elevated { $true }
    $result = Install-DockerDesktop
    $result.Status | Should -Be 'fixed'
    Should -Invoke Install-ChocoPackage -Times 1 -ParameterFilter { $Id -eq 'docker-desktop' }
    Should -Invoke Start-Process -Times 0
  }

  It 'reports a requested reboot as pending' {
    Mock Test-Elevated { $true }
    Mock Install-ChocoPackage { 'reboot' }
    (Install-DockerDesktop).Status | Should -Be 'PENDING'
  }

  It 'reports a missing WSL as pending after installing it' {
    Mock Test-Wsl { $false }
    Mock Test-Elevated { $true }
    Mock wsl.exe { $global:LASTEXITCODE = 0 }
    $result = Install-DockerDesktop
    $result.Status | Should -Be 'PENDING'
    $result.Detail | Should -BeLike '*reboot*'
  }

  It 'starts Docker Desktop and waits for the engine' {
    $script:installed = $true
    Mock Start-Process { $script:engine = '29.0.0' }
    $result = Install-DockerDesktop
    $result.Status | Should -Be 'fixed'
    Should -Invoke Start-Process -Times 1 -ParameterFilter { $FilePath -like '*Docker Desktop.exe' }
  }

  It 'gives up after the deadline and reports the first-launch steps as pending' {
    $script:installed = $true
    $result = Install-DockerDesktop
    $result.Status | Should -Be 'PENDING'
    $result.Detail | Should -BeLike '*Subscription Service Agreement*'
  }

  It 'changes nothing under -WhatIf' {
    (Install-DockerDesktop -WhatIf).Status | Should -Be 'would fix'
    Should -Invoke Install-ChocoPackage -Times 0
    Should -Invoke Start-Process -Times 0
  }
}
