# Declare and initialize variables, making some of them dual purpose
$scriptPath = $MyInvocation.MyCommand.Path

Set-Variable -Name DOTFILES `
  -Scope Global `
  -Option Constant `
  -Value (Split-Path -Parent (Resolve-Path -Path $scriptPath))

$env:DOTFILES = $DOTFILES

Set-Variable -Name PROJECTS_DIR `
  -Scope Global `
  -Option Constant `
  -Value (Split-Path -Parent $DOTFILES)

$env:PROJECTS_DIR = $PROJECTS_DIR

#-----------------------------------------------------------------------------

function Import-Files {
    # Define the directories to load files from
    $loadDirs = @(
        Join-Path $DOTFILES "powershell/startup"
        Join-Path $HOME ".psshell_startup_hooks.d"
    )

    # Iterate over each directory separately to ensure files are loaded in
    # the order of the directories.
    foreach ($loadDir in $loadDirs) {
        if (Test-Path -Path $loadDir) {
            $loadFiles = Get-ChildItem -Path $loadDir -File `
                         | Where-Object { $_.Name -and $_.Extension -eq '.ps1' } `
                         | Sort-Object Name

            foreach ($file in $loadFiles) {
                if (Test-Path -Path $file.FullName -PathType Leaf) {
                  . $file.FullName
                }
            }
        }
    }
}

# Call the function to load the files
Import-Files

# We want this to be after all the other files are loaded because these paths
# take precedence.
# XXX: Move python path to dedicated python setup file
# Built with the platform's own separators so the same file works under
# Windows and Linux pwsh, then deduplicated keeping the first occurrence so
# these prepended entries win. Windows paths are case-insensitive, so dedup
# there ignores case.
$pathEntries = @(
    [IO.Path]::Combine($DOTFILES, 'powershell', 'bin')
    [IO.Path]::Combine($HOME, '.local', 'bin')
    [IO.Path]::Combine($HOME, 'AppData', 'Roaming', 'Python', 'Python312', 'Scripts')
) + ($env:PATH -split [IO.Path]::PathSeparator)

$pathComparer = if ([IO.Path]::DirectorySeparatorChar -eq '\') {
    [StringComparer]::OrdinalIgnoreCase
} else {
    [StringComparer]::Ordinal
}

$pathSeen = [Collections.Generic.HashSet[string]]::new($pathComparer)

$env:PATH = ($pathEntries | Where-Object { $_ -and $pathSeen.Add($_) }) `
            -join [IO.Path]::PathSeparator

# Remove work or scratch variables and functions from the environment
Remove-Variable -Name scriptPath, pathEntries, pathComparer, pathSeen
Remove-Item -Path Function:Import-Files

#-----------------------------------------------------------------------------
function s3cmd {
    $venvPath = "$HOME\pipx\venvs\s3cmd\Scripts"
    $activateScript = Join-Path -Path $venvPath -ChildPath "Activate.ps1"

    try {
        # Activate the virtual environment
        Invoke-Expression "& $activateScript"

        # Run s3cmd with all provided arguments
        $arguments = "$HOME\.local\bin\s3cmd " + ($args -join ' ')
        Start-Process -FilePath "python" -ArgumentList $arguments -NoNewWindow -Wait
    } finally {
        # Deactivate the virtual environment to clean up
        if (Test-Path function:deactivate) {
            Invoke-Expression "& deactivate"
        }
    }
}

#-----------------------------------------------------------------------------
# TBD:

# Depends on PSReadline
# export INPUTRC="$XDG_CONFIG_HOME/readline/inputrc"

# export EDITOR=code
