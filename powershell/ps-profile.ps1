<#
.SYNOPSIS
    This script checks if the PowerShell profile file ($PROFILE) exists.
    If the profile exists, the script exits with a message and suggests what to add if necessary.
    If the profile does not exist, it creates a new profile file that sources
    the `ps1-startup.ps1` file located in the directory where the script is run.

.DESCRIPTION
    The script is designed to simplify the setup of a PowerShell profile that includes
    custom startup configurations. The `ps1-startup.ps1` file in the current directory
    will be sourced in the profile file.

    HOW TO RUN
    Save this script as `setup-profile.ps1` and run it in PowerShell:
        ./setup-profile.ps1

    Ensure you have the necessary permissions to create files in the profile's directory.

.NOTES
    - Requires PowerShell 5.1 or higher.
    - On Linux/macOS, make the script executable using `chmod +x`.
#>

# Check for help parameters
param (
    [switch]$h,
    [switch]$help
)

if ($h -or $help) {
    Get-Help -Name $MyInvocation.MyCommand.Path
    exit 0
}

# Get the current directory
$currentDir = Get-Location

# Calculate the content to be added to the profile
$sourcePath = Join-Path $currentDir "ps1-startup.ps1"
$profileContent = ". $sourcePath"

# Check if $PROFILE exists
if (Test-Path $PROFILE) {
    $existingProfileContent = Get-Content -Path $PROFILE
    if ($existingProfileContent -notcontains $profileContent) {
        Write-Host @"

Profile already exists at: $PROFILE
To include your startup script, add the following line to your profile:
$profileContent

"@ -ForegroundColor Green
   } else {
        Write-Host @"

Profile already exists at: $PROFILE
and already includes the necessary content.

"@ -ForegroundColor Green

    }
    exit 0
}

# Create a new profile file that sources ps1-startup.ps1
try {
    # Ensure the profile directory exists
    $profileDir = Split-Path -Path $PROFILE
    if (-not (Test-Path $profileDir)) {
        New-Item -ItemType Directory -Path $profileDir -Force
    }

    # Write the content to the profile file
    Set-Content -Path $PROFILE -Value $profileContent -Encoding UTF8

    Write-Output "Profile created at: $PROFILE"
    Write-Output "The file sources: $sourcePath"    
} catch {
    Write-Error "Failed to create the profile file: $_"
    exit 1
}
