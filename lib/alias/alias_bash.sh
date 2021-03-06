#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

home_fries_aliases_wire_bash () {
  # 2016-06-28: Stay in same dir when launching bash.
  unalias bash 2> /dev/null
  # 2020-03-22: If run from tmux, ensure PROMPT_COMMAND unset,
  #             lest on every command you see, e.g.,
  #               __vte_prompt_command: command not found
  #             (AFAIK, __vte_prompt_command added by tmux.)
  alias bash='HOMEFRIES_CD="$(pwd)" PROMPT_COMMAND= bash'
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

unset_f_alias_bash () {
  unset -f home_fries_aliases_wire_bash
  # So meta.
  unset -f unset_f_alias_bash
}

# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ #

if [ "$0" = "${BASH_SOURCE[0]}" ]; then
  >&2 echo "ERROR: Trying sourcing the file instead: . $0" && exit 1
fi

