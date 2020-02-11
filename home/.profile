# vim:tw=0:ts=2:sw=2:et:norl:ft=bash

# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#
#  umask 022

my_profile () {

  setup_my_profile () {
    source_user_bashrc
    update_path_user_home_bin
    update_path_user_home_local_bin
    # NOTE: (lb): This updates LD_LIBRARY_PATH, but it doesn't stick
    #             for the window manager environment.
    update_ldpath_user_home_local_lib
    rvm_update_path_and_source
  }

  source_user_bashrc () {
    # Return unless running Bash.
    # 2020-02-06: (lb): Note that some environs are set when you logon to
    # your window manager, like `BASH=/bin/bash`, but not `BASH_VERSION`.
    [ -z "$BASH_VERSION" ] && return 0
    # Include .bashrc if it exists.
    [ ! -f "$HOME/.bashrc" ] && return 0
    source "$HOME/.bashrc"
  }

  prepend_path_part () {
    local path_elem="$1"
    # Don't bother if the directory doesn't exist.
    [ ! -d "${path_elem}" ] && return 0
    # Don't bother if the directory is already part of path.
    [[ ":${PATH}:" == *":${path_elem}:"* ]] && return 0
    # Prepend the paths with a colon, if necessary.
    [ -n "${PATH}" ] && PATH=":${PATH}"
    PATH="${path_elem}${PATH}"
    export PATH
  }

  prepend_ldpath_part () {
    local ldpath_elem="$1"
    # Don't bother if the directory doesn't exist.
    [ ! -d "${ldpath_elem}" ] && return 0
    # Don't bother if the directory is already part of path.
    [[ ":${LD_LIBRARY_PATH}:" == *":${ldpath_elem}:"* ]] && return 0
    # Prepend the paths with a colon, if necessary.
    [ -n "${LD_LIBRARY_PATH}" ] && LD_LIBRARY_PATH=":${LD_LIBRARY_PATH}"
    LD_LIBRARY_PATH="${ldpath_elem}${LD_LIBRARY_PATH}"
    export LD_LIBRARY_PATH
    # BROKEN/2020-02-06: Something is resetting LD_LIBRARY_PATH after this runs.
  }

  update_path_user_home_bin () {
    # Set PATH to include user's private bin/, if it exists.
    prepend_path_part "${HOME}/bin"
  }

  update_path_user_home_local_bin () {
    # 2020-02-06: (lb): The distro-supplied default (example) ~/.profile
    #   adds ~/bin to PATH, but I keep user-local applications one directory
    #   deeper, at ~/.local/bin (which may or may not be because I call
    #   ``configure --prefix=${HOME}/.local`` when building from source).
    # - NOTE: Ensuring ~/.local/bin is on PATH for your desktop manager
    #   makes wiring some desktop features easier, e.g., you don't have to
    #   write complicated keybinding actions.
    prepend_path_part "${HOME}/.local/bin"
  }

  update_ldpath_user_home_local_lib () {
    # And also.
    prepend_ldpath_part "${HOME}/.local/lib"
  }

  rvm_update_path_and_source () {
    # Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
    # FIXME/2020-02-06 17:42: Do we need this?
    # - I think ~/.profile sourced just once per MATE session, on first logon!
    # Because I see this in PATH, but cannot determine how being set, so now
    # assuming this here is why!
    if [ -d "$PATH:$HOME/.rvm/bin" ]; then
      export PATH="$PATH:$HOME/.rvm/bin"
    fi

    if [ -s "$HOME/.rvm/scripts/rvm" ]; then
      # Load RVM into a shell session *as a function*.
      source "$HOME/.rvm/scripts/rvm"
    fi
  }

  setup_my_profile
}

my_profile
unset -f my_profile

