# Git Aliases

These aliases are accessible via `git aliasname`.

## Information
- `aliases` - Show all defined git aliases
- `root` - Show repository root directory
- `remotes` - List remotes with URLs
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
- `amend` - Amend commit without editing message
- `c` - Record changes to repository
- `ca` - Modify the last commit
- `cb` - Commit with branch name
- `ci` - Commit interactively
- `cm` - Commit with message
- `out` - Show commits not pushed to upstream
- `undo` - Undo last commit keeping changes staged

## Branching
- `b` - List branches
- `ba` - List all branches including remote
- `bc` - Show current branch name
- `bd` - Delete branch if merged
- `bD` - Force delete branch
- `bm` - Show merged branches
- `bnm` - Show unmerged branches
- `co` - Switch branches or restore files

## Remote Operations
- `f` - Download objects and refs
- `pl` - Fetch and integrate with another repo
- `m` - Join development histories

## Conflict Resolution
- `conflicted` - Show files with merge conflicts

## History
- `graph` - Compact graph view
- `l` - Show commit logs with graph
- `last` - Show last commit
- `latest-tag` - Show most recent version tag
- `lc` - Show changes since branch point in oneline format
- `lm` - Show merge logs with decoration
- `ln` - Show logs with numstat
- `search` - Search commit contents
- `since` - Show commits since date
- `until` - Show commits until date
