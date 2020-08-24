#!/bin/bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# 2020-02-06: Parts generated by git@github.com:junegunn/fzf.git:install
#             then refactored into functions and commented by (lb).

# Setup fzf
# ---------
#
# (lb): To migrate to Zoidy Pooh Ansible task, I either need
#       to call fzf/install, or I need to go-get-install it.
#       Because the install script is interactive,
#       and appends the next three blocks to ~/.bashrc
#       ... which I've since wrapped in functions.
#
fzf_update_path () {
  if [[ ! "$PATH" == */kit/working/golang/fzf/bin* ]]; then
    export PATH="${PATH:+${PATH}:}/kit/working/golang/fzf/bin"
  fi
}

# Auto-completion
# ---------------
fzf_wire_completion () {
  [[ $- == *i* ]] && . "/kit/working/golang/fzf/shell/completion.bash" 2> /dev/null
}

# Key bindings
# ------------
fzf_wire_key_bindings () {
  . "/kit/working/golang/fzf/shell/key-bindings.bash"
}

# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# LEARNING!/2020-02-12: The `fd` command is new to me.
# - Here's a crash course, courtesy junegunn:
#   https://github.com/junegunn/fzf#respecting-gitignore
#
#     # Feed the output of fd into fzf
#     fd --type f | fzf
#
#     # Setting fd as the default source for fzf
#     export FZF_DEFAULT_COMMAND='fd --type f'
#
#     # Now fzf (w/o pipe) will use fd instead of find
#     fzf
#
#     # To apply the command to CTRL-T as well
#     export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
#
#     # If you want the command to follow symbolic links, and don't
#     # want it to exclude hidden files, use the following command:
#
#     export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
fzf_wire_default_cmd_fd () {
  command -v fd > /dev/null || return
  # (lb): Let's go with the suggested command, sounds about right to me!
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
  export FZF_CTRL_T_COMMAND="${FZF_DEFAULT_COMMAND}"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main () {
  # FIXME/2020-08-24 14:40: Make this path generic.
  [ -d "/kit/working/golang/fzf" ] || return

  fzf_update_path
  fzf_wire_completion
  fzf_wire_key_bindings
  fzf_wire_default_cmd_fd
}

main "$@"
unset -f main

