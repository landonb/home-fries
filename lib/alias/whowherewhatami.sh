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
#   ## alias whereami=is an actual package you can install.
#   # alias whereami="echo 'How should I know?' ; \
#   #   /usr/bin/python /usr/lib/command-not-found whereami"
#   npm install -g @rafaelrinaldi/whereami

home_fries_aliases_wire_amis () {
  alias howami="echo 'Doing well. Thanks for asking.' ; \
                /usr/bin/python /usr/lib/command-not-found howami"
  alias whatami="echo 'Neither plant nor animal.' ; \
                /usr/bin/python /usr/lib/command-not-found whatami"
  alias whenami="echo 'You are in the here and now.' ; \
                /usr/bin/python /usr/lib/command-not-found whenami"
  alias whyami="echo 'Because you gotta be somebody.' ; \
                /usr/bin/python /usr/lib/command-not-found whyami"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

unset_f_alias_amis () {
  unset -f home_fries_aliases_wire_amis
  # So meta.
  unset -f unset_f_alias_amis
}

# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ #

main () {
  :
}

main ""
unset -f main

