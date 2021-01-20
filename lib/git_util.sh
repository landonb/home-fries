#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# Most of my Git magic is elsewhere:
#
#   github.com:landonb/git-smart#💡
#   github.com:landonb/git-veggie-patch#🥦
#   github.com:landonb/git-my-merge-status#🌵
#   and more to come!

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# 2021-01-19: Are you look for _git_safe () ?
# - I moved it to:
#
#     https://github.com/landonb/git-smart/blob/release/lib/XXX

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# *** git-bfg wrapper.

# 2021-01-19: This is quite stale. I think I demoed BFG once,
#             but I never started using it for anything.

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
  :
}

main "$@"
unset -f main

