# Powershell Setup and Configuration

This was developed using Powershell 7+.

## First Steps

I am assuming `git` and `powershell 7+` have been installed and that the
repositories (currently dotfiles, dotvim, and private_dotfiles) have been cloned
in the appropriate locations.

* Set the profile for powershell using the `ps-profile.ps1` script. Use
  `ps-profile -h` for details.

* Update your modules and scripts. See `Update-All -h` for details.

* Set the execution policy to `RemoteSigned` (unless you have a different use
  case, in which case you'll know what you need to do).

  Run `Elevate Set-ExecutionPolicy RemoteSigned`. `Elevate` is a script in the
  bin directory this document is stored in.

* Install the modules listed in `ps-packages.txt` in this directory.