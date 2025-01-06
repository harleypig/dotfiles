# Aliases and functions for git

# Check the following for more ideas:
# https://gist.github.com/chrismccoy/8775224
# https://github.com/git/git/blob/master/mergetools/vimdiff

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    return
}

#-----------------------------------------------------------------------------
# TBD: Fix inputrc setup

# Show git short status for current directory by pressing Ctl-g-s.
#bind -x '"\C-gs": "git status -s ."'

# Show all local and remote branches for all remotes by pressing Ctl-g-r.
#bind -x '"\C-gr": "git branch -ra | column"'

#-----------------------------------------------------------------------------
function Get-GitTopLevel {
    $topLevel = git rev-parse --show-toplevel 2>$null
    if (-not $topLevel) {
        Write-Output "Not in a git repository."
        return $null
    }
    return $topLevel
}

#-----------------------------------------------------------------------------
function Set-GitTopLevelLocation {
    $dir = Get-GitTopLevel
    if (-not $dir) {
        Write-Output "Unable to change to $dir"
        return
    }
    Set-Location -Path $dir
}

Set-Alias -Name gtl -Value Set-GitTopLevelLocation

#-----------------------------------------------------------------------------
# Convert the following functions to powershell. Be sure to use approved verbs for the names. Create aliases for each function using the old name as the alias. AI!
function ga() { git add "$@"; }
function gca() { git commit -a -v -m "$@"; }
function gc() { git commit -v -m "$@"; }
function gco() { git checkout "$@"; }
function gf() { git fetch --all --tags; }
function gmv() { git mv "$@"; }
function grm() { git rm "$@"; }

#-----------------------------------------------------------------------------
alias gall='git add .'
alias gba='git branch -ra -v'
alias gb='git branch'
alias gcp='git cherry-pick'
alias gdc='git diff --cached'
alias gd='git diff'
alias gds='git diffstat'
alias glg='git lg'
alias gl='git pull'
alias gpa='git remote | xargs -L1 git push --all'
alias gpall='git push --all'
alias gp='git push'
alias gs='git status -s'

#-----------------------------------------------------------------------------
# https://github.com/git/git/blob/master/contrib/completion/git-completion.bash
if [[ -r "$XDG_CONFIG_HOME/completions/git" ]]; then
  export GIT_COMPLETION_SHOW_ALL=1
  export GIT_COMPLETION_SHOW_ALL_COMMANDS=1
  export GIT_COMPLETION_IGNORE_CASE=1

  source "$XDG_CONFIG_HOME/completions/git"

  __git_complete ga  _git_add
  __git_complete gc  _git_commit
  __git_complete gco _git_checkout
  __git_complete gcp _git_cherry_pick
  __git_complete gdc _git_diff
  __git_complete gd  _git_diff
  __git_complete gl  _git_pull
  __git_complete gmv _git_mv
  __git_complete gp  _git_push
  __git_complete grm _git_rm

fi

#-----------------------------------------------------------------------------
# cygwin specific stuff

#if [[ "$(uname -o)" == "Cygwin" ]]; then
#  alias git="'$(cygpath -u "C:\Program Files\Git\bin\git.exe")'"
#fi
