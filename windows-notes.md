# Windows Dotfiles Setup

### Cheerfully stolen from [changyuheng's dotfiles](https://github.com/changyuheng/dotfiles)

1 `$HOME` (`%USERPROFILE%`) folder **has to** be on an [NTFS](https://en.wikipedia.org/wiki/NTFS) volume.

1. [Activate Developer Mode](https://docs.microsoft.com/en-us/windows/apps/get-started/enable-your-device-for-development) from: Start > Settings > Update & Security > For developers > Developer Mode. Enabling this feature will enable the symbolic link support.

1. Install [OpenSSH Client](https://docs.microsoft.com/en-us/windows-server/administration/openssh/openssh_install_firstuse) from: Start > Settings > Apps > Apps & Features > Optional Features

1. Enable the [long file path support](https://docs.microsoft.com/en-us/windows/win32/fileio/maximum-file-path-limitation?tabs=cmd) from: Start > Local Group Policy Editor > Local Computer Policy > Computer Configuration > Administrative Templates > System > Filesystem > Enable Win32 long paths

1. Download and install [MSYS2](https://www.msys2.org/#installation), then:

   1. Enable the symbolic link support in MSYS2 by uncommenting the following line in `C:\msys64\msys2_shell.cmd`

      ```
      rem set MSYS=winsymlinks:nativestrict
      ```

      and the following line in `C:\msys64\mingw64.ini`.

      ```
      #MSYS=winsymlinks:nativestrict
      ```

      Note: You can use VS Code to edit those files.

   1. Make `%TMEP%` mounted at `/tmp` by adding the following contents to `C:\msys64\etc\fstab`.

      ```
      none /tmp usertemp binary,posix=0,noacl 0 0
      ```

   1. Set Windows `%USERPROFILE%` folder (`C:\Users\<user name>`) as the `$HOME` folder by adding the following contents to `C:\msys64\etc\fstab`. Ref: [How to change HOME directory and start directory on MSYS2?](https://stackoverflow.com/a/66946901).

      ```
      ##################################################################
      # Canonicalize the two home directories by mounting the windows  #
      # user home with the same path mapping as unix.                  #
      ##################################################################
      C:/Users /home ntfs binary,posix=0,noacl,user 0 0
      ```

   1. [Install Git for Windows](https://github.com/git-for-windows/git/wiki/Install-inside-MSYS2-proper) via MSYS2 with the following instructions.

      1. Add the Git for Windows package repositories above any others (i.e. just before `[mingw32]` on line #68 as of this writing) to `C:\msys64\etc\pacman.conf`:

         ```
         [git-for-windows]
         Server = https://wingit.blob.core.windows.net/x86-64

         [git-for-windows-mingw32]
         Server = https://wingit.blob.core.windows.net/i686
         ```

      1. Open "MSYS2 MinGW x64" MinTTY (from Windows Start).

      1. Authorize the signing key with:

         ```
         curl -L https://raw.githubusercontent.com/git-for-windows/build-extra/HEAD/git-for-windows-keyring/git-for-windows.gpg |
         pacman-key --add - &&
         pacman-key --lsign-key E8325679DFFF09668AD8D7B67115A57376871B1C &&
         pacman-key --lsign-key 3B6D86A1BA7701CD0F23AED888138B9E1A9F3986
         ```

      1. Then synchronize with new repositories with

         ```
         pacman -Syyuu
         ```

         This installs a new `msys2-runtime` and therefore will ask you to terminate all MSYS2 processes. Save what you need from other open MSYS2 shells and programs, exit them and confirm the Pacman prompt. Double-check Task Manager and kill `pacman.exe` if it's still running after the window is closed. Start a new MSYS2 terminal.

      1. Then synchronize *again* to install the rest:

         ```
         pacman -Suu
         ```

         It might happen that some packages are downgraded, this is expected.

      1. And finally install the packages containing Git, its documentation and some extra things:

         ```
         pacman -S mingw-w64-x86_64-{git,git-doc-html,git-doc-man,git-lfs} git-extra
         ```

   1. Install necessary packages in `MSYS2 MinGW x64`.

      ```
      pacman -Sy man tmux zsh
      ```

## TODO

Rip off what I can use from [here](https://github.com/LucHermitte/Bash-scripts/blob/master/cyg-wrapper.sh)
