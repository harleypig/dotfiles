# Declare and initialize variables
$scriptPath = $MyInvocation.MyCommand.Path
$DOTFILES = Split-Path -Parent (Resolve-Path -Path $scriptPath)
$PROJECTS_DIR = Split-Path -Parent $DOTFILES

# Update the PATH environment variable
$PATH = "$DOTFILES\bin;$HOME\.local\bin;$PATH"

# Private dotfiles variable (local to this script)
$private_dotfiles = Join-Path $PROJECTS_DIR "private_dotfiles"

# Check if the OpenAI API key file exists and is readable
$apiKeyFile = Join-Path $private_dotfiles "api-key.openai"
if (Test-Path -Path $apiKeyFile) {
    $OPENAI_API_KEY = (Get-Content -Path $apiKeyFile -Raw).TrimEnd()

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
