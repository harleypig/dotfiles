#!/usr/bin/env python3

import os
import sys
import argparse
from get_vault_key.get_vault_key import (
    VaultKeyManager, 
    VaultKeyError, 
    warn, 
    die
)

#-----------------------------------------------------------------------------
# Setup and Sanity
CACHE_DIR = os.environ.get('XDG_CACHE_HOME', os.path.expanduser('~/.cache'))
VAULT_PATHS_FILENAME = 'vault-paths.json'


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
