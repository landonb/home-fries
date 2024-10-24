#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=bash
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

home_fries_aliases_wire_pwd () {
  # [lb] uses p frequently, just like h and ll.
  claim_alias_or_warn "p" "pwd"

  # 2021-01-28: A real wisenheimer.
  #  claim_alias_or_warn "P" 'pwd && pwd | tr -d "\n" | xclip -selection c'
  # 2022-11-04: Crank it up a notch?
  # - Print current directory to stdout and copy to clipboard,
  #   after replacing leading home path with tilde.
  #   - Use case: Pasting somewhere, like notes, where you might
  #     want to use a user-agnostic home path, or you just want
  #     a shorter path.
  type xclip > /dev/null 2>&1 \
    && claim_alias_or_warn "P" \
      'pwd | sed -E \"s#^${HOME}(/|$)#~\1#\" | tee >(tr -d \"\n\" | xclip -selection c)' \
    || claim_alias_or_warn "P" \
      'pwd | sed -E \"s#^${HOME}(/|$)#~\1#\" | tee >(tr -d \"\n\" | pbcopy)'
}

# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ #

if [ "$0" = "${BASH_SOURCE[0]}" ]; then
  >&2 echo "ERROR: Trying sourcing the file instead: . $0" && exit 1
fi

