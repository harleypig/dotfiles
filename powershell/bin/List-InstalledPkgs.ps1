<#
.SYNOPSIS
    Lists installed PowerShell packages and outputs to the screen and a file.

.DESCRIPTION
    This script lists the names of installed PowerShell packages.
    If the `-Full` switch is provided, it includes version information. Outputs results to the console and writes them to the specified file (default: `ps-packages.txt`).

.PARAMETER Full
    Include version information for each package.

.PARAMETER File
    Specify the output file. Defaults to `./ps-packages.txt`.

.PARAMETER Quiet
    Suppress output to the screen. Only writes to the file.

.EXAMPLE
    ./Dump-PSPackages.ps1
    Outputs the names of all installed packages.

.EXAMPLE
    ./Dump-PSPackages.ps1 -Full
    Outputs the names and versions of all installed packages.

.EXAMPLE
    ./Dump-PSPackages.ps1 -File "C:\Temp\packages.txt"
    Outputs the names of all installed packages to the specified file.

.EXAMPLE
    ./Dump-PSPackages.ps1 -Quiet
    Outputs the names of all installed packages to the file without screen output. 
#>

param (
  [switch]$Full,
  [string]$File = "./ps-packages.txt",
  [switch]$Quiet
)

# Check if the file path is writable
try {
  # Resolve the full path of the file
  $resolvedFile = (Resolve-Path -Path $File -ErrorAction SilentlyContinue).Path
  if (-not $resolvedFile) {
    $resolvedFile = Join-Path -Path (Get-Location).Path -ChildPath $File
  }

  # Extract the directory from the resolved file path
  $fileDirectory = [System.IO.Path]::GetDirectoryName($resolvedFile)

  # Validate directory
  if (-not (Test-Path -Path $fileDirectory)) {
    throw "The directory '$fileDirectory' does not exist."
  }
  if (-not (Test-Path -Path $fileDirectory -PathType Container)) {
    throw "The specified path '$fileDirectory' is not a valid directory."
  }
  if (-not (Get-Acl -Path $fileDirectory).Access | Where-Object { $_.FileSystemRights -match 'Write' }) {
    throw "The directory '$fileDirectory' is not writable."
  }

  # Update the $File variable to the resolved full path
  $File = $resolvedFile
} catch {
  Write-Error "Error: Unable to write to the specified file path '$File'. $_"
  exit 1
}

# Fetch installed modules
$installedModules = Get-InstalledModule

# Determine the output format based on the -Full switch
$filterString = if ($Full) {
  "{0} -Version {1}"
} else {
  "{0}"
}

# Generate the output
$output = $installedModules | ForEach-Object {
  $filterString -f $_.Name, $_.Version
}

# Output to the screen unless Quiet is specified
if (-not $Quiet) {
  $output | ForEach-Object { Write-Output $_ }
}

# Save to file
$output | Set-Content -Path $File

Write-Host "Package list saved to $File"
