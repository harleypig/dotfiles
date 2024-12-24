# Declare and initialize variables
$scriptPath = $MyInvocation.MyCommand.Path
#$env:DOTFILES = Split-Path -Parent (Resolve-Path -Path $scriptPath)
$DOTFILES = Split-Path -Parent (Resolve-Path -Path $scriptPath)
#$env:PROJECTS_DIR = Split-Path -Parent $env:DOTFILES
$PROJECTS_DIR = Split-Path -Parent $DOTFILES

# Update the PATH environment variable
#$env:PATH = "$env:DOTFILES\bin;$HOME\.local\bin;$env:PATH"
$PATH = "$DOTFILES\bin;$HOME\.local\bin;$PATH"

# Private dotfiles variable (local to this script)
#$private_dotfiles = Join-Path $env:PROJECTS_DIR "private_dotfiles"
$private_dotfiles = Join-Path $PROJECTS_DIR "private_dotfiles"

# Check if the OpenAI API key file exists and is readable
$apiKeyFile = Join-Path $private_dotfiles "api-key.openai"
if (Test-Path -Path $apiKeyFile) {
    $env:OPENAI_API_KEY = Get-Content -Path $apiKeyFile -Raw
    $OPENAI_API_KEY = Get-Content -Path $apiKeyFile -Raw

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

# A I ! Convert this bash code to powershell, please.
# if command -v aider &> /dev/null; then
#   export AIDER_DARK_MODE=true
#   export AIDER_EDITOR=code
#   export AIDER_GITIGNORE=false
#   export AIDER_MAP_TOKENS=2048
#   export AIDER_VIM=true
#   export AIDER_WATCH_FILES=true
# fi
