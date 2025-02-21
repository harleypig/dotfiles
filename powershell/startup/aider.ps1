# OPENAI_API_KEY is loaded in 000-loadtokens

if (Get-Command aider -ErrorAction SilentlyContinue) {
    $env:AIDER_DARK_MODE = "true"
    $env:AIDER_EDITOR = "code --wait"
    $env:AIDER_GITIGNORE = "false"
    $env:AIDER_LINE_ENDINGS='lf'
    $env:AIDER_MAP_TOKENS = 2048
    $env:AIDER_MAX_CHAT_HISTORY_TOKENS=2048
    $env:AIDER_VIM = "true"
    $env:AIDER_WATCH_FILES = "true"

    $env:AIDER_COMMIT_PROMPT = "Follow the Conventional Commits specification for the commit message. The commit message should start with a type (e.g., feat, fix, chore) followed by a concise summary of the changes. In the body, include a list of files affected and a brief description of the changes made to each.  Format the descriptions as a bullet list, with each item indented for clarity and readability. Ensure the list is well-organized and easy to understand."
}
