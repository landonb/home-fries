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

home_fries_aliases_wire_amis () {
  claim_alias_or_warn "howami" "echo 'Doing well. Thanks for asking.' ; \
                /usr/bin/python /usr/lib/command-not-found howami"
  claim_alias_or_warn "whatami" "echo 'Neither plant nor animal.' ; \
                /usr/bin/python /usr/lib/command-not-found whatami"
  claim_alias_or_warn "whenami" "echo 'You are in the here and now.' ; \
                /usr/bin/python /usr/lib/command-not-found whenami"
  claim_alias_or_warn "whyami" "echo 'Because you gotta be somebody.' ; \
                /usr/bin/python /usr/lib/command-not-found whyami"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

unset_f_alias_amis () {
  unset -f home_fries_aliases_wire_amis
  # So meta.
  unset -f unset_f_alias_amis
}

# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ #

if [ "$0" = "${BASH_SOURCE[0]}" ]; then
  >&2 echo "ERROR: Trying sourcing the file instead: . $0" && exit 1
fi

