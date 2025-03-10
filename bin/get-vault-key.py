#!/usr/bin/env python3

# Create the code based on the following AI!
# use hashicorp vault python library
#
# Check if VAULT_TOKEN is set
#   if not, then display warning and exit.
#
# accept these args:
#   discover - find all paths and secrets and save them to a file
#   list <path> - list all paths and secrets under path
#   get <path> <secret> - display secret value
#
# the save file is a json dict:
# { pathname: { pathname: "", [ list of secrets ] }}
#
# example dict for
#   top1/a/secret1
#   top1/a/b/secret2
#   top2/c/d/secret3
#
# { "top1": { "a": { "b": ["secret2"] }, ["secret1"] },
#   "top2": { "c": { "d": ["secret3"] } } }
