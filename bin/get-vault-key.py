#!/usr/bin/env python3

import os
import sys
import json
import argparse
import hvac
from pathlib import Path

# TODO:
# * add option to set cache filename
# * add option to set cache directory

#-----------------------------------------------------------------------------
# Setup and Sanity
CACHE_DIR = os.environ.get('XDG_CACHE_HOME', os.path.expanduser('~/.cache'))
VAULT_PATHS_FILENAME = 'vault-paths.json'
VAULT_PATHS_FILE = os.path.join(CACHE_DIR, VAULT_PATHS_FILENAME)

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
    # Modify this function to allow for cache_dir and vault_paths_filename,
    # defaulting to the environment variables above. Create the
    # vault_paths_file class variable and set it to
    # 'cache_dir/vault_paths_filename'. Modify the rest of this class to use
    # this variable, AI!
    def __init__(self):
        """Initialize the VaultKeyManager and load vault paths if available."""
        self.vault_data = None

        try:
            self.vault_data = self.load_vault_paths()

        except VaultPathNotFoundError:
            # It's okay if the file doesn't exist yet
            pass

        except VaultKeyError as e:
            self.warn(f"Warning: {str(e)}")

    #-------------------------------------------------------------------------
    @staticmethod
    def warn(message):
        """Print a warning message to stderr."""
        print(message, file=sys.stderr)

    #-------------------------------------------------------------------------
    @staticmethod
    def die(message=None, exit_code=1):
        """Print an error message and exit with the specified code (default 1)."""
        if message is not None:
            VaultKeyManager.warn(message)

        sys.exit(exit_code)

    #-------------------------------------------------------------------------
    def load_vault_paths(self):
        """Load the vault paths from the JSON file."""
        try:
            with open(VAULT_PATHS_FILE, 'r') as f:
                return json.load(f)

        except FileNotFoundError:
            raise VaultPathNotFoundError(f"Vault paths file not found. Run '{sys.argv[0]} discover' first.")

        except json.JSONDecodeError:
            raise VaultKeyError(f"Error parsing vault paths file. The file may be corrupted.")

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
            raise VaultAuthenticationError("Vault token is not set. Run 'source set-vault-token' and try again.")

        # Create the client
        try:
            self.client = hvac.Client(url=os.environ.get('VAULT_ADDR', 'https://vault.example.com'), token=token)

            if not self.client.is_authenticated():
                raise VaultAuthenticationError("Vault authentication failed. Check your token and try again.")

        except VaultAuthenticationError:
            raise

        except Exception as e:
            raise VaultKeyError(f"Error connecting to Vault: {str(e)}")

    #-------------------------------------------------------------------------
    def discover_paths(self, root_paths=None):
        """
        Discover all paths and secrets in Vault and save to a file.

        Args:
            root_paths: List of root paths to start discovery from (default: ['dai', 'dao'])
        """
        # Ensure client is set
        self.set_vault_client()
        if root_paths is None:
            root_paths = ['dai', 'dao']

        self.warn("Discovering vault paths...")

        # Initialize the structure
        vault_data = {}

        # Helper function to recursively discover paths
        def discover_recursive(path, structure):
            try:
                # List items at the current path
                response = self.client.secrets.kv.v2.list_secrets(path=path)

                if not response or 'data' not in response or 'keys' not in response['data']:
                    return

                keys = response['data']['keys']

                for key in keys:
                    # If key ends with /, it's a directory
                    if key.endswith('/'):
                        subpath = f"{path}/{key[:-1]}" if path else key[:-1]

                        # Create nested structure
                        if key[:-1] not in structure:
                            structure[key[:-1]] = {}

                        # Recursively discover
                        discover_recursive(subpath, structure[key[:-1]])

                    else:
                        # It's a secret
                        if 'secrets' not in structure:
                            structure['secrets'] = []

                        structure['secrets'].append(key)

            except Exception as e:
                self.warn(f"Error listing {path}: {str(e)}")

        # Start discovery from root paths
        for root_path in root_paths:
            vault_data[root_path] = {}
            discover_recursive(root_path, vault_data[root_path])

        # Save to file
        os.makedirs(os.path.dirname(VAULT_PATHS_FILE), exist_ok=True)
        with open(VAULT_PATHS_FILE, 'w') as f:
            json.dump(vault_data, f, indent=2)

        print(f"Vault paths saved to {VAULT_PATHS_FILE}")

    #-------------------------------------------------------------------------
    def find_matching_paths(self, structure, search_path):
        """Find all paths that match the search pattern."""
        matches = []

        def search_recursive(current_path, struct, prefix=""):
            # Check if this node has secrets
            if 'secrets' in struct and search_path.lower() in (prefix + current_path).lower():
                matches.append(prefix + current_path)

            # Recursively search subdirectories
            for key, value in struct.items():
                if key != 'secrets':  # Skip the secrets list
                    new_prefix = prefix + current_path + "/" if current_path else prefix
                    search_recursive(key, value, new_prefix)

        # Start recursive search from the root
        for root_key, root_value in structure.items():
            search_recursive(root_key, root_value)

        return matches

    #-------------------------------------------------------------------------
    def select_path(self, matches):
        """Let the user select a path if multiple matches are found."""
        selected = select_from_list(matches, prompt="Select a path")
        if selected is None:
            self.die("Operation cancelled by user")
        return selected

    #-------------------------------------------------------------------------
    def list_secrets(self, path):
        """List all secrets at the specified path."""
        # Ensure client is set
        self.set_vault_client()
        try:
            print(f"Listing secrets in {path}:")
            # Read the secret
            response = self.client.secrets.kv.v2.read_secret_version(path=path)

            if response and 'data' in response and 'data' in response['data']:
                for key in response['data']['data'].keys():
                    print(key)

            else:
                print("No secrets found or unexpected data format.")

        except Exception as e:
            raise VaultKeyError(f"Error listing secrets at {path}: {str(e)}")

    #-------------------------------------------------------------------------
    def get_secret(self, path, secret_name):
        """Get the value of a specific secret."""
        # Ensure client is set
        self.set_vault_client()
        try:
            # Read the secret
            response = self.client.secrets.kv.v2.read_secret_version(path=path)

            if response and 'data' in response and 'data' in response['data']:
                if secret_name in response['data']['data']:
                    # Create JSON response
                    result = {
                        secret_name: response['data']['data'][secret_name],
                        "path": path
                    }

                    print(json.dumps(result, indent=2))

                else:
                    raise VaultSecretNotFoundError(f"Secret '{secret_name}' not found in path '{path}'")

            else:
                raise VaultKeyError(f"No data found at path '{path}' or unexpected data format.")

        except VaultKeyError:
            raise

        except Exception as e:
            raise VaultKeyError(f"Error getting secret from {path}: {str(e)}")

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
                print(f"Invalid selection. Please enter a number between {0 if cancel_option else 1} and {len(items)}.")

        except ValueError:
            print("Please enter a number.")

#-----------------------------------------------------------------------------
def main():
    parser = argparse.ArgumentParser(description="Vault key management utility")
    subparsers = parser.add_subparsers(dest='command', help='Command to execute')

    # discover command
    discover_parser = subparsers.add_parser('discover', help='Discover all vault paths and secrets')
    # Add optional argument for root paths
    discover_parser.add_argument('--root-paths', nargs='+',
                                 help='Root paths to start discovery from (default: dai dao)')


    # list command
    list_parser = subparsers.add_parser('list', help='List secrets at a path')
    list_parser.add_argument('path', help='Path to list secrets from')

    # get command
    get_parser = subparsers.add_parser('get', help='Get a specific secret value')
    get_parser.add_argument('path', help='Path to the secret')
    get_parser.add_argument('secret', help='Name of the secret to retrieve')

    args = parser.parse_args()

    # Create manager instance
    manager = VaultKeyManager()

    if args.command == 'discover':
        try:
            # Get root paths if provided
            root_paths = args.root_paths if hasattr(args, 'root_paths') and args.root_paths else None

            manager.discover_paths(root_paths)

        except VaultKeyError as e:
            manager.die(str(e))

    elif args.command == 'list' or args.command == 'get':
        try:
            # Load vault paths if not already loaded
            vault_data = manager.vault_data or manager.load_vault_paths()

            # Find matching paths
            matches = manager.find_matching_paths(vault_data, args.path)

            if not matches:
                manager.die(f"No matching paths found for '{args.path}'")

            # Select path if multiple matches
            selected_path = manager.select_path(matches)

            # Execute command
            if args.command == 'list':
                manager.list_secrets(selected_path)

            elif args.command == 'get':
                manager.get_secret(selected_path, args.secret)

        except VaultKeyError as e:
            manager.die(str(e))

    else:
        parser.print_help()
        sys.exit(1)

#-----------------------------------------------------------------------------
if __name__ == "__main__":
    main()
