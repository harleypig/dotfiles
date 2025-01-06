<#
.SYNOPSIS
    Elevates a command to run with administrative privileges.

.DESCRIPTION
    This script allows you to run a specified command with elevated privileges
    using PowerShell's RunAs verb. It accepts an arbitrary number of parameters
    as part of the command to be executed.

.PARAMETER Command
    The command and its parameters to be executed with elevated privileges.

.EXAMPLE
    Elevate choco install terraform
    This example runs the Chocolatey install command for Terraform with elevated
    privileges.
#>

param (
  [Parameter(Mandatory=$false, HelpMessage="Display help information.")]
  [switch]$h,

  [Parameter(Mandatory=$true, Position=0, ValueFromRemainingArguments=$true,
             HelpMessage="The command and its parameters to be executed with
             elevated privileges.")]
  [string[]]$Command
)

if ($h) {
  Get-Help -Full
  return
}

$commandString = $Command -join ' '
Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -Command `$commandString"
