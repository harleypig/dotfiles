# Modify the Get-InstalledModule line to keep the user informed.
# * Each message should appear on the same line, with the final message "All modules updated." being the only line seen.

Get-InstalledModule | ForEach-Object {
  Update-Module -Name $_.Name
}

# Update all installed scripts
Get-InstalledScript | ForEach-Object {
  Update-Script -Name $_.Name
}
