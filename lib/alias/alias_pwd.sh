#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=bash
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

home_fries_aliases_wire_pwd() {
  # [lb] uses p frequently, just like h and ll.
  # - HSTRY: Previously just a simple alias with no side-effects:
  #     claim_alias_or_warn "p" "pwd"
  #   But now copies to clipboard.
  #   - UCASE: In macOS Save dialog, if file list has focus, pressing
  #     "/" key (and only that key, AFAIK; and pasting doesn't work)
  #     lets you enter a path to the target directory. But you cannot
  #     paste a ~/path without deleting the "/" that you typed (or else
  #     the path looks like "/~/path", which obvi. won't work). You
  #     can, however, paste a full path (such that the path starts
  #     with a double-"/", e.g., "//path", which is acceptable).
  #     - Otherwise I almost always use "P" when I want to copy a
  #       file path, because usually I want the tilde path (which
  #       is not only shorter, but works across hosts, regardless
  #       of the home directory path or username (i.e., /home/user
  #       vs. /User/home)).
  command -v pbcopy >/dev/null &&
    claim_alias_or_warn "p" \
      'pwd | tee >(tr -d \"\n\" | pbcopy)' ||
    claim_alias_or_warn "p" \
      'pwd | tee >(tr -d \"\n\" | xclip -selection c)'

  # 2021-01-28: A real wisenheimer.
  #  claim_alias_or_warn "P" 'pwd && pwd | tr -d "\n" | xclip -selection c'
  # 2022-11-04: Crank it up a notch?
  # - Print current directory to stdout and copy to clipboard,
  #   after replacing leading home path with tilde.
  #   - Use case: Pasting somewhere, like notes, where you might
  #     want to use a user-agnostic home path, or you just want
  #     a shorter path.
  command -v pbcopy >/dev/null &&
    claim_alias_or_warn "P" \
      'pwd | sed -E \"s#^${HOME}(/|$)#~\1#\" | tee >(tr -d \"\n\" | pbcopy)' ||
    claim_alias_or_warn "P" \
      'pwd | sed -E \"s#^${HOME}(/|$)#~\1#\" | tee >(tr -d \"\n\" | xclip -selection c)'
}

# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ #

if [ "$0" = "${BASH_SOURCE[0]}" ]; then
  >&2 echo "ERROR: Trying sourcing the file instead: . $0" && exit 1
fi
