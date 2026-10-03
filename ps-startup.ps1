# Declare and initialize variables, making some of them dual purpose
$scriptPath = $MyInvocation.MyCommand.Path

Set-Variable -Name DOTFILES `
  -Scope Global `
  -Option Constant `
  -Value (Split-Path -Parent (Resolve-Path -Path $scriptPath))

$env:DOTFILES = $DOTFILES

Set-Variable -Name PROJECTS_DIR `
  -Scope Global `
  -Option Constant `
  -Value (Split-Path -Parent $DOTFILES)

$env:PROJECTS_DIR = $PROJECTS_DIR

#-----------------------------------------------------------------------------
# A non-interactive pwsh (-File, -Command, a script path, piped stdin) still
# loads this profile, so a module holding interactive-only setup (aliases,
# functions, prompt, PSReadLine) starts with
#   if (-not $DOTFILES_INTERACTIVE) { return }
# the analogue of bash's [[ $- == *i* ]] || return 0. Everything else must
# stay cheap and side-effect free: environment only.

function Test-InteractiveSession {
    <#
    .SYNOPSIS
    Reports whether this pwsh session will sit at an interactive prompt.

    .DESCRIPTION
    [Environment]::UserInteractive cannot make this call: it is true for any
    process outside a Windows service, pwsh -File on Linux included, and no
    public API exposes the host's own decision. So this applies bash's test
    to pwsh's command line -- interactive when no command or script is given
    (or -NoExit precedes it), -NonInteractive is absent, and stdin is not
    redirected.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param ()

    function Test-Switch {
        <#
        .SYNOPSIS
        Matches a pwsh switch name, stripped of its dashes, against
        'fullname:shortest' forms. pwsh accepts any prefix of the full name
        at least as long as the shortest documented form (about_Pwsh); a
        form without ':' is an exact-only alias.
        #>
        [OutputType([bool])]
        param ([string]$Name, [string[]]$Forms)

        foreach ($form in $Forms) {
            $full, $shortest = $form -split ':'

            if ($Name -eq $full -or
                ($shortest -and $Name.Length -ge $shortest.Length -and
                 $full.StartsWith($Name))) {
                return $true
            }
        }

        return $false
    }

    $payloadForms = 'command:c', 'cwa', 'encodedcommand:e', 'ec', 'file:f'

    $valueForms = 'configurationname:config', 'configurationfile',
                  'custompipename', 'executionpolicy:ex', 'ep',
                  'inputformat:inp', 'if', 'outputformat:o', 'of',
                  'settingsfile:settings', 'windowstyle:w',
                  'workingdirectory:wo', 'wd'

    # '/' introduces a switch only on Windows; elsewhere it starts a path.
    $switchPrefix = if ([IO.Path]::DirectorySeparatorChar -eq '\') {
        '^(--?|/)'
    } else {
        '^--?'
    }

    $cliArgs = [Environment]::GetCommandLineArgs()
    $noExit = $false
    $nonInteractive = $false
    $runsPayload = $false

    for ($i = 1; $i -lt $cliArgs.Count; $i++) {
        $arg = $cliArgs[$i]

        if ($arg -notmatch $switchPrefix) {
            # A bare argument is the script path; the rest belongs to it.
            $runsPayload = $true
            break
        }

        $name = ($arg -replace $switchPrefix, '').ToLowerInvariant()

        if (Test-Switch -Name $name -Forms $payloadForms) {
            # '-' reads commands from stdin, which the stdin test decides.
            $runsPayload = ($i + 1 -lt $cliArgs.Count) -and
                           ($cliArgs[$i + 1] -ne '-')
            break

        } elseif (Test-Switch -Name $name -Forms 'noexit:noe') {
            $noExit = $true

        } elseif (Test-Switch -Name $name -Forms 'noninteractive:noni') {
            $nonInteractive = $true

        } elseif (Test-Switch -Name $name -Forms $valueForms) {
            $i++
        }
    }

    -not $nonInteractive -and
        (-not $runsPayload -or $noExit) -and
        -not [Console]::IsInputRedirected
}

Set-Variable -Name DOTFILES_INTERACTIVE `
  -Scope Global `
  -Option ReadOnly `
  -Force `
  -Value (Test-InteractiveSession)

#-----------------------------------------------------------------------------

function Import-Files {
    # Define the directories to load files from
    $loadDirs = @(
        Join-Path $DOTFILES "powershell/startup"
        Join-Path $HOME ".psshell_startup_hooks.d"
    )

    # Iterate over each directory separately to ensure files are loaded in
    # the order of the directories.
    foreach ($loadDir in $loadDirs) {
        if (Test-Path -Path $loadDir) {
            $loadFiles = Get-ChildItem -Path $loadDir -File `
                         | Where-Object { $_.Name -and $_.Extension -eq '.ps1' } `
                         | Sort-Object Name

            foreach ($file in $loadFiles) {
                if (Test-Path -Path $file.FullName -PathType Leaf) {
                  . $file.FullName
                }
            }
        }
    }
}

# Call the function to load the files
Import-Files

# We want this to be after all the other files are loaded because these paths
# take precedence.
# XXX: Move python path to dedicated python setup file
# Built with the platform's own separators so the same file works under
# Windows and Linux pwsh, then deduplicated keeping the first occurrence so
# these prepended entries win. Windows paths are case-insensitive, so dedup
# there ignores case.
$pathEntries = @(
    [IO.Path]::Combine($DOTFILES, 'powershell', 'bin')
    [IO.Path]::Combine($HOME, '.local', 'bin')
    [IO.Path]::Combine($HOME, 'AppData', 'Roaming', 'Python', 'Python312', 'Scripts')
) + ($env:PATH -split [IO.Path]::PathSeparator)

$pathComparer = if ([IO.Path]::DirectorySeparatorChar -eq '\') {
    [StringComparer]::OrdinalIgnoreCase
} else {
    [StringComparer]::Ordinal
}

$pathSeen = [Collections.Generic.HashSet[string]]::new($pathComparer)

$env:PATH = ($pathEntries | Where-Object { $_ -and $pathSeen.Add($_) }) `
            -join [IO.Path]::PathSeparator

# Remove work or scratch variables and functions from the environment
Remove-Variable -Name scriptPath, pathEntries, pathComparer, pathSeen
Remove-Item -Path Function:Import-Files, Function:Test-InteractiveSession

#-----------------------------------------------------------------------------
if ($DOTFILES_INTERACTIVE) {
    function s3cmd {
        $venvPath = "$HOME\pipx\venvs\s3cmd\Scripts"
        $activateScript = Join-Path -Path $venvPath -ChildPath "Activate.ps1"

        try {
            # Activate the virtual environment
            Invoke-Expression "& $activateScript"

            # Run s3cmd with all provided arguments
            $arguments = "$HOME\.local\bin\s3cmd " + ($args -join ' ')
            Start-Process -FilePath "python" -ArgumentList $arguments -NoNewWindow -Wait
        } finally {
            # Deactivate the virtual environment to clean up
            if (Test-Path function:deactivate) {
                Invoke-Expression "& deactivate"
            }
        }
    }
}

#-----------------------------------------------------------------------------
# TBD:

# Depends on PSReadline
# export INPUTRC="$XDG_CONFIG_HOME/readline/inputrc"

# export EDITOR=code
