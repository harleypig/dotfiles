#!/usr/bin/env bats

# Integration test for the PowerShell startup (ps-startup.ps1 + the
# powershell/startup/*.ps1 modules), run in a pwsh container. Deploys
# ps-startup.ps1 as the profile and asserts it comes up with DOTFILES set,
# the startup modules loaded, and no parser errors. Skips when docker is
# unavailable.

# shellcheck disable=SC2016  # PowerShell $env: refs are evaluated by pwsh.

load ../helpers/common

# The PowerShell team's own mcr.microsoft.com/powershell images are
# deprecated and frozen (latest is pwsh 7.4.2); Microsoft now ships pwsh in
# the .NET SDK image. 10.0.402-noble carries pwsh 7.6.7 (LTS) on Ubuntu
# 24.04. Dependabot cannot see this pin, so bump it by hand.
PS_IMAGE='mcr.microsoft.com/dotnet/sdk:10.0.402-noble@sha256:747cbade5bfd918a175ac32f8f1d931edec2c7d0d5397a3de72eaef1ac1f66d2'

setup() {
  load_bats_libs
  command -v docker > /dev/null 2>&1 || skip "docker not available"
}

# Deploy ps-startup.ps1 as the pwsh profile and run a pwsh script (passed via
# an env var, written to a file so the container's bash never expands its
# $env: references). pwsh loads the profile, then runs the script.
# The repo is mounted read-only at /dotfiles. Arguments: docker's tty flag
# (empty or -t), pwsh's arguments (word-split; the script is /tmp/cmd.ps1),
# the script, and optional bash run before pwsh starts, e.g. to seed PATH.
# Sets $output/$status.
ps_run() {
  # shellcheck disable=SC2086  # $1 is empty or one flag; empty must vanish.
  run docker run --rm $1 -v "$(dotfiles_root):/dotfiles:ro" -e PSARGS="$2" \
    -e PSCMD="$3" -e PREP="${4:-}" "$PS_IMAGE" bash -c '
      eval "$PREP"
      mkdir -p ~/.config/powershell
      printf "%s\n" ". /dotfiles/ps-startup.ps1" \
        > ~/.config/powershell/Microsoft.PowerShell_profile.ps1
      printf "%s" "$PSCMD" > /tmp/cmd.ps1
      pwsh $PSARGS
    '
}

# A non-interactive run: pwsh -File, no tty. Arguments: script, prep.
ps_startup() {
  ps_run '' '-File /tmp/cmd.ps1' "$@"
}

# A non-interactive run whose stderr comes back with each line prefixed
# "stderr: ", so a test can tell the two streams apart. Arguments: script,
# prep.
ps_startup_split() {
  ps_run '' '-File /tmp/cmd.ps1' "$1" "${2:-}
    pwsh() { { command pwsh \"\$@\" 2>&1 1>&3 | sed 's/^/stderr: /'; } 3>&1; }"
}

# An interactive run: stdin is a pseudo-tty and -NoExit keeps the session at
# its prompt after the script. The exit ends that session; it has to be in
# -Command, since an exit inside a -File script only ends the script.
ps_startup_interactive() {
  ps_run '-t' '-NoExit -Command . /tmp/cmd.ps1; exit' "$@"
}

# A real interactive session that renders its prompt: script(1) gives pwsh
# a pseudo-tty, so the host draws the prompt after the script. Nothing here
# is a terminal, so the input fed in answers the host's cursor-position
# query (ESC[6n, which it blocks on before drawing) and then types exit,
# repeating both until the session ends. Arguments: script, prep, and
# pwsh's arguments (default: run the script and stay at the prompt).
ps_render() {
  ps_run '' "${3:--NoExit -Command . /tmp/cmd.ps1}" "$1" "${2:-}
    pwsh() {
      (while sleep 1; do printf '\\033[1;1R'; sleep 1; printf 'exit\\r'; done) |
        timeout 60 script -qec \"pwsh \$*\" /dev/null
    }"
}

# Defines Show-Prompt, which writes its label and a prompt render with ESC
# spelled \e and newlines spelled |, so a line can be asserted exactly.
PS_SHOW='
  function Show-Prompt {
    param ([string]$Label, [string]$Render)
    $shown = $Render -replace [char]27, "\e" -replace "`n", "|"
    Write-Output "$Label=$shown"
  }
'

# Repositories for the git segment, built before pwsh starts: main (with a
# stash, which its worktrees share, a worktree on side and a detached
# worktree), a clone one commit ahead of it, and a bare repo.
GIT_PREP='
  g() { git -c user.name=t -c user.email=t@t "$@"; }
  git init -q -b main /tmp/repo && cd /tmp/repo
  echo a > f && git add f && g commit -q -m f
  echo b > f && g stash -q
  git worktree add -q /tmp/wt -b side
  git worktree add -q --detach /tmp/det
  git clone -q /tmp/repo /tmp/clone
  cd /tmp/clone && g commit -q --allow-empty -m ahead
  git init -q --bare /tmp/bare.git
  cd /
'

# Reports the env and the interactive-only setup a session ended up with.
PS_REPORT='
  Write-Output "DOTFILES=$env:DOTFILES"
  Write-Output "interactive=$DOTFILES_INTERACTIVE"
  Write-Output "hasAlias=$([bool](Get-Alias c -ErrorAction SilentlyContinue))"
  Write-Output "hasFunc=$([bool](Get-Command Set-ParentDirectory -ErrorAction SilentlyContinue))"
  Write-Output "hasS3cmd=$([bool](Get-Command s3cmd -ErrorAction SilentlyContinue))"
  Write-Output "hasPath=$(($env:PATH -split [IO.Path]::PathSeparator) -contains "/dotfiles/powershell/bin")"
  Write-Output "hasPrompt=$([bool](Get-Command Format-PromptGit -ErrorAction SilentlyContinue))"
'

@test "non-interactive pwsh -File gets the env but not the interactive setup" {
  ps_startup "$PS_REPORT"
  assert_success
  assert_output --partial 'DOTFILES=/dotfiles'
  assert_output --partial 'hasPath=True'
  assert_output --partial 'interactive=False'
  assert_output --partial 'hasAlias=False'
  assert_output --partial 'hasFunc=False'
  assert_output --partial 'hasS3cmd=False'
  assert_output --partial 'hasPrompt=False'
}

@test "interactive pwsh gets both the env and the interactive setup" {
  ps_startup_interactive "$PS_REPORT"
  assert_success
  assert_output --partial 'DOTFILES=/dotfiles'
  assert_output --partial 'hasPath=True'
  assert_output --partial 'interactive=True'
  assert_output --partial 'hasAlias=True'
  assert_output --partial 'hasFunc=True'
  assert_output --partial 'hasS3cmd=True'
  assert_output --partial 'hasPrompt=True'
  refute_output --partial 'ParserError'
  refute_output --partial 'is not recognized'
}

@test "interactive pwsh applies the PSReadLine history settings" {
  # XDG_STATE_HOME is seeded so the save path is checkable; the handler is
  # probed directly with a leading-space line, a HISTIGNORE word and a line
  # that must be kept.
  ps_startup_interactive '
    $o = Get-PSReadLineOption
    Write-Output "noDups=$($o.HistoryNoDuplicates)"
    Write-Output "maxCount=$($o.MaximumHistoryCount)"
    Write-Output "savePath=$($o.HistorySavePath)"
    Write-Output "dirExists=$(Test-Path /tmp/state/powershell)"
    $h = $o.AddToHistoryHandler
    Write-Output "space=$($h.Invoke(" Get-Date"))"
    Write-Output "ignored=$($h.Invoke("exit"))"
    Write-Output "kept=$($h.Invoke("Get-Date"))"
  ' 'export XDG_STATE_HOME=/tmp/state'
  assert_success
  assert_output --partial 'noDups=True'
  assert_output --partial 'maxCount=100000'
  assert_output --partial 'savePath=/tmp/state/powershell/history'
  assert_output --partial 'dirExists=True'
  assert_output --partial 'space=False'
  assert_output --partial 'ignored=False'
  assert_output --partial 'kept=True'
  refute_output --partial 'Exception'
  refute_output --partial 'is not recognized'
}

@test "pwsh startup classifies each way of starting pwsh" {
  # One container, every invocation on a tty unless it pipes stdin, so only
  # the command line (or the pipe) decides. Each line is label=verdict.
  run docker run --rm -t -v "$(dotfiles_root):/dotfiles:ro" "$PS_IMAGE" \
    bash -c '
      mkdir -p ~/.config/powershell
      printf "%s\n" ". /dotfiles/ps-startup.ps1" \
        > ~/.config/powershell/Microsoft.PowerShell_profile.ps1
      r="Write-Output \"\$DOTFILES_INTERACTIVE\""
      printf "%s\n" "$r" > /tmp/r.ps1
      v() { printf "%s=%s\n" "$1" "$(grep -oE "True|False" | tail -n 1)"; }
      pwsh -Command "$r" | v command
      pwsh -c "$r" | v c-short
      pwsh -comm "$r" | v c-prefix
      pwsh /tmp/r.ps1 | v positional
      pwsh -ExecutionPolicy Bypass -File /tmp/r.ps1 | v value-then-file
      pwsh -NonInteractive -NoExit -Command "$r; exit" | v noninteractive
      printf "%s\nexit\n" "$r" | pwsh -File - | v piped-stdin
      pwsh -NoExit -Command "$r; exit" | v noexit-command
      pwsh -wd /tmp -noe -c "$r; exit" | v value-then-noexit
    '
  assert_success
  assert_line --partial 'command=False'
  assert_line --partial 'c-short=False'
  assert_line --partial 'c-prefix=False'
  assert_line --partial 'positional=False'
  assert_line --partial 'value-then-file=False'
  assert_line --partial 'noninteractive=False'
  assert_line --partial 'piped-stdin=False'
  assert_line --partial 'noexit-command=True'
  assert_line --partial 'value-then-noexit=True'
}

@test "pwsh startup loads the modules without parser errors" {
  ps_startup 'Write-Output started-ok'
  assert_success
  assert_output --partial 'started-ok'
  refute_output --partial 'ParserError'
  refute_output --partial 'is not valid'
}

@test "pwsh startup builds PATH with the platform separators" {
  ps_startup '
    $env:PATH -split [IO.Path]::PathSeparator |
      ForEach-Object { Write-Output "entry=$_" }
  '
  assert_success
  assert_output --partial 'entry=/dotfiles/powershell/bin'
  refute_output --partial "\\"
  refute_output --regexp 'entry=[^[:space:]]*;'
}

@test "pwsh startup leaves no duplicate PATH entries" {
  # Seed an inherited PATH that repeats a system dir and already carries one
  # of the entries the profile prepends, so both dedup cases are exercised.
  ps_startup '
    $entries = $env:PATH -split [IO.Path]::PathSeparator
    $dups = @($entries | Group-Object | Where-Object Count -gt 1)
    Write-Output "dups=$($dups.Count)"
    $dups | ForEach-Object { Write-Output "dup=$($_.Name)" }
  ' 'export PATH="$HOME/.local/bin:$PATH:/usr/bin"'
  assert_success
  assert_output --partial 'dups=0'
}

@test "pwsh debug is silent unless DEBUG is a non-zero integer" {
  local script='debug "trace-msg"; "piped-msg" | debug; Write-Output done'

  ps_startup_split "$script"
  assert_success
  assert_line 'done'
  refute_output --partial 'msg'
  refute_output --partial 'stderr:'

  ps_startup_split "$script" 'export DEBUG=0'
  assert_success
  assert_line 'done'
  refute_output --partial 'stderr:'
}

@test "pwsh debug writes a call-stack-prefixed line to stderr" {
  ps_startup_split '
    function Invoke-Outer { Invoke-Inner }
    function Invoke-Inner { debug "trace-msg" }
    Invoke-Outer
    Write-Output done
  ' 'export DEBUG=1'
  assert_success
  assert_line 'done'
  assert_line --regexp \
    '^stderr: \[i\+[0-9]+ms\]\[cmd\.ps1:[0-9]{3}\]\[cmd\.ps1:Invoke-Outer:[0-9]{3}\]\[cmd\.ps1:Invoke-Inner:[0-9]{3}\] trace-msg$'
  refute_line 'stderr: done'
}

@test "pwsh debug traces each line of pipeline input" {
  ps_startup_split '"one", "two" | debug' 'export DEBUG=1'
  assert_success
  assert_line --regexp 'stderr: \[i\+[0-9]+ms\]\[cmd\.ps1:[0-9]{3}\] one$'
  assert_line --regexp 'stderr: \[i\+[0-9]+ms\]\[cmd\.ps1:[0-9]{3}\] two$'
}

@test "interactive pwsh renders the dotfiles prompt" {
  # Rendered by the host at /, outside any repository: user@host and the
  # directory on one line, the status badge and final character on the
  # next, and no git segment.
  ps_render 'Write-Output ready' "$GIT_PREP"
  assert_success
  assert_output --partial $'\e[0m\e[36m\e[91mroot\e[90m@\e[33m'
  assert_output --partial $'\e[32m/\e[0m\r\n\e[44;33m 0 \e[0m !! '
  refute_output --partial '('
  refute_output --partial 'Exception'
}

@test "interactive pwsh prompt reflects a failing native command" {
  # The failing command has to be the session's last: after a dot-sourced
  # script $? is the script's own success, whatever it ran last.
  ps_render '' 'printf "#!/bin/sh\nexit 3\n" > /usr/local/bin/fail3
    chmod +x /usr/local/bin/fail3' '-NoExit -Command fail3'
  assert_success
  assert_output --partial $'\e[41;37m 3 \e[0m !! '
}

@test "interactive pwsh prompt shows the git branch inside a repo" {
  ps_render 'Set-Location /tmp/repo' "$GIT_PREP"
  assert_success
  assert_output --partial $'\e[32m/tmp/repo\e[0m \e[32m(repo: main {1})\e[0m\r\n'
}

@test "pwsh prompt tells cmdlet failures, native failures and success apart" {
  ps_startup_interactive "$PS_SHOW"'
    Get-Item /nonexistent -ErrorAction SilentlyContinue
    $r = prompt; Show-Prompt cmdlet $r
    bash -c "exit 3"
    $r = prompt; Show-Prompt native $r
    Get-Date | Out-Null
    $r = prompt; Show-Prompt stale $r
    bash -c "exit 141"
    $r = prompt; Show-Prompt sigpipe $r
    Set-Location /tmp/repo
    bash -c "exit 4"
    $r = prompt
    Write-Output "lastexitcode=$LASTEXITCODE"
  ' "$GIT_PREP"
  assert_success
  assert_line --regexp 'cmdlet=.*\|\\e\[41;37m ERR \\e\[0m !! '
  assert_line --regexp 'native=.*\|\\e\[41;37m 3 \\e\[0m !! '
  assert_line --regexp 'stale=.*\|\\e\[44;33m 0 \\e\[0m !! '
  assert_line --regexp 'sigpipe=.*\|\\e\[44;33m 141 \\e\[0m !! '
  assert_line --partial 'lastexitcode=4'
}

@test "pwsh prompt git segment mirrors bin/git-status" {
  ps_startup_interactive "$PS_SHOW"'
    Set-Location /tmp/repo
    Show-Prompt clean (prompt)
    Set-Content f c
    Show-Prompt unstaged (prompt)
    git add f
    Show-Prompt staged (prompt)
    Set-Location /tmp/clone
    Show-Prompt ahead (prompt)
    New-Item .nopush | Out-Null
    Show-Prompt nopush (prompt)
    Set-Location /tmp/wt
    Show-Prompt worktree (prompt)
    Set-Location /tmp/det
    Show-Prompt detached (prompt)
    Set-Location /tmp/bare.git
    Show-Prompt bare (prompt)
    Set-Location /tmp/repo/.git
    Show-Prompt gitdir (prompt)
    Set-Location /
    Show-Prompt outside (prompt)
  ' "$GIT_PREP"
  assert_success
  assert_line --regexp 'clean=.* \\e\[32m\(repo: main \{1\}\)\\e\[0m\|'
  assert_line --regexp 'unstaged=.* \\e\[33m\(repo: main \{1\}\)\\e\[0m\|'
  assert_line --regexp 'staged=.* \\e\[31m\(repo: main \{1\}\)\\e\[0m\|'
  assert_line --regexp 'ahead=.* \\e\[32m\(clone: main \\e\[41;33mPUSH\\e\[0m\)\\e\[0m\|'
  assert_line --regexp 'nopush=.* \\e\[32m\(clone: main\)\\e\[0m\|'
  assert_line --regexp 'worktree=.* \\e\[32m\(wt: side \[wt:repo\] \{1\}\)\\e\[0m\|'
  assert_line --regexp 'detached=.* \\e\[32m\(det: \([0-9a-f]{7}\.\.\.\) \[wt:repo\] \{1\}\)\\e\[0m\|'
  assert_line --regexp 'bare=.* \\e\[41;33m\(BARE\)\\e\[0m\|'
  assert_line --regexp 'gitdir=.*/tmp/repo/\.git\\e\[0m\|'
  assert_line --regexp 'outside=.*: \\e\[32m/\\e\[0m\|'
}

@test "pwsh prompt shows the venv and the directory as bash does" {
  # /dotfiles is mounted read-only, so even root cannot write there.
  ps_startup_interactive "$PS_SHOW"'
    $env:VIRTUAL_ENV = "/tmp/repo/.venv"
    Set-Location /tmp/repo
    Show-Prompt inside (prompt)
    Set-Location /tmp
    Show-Prompt outside (prompt)
    Remove-Item Env:VIRTUAL_ENV
    $env:POETRY_ACTIVE = "1"
    Show-Prompt poetry (prompt)
    Remove-Item Env:POETRY_ACTIVE
    Set-Location /dotfiles
    Show-Prompt readonly (prompt)
    $env:DIR_PWD_MAX = "5"
    Set-Location /tmp/repo
    Show-Prompt truncated (prompt)
    Write-Output "disable=$env:VIRTUAL_ENV_DISABLE_PROMPT"
  ' "$GIT_PREP"
  assert_success
  assert_line --regexp 'inside=.*: \\e\[92m\(venv\)\\e\[0m \\e\[32m/tmp/repo'
  assert_line --regexp 'outside=.*: \\e\[31m\(venv: /tmp/repo\)\\e\[0m \\e\[32m/tmp\\e'
  assert_line --regexp 'poetry=.*: \\e\[95m\(poetry venv\)\\e\[0m '
  assert_line --regexp 'readonly=.*: \\e\[31m/dotfiles\\e\[0m\|'
  assert_line --regexp 'truncated=.*: \\e\[32m</repo\\e\[0m '
  assert_line --partial 'disable=1'
}

@test "pwsh prompt loads and renders where git is absent" {
  # pwsh runs with a PATH holding nothing else, so neither git nor test(1)
  # is found; the repo itself still exists.
  ps_startup_interactive "$PS_SHOW"'
    Set-Location /tmp/repo
    Show-Prompt nogit (prompt)
  ' "$GIT_PREP
    mkdir /tmp/nogit
    pwsh() { PATH=/tmp/nogit /usr/bin/pwsh \"\$@\"; }"
  assert_success
  assert_line --regexp 'nogit=.*: \\e\[32m/tmp/repo\\e\[0m\|'
  refute_output --partial 'repo: '
  refute_output --partial 'is not recognized'
  refute_output --partial 'Exception'
}

# Stubs, put first on PATH before pwsh starts, for each command named in
# $STUBS. Each prints its name and arguments, then any piped stdin line by
# line.
STUB_PREP='
  mkdir -p /tmp/stub
  for name in $STUBS; do
    printf "%s\n" "#!/bin/sh" "echo \"\${0##*/}:\$*\"" \
      "[ -t 0 ] || timeout 5 sed s/^/stdin:/" > /tmp/stub/$name
    chmod +x /tmp/stub/$name
  done
  export PATH="/tmp/stub:$PATH"
'

@test "interactive pwsh ports grep and g with --color=auto" {
  ps_startup_interactive '
    Write-Output "grepIs=$((Get-Command grep).ResolvedCommand.Name)"
    Write-Output "gIs=$((Get-Command g).ResolvedCommand.Name)"
    Write-Output "colors=$env:GREP_COLORS"
    grep -v -i "two words" file
    g pat
    "one", "two" | grep -e x
  ' "STUBS=grep $STUB_PREP"
  assert_success
  assert_line --partial 'grepIs=Invoke-Grep'
  assert_line --partial 'gIs=Invoke-Grep'
  assert_line --partial 'colors=mt=1;33'
  assert_line --partial 'grep:--color=auto -v -i two words file'
  assert_line --partial 'grep:--color=auto pat'
  assert_line --partial 'grep:--color=auto -e x'
  assert_line --partial 'stdin:one'
  assert_line --partial 'stdin:two'
  refute_output --partial 'is not recognized'
}

@test "interactive pwsh ports diffdir and diff onto colordiff when present" {
  ps_startup_interactive '
    Write-Output "diffIs=$((Get-Command diff).Definition)"
    diffdir a b
    diff -u x y
  ' "STUBS='diff colordiff' $STUB_PREP"
  assert_success
  assert_line --partial 'diffIs=colordiff'
  assert_line --partial 'colordiff:-qr a b'
  assert_line --partial 'colordiff:-u x y'
  refute_output --partial 'is not recognized'
}

@test "interactive pwsh diffdir uses plain diff without colordiff" {
  ps_startup_interactive '
    Write-Output "diffType=$((Get-Command diff).CommandType)"
    diffdir a b
  ' "STUBS=diff $STUB_PREP"
  assert_success
  assert_line --partial 'diffType=Application'
  assert_line --partial 'diff:-qr a b'
  refute_output --partial 'colordiff'
}

@test "interactive pwsh defines no grep or diff commands without the tools" {
  # PATH holds nothing else, so neither grep nor diff is found.
  ps_startup_interactive '
    foreach ($name in "grep", "g", "diff", "diffdir") {
      $found = [bool](Get-Command $name -ErrorAction SilentlyContinue)
      Write-Output "$name=$found"
    }
  ' 'mkdir /tmp/empty
    pwsh() { PATH=/tmp/empty /usr/bin/pwsh "$@"; }'
  assert_success
  assert_line --partial 'grep=False'
  assert_line --partial 'g=False'
  assert_line --partial 'diff=False'
  assert_line --partial 'diffdir=False'
  refute_output --partial 'Exception'
}

@test "interactive pwsh dumppath prints one line per PATH entry" {
  ps_startup_interactive '
    $entries = @(dumppath)
    Write-Output "count=$($entries.Count)"
    Write-Output "expected=$(@($env:PATH -split ":").Count)"
    $entries | ForEach-Object { Write-Output "entry=$_" }
  '
  assert_success
  assert_line --partial 'entry=/dotfiles/powershell/bin'
  refute_line --regexp 'entry=.*:'

  local count expected
  count=$(grep -o 'count=[0-9]*' <<< "$output")
  expected=$(grep -o 'expected=[0-9]*' <<< "$output")
  [[ ${count#count=} -gt 1 && ${count#count=} == "${expected#expected=}" ]]
}

# Runs a pwsh script with no profile, from /tmp/elsewhere rather than the
# repo, so powershell/ps-profile.ps1 cannot lean on the caller's directory.
# Each script points $PROFILE at a throwaway path before running it.
# Arguments: the script, and optional bash run first. Sets $output/$status.
ps_profile_run() {
  run docker run --rm -v "$(dotfiles_root):/dotfiles:ro" -e PSCMD="$1" \
    -e PREP="${2:-}" "$PS_IMAGE" bash -c '
      mkdir -p /tmp/elsewhere && cd /tmp/elsewhere
      eval "$PREP"
      printf "%s" "$PSCMD" > /tmp/cmd.ps1
      pwsh -NoProfile -File /tmp/cmd.ps1
    '
}

@test "ps-profile creates a profile that dot-sources the startup" {
  # The profile directory does not exist yet. Each dot-sourced path is read
  # back through the parser, so the check does not depend on its quoting.
  ps_profile_run '
    $PROFILE = "/tmp/new/profile.ps1"
    & /dotfiles/powershell/ps-profile.ps1
    $ast = [Management.Automation.Language.Parser]::ParseFile(
      $PROFILE, [ref]$null, [ref]$null)
    $ast.FindAll({
      param ($n)
      $n -is [Management.Automation.Language.CommandAst] -and
        $n.InvocationOperator -eq "Dot"
    }, $true) | ForEach-Object {
      $path = $_.CommandElements[0].Value
      Write-Output "sources=$path"
      Write-Output "exists=$(Test-Path -LiteralPath $path -PathType Leaf)"
    }
  '
  assert_success
  assert_line --partial 'Profile created at: /tmp/new/profile.ps1'
  assert_line 'sources=/dotfiles/ps-startup.ps1'
  assert_line 'exists=True'
}

@test "ps-profile leaves an existing profile untouched" {
  # First a profile without the line, then one that already carries it.
  ps_profile_run '
    $PROFILE = "/tmp/mine.ps1"
    $before = (Get-FileHash $PROFILE).Hash
    & /dotfiles/powershell/ps-profile.ps1
    Write-Output "unchanged=$($before -eq (Get-FileHash $PROFILE).Hash)"
    $PROFILE = "/tmp/done.ps1"
    $before = (Get-FileHash $PROFILE).Hash
    & /dotfiles/powershell/ps-profile.ps1
    Write-Output "unchanged=$($before -eq (Get-FileHash $PROFILE).Hash)"
  ' "printf '# mine\n' > /tmp/mine.ps1
    printf '%s\n' '# mine' \". '/dotfiles/ps-startup.ps1'\" > /tmp/done.ps1"
  assert_success
  assert_line --partial 'add the following line to your profile'
  assert_line --partial ". '/dotfiles/ps-startup.ps1'"
  assert_line --partial 'already includes the necessary content'
  assert_equal "$(grep -c '^unchanged=True$' <<< "$output")" 2
}

@test "a profile from ps-profile loads the startup wherever the repo is" {
  # A copy of the startup under a path holding a space, run by path from
  # elsewhere; a fresh pwsh then dot-sources the profile it wrote.
  ps_profile_run '
    $PROFILE = "/tmp/new/profile.ps1"
    & "/tmp/my dots/powershell/ps-profile.ps1" | Out-Null
    Set-Content /tmp/load.ps1 ". /tmp/new/profile.ps1",
      "Write-Output DOTFILES=`$env:DOTFILES",
      "Write-Output interactive=`$DOTFILES_INTERACTIVE"
    pwsh -NoProfile -File /tmp/load.ps1
  ' 'mkdir "/tmp/my dots"
    cp -r /dotfiles/ps-startup.ps1 /dotfiles/powershell "/tmp/my dots/"'
  assert_success
  assert_line 'DOTFILES=/tmp/my dots'
  assert_line 'interactive=False'
  refute_output --partial 'is not recognized'
}

# The scoping rule in ps-startup.ps1's header: Import-Files dot-sources each
# module inside a function, so a function or alias not declared global is
# gone once loading ends. Reports parsed=<count>, then one violation= line
# per top-level function or Set-Alias/New-Alias that is neither global nor
# under a "# load-time only" comment. Definitions nested in a function only
# exist while it runs, so they are not the module's to export. Scans
# $env:GUARD_DIR, default the repo's startup directory.
SCOPE_GUARD='
  using namespace System.Management.Automation.Language

  $dir = if ($env:GUARD_DIR) { $env:GUARD_DIR } else {
    "/dotfiles/powershell/startup"
  }

  # The loader picks files the same way.
  $files = @(Get-ChildItem -Path $dir -File |
    Where-Object Extension -eq ".ps1")

  Write-Output "parsed=$($files.Count)"

  function Test-GlobalScope ([CommandAst]$Command) {
    $elements = $Command.CommandElements

    for ($i = 1; $i -lt $elements.Count; $i++) {
      $param = $elements[$i]

      # pwsh takes any unambiguous prefix; none of Set-Alias other
      # parameters starts with s.
      if ($param -is [CommandParameterAst] -and
          "scope".StartsWith($param.ParameterName, "OrdinalIgnoreCase")) {
        $value = if ($param.Argument) { $param.Argument } else {
          $elements[$i + 1]
        }

        return $value -is [StringConstantExpressionAst] -and
          $value.Value -eq "Global"
      }
    }

    $false
  }

  foreach ($file in $files) {
    $tokens = $errors = $null
    $ast = [Parser]::ParseFile($file.FullName, [ref]$tokens, [ref]$errors)

    $markers = @($tokens | Where-Object {
      $_.Kind -eq "Comment" -and $_.Text -match "^#\s*load-time only\b"
    } | ForEach-Object { $_.Extent.StartLineNumber })

    $ast.FindAll({
      param ($node)
      $node -is [FunctionDefinitionAst] -or ($node -is [CommandAst] -and
        $node.GetCommandName() -in "Set-Alias", "New-Alias", "sal", "nal")
    }, $true) | ForEach-Object {
      $node = $_
      $line = $node.Extent.StartLineNumber

      for ($up = $node.Parent; $up; $up = $up.Parent) {
        if ($up -is [FunctionDefinitionAst]) { return }
      }

      if ($markers -contains ($line - 1)) { return }

      if ($node -is [FunctionDefinitionAst]) {
        if ($node.Name -notmatch "^global:") {
          Write-Output "violation=$($file.Name):${line}: function $($node.Name)"
        }

      } elseif (-not (Test-GlobalScope $node)) {
        Write-Output "violation=$($file.Name):${line}: $($node.Extent.Text)"
      }
    }
  }
'

@test "pwsh startup modules declare their functions and aliases global" {
  ps_profile_run "$SCOPE_GUARD"
  assert_success
  refute_line --partial 'violation='

  local parsed
  parsed=$(grep -o 'parsed=[0-9]*' <<< "$output")
  [[ ${parsed#parsed=} -gt 0 ]]
}

@test "pwsh scope guard flags a local function or alias and honours the marker" {
  # A copy of the real modules plus planted cases: each kind of local
  # definition, the marked and nested forms the guard must let through, and
  # the global forms it must accept however they are spelled.
  ps_profile_run "$SCOPE_GUARD" '
    cp -r /dotfiles/powershell/startup /tmp/planted
    export GUARD_DIR=/tmp/planted
    cat > /tmp/planted/zz-planted.ps1 <<"PS"
function Get-Planted { 1 }
Set-Alias -Name pa -Value Get-Planted
New-Alias pn Get-Planted -Scope Local
# load-time only
function Get-Marked { 1 }
function Global:Get-Outer { function Get-Inner { 1 }; Set-Alias pi Get-Inner }
Set-Alias -sc global -Name pg -Value Get-Outer
Set-Alias -Scope:Global -Name ph -Value Get-Outer
PS
  '
  assert_success
  assert_line 'violation=zz-planted.ps1:1: function Get-Planted'
  assert_line 'violation=zz-planted.ps1:2: Set-Alias -Name pa -Value Get-Planted'
  assert_line 'violation=zz-planted.ps1:3: New-Alias pn Get-Planted -Scope Local'
  assert_equal "$(grep -c '^violation=' <<< "$output")" 3
}
