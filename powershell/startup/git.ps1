# Aliases and functions for git

# Check the following for more ideas:
# https://gist.github.com/chrismccoy/8775224
# https://github.com/git/git/blob/master/mergetools/vimdiff

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    return
}

#-----------------------------------------------------------------------------
function Global:Get-GitTopLevel {
    $topLevel = git rev-parse --show-toplevel 2>$null
    if (-not $topLevel) {
        Write-Output "Not in a git repository."
        return $null
    }
    return $topLevel
}

#-----------------------------------------------------------------------------
function Global:Set-GitTopLevelLocation {
    $dir = Get-GitTopLevel
    if (-not $dir) {
        Write-Output "Unable to change to $dir"
        return
    }
    Set-Location -Path $dir
}

#-----------------------------------------------------------------------------
function Global:Add-Git { param ( [string[]]$Paths) git add $Paths }
function Global:Add-GitAll { git add .  }
function Global:Branch-Git { git branch }
function Global:Branch-GitAll { git branch -ra -v }
function Global:Checkout-Git { param ( [string]$Branch) git checkout $Branch }
function Global:CherryPick-Git { param ( [string]$Commit) git cherry-pick $Commit }
function Global:Commit-Git { param ( [string]$Message) git commit -v -m $Message }
function Global:Commit-GitAll { param ( [string]$Message) git commit -a -v -m $Message }
function Global:Diff-Git { git diff }
function Global:Diff-GitCached { git diff --cached }
function Global:DiffStat-Git { git diffstat }
function Global:Fetch-Git { git fetch --all --tags }
function Global:Log-Git { git lg }
function Global:Move-Git { param ( [string[]]$Paths) git mv $Paths }
function Global:Pull-Git { git pull }
function Global:Push-Git { git push }
function Global:Push-GitAll { git push --all }
function Global:Push-GitAllRemotes { git remote | ForEach-Object { git push --all $_ } }
function Global:Remove-Git { param ( [string[]]$Paths) git rm $Paths }
function Global:Status-GitShort { git status -s }

#-----------------------------------------------------------------------------
Set-Alias -Scope Global -Name ga -Value Add-Git
Set-Alias -Scope Global -Name gall -Value Add-GitAll
Set-Alias -Scope Global -Name gb -Value Branch-Git
Set-Alias -Scope Global -Name gba -Value Branch-GitAll
Set-Alias -Scope Global -Name gca -Value Commit-GitAll
Set-Alias -Scope Global -Name gco -Value Checkout-Git
Set-Alias -Scope Global -Name gcp -Value CherryPick-Git
Set-Alias -Scope Global -Name gd -Value Diff-Git
Set-Alias -Scope Global -Name gdc -Value Diff-GitCached
Set-Alias -Scope Global -Name gds -Value DiffStat-Git
Set-Alias -Scope Global -Name gf -Value Fetch-Git
Set-Alias -Scope Global -Name glg -Value Log-Git
Set-Alias -Scope Global -Name gmv -Value Move-Git
Set-Alias -Scope Global -Name gpa -Value Push-GitAllRemotes
Set-Alias -Scope Global -Name gpall -Value Push-GitAll
Set-Alias -Scope Global -Name grm -Value Remove-Git
Set-Alias -Scope Global -Name gs -Value Status-GitShort
Set-Alias -Scope Global -Name gtl -Value Set-GitTopLevelLocation

# Need to use another alias, these are taken
#Set-Alias -Scope Global -Name gc -Value Commit-Git
#Set-Alias -Scope Global -Name gl -Value Pull-Git
#Set-Alias -Scope Global -Name gp -Value Push-Git

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
