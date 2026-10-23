# Always loaded, interactive or not: a trace helper is environment-level, and
# startup modules sort after this one so they can call it. Named 000-debug so
# it sorts ahead of 000-loadtokens.

#-----------------------------------------------------------------------------
function Global:Write-DebugTrace {
    <#
    .SYNOPSIS
    Writes a call-stack-prefixed trace line to stderr when $env:DEBUG is a
    non-zero integer; otherwise does nothing.

    .DESCRIPTION
    The PowerShell counterpart of lib/debug's debug(). DEBUG is read as bash's
    ((DEBUG)) reads it, so 1 enables and 0, empty or a word does not. Each
    message line is written to the process's stderr as

        [I+12ms][file:func:042][file:017] message

    I or i is whether the session is interactive, +Nms is the time since the
    previous call (+0ms on the first), and each [file:func:line] is a caller,
    outermost first. $env:DBG_TRACE_LEN caps the number of callers shown
    (default 3).

    Output bypasses PowerShell's streams on purpose: the host renders
    Write-Debug and Write-Information on stdout under pwsh -File, which would
    mix the trace into a script's output.

    .EXAMPLE
    debug "loading tokens"

    .EXAMPLE
    git status --short | debug
    #>
    # The previous call's timestamp must outlive every caller's scope, as
    # bash's _DBG_LAST_US does; $script: would follow whichever script
    # called last.
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSAvoidGlobalVars', '',
        Justification = 'Timestamp shared across all callers')]
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, ValueFromPipeline,
                   ValueFromRemainingArguments)]
        [object[]]$Message
    )

    begin {
        $level = 0
        $enabled = [int]::TryParse($env:DEBUG, [ref]$level) -and $level -ne 0

        if (-not $enabled) {
            return
        }

        $now = [Diagnostics.Stopwatch]::GetTimestamp()
        $deltaMs = 0

        if ($null -ne $global:_DBG_LAST_TS) {
            $deltaMs = [long](($now - $global:_DBG_LAST_TS) * 1000 /
                              [Diagnostics.Stopwatch]::Frequency)
        }

        $global:_DBG_LAST_TS = $now

        $traceLen = 3
        if (-not [int]::TryParse($env:DBG_TRACE_LEN, [ref]$traceLen)) {
            $traceLen = 3
        }

        # Frame 0 is this function. <ScriptBlock> is a script's top level, the
        # counterpart of the main/source frames bash's version leaves unnamed.
        $frames = @(Get-PSCallStack | Select-Object -Skip 1 -First $traceLen)
        [array]::Reverse($frames)

        $trace = foreach ($frame in $frames) {
            $file = if ($frame.ScriptName) {
                (Split-Path -Leaf $frame.ScriptName) + ':'
            }

            $func = if ($frame.FunctionName -ne '<ScriptBlock>') {
                $frame.FunctionName + ':'
            }

            '[{0}{1}{2:d3}]' -f $file, $func, $frame.ScriptLineNumber
        }

        $mode = if ($DOTFILES_INTERACTIVE) { 'I' } else { 'i' }
        $prefix = "[$mode+${deltaMs}ms]$($trace -join '') "
    }

    process {
        if (-not $enabled) {
            return
        }

        foreach ($line in $Message) {
            [Console]::Error.WriteLine($prefix + $line)
        }
    }
}

Set-Alias -Name debug -Value Write-DebugTrace -Scope Global
