# proj: jump to a project directory under $PROJECTS_DIR. A function, not a
# script in powershell/bin, because only the caller's own session can change
# its location. Port of bin/proj plus the proj() wrapper in
# config/shell-startup/010-general.

if (-not $DOTFILES_INTERACTIVE) {
    return
}

#-----------------------------------------------------------------------------
function Global:proj {
    <#
    .SYNOPSIS
    Changes to $PROJECTS_DIR, or to $PROJECTS_DIR/<Name>.

    .DESCRIPTION
    With no name, goes to $PROJECTS_DIR. With a name, goes to that directory
    if it exists; if not, asks whether to create it (1), go to $PROJECTS_DIR
    instead (2), or cancel (3). Any other answer asks again; end of input
    cancels.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Position = 0)]
        [string]$Name
    )

    if (-not $env:PROJECTS_DIR) {
        Write-Error 'proj: PROJECTS_DIR is not set'
        return
    }

    if (-not $Name) {
        Set-Location -LiteralPath $env:PROJECTS_DIR
        return
    }

    $target = Join-Path -Path $env:PROJECTS_DIR -ChildPath $Name

    if (Test-Path -LiteralPath $target -PathType Container) {
        Set-Location -LiteralPath $target
        return
    }

    Write-Host "1) Create $target"
    Write-Host "2) Go to $env:PROJECTS_DIR"
    Write-Host '3) Cancel'

    while ($true) {
        $choice = Read-Host -Prompt "'$Name' not found. Choose"

        # $null is end of input; looping on it would never end.
        if ($null -eq $choice -or $choice -eq '3') {
            return
        }

        if ($choice -eq '1') {
            New-Item -ItemType Directory -Path $target -Force | Out-Null
            Set-Location -LiteralPath $target
            return
        }

        if ($choice -eq '2') {
            Set-Location -LiteralPath $env:PROJECTS_DIR
            return
        }
    }
}
