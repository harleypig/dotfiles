$private_dotfiles = "$PROJECTS_DIR/private_dotfiles"

#-----------------------------------------------------------------------------
if (Test-Path "$private_dotfiles/api-key.azure") {
  Set-Variable -Name AZURE_DEVOPS_EXT_PAT `
    -Scope Global `
    -Option Constant `
    -Value (Get-Content -Path "$private_dotfiles/api-key.azure" -Raw)
  }

#-----------------------------------------------------------------------------
if (Get-Command aider -ErrorAction SilentlyContinue) {
  if (Test-Path "$private_dotfiles/api-key.openai") {
    Set-Variable -Name OPENAI_API_KEY `
      -Scope Global `
      -Option Constant `
      -Value ((Get-Content -Path "$private_dotfiles/api-key.openai" -Raw).Trim())

    $env:OPENAI_API_KEY = $OPENAI_API_KEY
  }
}

#-----------------------------------------------------------------------------
if (Test-Path "$private_dotfiles/api-key.linode") {
  Set-Variable -Name LINODE_TOKEN `
    -Scope Global `
    -Option Constant `
    -Value (Get-Content -Path "$private_dotfiles/api-key.linode" -Raw)
}

#-----------------------------------------------------------------------------
if (Test-Path "$private_dotfiles/api-key.grok") {
  Set-Variable -Name XAI_API_KEY `
    -Scope Global `
    -Option Constant `
    -Value (Get-Content -Path "$private_dotfiles/api-key.grok" -Raw)
}

#-----------------------------------------------------------------------------
# Vault

if (Get-Command vault -ErrorAction SilentlyContinue) {
  if (Test-Path "$private_dotfiles/vault.addr") {
    Set-Variable -Name VAULT_ADDR `
      -Scope Global `
      -Option Constant `
      -Value (Get-Content -Path "$private_dotfiles/vault.addr" -Raw)
  }

  if (Test-Path "$private_dotfiles/pass.ldap") {
    Set-Variable -Name LDAP_PASS `
      -Scope Global `
      -Option Constant `
      -Value (Get-Content -Path "$private_dotfiles/pass.ldap" -Raw)
  }
}

#-----------------------------------------------------------------------------
Remove-Variable -Name private_dotfiles
