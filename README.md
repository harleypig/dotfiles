[![CodeFactor](https://www.codefactor.io/repository/github/harleypig/dotfiles/badge)](https://www.codefactor.io/repository/github/harleypig/dotfiles)

# Shell Startup Configuration

## My dotfiles that aren't in their own repository ...

The `.bash_profile`, `.bashrc`, and `.profile` files all link to the same
`shell-startup` file. This setup was chosen for a few reasons:

- It simplifies the process of figuring out which file is loaded when. Instead
    of having to trace through multiple files, there's just one central file
    to look at.
- The various startup files sourced during startup are required to perform
    whatever tasks are needed for that file. These tasks are usually broken up
    into discrete functions. For example, `shell_startup.d/tmux` sets up the
    environment for use with tmux.
- This setup also ensures that aliases and other configurations work when
    shelling from vim, which is a common use case.

This setup has been found to work well, but as with any configuration, it may
not be suitable for all use cases or environments.

## Powershell

## VSCode

Consider using Todo Tree Extension for XXX: or TBD: highlights.
