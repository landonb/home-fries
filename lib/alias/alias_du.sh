#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

home_fries_aliases_wire_du() {
  alias du="du -h"

  # DUNNO: Addubg `-C right` arg causes column to print leading empty line.
  claim_alias_or_warn "dum" "du -m -d 1 . | sort -n | column -t -C right | sed '/^\s\+$/d'"

  claim_alias_or_warn "dub" "du -b -d 1 . | sort -n | column -t -C right | sed '/^\s\+$/d'"

  # NOTED/2024-06-13: Duh.
  # - PREVY/2026-02-06: Nothing simple lasts forever.
  #   - New `dud` is how `duh` used to behave.
  #   - We probably don't need `dud`, other than
  #     to show how `duh` improves upon it (assuming
  #     you think `duh` is an improvement).
  #   - We might also drop or at least rename `dud` in
  #     the future, esp. because it's a fun command name,
  #     and I bet some feature will come along that's more
  #     deserving of such a cool command name.
  claim_alias_or_warn "dud" "du -h -d 1 ."
  # HSTRY/2026-02-06: Adding `dup` in case one wants
  # to sort `du` output by path name (though author
  # assumes I'll probably mostly use complicated new
  # `duh` that sorts human-readable output by usage
  # size, because previously I'd mostly use `dum` to
  # sort by size, but now I've got `duh` that sorts
  # by size *and* uses “human-readable” size values!).
  # - `dup` is also kinda a fun name, so don't expect
  #   that this command won't be renamed or dropped
  #   in the future, just like `dud` is "not safe".
  claim_alias_or_warn "dup" "du -h -d 1 . | sort -k2,2"
  claim_alias_or_warn "duh" "_hf_duh"

  # claim_alias_or_warn "duhome" "du -ah /home | sort -n"

  # Use same units, else sort mingles different sizes.
  # cd ~ && du -BG -d 1 . | sort -n

  # See also the `free` alias.

  # List the top 20 files/folders sizes.
  claim_alias_or_warn "dutop" 'du -sh * | sort -hr | head -20'
}

# Print "human-readable" size values (uses closest block
# size to minimize printed value length), but sort by size,
# from largest to least; and right-align the size values.
# - We use sed to assign the block size unit an integer value
#   we can sort on.
#   - We pick out the size unit using awk, as well as the
#     size value without the trailing unit, and use those
#     two values to sort; afterwards, we awk again to remove
#     those temporary sorting fields.
#   - Per man: "Units are K,M,G,T,P,E,Z,Y,R,Q (powers of 1024)...."
#     - Which we map to 0,1,2,...9, and reverse-sort on.

_hf_duh() {
  du -h -d 1 . |
    awk '{ print substr($1, length($1)), substr($1, 0,length($1)-1), $0 }' |
    sed \
      -e 's/^K/0/' \
      -e 's/^M/1/' \
      -e 's/^G/2/' \
      -e 's/^T/3/' \
      -e 's/^P/4/' \
      -e 's/^E/5/' \
      -e 's/^Z/6/' \
      -e 's/^Y/7/' \
      -e 's/^R/8/' \
      -e 's/^Q/9/' |
    sort -k1rn,1 -k2rn,2 |
    awk '{$1=""; $2=""}1' |
    column -t -C right |
    sed '/^\s\+$/d'
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

unset_f_alias_du() {
  unset -f home_fries_aliases_wire_du
  # So meta.
  unset -f unset_f_alias_du
}

# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ #

if [ "$0" = "${BASH_SOURCE[0]}" ]; then
  >&2 echo "ERROR: Trying sourcing the file instead: . $0" && exit 1
fi
