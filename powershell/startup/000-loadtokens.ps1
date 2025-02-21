$private_dotfiles = "$PROJECTS_DIR/private_dotfiles/api-key"
$config_file = "$DOTFILES/api-keys.cfg"

if (Test-Path $private_dotfiles -and Test-Path $config_file) {
  $config_lines = Get-Content -Path $config_file

  foreach ($line in $config_lines) {
    if ($line -match "^(?<varName>[^=]+)=(?<fileName>.+)$") {
      $varName = $matches['varName']
      $fileName = $matches['fileName']
      $filePath = Join-Path -Path $private_dotfiles -ChildPath $fileName

      if (Test-Path $filePath) {
        $value = (Get-Content -Path $filePath -Raw).Trim()
        $env:$varName = $value
      }
    }
  }
}

Remove-Variable -Name private_dotfiles, config_file
