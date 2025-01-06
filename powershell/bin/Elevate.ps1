param (
    [Parameter(Mandatory=$true, Position=0, ValueFromRemainingArguments=$true)]
    [string[]]$Command
)

$commandString = $Command -join ' '
Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -Command `$commandString"
