# OPENAI_API_KEY is loaded in 000-loadtokens

# The first test should test if OPENAI_API_KEY is set AI!
if (Test-Path -Path $apiKeyFile) {
    if (Get-Command aider -ErrorAction SilentlyContinue) {
        Set-Variable -Name AIDER_DARK_MODE -Scope Global -Value $true
        Set-Variable -Name AIDER_EDITOR -Scope Global -Value "code"
        Set-Variable -Name AIDER_GITIGNORE -Scope Global -Value $false
        Set-Variable -Name AIDER_MAP_TOKENS -Scope Global -Value 2048
        Set-Variable -Name AIDER_VIM -Scope Global -Value $true
        Set-Variable -Name AIDER_WATCH_FILES -Scope Global -Value $true
    }
}
