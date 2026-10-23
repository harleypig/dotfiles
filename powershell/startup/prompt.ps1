# The pwsh counterpart of config/shell-startup/bash_prompt (load-time
# constants) and lib/bash_prompt (the render), laid out the same way:
#
#   <blank line>
#   user@host: (venv) /current/dir (repo: branch)
#    0  $
#
# Segments of the bash prompt that are not ported, and why:
#   - pstree parent: pstree is not on Windows, and .NET has no cheap way
#     to walk a process's ancestry there.
#   - pacman-status: Arch's package manager, not a pwsh concern.
#   - loadavg: reads /proc/loadavg, which only Linux has.
#   - history -a/-c/-r: bash syncs history between sessions by hand;
#     PSReadLine already saves incrementally and reads other sessions'
#     history on its own.
#
# The git segment talks to git directly rather than calling bin/git-status,
# which needs bash, perl, bin/ansi and git's git-prompt.sh -- none of them
# present on Windows -- and forks a dozen processes per render. Here a render
# costs at most two git calls, and none where git is absent.

# The prompt runs long after this file's scope is gone, so its load-time
# state lives in one global table, $global:_DotfilesPrompt.
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSAvoidGlobalVars', '',
    Justification = 'Prompt state must outlive the loading scope')]
param ()

if (-not $DOTFILES_INTERACTIVE) {
    return
}

##############################################################################
# Constant work, done once at load. Colours are raw SGR sequences rather
# than $PSStyle: $PSStyle only exists on 7.2+, its members are the same
# strings, and [char]27 works on 5.1 too.

# load-time only
function Get-PromptColor {
    <#
    .SYNOPSIS
    The SGR escape sequence for a ';'-joined list of codes.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param ([string]$Codes)

    "$([char]27)[${Codes}m"
}

$isWindowsHost = [IO.Path]::DirectorySeparatorChar -eq '\'

$isAdmin = if ($isWindowsHost) {
    ([Security.Principal.WindowsPrincipal](
        [Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)
} else {
    [Environment]::UserName -eq 'root'
}

# bash's PROMPT_CHARS, by code point so this file stays ASCII: PowerShell
# 5.1 reads a BOM-less file as the ANSI code page, not UTF-8.
$promptChars = @(
    0x24, 0x25CF, 0x2605, 0x27A4, 0x276F, 0x2754, 0x26A1, 0x2738, 0x2660,
    0x2666, 0x2731, 0x2693, 0x26F3, 0x263F, 0x3E, 0x21E8, 0x2737, 0x26AB,
    0x2192, 0x2736, 0x2663, 0x2753, 0x2771
) | ForEach-Object { [string][char]$_ }

$gitCommand = Get-Command git -CommandType Application -ErrorAction Ignore |
    Select-Object -First 1

$testCommand = Get-Command test -CommandType Application -ErrorAction Ignore |
    Select-Object -First 1

# LastError is the one entry each render updates.
$global:_DotfilesPrompt = @{
    Off            = Get-PromptColor '0'
    Atsign         = Get-PromptColor '90'
    HostColor      = Get-PromptColor '33'
    UserColor      = if ($isAdmin) { Get-PromptColor '91' } else { Get-PromptColor '96' }
    Prompt         = Get-PromptColor '36'
    ExitGood       = Get-PromptColor '44;33'
    ExitBad        = Get-PromptColor '41;37'
    VenvPoetry     = Get-PromptColor '95'
    VenvOk         = Get-PromptColor '92'
    VenvBad        = Get-PromptColor '31'
    DirWritable    = Get-PromptColor '32'
    DirReadOnly    = Get-PromptColor '31'
    GitNormal      = Get-PromptColor '32'
    GitUnstaged    = Get-PromptColor '33'
    GitStaged      = Get-PromptColor '31'
    GitUpstream    = Get-PromptColor '41;33'
    UserName       = [Environment]::UserName
    HostName       = [Net.Dns]::GetHostName()
    IsAdmin        = $isAdmin
    Chars          = $promptChars
    Random         = [Random]::new()
    Git            = if ($gitCommand) { $gitCommand.Source }
    Test           = if ($testCommand) { $testCommand.Source }
    PathComparison = if ($isWindowsHost) {
        [StringComparison]::OrdinalIgnoreCase
    } else {
        [StringComparison]::Ordinal
    }
    LastError      = $global:Error[0]
}

# Python's Activate.ps1 wraps whatever prompt exists to prefix the venv name,
# which would show it twice; bash never sees activate's PS1 edit because
# _update_prompt rebuilds PS1 on every render.
$env:VIRTUAL_ENV_DISABLE_PROMPT = '1'

Remove-Variable -Name isWindowsHost, isAdmin, promptChars, gitCommand,
    testCommand
Remove-Item -Path Function:Get-PromptColor

##############################################################################
# Per-render functions.

#-----------------------------------------------------------------------------
function Global:Format-PromptExitStatus {
    <#
    .SYNOPSIS
    The exit-status badge: ' 0 ' in the good colour, or the failing code
    (ERR for a cmdlet failure) in the bad one.

    .DESCRIPTION
    pwsh has no PIPESTATUS. $? says whether the last command failed, cmdlet
    or native; $LASTEXITCODE holds the last native command's code and goes
    stale across cmdlets. So a failure is a cmdlet's when it left a new
    record in $Error (a native non-zero exit adds none, unless
    $PSNativeCommandUseErrorActionPreference turns it into a
    NativeCommandExitException), and a native one's otherwise. 141 is good,
    as in bash: a pipe writer killed by SIGPIPE.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param ([bool]$Succeeded, [object]$ExitCode, [object]$LastError)

    $p = $global:_DotfilesPrompt
    $code = '0'

    if (-not $Succeeded) {
        $newError = $null -ne $LastError -and
            -not [object]::ReferenceEquals($LastError, $p.LastError)

        $nativeError = $newError -and $null -ne $LastError.Exception -and
            $LastError.Exception.GetType().Name -eq 'NativeCommandExitException'

        if (($newError -and -not $nativeError) -or
            -not ($ExitCode -is [int] -and $ExitCode -ne 0)) {
            $code = 'ERR'
        } else {
            $code = [string]$ExitCode
        }
    }

    $p.LastError = $LastError

    $color = if ($code -eq '0' -or $code -eq '141') {
        $p.ExitGood
    } else {
        $p.ExitBad
    }

    "$color $code $($p.Off)"
}

#-----------------------------------------------------------------------------
function Global:Format-PromptVenv {
    <#
    .SYNOPSIS
    lib/bash_prompt's _venv: '(venv) ' when the shell is inside the active
    venv's project, '(venv: <project>) ' in the bad colour when it is not,
    '(poetry venv) ' under poetry. Symlinks in the current path are not
    resolved, where bash's readlink -e does.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param ([string]$Path)

    $p = $global:_DotfilesPrompt

    if (-not $env:VIRTUAL_ENV -and -not $env:POETRY_ACTIVE) {
        return ''
    }

    if ($env:POETRY_ACTIVE) {
        $color = $p.VenvPoetry
        $label = 'poetry venv'

    } else {
        $project = [IO.Path]::GetDirectoryName($env:VIRTUAL_ENV)
        $color = $p.VenvOk
        $label = 'venv'

        if (-not $Path.StartsWith($project, $p.PathComparison)) {
            $color = $p.VenvBad
            $label = "venv: $project"
        }
    }

    "$color($label)$($p.Off) "
}

#-----------------------------------------------------------------------------
function Global:Format-PromptDirectory {
    <#
    .SYNOPSIS
    bin/dir-readable: the path, green when writable and red when not,
    left-truncated past $env:DIR_PWD_MAX (45) characters and marked with
    $env:DIR_PWD_TRUNC ('<'). Without a test(1) on PATH (Windows) the path
    is always shown as writable.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param ([string]$Path)

    $p = $global:_DotfilesPrompt

    $max = 45
    if (-not [int]::TryParse($env:DIR_PWD_MAX, [ref]$max)) {
        $max = 45
    }

    $trunc = if ($env:DIR_PWD_TRUNC) { $env:DIR_PWD_TRUNC } else { '<' }

    $color = $p.DirWritable

    if ($p.Test) {
        & $p.Test -w $Path

        if ($LASTEXITCODE -ne 0) {
            $color = $p.DirReadOnly
        }
    }

    $shown = $Path

    if ($shown.Length -gt $max) {
        $shown = $trunc + $shown.Substring($shown.Length - $max)
    }

    "$color$shown$($p.Off)"
}

#-----------------------------------------------------------------------------
function Global:Format-PromptGit {
    <#
    .SYNOPSIS
    bin/git-status's default form: ' (repo: branch [wt:main] PUSH {n})',
    green when clean, yellow with unstaged changes, red with staged ones;
    ' (BARE)' in a bare repository; '' outside a work tree or without git.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param ([string]$Path)

    $p = $global:_DotfilesPrompt

    if (-not $p.Git) {
        return ''
    }

    # One call answers every repository question; rev-parse prints each
    # answer in order and stops at the first it cannot give, so a bare repo
    # yields only 'true', a .git directory stops after 'false', and outside
    # a repository nothing is printed.
    $info = @(& $p.Git rev-parse --is-bare-repository --is-inside-work-tree `
        --path-format=absolute --git-dir --git-common-dir --show-toplevel `
        2> $null)

    if ($info.Count -ge 1 -and $info[0] -eq 'true') {
        return " $($p.GitUpstream)(BARE)$($p.Off)"
    }

    if ($info.Count -lt 5 -or $info[1] -ne 'true') {
        return ''
    }

    $status = @(& $p.Git --no-optional-locks status --porcelain=v2 --branch `
        --show-stash --untracked-files=no 2> $null)

    if ($LASTEXITCODE -ne 0) {
        return ''
    }

    $branch = ''
    $oid = ''
    $ahead = $false
    $behind = $false
    $staged = $false
    $unstaged = $false
    $stash = 0

    foreach ($line in $status) {
        if ($line -match '^# branch\.head (.+)$') {
            $branch = $Matches[1]

        } elseif ($line -match '^# branch\.oid (.+)$') {
            $oid = $Matches[1]

        } elseif ($line -match '^# branch\.ab \+(\d+) -(\d+)$') {
            $ahead = $Matches[1] -ne '0'
            $behind = $Matches[2] -ne '0'

        } elseif ($line -match '^# stash (\d+)$') {
            $stash = [int]$Matches[1]

        } elseif ($line -match '^[12u] (.)(.)') {
            $staged = $staged -or $Matches[1] -ne '.'
            $unstaged = $unstaged -or $Matches[2] -ne '.'
        }
    }

    # __git_ps1's detached form, which bin/git-status passes through.
    if ($branch -eq '(detached)') {
        $branch = "($($oid.Substring(0, [Math]::Min(7, $oid.Length)))...)"
    }

    $color = $p.GitNormal

    if ($staged) {
        $color = $p.GitStaged

    } elseif ($unstaged) {
        $color = $p.GitUnstaged
    }

    # PUSH wins over PULL when both apply, and .nopush in the current
    # directory hides it, as in bin/git-status.
    $upstream = ''

    if ($ahead -and -not [IO.File]::Exists([IO.Path]::Combine($Path, '.nopush'))) {
        $upstream = " $($p.GitUpstream)PUSH$($p.Off)"

    } elseif ($behind) {
        $upstream = " $($p.GitUpstream)PULL$($p.Off)"
    }

    $worktree = ''

    if ($info[2] -ne $info[3]) {
        $main = [IO.Path]::GetFileName([IO.Path]::GetDirectoryName(
            $info[3].TrimEnd('/', '\')))
        $worktree = " [wt:$main]"
    }

    $stashInfo = if ($stash -gt 0) { " {$stash}" } else { '' }

    $repo = [IO.Path]::GetFileName($info[4].TrimEnd('/', '\'))

    " $color($repo`: $branch$worktree$upstream$stashInfo)$($p.Off)"
}

#-----------------------------------------------------------------------------
function Global:prompt {
    <#
    .SYNOPSIS
    Renders the prompt; see the file header for its layout.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param ()

    # $? and $LASTEXITCODE describe the user's last command only until this
    # function runs a statement of its own, so they are read first, and
    # $LASTEXITCODE is put back at the end because git and test overwrite it.
    $succeeded = $?
    $exitCode = $global:LASTEXITCODE

    # A git or test failure inside the prompt must not land in $Error or
    # throw, whatever the session has set.
    $PSNativeCommandUseErrorActionPreference = $false
    $ErrorActionPreference = 'Continue'

    $p = $global:_DotfilesPrompt

    $status = Format-PromptExitStatus -Succeeded $succeeded `
        -ExitCode $exitCode -LastError $global:Error[0]

    $finalChar = if ($p.IsAdmin) {
        '!!'
    } else {
        $p.Chars[$p.Random.Next($p.Chars.Count)]
    }

    $location = $ExecutionContext.SessionState.Path.CurrentLocation

    $where = if ($location.Provider.Name -eq 'FileSystem') {
        $path = $location.ProviderPath

        (Format-PromptVenv -Path $path) +
        (Format-PromptDirectory -Path $path) +
        (Format-PromptGit -Path $path)
    } else {
        $location.Path
    }

    $global:LASTEXITCODE = $exitCode

    "`n$($p.Off)$($p.Prompt)$($p.UserColor)$($p.UserName)$($p.Atsign)@" +
        "$($p.HostColor)$($p.HostName): $where`n$status $finalChar "
}
