# Declare and initialize variables, make some of them dual purpose
$scriptPath = $MyInvocation.MyCommand.Path

$env:DOTFILES = Split-Path -Parent (Resolve-Path -Path $scriptPath)
$DOTFILES = $env:DOTFILES

$env:PROJECTS_DIR = Split-Path -Parent $env:DOTFILES
$PROJECTS_DIR = $env:PROJECTS_DIR

#-----------------------------------------------------------------------------
# Convert this load_files function to powershell please, AI?

load_files() {
  declare -a load_dirs
  load_dirs+=("$DOTFILES/powershell/psshell-startup")
  load_dirs+=("$HOME/.psshell_startup.d")

  # Run each directory instead of doing a find on all directories at once
  # because we want these files loaded in this particular order.

  for load_dir in "${load_dirs[@]}"; do
    [[ -d $load_dir ]] || continue

    readarray -t load_files < <(/usr/bin/find "$load_dir" -type f -not -iname '*_inactive' | /usr/bin/sort)

    for f in "${load_files[@]}"; do
      # shellcheck disable=SC1090
      [[ -r $f ]] && source "$f"
    done
  done
}

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
