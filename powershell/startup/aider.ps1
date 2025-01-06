# OPENAI_API_KEY is loaded in 000-loadtokens

# if command -v aider &> /dev/null; then

$private_dotfiles = Join-Path $PROJECTS_DIR "private_dotfiles"

# Check if the OpenAI API key file exists and is readable
$apiKeyFile = Join-Path $private_dotfiles "api-key.openai"

# Modify this test to check if aider, an application, is available and if OPENAI_API_KEY (not $env:OPENAI_API_KEY) is set, then set the variables using set-variable as global AI!
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
