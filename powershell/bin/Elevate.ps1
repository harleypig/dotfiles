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
    .\Elevate.ps1 -Command "choco", "install", "terraform"
    This example runs the Chocolatey install command for Terraform with elevated
    privileges.

.NOTES
    Author: Your Name
    Date: 2025-01-05
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
