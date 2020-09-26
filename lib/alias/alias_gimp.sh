#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

home_fries_aliases_wire_gimp () {
  home_fries_create_alias_flatpak_gimp
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

home_fries_create_alias_flatpak_gimp () {
  if [ -d "${HOME}/.var/app/org.gimp.GIMP" ]; then
    # Desktop entry is more complicated:
    #   /usr/bin/flatpak run \
    #     --branch=stable \
    #     --arch=x86_64 \
    #     --command=gimp-2.10 \
    #     --file-forwarding org.gimp.GIMP \
    #     @@u %U @@
    alias gimp='flatpak run org.gimp.GIMP'
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

unset_f_alias_gimp () {
  unset -f home_fries_aliases_wire_gimp
  unset -f home_fries_create_alias_flatpak_gimp
  # So meta.
  unset -f unset_f_alias_gimp
}

# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ #

main () {
  :
}

main ""
unset -f main

