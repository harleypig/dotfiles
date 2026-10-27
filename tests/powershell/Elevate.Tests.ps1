#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0' }

# Tests for powershell/bin/Elevate.ps1. Start-Process is mocked, so no test
# reaches UAC. Where the arguments must survive the trip, the mock runs the
# elevated command line in a plain, unelevated pwsh instead, and a helper
# script on the far side records what it received.

[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
  'PSUseDeclaredVarsMoreThanAssignments', '',
  Justification = 'Pester shares BeforeAll/BeforeEach variables with It blocks, which PSScriptAnalyzer cannot see.')]
param ()

Describe 'Elevate.ps1' {
  BeforeAll {
    $script:elevate = [IO.Path]::GetFullPath((Join-Path -Path $PSScriptRoot -ChildPath '../../powershell/bin/Elevate.ps1'))

    function ConvertFrom-EncodedArgument {
      param ([string[]]$ArgumentList)
      $encoded = $ArgumentList[[array]::IndexOf($ArgumentList, '-EncodedCommand') + 1]
      [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($encoded))
    }

    # Writes its arguments and working directory to received.json, then
    # exits with the code in $env:ELEVATE_TEST_EXIT.
    $script:helper = Join-Path -Path $TestDrive -ChildPath "it's here.ps1"
    [IO.File]::WriteAllText($script:helper, @'
@{ Args = @($args | ForEach-Object { [string]$_ }); Location = (Get-Location).Path } |
  ConvertTo-Json | Set-Content -LiteralPath (Join-Path -Path $PSScriptRoot -ChildPath 'received.json')
exit [int]$env:ELEVATE_TEST_EXIT
'@)
    $script:received = Join-Path -Path $TestDrive -ChildPath 'received.json'
  }

  BeforeEach {
    Remove-Item -LiteralPath $script:received -ErrorAction SilentlyContinue
    $env:ELEVATE_TEST_EXIT = '0'

    Mock Start-Process {
      & $FilePath @ArgumentList
      [pscustomobject]@{ ExitCode = $LASTEXITCODE }
    }
  }

  AfterAll {
    Remove-Item -Path Env:ELEVATE_TEST_EXIT -ErrorAction SilentlyContinue
  }

  It 'starts one elevated pwsh, waits for it, and runs an encoded command' {
    Mock Start-Process { [pscustomobject]@{ ExitCode = 0 } }

    & $script:elevate choco install terraform -y

    Should -Invoke Start-Process -Times 1 -Exactly -ParameterFilter {
      $Verb -eq 'RunAs' -and $Wait -and $PassThru -and
      $FilePath -eq (Get-Process -Id $PID).Path -and
      $ArgumentList -contains '-EncodedCommand' -and $ArgumentList -contains '-NoProfile'
    }
  }

  It 'quotes each argument as a literal and leaves parameter names bare' {
    Mock Start-Process { [pscustomobject]@{ ExitCode = 0 } }
    $expected = [regex]::Escape("& 'Set-ExecutionPolicy' 'RemoteSigned' -Scope: 'LocalMachine' '`$x' 'it''s'")

    & $script:elevate Set-ExecutionPolicy RemoteSigned -Scope: LocalMachine '$x' "it's"

    Should -Invoke Start-Process -Times 1 -Exactly -ParameterFilter {
      (ConvertFrom-EncodedArgument -ArgumentList $ArgumentList) -match $expected
    }
  }

  It 'passes every argument through unchanged, spaces, quotes and dashes included' {
    & $script:elevate $script:helper 'a b' "it's" '$env:PATH' -y --version 1.2 -Verbose -h

    $got = Get-Content -LiteralPath $script:received -Raw | ConvertFrom-Json
    $got.Args | Should -Be @('a b', "it's", '$env:PATH', '-y', '--version', '1.2', '-Verbose', '-h')
  }

  It 'binds a parameter name for a cmdlet' {
    $target = Join-Path -Path $TestDrive -ChildPath 'value.txt'

    & $script:elevate Set-Content -LiteralPath $target -Value 'x y'

    $LASTEXITCODE | Should -Be 0
    Get-Content -LiteralPath $target | Should -Be 'x y'
  }

  It 'runs the command in the current directory' {
    $dir = Join-Path -Path $TestDrive -ChildPath "o'dir"
    [IO.Directory]::CreateDirectory($dir) | Out-Null

    Push-Location -LiteralPath $dir
    try {
      & $script:elevate $script:helper
    } finally {
      Pop-Location
    }

    (Get-Content -LiteralPath $script:received -Raw | ConvertFrom-Json).Location | Should -Be $dir
  }

  It 'returns a native command''s own exit code' {
    $env:ELEVATE_TEST_EXIT = '7'

    & $script:elevate $script:helper

    $LASTEXITCODE | Should -Be 7
  }

  It 'returns 1 when a cmdlet fails' {
    & $script:elevate Get-Item -LiteralPath (Join-Path -Path $TestDrive -ChildPath 'missing') 2>$null

    $LASTEXITCODE | Should -Be 1
  }

  It 'returns 0 when a cmdlet succeeds' {
    & $script:elevate Get-Item -LiteralPath $TestDrive

    $LASTEXITCODE | Should -Be 0
  }

  It 'fails when UAC is declined' {
    Mock Start-Process { throw 'The operation was canceled by the user.' }

    & $script:elevate choco install terraform 2>$null

    $LASTEXITCODE | Should -Be 1
  }

  It 'fails when Start-Process rejects -Verb, as off Windows' {
    Mock Start-Process {
      throw [Management.Automation.ParameterBindingException]::new("The parameter '-Verb' is not supported")
    }

    & $script:elevate choco install terraform 2>$null

    $LASTEXITCODE | Should -Be 1
  }

  It 'shows this script''s help for -h, without elevating' {
    $help = & $script:elevate -h | Out-String

    $help | Should -Match 'Runs a command with administrative privileges'
    Should -Invoke Start-Process -Times 0
  }

  It 'fails without a command, without elevating' {
    & $script:elevate 2>$null

    $LASTEXITCODE | Should -Be 1
    Should -Invoke Start-Process -Times 0
  }
}
