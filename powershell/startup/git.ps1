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
# Convert this function to a powershell function and fix the set-alias to use this function instead AI!
# Go to current git repo toplevel directory.
function gtl() {
  local dir
  dir="$(gtoplevel)" || return 1

  cd "$dir" || {
    echo "Unable to change to $dir"
    return 1
  }
}

Set-Alias -Name gtl -Value Get-GitTopLevel

#-----------------------------------------------------------------------------
## Go to current git toplevel directory, perform the git command and return
## to the original directory.
#function git_cmd_return() {
#  gtl || return 1
#  git "$@"
#  # shellcheck disable=SC2164
#  cd - > /dev/null
#}

#-----------------------------------------------------------------------------
function gsubadd() {
  if (($# < 1)) || (($# > 3)); then
    cat << EOH
  Usage: gsubadd <repo> [submodule] [branch]

  This function will add the repository in $vim_bundles
  and set the various settings in .gitmodule for that submodule.

  If submodule is not provided the basename, minus any .git extension.

  If branch is not provided the default of 'master' will be used.

EOH

    return 1
  fi

  gtl || return 1

  local repo name name_dir branch

  repo=$1
  debug "repo: $repo"

  name="${2:-$(basename "$repo" .git)}"
  debug "name: $name"

  name_dir="$vim_bundles/$name"
  debug "name_dir: $name_dir"

  branch="${3:-master}"
  debug "branch: $branch"

  if [[ -d $name_dir ]]; then
    mkdir -p "$name" || die "unable to create $name_dir"
  fi

  debug "git submodule add -b \"$branch\" \"$repo\" \"$name_dir\""
  git submodule add -b "$branch" "$repo" "$name_dir"

  debug "git config -f .gitmodules submodule.\"$name_dir\".ignore dirty"
  git config -f .gitmodules submodule."$name_dir".ignore dirty

  debug "git add .gitmodules"
  git add .gitmodules

  debug "git commit -m \"added $name submodule\""
  git commit -m "added $name submodule"

  # shellcheck disable=SC2164
  cd - > /dev/null
}

#-----------------------------------------------------------------------------
function gsubrm() {
  gtl || return 1

  [[ -z $1 ]] && {
    debug "Must pass a bundle to be removed"
    return 1
  }

  name=$1
  name_dir="$vim_bundles/$name"

  [[ -d $name_dir ]] || {
    debug "$name_dir does not exist"
    return 1
  }

  debug "git rm $name_dir"
  git rm "$name_dir"

  debug "rm -fr .git/modules/$vim_bundles/$name"
  rm -fr ".git/modules/$vim_bundles/$name"

  debug "git config -f .git/config --remove-section submodule.\"$name_dir\""
  git config -f .git/config --remove-section submodule."$name_dir" 2> /dev/null

  debug "git commit -m \"removed $name bundle\""
  git commit -m "removed $name bundle"

  # shellcheck disable=SC2164
  cd - > /dev/null
}
#-----------------------------------------------------------------------------
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
