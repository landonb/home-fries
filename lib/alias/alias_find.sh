#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

home_fries_aliases_wire_find () {
  # Does this help?
  claim_alias_or_warn "findi" "find . -iname"

  # Show directory statistics: show count of files of each extension.
  # NOTE: \L to convert string to lowercase
  claim_alias_or_warn "stats" "find . -type f -not -path './.git/*' | /usr/bin/env sed -n 's/..*\.//p' | /usr/bin/env sed -E 's/(.*)/\L\1/' | sort | uniq -c | sort -n -r"

  # Previous match finds files with dot.ends. Next one includes all files.
  #   claim_alias_or_warn "mostats" "find . -type f -not -path './.git/*' | /usr/bin/env sed -n 's/\(..*\.\)\?\(..*\/\)\?//p' | /usr/bin/env sed -E 's/(.*)/\L\1/' | sort | uniq -c | sort -n -r"
  # Or collect undotted files into one unnamed file count.
  claim_alias_or_warn "mostats" "find . -type f -not -path './.git/*' | /usr/bin/env sed -n 's/\(..*\.\)\?//p' | /usr/bin/env sed -E 's/(.*)/\L\1/' | /usr/bin/env sed -n 's/\(..*\/.*\)\?//p' | sort | uniq -c | sort -n -r"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

unset_f_alias_find () {
  unset -f home_fries_aliases_wire_find
  # So meta.
  unset -f unset_f_alias_find
}

# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ #

if [ "$0" = "${BASH_SOURCE[0]}" ]; then
  >&2 echo "ERROR: Trying sourcing the file instead: . $0" && exit 1
fi

