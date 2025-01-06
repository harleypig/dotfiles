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
  Set-Variable -Name OPENAI_API_KEY `
    -Scope Global `
    -Option Constant `
    -Value (Get-Content -Path "$private_dotfiles/api-key.openai" -Raw)
}

#-----------------------------------------------------------------------------
if (Test-Path "$private_dotfiles/api-key.linode") {
  Set-Variable -Name LINODE_TOKEN `
    -Scope Global `
    -Option Constant `
    -Value (Get-Content -Path "$private_dotfiles/api-key.linode" -Raw)
}

#-----------------------------------------------------------------------------
# Vault

# Convert the env variables in this section the same way please AI!
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
