param (
    [Parameter(Mandatory=$true, Position=0)]
    [string]$Command
)

Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -Command `$Command"
