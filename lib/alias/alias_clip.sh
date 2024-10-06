#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma <https://tallybark.com/>
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# USAGE: echo "foo" | clip
#
# - Copies whatever is on stdin to the clipboard.
home_fries_aliases_wire_clip () {
  claim_alias_or_warn "clip" "_hf_clip"
}

_hf_clip () {
  tee >(tr -d "\n" | $(command -v xclip > /dev/null && xclip-selection c || pbcopy))
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# Called by `home_fries_bashrc_cleanup`
unset_f_alias_clip () {
  unset -f home_fries_aliases_wire_clip
  # So meta.
  unset -f unset_f_alias_clip
}

# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ #

if [ "$0" = "${BASH_SOURCE[0]}" ]; then
  >&2 echo "ERROR: Trying sourcing the file instead: . $0" && exit 1
fi

