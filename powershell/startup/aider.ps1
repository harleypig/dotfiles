# OPENAI_API_KEY is loaded in 000-loadtokens

if (Get-Command aider -ErrorAction SilentlyContinue) {
    #Set-Variable -Name AIDER_
    $env:AIDER_DARK_MODE = "true"
    $env:AIDER_EDITOR = "code --wait"
    $env:AIDER_GITIGNORE = "false"
    $env:AIDER_LINE_ENDINGS='lf'
    $env:AIDER_MAP_TOKENS = 2048
    $env:AIDER_MAX_CHAT_HISTORY_TOKENS=2048
    $env:AIDER_VIM = "true"
    $env:AIDER_WATCH_FILES = "true"
}