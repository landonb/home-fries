#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# SAVVY: Omit a few chars from passwords, so that the history cleaner
# doesn't mistake file paths for passwords, e.g., a path suchs as this:
#     $ echo this-file-is-NUMBER-01 \
#       | perl -p -e \
#         's/(^|\s)(?=[^\s]*[a-z][^\s]*)(?=[^\s]*[A-Z][^\s]*)(?=[^\s]*[0-9][^\s]*)[^\s]{15,24}(\s|\n|$)/\1XXXX_REDACT_XXXX\2/g'
#     XXXX_REDACT_XXXX
#   - CXREF: ~/.homefries/lib/hist_util.sh
# - Use `pwgen -r`, but note this "will disable the phomeme-based generator
#   and uses the random password generator."
#   - CXREF: https://github.com/tytso/pwgen/blob/master/pw_phonemes.c

PWGEN_OMIT="${PWGEN_OMIT:--r -/}"

home_fries_aliases_wire_pwgen () {
  # 2016-09-24: Why didn't I think of this 'til now?
  # [Note also that pass can just do it, too.]
  claim_alias_or_warn "pwgen16" "pwgen -n 16 -s -N 1 -y ${PWGEN_OMIT}"
  claim_alias_or_warn "pwgen21" "pwgen -n 21 -s -N 1 -y ${PWGEN_OMIT}"

  # 2022-09-25: To make double-clicking passwords in the terminal easier
  # to copy-paste, ensure first two and final two characters are alphanums.
  # Not to give the game away. The password is still secure. At least
  # until quantum computing screws us over and we all need to move to
  # elliptic-curve cryptography.
  # - Note the surrounding () is necessary for redirection, e.g., `pwgen23 > foo`.
  claim_alias_or_warn "pwgen23" "_hf_aliases_wire_pwgen_clip_and_print"
}

_hf_aliases_wire_pwgen_pwgen23 () {
  pwgen 2 1 ${PWGEN_OMIT} \
    | tr -d '\n'
  pwgen -n 21 -s -N 1 -y ${PWGEN_OMIT} \
    | tr -d '\n'
  pwgen 2 1 ${PWGEN_OMIT}
}

_hf_aliases_wire_pwgen_clip_and_print () {
  local pwd="$(_hf_aliases_wire_pwgen_pwgen23)"

  echo "${pwd}" | _hf_aliases_wire_pwgen_clip_and_print_os_aware
}

_hf_aliases_wire_pwgen_clip_and_print_os_aware () {
  type xclip > /dev/null 2>&1 \
    && cat | tee >(tr -d "\n" | xclip -selection c) \
    || cat | tee >(tr -d "\n" | pbcopy)
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

unset_f_alias_pwgen () {
  unset -f home_fries_aliases_wire_pwgen
  # So meta.
  unset -f unset_f_alias_pwgen
}

# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ #

if [ "$0" = "${BASH_SOURCE[0]}" ]; then
  >&2 echo "ERROR: Trying sourcing the file instead: . $0" && exit 1
fi

