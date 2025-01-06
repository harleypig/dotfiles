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

#-----------------------------------------------------------------------------
function Add-Git {
    param (
        [string[]]$Paths
    )
    git add $Paths
}

#-----------------------------------------------------------------------------
function Commit-GitAll {
    param (
        [string]$Message
    )
    git commit -a -v -m $Message
}

#-----------------------------------------------------------------------------
function Commit-Git {
    param (
        [string]$Message
    )
    git commit -v -m $Message
}

#-----------------------------------------------------------------------------
function Checkout-Git {
    param (
        [string]$Branch
    )
    git checkout $Branch
}

#-----------------------------------------------------------------------------
function Fetch-Git {
    git fetch --all --tags
}

#-----------------------------------------------------------------------------
function Move-Git {
    param (
        [string[]]$Paths
    )
    git mv $Paths
}

#-----------------------------------------------------------------------------
function Remove-Git {
    param (
        [string[]]$Paths
    )
    git rm $Paths
}

# Convert these bash aliases to powershell functions. Be sure to use approved verbs for the name of the function. Create aliases for each in the alias section below, using the old name of the alias as the new name AI!
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
Set-Alias -Name gtl -Value Set-GitTopLevelLocation
Set-Alias -Name ga -Value Add-Git
Set-Alias -Name gca -Value Commit-GitAll
Set-Alias -Name gc -Value Commit-Git
Set-Alias -Name gco -Value Checkout-Git
Set-Alias -Name gf -Value Fetch-Git
Set-Alias -Name gmv -Value Move-Git
Set-Alias -Name grm -Value Remove-Git

#-----------------------------------------------------------------------------
# TBD
# https://github.com/git/git/blob/master/contrib/completion/git-completion.bash
# if [[ -r "$XDG_CONFIG_HOME/completions/git" ]]; then
#   export GIT_COMPLETION_SHOW_ALL=1
#   export GIT_COMPLETION_SHOW_ALL_COMMANDS=1
#   export GIT_COMPLETION_IGNORE_CASE=1

#   source "$XDG_CONFIG_HOME/completions/git"

#   __git_complete ga  _git_add
#   __git_complete gc  _git_commit
#   __git_complete gco _git_checkout
#   __git_complete gcp _git_cherry_pick
#   __git_complete gdc _git_diff
#   __git_complete gd  _git_diff
#   __git_complete gl  _git_pull
#   __git_complete gmv _git_mv
#   __git_complete gp  _git_push
#   __git_complete grm _git_rm

# fi
