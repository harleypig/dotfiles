if (Get-Command aider -ErrorAction SilentlyContinue) {
    # The path to aider.env is $DOTFILES/aider.env, AI!
    $envFilePath = "C:\path\to\aider.env"
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
