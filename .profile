# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# SNIPD/2023-04-16: Default ~/.profile on Linux Mint 21.3:

# # ~/.profile: executed by the command interpreter for login shells.
# # This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# # exists.
# # see /usr/share/doc/bash/examples/startup-files for examples.
# # the files are located in the bash-doc package.
#
# # the default umask is set in /etc/profile; for setting the umask
# # for ssh logins, install and configure the libpam-umask package.
# #umask 022
#
# # if running bash
# if [ -n "$BASH_VERSION" ]; then
#     # include .bashrc if it exists
#     if [ -f "$HOME/.bashrc" ]; then
#   . "$HOME/.bashrc"
#     fi
# fi
#
# # set PATH so it includes user's private bin if it exists
# if [ -d "$HOME/bin" ] ; then
#     PATH="$HOME/bin:$PATH"
# fi
#
# # set PATH so it includes user's private bin if it exists
# if [ -d "$HOME/.local/bin" ] ; then
#     PATH="$HOME/.local/bin:$PATH"
# fi

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

my_profile () {

  setup_my_profile () {
    source_user_bashrc
    update_path_user_home_bin
    update_path_user_home_local_bin
    # NOTE: (lb): This updates LD_LIBRARY_PATH, but it doesn't stick
    #             for the window manager environment.
    update_ldpath_user_home_local_lib
    profile_unset_functions
  }

  source_user_bashrc () {
    # Return unless interactive shell (and Bashrc is already loading).
    ! ${HOMEFRIES_STARTUP:-false} || return 0

    # 2020-02-06: (lb): Note that some environs are set when you logon to
    # your window manager, like `BASH=/bin/bash`, but not `BASH_VERSION`.
    [ -n "$BASH_VERSION" ] || return 0

    # Include .bashrc if it exists.
    [ -f "$HOME/.bashrc" ] || return 0

    HOMEFRIES_STARTUP=true . "$HOME/.bashrc"
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

  profile_unset_functions () {
    unset -f setup_my_profile
    unset -f source_user_bashrc
    unset -f prepend_path_part
    unset -f prepend_ldpath_part
    unset -f update_path_user_home_bin
    unset -f update_path_user_home_local_bin
    unset -f update_ldpath_user_home_local_lib
    unset -f profile_unset_functions
  }

  setup_my_profile
}

my_profile
unset -f my_profile

