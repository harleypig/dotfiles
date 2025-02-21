if (Get-Command aider -ErrorAction SilentlyContinue) {
    $envFilePath = "$env:DOTFILES\aider.env"
    if (Test-Path $envFilePath) {
        Get-Content $envFilePath | ForEach-Object {
            if ($_ -match "^(.*?)=(.*)$") {
                $envName = $matches[1]
                $envValue = $matches[2]
                $env:$envName = $envValue
            }
        }
    }

    $env:AIDER_EDITOR = "code --wait"
}
