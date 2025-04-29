# git-commit-comment

A utility script that combines Git commits with Azure DevOps work item updates.

## Usage

```bash
git-commit-comment "Message with #workItemId"
```

## Requirements

- Azure CLI with DevOps extension
- Git

## Features

- Extracts work item ID from commit message (format: #123456)
- Validates the work item ID exists in Azure DevOps
- Creates a Git commit with the provided message
- Adds the commit message as a discussion comment on the Azure DevOps work item
- Fails with appropriate error messages if any step fails

## Installation

* Create a file somewhere accessible from your `PATH`.
* Name it whatever fits your needs.
* Copy and paste the code below into the file.
* Make it executable.

## Code

See `bin/git-commit-comment`.
