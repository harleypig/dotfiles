#!/usr/bin/env python3

"""Utility functions for the get_vault_key package."""

import sys


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
