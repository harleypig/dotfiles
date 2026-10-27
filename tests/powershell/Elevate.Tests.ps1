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
    $script:window = Join-Path -Path $TestDrive -ChildPath 'window.txt'

    function Get-WindowText {
      Get-Content -LiteralPath $script:window -Raw
    }
  }

  BeforeEach {
    Remove-Item -LiteralPath $script:received -ErrorAction SilentlyContinue
    $env:ELEVATE_TEST_EXIT = '0'

    # The piped line answers the close wait on a failure, and the window's
    # output, prompt included, goes to window.txt for the tests to read.
    Remove-Item -LiteralPath $script:window -ErrorAction SilentlyContinue
    Mock Start-Process {
      $output = '' | & $FilePath @ArgumentList 2>&1 | Out-String
      $code = $LASTEXITCODE
      [IO.File]::WriteAllText((Join-Path -Path $TestDrive -ChildPath 'window.txt'), $output)
      [pscustomobject]@{ ExitCode = $code }
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

  It 'lets the window close on its own when the command succeeds' {
    & $script:elevate $script:helper

    $LASTEXITCODE | Should -Be 0
    (Get-WindowText) | Should -Not -Match 'press Enter'
  }

  It 'keeps the window open on a non-zero exit, until Enter, then returns the code' {
    $env:ELEVATE_TEST_EXIT = '7'

    & $script:elevate $script:helper

    $LASTEXITCODE | Should -Be 7
    (Get-WindowText) | Should -Match 'failed \(exit 7\); press Enter to close this window'
  }

  It 'keeps the window open, with the error readable, when a cmdlet fails' {
    & $script:elevate Get-Item -LiteralPath (Join-Path -Path $TestDrive -ChildPath 'missing') 2>$null

    $LASTEXITCODE | Should -Be 1
    (Get-WindowText) | Should -Match 'Cannot find path'
    (Get-WindowText) | Should -Match 'failed \(exit 1\); press Enter'
  }

  It 'keeps the window open when the elevated session cannot reach the directory' {
    $dir = Join-Path -Path $TestDrive -ChildPath 'gone'
    [IO.Directory]::CreateDirectory($dir) | Out-Null

    Push-Location -LiteralPath $dir
    try {
      [IO.Directory]::Delete($dir)
      & $script:elevate $script:helper
    } finally {
      Pop-Location
    }

    $LASTEXITCODE | Should -Be 1
    Test-Path -LiteralPath $script:received | Should -BeFalse
    (Get-WindowText) | Should -Match 'failed \(exit 1\); press Enter'
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
