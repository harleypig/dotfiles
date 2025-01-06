# Declare and initialize variables, making some of them dual purpose
$scriptPath = $MyInvocation.MyCommand.Path

$env:DOTFILES = Split-Path -Parent (Resolve-Path -Path $scriptPath)
$DOTFILES = $env:DOTFILES

$env:PROJECTS_DIR = Split-Path -Parent $env:DOTFILES
$PROJECTS_DIR = $env:PROJECTS_DIR

#-----------------------------------------------------------------------------
function Import-Files {
    # Define the directories to load files from
    $loadDirs = @(
        Join-Path $env:DOTFILES "powershell/startup"
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
                  # Add a message stating which files are being sourced AI!
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
$env:PATH = "$env:DOTFILES\powershell\bin;" `
            + "$HOME\.local\bin;" `
            + "$env:PATH"

# TBD: move to `000-loadtokens` in psshell-startup
# Private dotfiles variable, local to this script
$private_dotfiles = Join-Path $env:PROJECTS_DIR "private_dotfiles"

# Check if the OpenAI API key file exists and is readable
$apiKeyFile = Join-Path $private_dotfiles "api-key.openai"
if (Test-Path -Path $apiKeyFile) {
    $env:OPENAI_API_KEY = (Get-Content -Path $apiKeyFile -Raw).TrimEnd()

    # Check if the 'aider' command is available
    if (Get-Command aider -ErrorAction SilentlyContinue) {
        $env:AIDER_DARK_MODE = $true
        $env:AIDER_EDITOR = "code"
        $env:AIDER_GITIGNORE = $false
        $env:AIDER_MAP_TOKENS = 2048
        $env:AIDER_VIM = $true
        $env:AIDER_WATCH_FILES = $true
    }
}

# Remove work or scratch variables and functions from the environment
Remove-Variable -Name scriptPath, private_dotfiles
Remove-Item -Path Function:Import-Files

#-----------------------------------------------------------------------------
# TBD:

# Depends on PSReadline
# export INPUTRC="$XDG_CONFIG_HOME/readline/inputrc"

# export EDITOR=code
