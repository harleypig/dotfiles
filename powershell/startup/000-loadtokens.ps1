$private_dotfiles = "$PROJECTS_DIR/private_dotfiles"

#-----------------------------------------------------------------------------
if (Test-Path "$private_dotfiles/api-key.azure") {
  Set-Variable -Name AZURE_DEVOPS_EXT_PAT `
    -Scope Global `
    -Option Constant `
    -Value (Get-Content -Path "$private_dotfiles/api-key.azure" -Raw)
}

#-----------------------------------------------------------------------------
if (Test-Path "$private_dotfiles/api-key.openai") {
  # Convert this variable the same way aI!
  $env:OPENAI_API_KEY = Get-Content -Path "$private_dotfiles/api-key.openai" -Raw
}

#-----------------------------------------------------------------------------
if (Test-Path "$private_dotfiles/api-key.linode") {
  $env:LINODE_TOKEN = Get-Content -Path "$private_dotfiles/api-key.linode" -Raw
}

#-----------------------------------------------------------------------------
# Vault

if (Get-Command vault -ErrorAction SilentlyContinue) {
  if (Test-Path "$private_dotfiles/vault.addr") {
    $env:VAULT_ADDR = Get-Content -Path "$private_dotfiles/vault.addr" -Raw
  }

  if (Test-Path "$private_dotfiles/pass.ldap") {
    $env:LDAP_PASS = Get-Content -Path "$private_dotfiles/pass.ldap" -Raw
  }
}

#-----------------------------------------------------------------------------
Remove-Variable -Name private_dotfiles
