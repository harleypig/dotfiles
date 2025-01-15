# OPENAI_API_KEY is loaded in 000-loadtokens

#if ($null -ne (Get-Variable -Name $env:AIDER_OPENAI_API_KEY -ErrorAction SilentlyContinue)) {
if ($null -ne $env:OPENAI_API_KEY) {
    if (Get-Command aider -ErrorAction SilentlyContinue) {
        #Set-Variable -Name AIDER_
        $env:AIDER_DARK_MODE = "true"
        $env:AIDER_EDITOR = "code --wait"
        $env:AIDER_GITIGNORE = "false"
        $env:AIDER_MAP_TOKENS = 2048
        $env:AIDER_MAX_CHAT_HISTORY_TOKENS=2048
        $env:AIDER_VIM = "true"
        $env:AIDER_WATCH_FILES = "true"
    }
}
