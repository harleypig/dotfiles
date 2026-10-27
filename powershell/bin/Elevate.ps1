#Requires -Version 7

<#
.SYNOPSIS
  Runs a command with administrative privileges, waits for it, and returns
  its exit code.

.DESCRIPTION
  Starts an elevated copy of the pwsh running this script, through UAC
  (Start-Process -Verb RunAs), in the current directory, and runs the
  command there. This script waits for it to finish and exits with its exit
  code: a native command's own code, otherwise 0 on success and 1 on
  failure. A declined UAC prompt is an error, and exits 1.

  The command and its arguments arrive in the elevated shell exactly as they
  were passed here: each argument is quoted as a literal, except one shaped
  like a parameter name (-Scope, --version), which stays bare so a cmdlet
  binds it by name.

  The command's output shows only in the elevated window. When the command
  succeeds the window closes as it ends. When it fails (a non-zero exit, a
  cmdlet error) the window stays open, its output readable, until Enter is
  pressed, and the exit code comes back once it closes. Where the current
  directory does not exist for the elevated session (a mapped network
  drive), the command does not run, the window waits the same way, and the
  exit code is 1.

  Elevate -h shows this help.

.EXAMPLE
  Elevate choco install terraform -y
  Installs Terraform with Chocolatey, elevated, and returns choco's exit
  code.

.EXAMPLE
  Elevate Set-ExecutionPolicy RemoteSigned -Scope LocalMachine
  Runs a cmdlet elevated; -Scope binds by name.
#>

# No param block: an advanced script would take -Verbose, -h and the like
# for itself instead of passing them on to the command.

if ($args.Count -eq 1 -and $args[0] -eq '-h') {
  Get-Help -Name $PSCommandPath -Full
  return
}

if ($args.Count -eq 0) {
  Write-Error 'No command given. Elevate -h shows the help.'
  exit 1
}

$words = for ($i = 0; $i -lt $args.Count; $i++) {
  $word = [string]$args[$i]

  if ($i -gt 0 -and $word -match '^--?[A-Za-z][\w-]*:?$') {
    $word
  } else {
    "'" + ($word -replace "'", "''") + "'"
  }
}

$location = "'" + ((Get-Location).Path -replace "'", "''") + "'"

# pwsh -Command reduces any other native exit code to 1, so pass it on
# explicitly. The elevated window is the only place the output shows, so on
# a failure it waits for Enter before closing; the catch keeps a terminating
# error, an unreachable directory included, from closing it first.
$script = @"
`$code = 1
try {
  Set-Location -LiteralPath $location -ErrorAction Stop
  & $($words -join ' ')
  `$ok = `$?
  `$code = if (`$null -ne `$LASTEXITCODE) { `$LASTEXITCODE } elseif (`$ok) { 0 } else { 1 }
} catch {
  Write-Error -ErrorRecord `$_
}
if (`$code -ne 0) {
  Read-Host -Prompt "Elevate: the command failed (exit `$code); press Enter to close this window" | Out-Null
}
exit `$code
"@

# -EncodedCommand sidesteps quoting the script for the command line.
$encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($script))

$start = @{
  FilePath     = (Get-Process -Id $PID).Path
  ArgumentList = '-NoProfile', '-ExecutionPolicy', 'Bypass', '-EncodedCommand', $encoded
  Verb         = 'RunAs'
  Wait         = $true
  PassThru     = $true
  ErrorAction  = 'Stop'
}

# A refused UAC prompt, or an edition with no -Verb, must not fall through
# to the exit below with no process and report success.
try {
  $process = Start-Process @start
} catch {
  Write-Error -ErrorRecord $_
  exit 1
}

exit $process.ExitCode
