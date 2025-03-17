#!/usr/bin/env python3

import os
import sys
import json
import argparse
import hvac
import re
from pathlib import Path

#-----------------------------------------------------------------------------
# Setup and Sanity
CACHE_DIR = os.environ.get('XDG_CACHE_HOME', os.path.expanduser('~/.cache'))
VAULT_PATHS_FILENAME = 'vault-paths.json'


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
    # Ensure client is set
    self.set_vault_client()

    if root_paths is None:
      raise ValueError("root_paths cannot be None")

    print("Discovering vault paths...")

    # Initialize the structure
    vault_data = {}

    # Helper function to recursively discover paths
    def discover_recursive(path, structure):
      try:
        response = self._list_secrets(path=path)

        if not response or 'data' not in response or 'keys' not in response['data']:
          return

        keys = response['data']['keys']

        # Clear the line and print the current path
        print(f"\r\033[K", end="")  # ANSI escape code to clear the line
        print(f"Discovering: {path}", end="", flush=True)

        # Process each key from list_secrets
        for key in keys:
          # If key ends with /, it's a directory
          if key.endswith('/'):
            dir_name = key[:-1]
            
            # Ensure __directories__ exists
            if "__directories__" not in structure:
              structure["__directories__"] = {}
              
            # Create directory entry if it doesn't exist
            if dir_name not in structure["__directories__"]:
              structure["__directories__"][dir_name] = {}
              
            # Recursively discover
            subpath = f"{path}/{dir_name}" if path else dir_name
            discover_recursive(subpath, structure["__directories__"][dir_name])
          else:
            # It's a secret key - get its contents with read_secret
            secret_path = f"{path}/{key}" if path else key
            response = self._read_secret(path=secret_path)
            
            if response and 'data' in response:
              # Extract key names from the secret
              if isinstance(response['data'], dict):
                key_names = list(response['data'].keys())
              else:
                key_names = response['data']
                
              # Add to __keys__ if we found any
              if key_names:
                if "__keys__" not in structure:
                  structure["__keys__"] = []
                  
                # Add any new keys that aren't already in the list
                for key_name in key_names:
                  if key_name not in structure["__keys__"]:
                    structure["__keys__"].append(key_name)

      except Exception as e:
        raise VaultKeyError(f"Error listing {path}: {str(e)}")

    # Start discovery from root paths
    for root_path in root_paths:
      vault_data[root_path] = {}
      discover_recursive(root_path, vault_data[root_path])

    # Save to file
    vault_paths_file = os.path.join(self.cache_dir, self.vault_paths_filename)
    os.makedirs(os.path.dirname(vault_paths_file), exist_ok=True)

    with open(vault_paths_file, 'w') as f:
      json.dump(vault_data, f, indent=2)

    # Print a newline first to move to a new line after the last status update
    print(f"\nVault paths saved to {vault_paths_file}")

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
        elif "__directories__" in current and part in current["__directories__"]:
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
        elif "__directories__" in current and part in current["__directories__"]:
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


#-----------------------------------------------------------------------------
def warn(message):
  """Print a warning message to stderr."""
  print(message, file=sys.stderr)


#-----------------------------------------------------------------------------
def die(message=None, exit_code=1):
  """Print an error message and exit with the specified code (default 1)."""
  if message is not None:
    warn(message)

  sys.exit(exit_code)


#-----------------------------------------------------------------------------
def select_from_list(items, prompt="Select an option", cancel_option=True):
  """
    Display a list of choices and allow the user to select one.

    Args:
        items: List of items to choose from
        prompt: Prompt to display to the user
        cancel_option: Whether to include a cancel option

    Returns:
        The selected item, or None if cancelled
    """
  if not items:
    return None

  if len(items) == 1:
    return items[0]

  print(f"{prompt}:")
  for i, item in enumerate(items, 1):
    print(f"  {i}) {item}")

  if cancel_option:
    print("  0) Cancel")

  while True:
    try:
      choice = input(f"{prompt} (0-{len(items)}): ")

      if choice == "0" and cancel_option:
        return None

      choice = int(choice)

      if 1 <= choice <= len(items):
        return items[choice - 1]

      else:
        print(
          f"Invalid selection. Please enter a number between {0 if cancel_option else 1} and {len(items)}."
        )

    except ValueError:
      print("Please enter a number.")


#-----------------------------------------------------------------------------
def parseargs(showhelp=False):
  """
    Parse command line arguments and return the parsed arguments.

    Args:
        showhelp: If True, print help and exit instead of parsing arguments
    """
  #-------------------------------------------------------------------------
  # Create a parent parser for common options
  parent_parser = argparse.ArgumentParser(add_help=False)

  # Add global options to the parent parser
  parent_parser.add_argument(
    '--cache-dir',
    default=os.environ.get('VAULT_CACHE_DIR', CACHE_DIR),
    help=f'Directory to store vault paths file (default: {CACHE_DIR})')

  parent_parser.add_argument(
    '--paths-file',
    default=os.environ.get('VAULT_PATHS_FILENAME', VAULT_PATHS_FILENAME),
    help=f'Name of the vault paths file (default: {VAULT_PATHS_FILENAME})')

  parent_parser.add_argument(
    '--vault-addr',
    default=os.environ.get('VAULT_ADDR'),
    help='Vault server address (default: from VAULT_ADDR environment variable)'
  )

  #-------------------------------------------------------------------------
  # Create the main parser that will display in the top-level help
  parser = argparse.ArgumentParser(description="Get Vault key value utility")

  subparsers = parser.add_subparsers(
    dest='command', title='Possible commands', help='Command to execute')

  #-------------------------------------------------------------------------
  # discover command
  discover_parser = subparsers.add_parser(
    'discover',
    parents=[parent_parser],
    help='Discover all vault paths and secrets')

  discover_parser.add_argument(
    '--root-paths',
    nargs='+',
    metavar='<root path>',
    help='Root paths to start discovery from')

  #-------------------------------------------------------------------------
  # list command
  list_parser = subparsers.add_parser(
    'list', parents=[parent_parser], help='List secrets at a path')

  list_parser.add_argument('path', help='Path to list secrets from')
  list_parser.add_argument(
    '--regex', '-r', action='store_true', help='Treat path as a regex pattern')

  #-------------------------------------------------------------------------
  # get command
  get_parser = subparsers.add_parser(
    'get', parents=[parent_parser], help='Get a specific secret value')

  get_parser.add_argument('path', help='Path to the secret')
  get_parser.add_argument('secret', help='Name of the secret to retrieve')
  get_parser.add_argument(
    '--regex', '-r', action='store_true', help='Treat path as a regex pattern')

  #-------------------------------------------------------------------------
  if showhelp:
    parser.print_help()
    sys.exit(0)

  return parser.parse_args()


#-----------------------------------------------------------------------------
def main():
  args = parseargs(showhelp=len(sys.argv) <= 1)

  #  # Debug code to dump args and exit
  #  print("DEBUG: Command line arguments:")
  #  print(json.dumps(vars(args), indent=2))
  #  sys.exit(0)

  # Create manager instance
  manager = VaultKeyManager(
    cache_dir=args.cache_dir,
    vault_paths_filename=args.paths_file,
    vault_addr=args.vault_addr)

  if args.command == 'discover':
    try:
      # Check if root_paths is provided
      if not hasattr(args, 'root_paths') or not args.root_paths:
        die("Error: --root-paths is required for the discover command")

      # Set vault client with provided address
      manager.discover_paths(args.root_paths)

    except (VaultKeyError, ValueError) as e:
      die(str(e))

  elif args.command == 'list' or args.command == 'get':
    try:
      matches = manager.find_matching_paths(
        args.path, use_regex=args.regex if hasattr(args, 'regex') else False)

      if not matches:
        die(f"No matching paths found for '{args.path}'")

      selected_path = manager.select_path(matches)

      # Execute command
      if args.command == 'list':
        manager.list_secrets(selected_path)

      elif args.command == 'get':
        manager.get_secret(selected_path, args.secret)

    except VaultKeyError as e:
      die(str(e))

  else:
    # Show help for invalid command
    parseargs(showhelp=True)
    sys.exit(1)


#-----------------------------------------------------------------------------
if __name__ == "__main__":
  main()
