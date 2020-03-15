#!/bin/bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# Most of my Git magic is elsewhere:
#
#   github.com:landonb/git-FlU
#   github.com:landonb/git-veggie-patch
#   github.com:landonb/git-my-merge-status
#   and more to come!

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# *** Interrogate user on clobbery git command.

# 2017-06-06: Like the home-fries /bin/rm monkey patch (rm_safe), why not
# preempt "unsafe" git commands with a similarly pesky are-you-sure? prompt.
# - Specifically added because sometimes when I mean to type
#     `git reset HEAD blurgh`  I type instead
#     `git co -- blurgh`       -- oh no! --
#   but I will note that since this command (comment) was added I've stopped.
_paranoid_git () {
  local disallowed=false
  local prompt_yourself=false

  if [ $# -ge 2 ]; then
    # Verify `git co -- ...` command.
    # NOTE: `co` is a home-🍟 alias, `co = checkout`.
    # NOTE: (lb): I'm not concerned with the long-form counterpart, `checkout`,
    #       a command I almost never type, and for which can remain unchecked,
    #       as a sort of "force-checkout" option to avoid being prompted.
    if [ "$1" = "co" ] && [ "$2" = "--" ]; then
      prompt_yourself=true
    fi
    # Also catch `git co .`.
    if [ "$1" = "co" ] && [ "$2" = "." ]; then
      prompt_yourself=true
    fi

    # Verify `git reset --hard ...` command.
    if [ "$1" = "reset" ] && [ "$2" = "--hard" ]; then
      prompt_yourself=true
    fi
  fi

  # Prompt if guarded.
  if ${prompt_yourself}; then
    echo -n "Are you sure this is absolutely what you want? [Y/n] "
    read -e YES_OR_NO
    if [[ ${YES_OR_NO^^} =~ ^Y.* ]] || [ -z "${YES_OR_NO}" ]; then
      # FIXME/2017-06-06: Someday soon I'll remove this sillinessmessage.
      # - 2020-01-08: lb: I'll see it when I believe it.
      echo "YASSSSSSSSSSSSS"
    else
      echo "I see"
      disallowed=true
    fi
  fi

  if ! ${disallowed}; then
    command git "$@"
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# *** git-bfg wrapper.

git-bfg () {
  # Note that the ZP Ansible git-bfg install task makes a symlink to the BFG JAR,
  # whose name includes the version, SHA, and branch, e.g., it might really be
  # called "bfg-1.13.1-SNAPSHOT-master-5158aa4.jar".
  local bfg_jar="${HOME}/.local/bin/bfg.jar"
  if [ ! -f "${bfg_jar}" ]; then
    local zphf_uroi="https://github.com/landonb/zoidy_home-fries"
    local help_hint="Run the Zoidy Pooh task ‘app-git-the-bfg’ from: ${zphf_uroi}"
    >&2 echo "ERROR: The BFG is not installed. ${help_hint}"
    return 1
  fi
  java -jar ${HOME}/.local/bin/bfg.jar "$@"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main () {
  # unalias git 2> /dev/null
  alias git='_paranoid_git'
}

main "$@"
unset -f main

