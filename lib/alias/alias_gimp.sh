#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

home_fries_aliases_wire_gimp () {
  home_fries_create_alias_gimp_flatpak
  home_fries_create_alias_gimp_macos
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

home_fries_create_alias_gimp_flatpak () {
  # SAVVY/2023-04-23: This directory created on first run, so unreliable.
  #  [ -d "${HOME}/.var/app/org.gimp.GIMP" ] || return
  [ -d "${HOME}/.local/share/flatpak/app/org.gimp.GIMP" ] \
    || [ -d "/var/lib/flatpak/app/org.gimp.GIMP" ] \
    || return
  # See also:
  #   if flatpak info org.gimp.GIMP > /dev/null 2>&1; then
  #     ...
  # but not as quick as dir-check.

  # Desktop entry is more complicated:
  #   /usr/bin/flatpak run \
  #     --branch=stable \
  #     --arch=x86_64 \
  #     --command=gimp-2.10 \
  #     --file-forwarding org.gimp.GIMP \
  #     @@u %U @@

  # Note that we shadow /usr/bin/gimp
  alias gimp="flatpak run org.gimp.GIMP"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

home_fries_create_alias_gimp_macos () {
  [ "$(uname)" = "Darwin" ] || return

  # gimp is hashed (/usr/local/bin/gimp) by default, but
  # running `gimp` itself generates warnings and exits 255.

  # FIXME/2023-04-30: Make this version-agnostic.
  # - TRYME: Wouldn't this work?
  #     alias gimp="open /Applications/GIMP-*.app"
  #
  # claim_alias_or_warn "gimp" "open /Applications/GIMP-2.10.app"
  alias gimp="open /Applications/GIMP-2.10.app"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

unset_f_alias_gimp () {
  unset -f home_fries_aliases_wire_gimp
  unset -f home_fries_create_alias_gimp_flatpak
  unset -f home_fries_create_alias_gimp_macos
  # So meta.
  unset -f unset_f_alias_gimp
}

# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ #

if [ "$0" = "${BASH_SOURCE[0]}" ]; then
  >&2 echo "ERROR: Trying sourcing the file instead: . $0" && exit 1
fi

