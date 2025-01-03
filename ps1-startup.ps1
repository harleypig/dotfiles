# Declare and initialize variables, make some of them dual purpose
$scriptPath = $MyInvocation.MyCommand.Path

$env:DOTFILES = Split-Path -Parent (Resolve-Path -Path $scriptPath)
$DOTFILES = $env:DOTFILES

$env:PROJECTS_DIR = Split-Path -Parent $env:DOTFILES
$PROJECTS_DIR = $env:PROJECTS_DIR

#-----------------------------------------------------------------------------
function Load-Files {
    # Define the directories to load files from
    $loadDirs = @(
        Join-Path $env:DOTFILES "powershell/psshell-startup"
        Join-Path $HOME ".psshell_startup.d"
    )

    # Please fix this comment to be more readable, AI!
    # Iterate over each directory rather than all files at once because we want to load these files in the order of the directories.
    foreach ($loadDir in $loadDirs) {
        if (Test-Path -Path $loadDir) {
            # Get all files in the directory, excluding those with '_inactive' in their names
            $loadFiles = Get-ChildItem -Path $loadDir -File | Where-Object { $_.Name -notmatch '_inactive' } | Sort-Object Name

            # Source each file
            foreach ($file in $loadFiles) {
                if (Test-Path -Path $file.FullName -PathType Leaf) {
                    # Execute the file
                    . $file.FullName
                }
            }
        }
    }
}

# Call the function to load the files
Load-Files

# Update the PATH environment variable
$env:PATH = "$env:DOTFILES\powershell\bin;$HOME\.local\bin;$env:PATH"
function dumppath { $env:PATH -split ';' | ForEach-Object { Write-Output $_ } }

# Private dotfiles variable (local to this script)
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
        $env:AIDER_SHOW_RELEASE_NOTES = $true
        $env:AIDER_VIM = $true
        $env:AIDER_WATCH_FILES = $true
    }
}

Remove-Variable -Name scriptPath, private_dotfiles

# Depends on PSReadline
# export INPUTRC="$XDG_CONFIG_HOME/readline/inputrc"

# export EDITOR=code
