#!/usr/bin/env python3

"""Exception classes for the get_vault_key package."""

#-----------------------------------------------------------------------------
# Custom exceptions
class VaultKeyError(Exception):
  """Base exception for VaultKeyManager errors."""
  pass


class VaultPathNotFoundError(VaultKeyError):
  """Exception raised when a vault path is not found."""
  pass


class VaultAuthenticationError(VaultKeyError):
  """Exception raised when vault authentication fails."""
  pass


class VaultSecretNotFoundError(VaultKeyError):
  """Exception raised when a secret is not found."""
  pass
