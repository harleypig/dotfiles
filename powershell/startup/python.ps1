# Python user-scripts directories (pip install --user), one per installed
# version, newest first. None exists outside Windows, so nothing is added
# there.
#
# This runs before ps-startup.ps1 prepends its own entries, which then land
# ahead of these; that block deduplicates the result.
$pythonUserBase = [IO.Path]::Combine($HOME, 'AppData', 'Roaming', 'Python')

if (Test-Path -Path $pythonUserBase -PathType Container) {
    $pythonScripts = @(
        Get-ChildItem -Path $pythonUserBase -Directory |
            Where-Object { $_.Name -match '^Python\d+$' } |
            Sort-Object -Property { [int]($_.Name -replace '\D') } -Descending |
            ForEach-Object { [IO.Path]::Combine($_.FullName, 'Scripts') } |
            Where-Object { Test-Path -Path $_ -PathType Container }
    )

    if ($pythonScripts) {
        $env:PATH = ($pythonScripts + $env:PATH) -join [IO.Path]::PathSeparator
    }
}
