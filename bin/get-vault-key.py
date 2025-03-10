#!/usr/bin/env python3

import os
import sys
import json
import argparse
import hvac
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
    def __init__(self, cache_dir=None, vault_paths_filename=None, vault_addr=None):
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

        self.vault_addr = vault_addr
        self.cache_dir = cache_dir
        self.vault_paths_filename = vault_paths_filename
        self.vault_data = None

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
            raise VaultPathNotFoundError(f"Vault paths file not found at {vault_paths_file}. Run '{sys.argv[0]} discover' first.")

        except json.JSONDecodeError as e:
            raise VaultKeyError(f"Error parsing vault paths file ({vault_paths_file}). The file may be corrupted: {str(e)}")

        except Exception as e:
            raise VaultKeyError(f"Error loading vault paths: {str(e)}")

    #-------------------------------------------------------------------------
    def set_vault_client(self, vault_addr=None):
        """Set up and configure the vault client if not already set."""
        # If client is already set, just return
        if hasattr(self, 'client') and self.client is not None:
            return

        # Check if VAULT_TOKEN is set
        token = os.environ.get('VAULT_TOKEN')

        # Use instance variable if no vault_addr is provided
        if vault_addr is None:
            vault_addr = self.vault_addr or os.environ.get('VAULT_ADDR')

            if vault_addr is None:
                raise VaultAuthenticationError("Vault address is not set. Set VAULT_ADDR environment variable or provide vault_addr parameter.")

        if not token:
            raise VaultAuthenticationError("Vault token is not set. Run 'source set-vault-token' and try again.")

        # Create the client
        try:
            self.client = hvac.Client(url=vault_addr, token=token)

            if not self.client.is_authenticated():
                raise VaultAuthenticationError("Vault authentication failed. Check your token and try again.")

        except VaultAuthenticationError:
            raise

        except Exception as e:
            raise VaultKeyError(f"Error connecting to Vault: {str(e)}")

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

        print(f"Vault paths saved to {vault_paths_file}")

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
            die("Operation cancelled by user")
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
                print(f"Invalid selection. Please enter a number between {0 if cancel_option else 1} and {len(items)}.")

        except ValueError:
            print("Please enter a number.")

#-----------------------------------------------------------------------------
def parseargs(showhelp=False):
    """
    Parse command line arguments and return the parsed arguments.
    
    Args:
        showhelp: If True, print help and exit instead of parsing arguments
    """
    # Create a parent parser for common options
    parent_parser = argparse.ArgumentParser(add_help=False)

    # Add global options to the parent parser
    parent_parser.add_argument('--cache-dir',
                       default=os.environ.get('VAULT_CACHE_DIR', CACHE_DIR),
                       help=f'Directory to store vault paths file (default: {CACHE_DIR})')

    parent_parser.add_argument('--paths-file',
                       default=os.environ.get('VAULT_PATHS_FILENAME', VAULT_PATHS_FILENAME),
                       help=f'Name of the vault paths file (default: {VAULT_PATHS_FILENAME})')

    parent_parser.add_argument('--vault-addr',
                       default=os.environ.get('VAULT_ADDR'),
                       help='Vault server address (default: from VAULT_ADDR environment variable)')

    #-------------------------------------------------------------------------
    # Create the main parser that will display in the top-level help
    parser = argparse.ArgumentParser(description="Vault key management utility")

    # Add the global options to the main parser too
    parser.add_argument('--cache-dir',
                       default=os.environ.get('VAULT_CACHE_DIR', CACHE_DIR),
                       help=f'Directory to store vault paths file (default: {CACHE_DIR})')
    parser.add_argument('--paths-file',
                       default=os.environ.get('VAULT_PATHS_FILENAME', VAULT_PATHS_FILENAME),
                       help=f'Name of the vault paths file (default: {VAULT_PATHS_FILENAME})')
    parser.add_argument('--vault-addr',
                       default=os.environ.get('VAULT_ADDR'),
                       help='Vault server address (default: from VAULT_ADDR environment variable)')

    subparsers = parser.add_subparsers(dest='command', help='Command to execute')

    #-------------------------------------------------------------------------
    # Create subparsers with the parent parser
    discover_parser = subparsers.add_parser('discover', parents=[parent_parser],
                                           help='Discover all vault paths and secrets')

    discover_parser.add_argument('--root-paths', nargs='+',
                               metavar='<root path>',
                               help='Root paths to start discovery from (default: dai dao)')

    #-------------------------------------------------------------------------
    list_parser = subparsers.add_parser('list', parents=[parent_parser],
                                       help='List secrets at a path')

    list_parser.add_argument('path', help='Path to list secrets from')

    #-------------------------------------------------------------------------
    get_parser = subparsers.add_parser('get', parents=[parent_parser],
                                      help='Get a specific secret value')

    get_parser.add_argument('path', help='Path to the secret')
    get_parser.add_argument('secret', help='Name of the secret to retrieve')

    #-------------------------------------------------------------------------
    if showhelp:
        parser.print_help()
        sys.exit(0)
    
    return parser.parse_args()

#-----------------------------------------------------------------------------
def main():
    args = parseargs(showhelp=len(sys.argv) <= 1)

    # Create manager instance
    manager = VaultKeyManager(
        cache_dir=args.cache_dir,
        vault_paths_filename=args.paths_file,
        vault_addr=args.vault_addr
    )

    if args.command == 'discover':
        try:
            # Get root paths if provided, otherwise use defaults
            root_paths = args.root_paths if hasattr(args, 'root_paths') and args.root_paths else ['dai', 'dao']

            # Set vault client with provided address
            manager.discover_paths(root_paths)

        except (VaultKeyError, ValueError) as e:
            die(str(e))

    elif args.command == 'list' or args.command == 'get':
        try:
            # Find matching paths
            matches = manager.find_matching_paths(args.path)

            if not matches:
                die(f"No matching paths found for '{args.path}'")

            # Select path if multiple matches
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
