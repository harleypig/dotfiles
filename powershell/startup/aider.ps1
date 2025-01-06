# OPENAI_API_KEY is loaded in 000-loadtokens

# if command -v aider &> /dev/null; then

$private_dotfiles = Join-Path $PROJECTS_DIR "private_dotfiles"

# Check if the OpenAI API key file exists and is readable
$apiKeyFile = Join-Path $private_dotfiles "api-key.openai"

if (Test-Path -Path $apiKeyFile) {
    Set-Variable -Name OPENAI_API_KEY `
      -Scope Global `
      -Option Constant `
      -Value ((Get-Content -Path $apiKeyFile -Raw).TrimEnd())

    if (Get-Command aider -ErrorAction SilentlyContinue) {
        Set-Variable -Name AIDER_DARK_MODE -Scope Global -Value $true
        Set-Variable -Name AIDER_EDITOR -Scope Global -Value "code"
        Set-Variable -Name AIDER_GITIGNORE -Scope Global -Value $false
        Set-Variable -Name AIDER_MAP_TOKENS -Scope Global -Value 2048
        Set-Variable -Name AIDER_VIM -Scope Global -Value $true
        Set-Variable -Name AIDER_WATCH_FILES -Scope Global -Value $true
    }
}
