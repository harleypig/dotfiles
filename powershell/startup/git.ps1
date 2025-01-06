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

function Add-GitAll {
    git add .
}
Set-Alias -Name gall -Value Add-GitAll

function Branch-GitAll {
    git branch -ra -v
}
Set-Alias -Name gba -Value Branch-GitAll

function Branch-Git {
    git branch
}
Set-Alias -Name gb -Value Branch-Git

function CherryPick-Git {
    param (
        [string]$Commit
    )
    git cherry-pick $Commit
}
Set-Alias -Name gcp -Value CherryPick-Git

function Diff-GitCached {
    git diff --cached
}
Set-Alias -Name gdc -Value Diff-GitCached

function Diff-Git {
    git diff
}
Set-Alias -Name gd -Value Diff-Git

function DiffStat-Git {
    git diffstat
}
Set-Alias -Name gds -Value DiffStat-Git

function Log-Git {
    git lg
}
Set-Alias -Name glg -Value Log-Git

function Pull-Git {
    git pull
}
Set-Alias -Name gl -Value Pull-Git

function Push-GitAllRemotes {
    git remote | ForEach-Object { git push --all $_ }
}
Set-Alias -Name gpa -Value Push-GitAllRemotes

function Push-GitAll {
    git push --all
}
Set-Alias -Name gpall -Value Push-GitAll

function Push-Git {
    git push
}
Set-Alias -Name gp -Value Push-Git

function Status-GitShort {
    git status -s
}
Set-Alias -Name gs -Value Status-GitShort

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
