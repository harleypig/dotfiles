# Declare and initialize variables, making some of them dual purpose
$scriptPath = $MyInvocation.MyCommand.Path

Set-Variable -Name DOTFILES `
  -Scope Global `
  -Option Constant `
  -Value (Split-Path -Parent (Resolve-Path -Path $scriptPath))

Set-Variable -Name PROJECTS_DIR `
  -Scope Global `
  -Option Constant `
  -Value (Split-Path -Parent $DOTFILES)

#-----------------------------------------------------------------------------

function Import-Files {
    # Define the directories to load files from
    $loadDirs = @(
        Join-Path $DOTFILES "powershell/startup"
        Join-Path $HOME ".psshell_startup.d"
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
$env:PATH = "$DOTFILES\powershell\bin;" `
            + "$HOME\.local\bin;" `
            + "$HOME\AppData\Roaming\Python\Python312\Scripts;" `
            + "$env:PATH"

# Remove work or scratch variables and functions from the environment
Remove-Variable -Name scriptPath
Remove-Item -Path Function:Import-Files

#-----------------------------------------------------------------------------
function s3cmd {
    $venvPath = "$HOME\pipx\venvs\s3cmd\Scripts"
    $activateScript = Join-Path -Path $venvPath -ChildPath "Activate.ps1"

    try {
        # Activate the virtual environment
        Invoke-Expression "& $activateScript"

        # Run s3cmd with all provided arguments
        Start-Process -FilePath "python" -ArgumentList "$HOME\.local\bin\s3cmd", @args -NoNewWindow -Wait
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
