#!/usr/bin/env python3

import os
import sys
import json
import argparse
import hvac
from pathlib import Path

# Constants
XDG_CACHE_HOME = os.environ.get('XDG_CACHE_HOME', os.path.expanduser('~/.cache'))
VAULT_PATHS_FILE = os.path.join(XDG_CACHE_HOME, 'vault-paths.json')

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
def get_vault_client():
    """Get a configured vault client."""
    # Check if VAULT_TOKEN is set
    token = os.environ.get('VAULT_TOKEN')
    if not token:
        die("Vault token is not set. Run 'source set-vault-token' and try again.")

    # Create and return the client
    try:
        client = hvac.Client(url=os.environ.get('VAULT_ADDR', 'https://vault.example.com'), token=token)
        if not client.is_authenticated():
            die("Vault authentication failed. Check your token and try again.")
        return client
    except Exception as e:
        die(f"Error connecting to Vault: {str(e)}")

#-----------------------------------------------------------------------------
def discover_paths(client):
    """Discover all paths and secrets in Vault and save to a file."""
    print("Discovering vault paths...")

    # Initialize the structure
    vault_structure = {}

    # Helper function to recursively discover paths
    def discover_recursive(path, structure):
        try:
            # List items at the current path
            response = client.secrets.kv.v2.list_secrets(path=path)
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
            warn(f"Error listing {path}: {str(e)}")

    # Start discovery from root paths
    for root_path in ['dai', 'dao']:
        vault_structure[root_path] = {}
        discover_recursive(root_path, vault_structure[root_path])

    # Save to file
    os.makedirs(os.path.dirname(VAULT_PATHS_FILE), exist_ok=True)
    with open(VAULT_PATHS_FILE, 'w') as f:
        json.dump(vault_structure, f, indent=2)

    print(f"Vault paths saved to {VAULT_PATHS_FILE}")

#-----------------------------------------------------------------------------
def find_matching_paths(structure, search_path):
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

#-----------------------------------------------------------------------------
def select_path(matches):
    """Let the user select a path if multiple matches are found."""
    if len(matches) == 1:
        return matches[0]

    print("Multiple matching paths found:")
    for i, path in enumerate(matches, 1):
        print(f"  {i}) {path}")
    print("  0) Cancel")

    while True:
        try:
            choice = input("Select a path (0 to cancel): ")
            if choice == "0":
                die("Operation cancelled by user")
            choice = int(choice)
            if 1 <= choice <= len(matches):
                return matches[choice - 1]
            else:
                warn("Invalid selection. Try again.")
        except ValueError:
            warn("Please enter a number.")

#-----------------------------------------------------------------------------
def list_secrets(client, path):
    """List all secrets at the specified path."""
    try:
        print(f"Listing secrets in {path}:")
        # Read the secret
        response = client.secrets.kv.v2.read_secret_version(path=path)
        if response and 'data' in response and 'data' in response['data']:
            for key in response['data']['data'].keys():
                print(key)
        else:
            print("No secrets found or unexpected data format.")
    except Exception as e:
        die(f"Error listing secrets at {path}: {str(e)}")

#-----------------------------------------------------------------------------
def get_secret(client, path, secret_name):
    """Get the value of a specific secret."""
    try:
        # Read the secret
        response = client.secrets.kv.v2.read_secret_version(path=path)
        if response and 'data' in response and 'data' in response['data']:
            if secret_name in response['data']['data']:
                # Create JSON response
                result = {
                    secret_name: response['data']['data'][secret_name],
                    "path": path
                }
                print(json.dumps(result, indent=2))
            else:
                die(f"Secret '{secret_name}' not found in path '{path}'")
        else:
            die(f"No data found at path '{path}' or unexpected data format.")
    except Exception as e:
        die(f"Error getting secret from {path}: {str(e)}")

#-----------------------------------------------------------------------------
def main():
    parser = argparse.ArgumentParser(description="Vault key management utility")
    subparsers = parser.add_subparsers(dest='command', help='Command to execute')

    # discover command
    discover_parser = subparsers.add_parser('discover', help='Discover all vault paths and secrets')

    # list command
    list_parser = subparsers.add_parser('list', help='List secrets at a path')
    list_parser.add_argument('path', help='Path to list secrets from')

    # get command
    get_parser = subparsers.add_parser('get', help='Get a specific secret value')
    get_parser.add_argument('path', help='Path to the secret')
    get_parser.add_argument('secret', help='Name of the secret to retrieve')

    args = parser.parse_args()

    # Get vault client
    client = get_vault_client()

    if args.command == 'discover':
        discover_paths(client)

    elif args.command == 'list' or args.command == 'get':
        # Load vault paths
        try:
            with open(VAULT_PATHS_FILE, 'r') as f:
                vault_structure = json.load(f)
        except FileNotFoundError:
            die(f"Vault paths file not found. Run '{sys.argv[0]} discover' first.")

        # Find matching paths
        matches = find_matching_paths(vault_structure, args.path)

        if not matches:
            die(f"No matching paths found for '{args.path}'")

        # Select path if multiple matches
        selected_path = select_path(matches)

        # Execute command
        if args.command == 'list':
            list_secrets(client, selected_path)
        elif args.command == 'get':
            get_secret(client, selected_path, args.secret)

    else:
        parser.print_help()
        sys.exit(1)

#-----------------------------------------------------------------------------
if __name__ == "__main__":
    main()
