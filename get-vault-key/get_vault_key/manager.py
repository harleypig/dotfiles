#!/usr/bin/env python3

"""VaultKeyManager class for managing Vault keys and paths."""

import os
import sys
import json
import re
import hvac
from .exceptions import (
    VaultKeyError,
    VaultPathNotFoundError,
    VaultAuthenticationError,
    VaultSecretNotFoundError
)


#-----------------------------------------------------------------------------
class VaultKeyManager:
  """Class to manage Vault keys and paths."""

  #-------------------------------------------------------------------------
  def __init__(
      self, cache_dir=None, vault_paths_filename=None, vault_addr=None):
    """
        Initialize the VaultKeyManager and load vault paths if available.

        Args:
            cache_dir: Directory to store vault paths file (default: from environment)
            vault_paths_filename: Name of the vault paths file (default: from environment)
            vault_addr: Vault server address (default: from environment)
        """
    if cache_dir is None:
      raise ValueError("cache_dir cannot be None")

    if vault_paths_filename is None:
      raise ValueError("vault_paths_filename cannot be None")

    self.cache_dir = cache_dir
    self.vault_addr = vault_addr
    self.vault_data = None
    self.vault_paths_filename = vault_paths_filename

    try:
      self.vault_data = self.load_vault_paths()

    except VaultPathNotFoundError:
      # It's okay if the file doesn't exist yet
      pass

    except VaultKeyError:
      # Re-raise the exception for the caller to handle
      raise

  #-------------------------------------------------------------------------
  def load_vault_paths(self):
    """Load the vault paths from the JSON file."""
    vault_paths_file = os.path.join(self.cache_dir, self.vault_paths_filename)

    try:
      with open(vault_paths_file, 'r') as f:
        return json.load(f)

    except FileNotFoundError:
      raise VaultPathNotFoundError(
        f"Vault paths file not found at {vault_paths_file}. Run '{sys.argv[0]} discover' first."
      )

    except json.JSONDecodeError as e:
      raise VaultKeyError(
        f"Error parsing vault paths file ({vault_paths_file}). The file may be corrupted: {str(e)}"
      )

    except Exception as e:
      raise VaultKeyError(f"Error loading vault paths: {str(e)}")

  #-------------------------------------------------------------------------
  def set_vault_client(self):
    """Set up and configure the vault client if not already set."""

    # If client is already set, just return
    if hasattr(self, 'client') and self.client is not None:
      return

    # Check if VAULT_TOKEN is set
    token = os.environ.get('VAULT_TOKEN')

    if not token:
      raise VaultAuthenticationError(
        "Vault token is not set. Run 'source set-vault-token' and try again.")

    if self.vault_addr is None:
      raise VaultAuthenticationError("Vault address is not set.")

    # Create the client
    try:
      self.client = hvac.Client(url=self.vault_addr, token=token)

      if not self.client.is_authenticated():
        raise VaultAuthenticationError(
          "Vault authentication failed. Check your token and try again.")

    except VaultAuthenticationError:
      raise

    except Exception as e:
      raise VaultKeyError(f"Error connecting to Vault: {str(e)}")

  #-------------------------------------------------------------------------
  def _list_secrets(self, path, mount_point=''):
    return self.client.secrets.kv.v1.list_secrets(
      path=path, mount_point=mount_point)

  #-------------------------------------------------------------------------
  def _read_secret(self, path, mount_point=''):
    return self.client.secrets.kv.v1.read_secret(
      path=path, mount_point=mount_point)

  #-------------------------------------------------------------------------
  def discover_paths(self, root_paths):
    """
        Discover all paths and secrets in Vault and save to a file.

        Args:
            root_paths: List of root paths to start discovery from
        """
    self.set_vault_client()

    if root_paths is None:
      raise ValueError("root_paths cannot be None")

    vault_data = {}

    # Helper function to recursively discover paths
    def discover_recursive(path, structure):
      try:
        response = self._list_secrets(path=path)

        if not response or 'data' not in response or 'keys' not in response[
            'data']:
          return

        keys = response['data']['keys']

        # Clear the line and print the current path
        print(f"\r\033[K", end="")  # ANSI escape code to clear the line
        print(f"Discovering: {path}", end="", flush=True)

        for key in keys:
          # If key ends with /, it's a directory
          if key.endswith('/'):
            dir_name = key[:-1]

            if "__directories__" not in structure:
              structure["__directories__"] = {}

            if dir_name not in structure["__directories__"]:
              structure["__directories__"][dir_name] = {}

            subpath = f"{path}/{dir_name}" if path else dir_name
            discover_recursive(subpath, structure["__directories__"][dir_name])

          else:
            secret_path = f"{path}/{key}" if path else key
            response = self._read_secret(path=secret_path)

            if response and 'data' in response:
              if isinstance(response['data'], dict):
                key_names = list(response['data'].keys())

                if key_names:
                  if "__directories__" not in structure:
                    structure["__directories__"] = {}

                  structure["__directories__"][key] = {"__keys__": key_names}

              else:
                raise VaultKeyError(
                  f"Didn't understand {secret_path} response: {response}")

      except Exception as e:
        raise VaultKeyError(f"Error listing {path}: {str(e)}")

    for root_path in root_paths:
      vault_data[root_path] = {}
      discover_recursive(root_path, vault_data[root_path])

    vault_paths_file = os.path.join(self.cache_dir, self.vault_paths_filename)
    os.makedirs(os.path.dirname(vault_paths_file), exist_ok=True)

    with open(vault_paths_file, 'w') as f:
      json.dump(vault_data, f)

    # Clear the line and print the location of the save file
    print(f"\r\033[K", end="")  # ANSI escape code to clear the line
    print(f"Vault paths saved to {vault_paths_file}")

  #-------------------------------------------------------------------------
  def find_matching_paths(self, search_path, use_regex=False):
    """
    Find all paths that match the search pattern.

    Args:
        search_path: The path pattern to search for
        use_regex: If True, treat search_path as a regex pattern

    Returns:
        List of matching paths
    """
    if self.vault_data is None:
      self.vault_data = self.load_vault_paths()

    matches = []

    # Compile regex pattern if using regex
    pattern = None

    if use_regex:
      try:
        pattern = re.compile(search_path, re.IGNORECASE)

      except re.error as e:
        raise VaultKeyError(f"Invalid regex pattern: {str(e)}")

    else:
      # For non-regex searches, convert to lowercase once
      search_lower = search_path.lower()

    # Lazily initialize the all_paths cache
    if not hasattr(self, '_all_paths_cache') or self._all_paths_cache is None:
      self._all_paths_cache = self._get_all_paths(self.vault_data)

    # Filter paths that could potentially match
    candidate_paths = []

    for path in self._all_paths_cache:
      if use_regex:
        # For regex, we can do a quick substring check if the pattern contains literal text
        literals = self._extract_literals_from_regex(search_path)

        if literals and not any(lit.lower() in path.lower()
                                for lit in literals):
          continue  # Skip if none of the literal parts are in the path

      else:
        # For non-regex, simple substring check
        if search_lower not in path.lower():
          continue

      candidate_paths.append(path)

    # Now do the actual matching on the filtered candidates
    for path in candidate_paths:
      if use_regex:
        if pattern.search(path):
          matches.append(path)

      else:
        # Already know it contains the substring
        matches.append(path)

    return matches

  #-------------------------------------------------------------------------
  def _get_all_paths(self, structure):
    """Get a flat list of all paths in the structure."""
    all_paths = []

    def collect_paths(current_path, struct, prefix=""):
      full_path = prefix + current_path

      # Check if this node has any direct keys
      if "__keys__" in struct:
        all_paths.append(full_path)

      # Process nested directories
      if "__directories__" in struct:
        for dir_name, dir_value in struct["__directories__"].items():
          new_prefix = full_path + "/" if current_path else prefix
          collect_paths(dir_name, dir_value, new_prefix)

    for root_key, root_value in structure.items():
      collect_paths(root_key, root_value)

    return all_paths

  #-------------------------------------------------------------------------
  def _extract_literals_from_regex(self, regex_pattern):
    """Extract literal substrings from a regex pattern."""
    # This is a simplified implementation
    # A more robust version would handle more regex features
    literals = []
    current = ""

    for char in regex_pattern:
      if char in "\\^$.|?*+()[{":
        if current:
          literals.append(current)
          current = ""

      else:
        current += char

    if current:
      literals.append(current)

    return [
      lit for lit in literals if len(lit) > 2
    ]  # Only return substantial literals

  #-------------------------------------------------------------------------
  def select_path(self, matches):
    """Let the user select a path if multiple matches are found."""
    from .utils import select_from_list, die
    
    selected = select_from_list(matches, prompt="Select a path")

    if selected is None:
      die("Operation cancelled by user")

    return selected

  #-------------------------------------------------------------------------
  def list_secrets(self, path):
    """List all secrets at the specified path."""
    # Ensure client is set
    self.set_vault_client()

    try:
      print(f"Listing secrets in {path}:")

      # For mock data, we'll extract from our vault_data structure
      if self.vault_data is None:
        self.vault_data = self.load_vault_paths()

      # Navigate to the path in the structure
      current = self.vault_data
      path_parts = path.split('/')

      for part in path_parts:
        if part in current:
          current = current[part]
        elif "__directories__" in current and part in current[
            "__directories__"]:
          current = current["__directories__"][part]
        else:
          raise VaultKeyError(f"Path part '{part}' not found in '{path}'")

      # List all keys at this path
      if "__keys__" in current:
        for key in current["__keys__"]:
          print(key)
      else:
        print("No secrets found at this path.")

      # If there are directories, list them too
      if "__directories__" in current and current["__directories__"]:
        print("\nSubdirectories:")
        for dir_name in current["__directories__"].keys():
          print(f"{dir_name}/")

    except Exception as e:
      raise VaultKeyError(f"Error listing secrets at {path}: {str(e)}")

  #-------------------------------------------------------------------------
  def get_secret(self, path, secret_name):
    """Get the value of a specific secret."""
    # Ensure client is set
    self.set_vault_client()

    try:
      # For mock data, we'll extract from our vault_data structure
      if self.vault_data is None:
        self.vault_data = self.load_vault_paths()

      # Navigate to the path in the structure
      current = self.vault_data
      path_parts = path.split('/')

      for part in path_parts:
        if part in current:
          current = current[part]
        elif "__directories__" in current and part in current[
            "__directories__"]:
          current = current["__directories__"][part]
        else:
          raise VaultKeyError(f"Path part '{part}' not found in '{path}'")

      # Check if the secret exists in the keys list
      if "__keys__" in current and secret_name in current["__keys__"]:
        # In a real implementation, we would fetch the actual secret value here
        # For mock data, we'll just return a placeholder
        result = {
          secret_name: "mock_value",
          "description": "mock_description",
          "path": path
        }
        print(json.dumps(result, indent=2))
      else:
        raise VaultSecretNotFoundError(
          f"Secret '{secret_name}' not found in path '{path}'")

    except VaultKeyError:
      raise

    except Exception as e:
      raise VaultKeyError(f"Error getting secret from {path}: {str(e)}")
