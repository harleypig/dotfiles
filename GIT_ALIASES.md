# Git Aliases

These aliases are accessible via `git aliasname`.

## Information
- `aliases` - Show all defined git aliases
- `s` - Show working tree status
- `ss` - Show short status
- `st` - Show status with branch info
- `changes` - Show status of changes

## File Management
- `find` - Search for file in git tree
- `ignore` - Add file to .gitignore
- `ignored` - Show ignored files
- `new` - Show new files in incoming merge

## File Tracking
- `assume` - Mark file as assumed unchanged
- `assumed` - List assumed-unchanged files
- `unassume` - Clear assume-unchanged for file
- `unassumeall` - Clear all assume-unchanged
- `untrack` - Stop tracking a file
- `wip` - Commit work in progress

## Staging Management
- `a` - Add file contents to index
- `aa` - Add all file contents to index
- `ai` - Add files interactively
- `au` - Add modified/deleted files only
- `unadd` - Undo git add, specific or all files
- `unstage` - Undo last commit, specific or all files

## Diffing
- `d` - Show changes with color and word diff
- `dc` - Show staged changes with color
- `dd` - Show directory statistics
- `ds` - Show change statistics
- `dt` - Open diff tool
- `diffstat` - Show change statistics

## Committing
- `c` - Record changes to repository
- `ca` - Modify the last commit
- `cb` - Commit with branch name
- `ci` - Commit interactively
- `cm` - Commit with message
- `out` - Show commits not pushed to upstream

## Branching
- `b` - List branches
- `ba` - List all branches including remote
- `bc` - Show current branch name
- `co` - Switch branches or restore files

## Remote Operations
- `f` - Download objects and refs
- `pl` - Fetch and integrate with another repo
- `m` - Join development histories

## Conflict Resolution
- `conflicted` - Show files with merge conflicts

## History
- `l` - Show commit logs with graph
- `lc` - Show changes since branch point
- `lp` - Show logs with author and graph
- `logm` - Show merge logs with decoration
- `logn` - Show logs with numstat
- `latest-tag` - Show most recent version tag
