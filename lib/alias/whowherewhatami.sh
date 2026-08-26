#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# *** ``*ami``s

# The `whoami` is just `id -un` in disguise.
# Here are its lesser known sibling commands.
#
# 2018-03-28: There's a package for that!
#   ## claim_alias_or_warn "whereami" "is an actual package you can install."
#   # claim_alias_or_warn "whereami" "echo 'How should I know?' ; \
#   #   /usr/bin/python /usr/lib/command-not-found whereami"
#   npm install -g @rafaelrinaldi/whereami

# Sometimes same output as command-not-found, e.g.,
#     $ python3 /usr/lib/command-not-found howami
#     howami: command not found
# - But not always, e.g.,
#     $ python3 /usr/lib/command-not-found whyami
#     Command 'whyami' not found, did you mean:
#       command 'whoami' from deb coreutils
#     Try: sudo apt install <deb name>
#
# HSTRY/2026-08-26: Removed /usr/lib/command-not-found usage because not
# installed on Debian by default. Also overkill. Espec. for Joke Aliases.

home_fries_aliases_wire_amis() {
  claim_alias_or_warn "howami" \
    "echo -e 'Doing well. Thanks for asking.\nhowami: command not found'"
  claim_alias_or_warn "whatami" \
    "echo -e 'Neither plant nor animal.\nwhatami: command not found'"
  claim_alias_or_warn "whenami" \
    "echo -e 'You are in the here and now.\nwhenami: command not found'"
  claim_alias_or_warn "whyami" \
    "echo -e 'Because you gotta be somebody.\nwhyami: command not found'"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

unset_f_alias_amis() {
  unset -f home_fries_aliases_wire_amis
  # So meta.
  unset -f unset_f_alias_amis
}

# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ #

if [ "$0" = "${BASH_SOURCE[0]}" ]; then
  >&2 echo "ERROR: Trying sourcing the file instead: . $0" && exit 1
fi
