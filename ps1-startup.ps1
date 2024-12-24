# Declare and initialize variables, make some of them dual purpose
$scriptPath = $MyInvocation.MyCommand.Path

$env:DOTFILES = Split-Path -Parent (Resolve-Path -Path $scriptPath)
$DOTFILES = $env:DOTFILES

$env:PROJECTS_DIR = Split-Path -Parent $env:DOTFILES
$PROJECTS_DIR = $env:PROJECTS_DIR

# Update the PATH environment variable
$env:PATH = "$env:DOTFILES\bin;$HOME\.local\bin;$env:PATH"
# Convert the following bash alias to a powershell alias AI!
alias dumppath='echo -e ${PATH//:/\\n}'

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
        $env:AIDER_VIM = $true
        $env:AIDER_WATCH_FILES = $true
    }
}

Remove-Variable -Name scriptPath, private_dotfiles
