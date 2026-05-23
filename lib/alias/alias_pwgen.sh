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

home_fries_aliases_wire_pwgen() {
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
  claim_alias_or_warn "pwgen23" "_hf_pwgen23_clip_echo"

  claim_alias_or_warn "pwgenPIN" \
    "pwgen -A -r abcdefghijklmnopqrstuvwxyz \\\${PWGEN_PINLEN:-4} \
    | _hf_clip_echo"

  claim_alias_or_warn "pwgenPINs" "_hf_pwgenPINs"
}

# ***

_hf_pwgen23() {
  pwgen 2 1 ${PWGEN_OMIT} |
    tr -d '\n'
  pwgen -n 21 -s -N 1 -y ${PWGEN_OMIT} |
    tr -d '\n'
  pwgen 2 1 ${PWGEN_OMIT}
}

# ***

_hf_pwgen23_clip_echo() {
  local pwd="$(_hf_pwgen23)"

  echo "${pwd}" | _hf_clip_echo
}

# ***

# pwgen PIN generator.
#
# - UCASE: Like default `command pwgen` output, but 4-digit PINs!
#
# REFER:
#
# - We could use Bash `{a..z}` instead of literal a-z.
#   - Author often forgets that {a..z} exists, but then I realize
#     that it's not as portable (POSIX) as literal a-z. Which is a
#     good reason to avoid {a..z}-like expansions.
#   - You'd also want to use `printf %c {a..z}`,
#     because `echo {a..z}` delimits with spaces.
#   - Because not POSIX, let's not be clever; use literal a-z,
#     not {a..z}, so non-Bash devs can use this code.
#
# - Use `pwgen -A` instead of {A..Z}.
#   - Note {A..Z} doesn't technically work:
#       $ pwgen -r abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ
#       Error: No upper case letters left in the valid set
#   - And the work-around is a teeny-tiny bit stanky, e.g.:
#       pwgen -r $(printf '%c' {a..z})$(printf '%c' {A..Y}) -N 100 \
#         | sed 's/[Z ]//g' \
#         ...
#   - Aside: I love the crassity of the manual description:
#       -A, --no-capitalize
#           Don't bother to include any capital letters in the generated passwords.
#     - "Don't bother"! =P
#
# - When printing to an interactive terminal, the pwgen output is wrapped
#   at around 72 characters, and each row is 8 columns of 8 characters
#   (8 chars plus a space is ((8+1)*8) = 9*8 = 72 characters per line).
#   - So there are eight 8-character random passwords per line.
#     - E.g., you can print one row (line) of output with `pwgen -N 8`.
#     - Or two rows with `-N 16`, etc.
#   - But when piping pwgen output, it prints only one password *per line*.
#     - E.g., `pwgen | cat` is equivalent to `pwgen -N 1`:
#         $ pwgen | cat
#         Ju6yei4o
#         $ pwgen -N 1
#         Seech1ge
#     - SAVVY: Note the default `pwgen` command prints 20 (!) rows,
#       equivalent to `-N $((20 * 8))` or `-N 160`.
#
# - As noted, non-interactive pwgen prints only one password *per line*,
#   e.g.:
#     $ pwgen -N 2 | cat
#     Ohx6eCha
#     ooF5ieki
#   - So remove newlines (tr -d), which creates a long string of
#     random digits [Calculated for fun: 20*8*8 = 1,280 digits].
#
# - Separate long string into groups of digits (_hf_spacify).
#   - PINs are generally 4 digits, so add a space every 4 digits.
#
# - Wrap output based on terminal width (_hf_wrap_at_most).
#   - Wrap at max. width 80, or terminal window width, whichever is less.
#     - (4-digit PIN + 1 space) * 8 (8-char pwds/ln. normally) * 2 = 5 * 16 = 80.
#       - I.e., wrap at 80 characters, so output is 16 4-digit PINs,
#         each separated by a space.

_hf_pwgenPINs() {
  # ALTLY: But less portable, using Bash {a..z} and $(( )):
  #   pwgen -A -r $(printf '%c' {a..z}) -N $((20 * 8)) |
  pwgen -A -r abcdefghijklmnopqrstuvwxyz -N $(echo "20 * 8" | bc) |
    tr -d '\n' |
    _hf_spacify ${PWGEN_PINLEN:-4} |
    _hf_wrap_at_most ${PWGEN_MAXWRAP:-80}
  echo
}

# ***

# Insert a space every X characters.
#
# - Using sed:
#     sed 's/.\{X\}/& /g'
#   - E.g.:
#     $ echo "123456789" | sed 's/.\{3\}/& /g'
#     123 456 789
#   - Aside/Funny: Ha, the Google AI Overview example output is incorrect
#     (unsurprisingly):
#       echo "123456789" | sed 's/.\{3\}/& /g'
#       # Output: 123456 789
#     - Obviously, it should be this:
#       echo "123456789" | sed 's/.\{3\}/& /g'
#       # Output: 123 456 789
# - Using fold:
#     fold -wX
#   - Though because fold adds line breaks, you need to rejoin
#     lines using a space, e.g.:
#       $ echo "ABCDEFGH" | fold -w4 | paste -sd' '
#       ABCD EFGH
# - Using awk (useful if already using awk (otherwise syntax
#   is less obvious to most casual Linux used, IMHO)):
#   - E.g.:
#       $ echo "11223344" | awk '{gsub(/.{2}/,"& ")}1'
#       11 22 33 44
#
# - THANX: Examples above copied (and fixed) from GAIO:
#   https://www.google.com/search?q=bash+insert+space+every+x+characters

_hf_spacify() {
  sed 's/.\{'$1'\}/& /g'
}

# ***

# Wrap output at specified max width, or terminal width if less.
#
# - Using fold:
#   - Hard wrap at exact width, e.g., at the terminal width:
#     cat yourfile.txt | fold -w $(tput cols)
#   - Wrap on spaces (don't break words), e.g.:
#     cat yourfile.txt | fold -s -w $(tput cols)
#
# - Using fmt:
#   - "Soft" wrap at the terminal width:
#     cat yourfile.txt | fmt -w $(tput cols)
#     - Dunno: Author unclear exactly how fmt works. The -w width
#       is more of a suggestion. See also `fmt -g` goal width, ha.
#     - Also, fmt also uses a double-space instead of a line break
#       to delimit paragraphs.
#       - E.g., compare these outputs:
#
#          rand_lipsum="$(
#            curl -s -X POST https://lipsum.com/feed/json \
#              | jq -r '.feed.lipsum'
#          )"
#          meld \
#            <(echo "by fold" ; echo "${rand_lipsum}" | fold -s -w ${PWGEN_MAXWRAP:-80}) \
#            <(echo "by fmt!" ; echo "${rand_lipsum}" | fmt -w ${PWGEN_MAXWRAP:-80}) &
#
# - Aside: Truncate each line instead of wrapping it:
#     cat yourfile.txt | cut -c 1-$(tput cols)
#   - TRYME: DepoXy users can more easily play with Lorem text, e.g.:
#       lipsum | cut -c 1-$(tput cols)
#     - Or:
#       lip="$(lorem-ipsum)" ; echo -e "RAW:\n${lip}\n\nCUT:" ; echo "${lip}" | cut -c 1-$(tput cols)
#
# - THANX: https://www.google.com/search?q=bash+terminal+split+text+at+terminal+width

# Don't break words, aka split on spaces (fold -s); and break (fold -w)
# at specified width ($1) or terminal width (tput cols)
_hf_wrap_at_most() {
  fold -s -w $(_hf_min $(tput cols) $1)
}

# ***

# Min/Max funcs.
#
# - Print maximum value examples:
#   - Integer max, using ternary operator and arithmetic expansion:
#     a=420 ; b=69 ; max=$(( a > b ? a : b ))
#   - Float max:
#     a=10.5 ; b=10.2 ; max=$(awk -v n1="$a" -v n2="$b" 'BEGIN {print (n1>n2 ? n1 : n2)}')
#   - Using a list, which is reverse-numerically sorted:
#     numbers=(5 12 8 43 2)
#     max=$(printf "%s\n" "${numbers[@]}" | sort -nr | head -1)
#
# - THANX: https://www.google.com/search?q=bash+pick+max+of+two+values

# USAGE: E.g.:
#   val=$(_hf_max 800 85)
_hf_max() {
  echo $(($1 > $2 ? $1 : $2))
}

_hf_min() {
  echo $(($1 < $2 ? $1 : $2))
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

unset_f_alias_pwgen() {
  unset -f home_fries_aliases_wire_pwgen
  # So meta.
  unset -f unset_f_alias_pwgen
}

# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ #

# Technically BASH_SOURCE[0], but let's be POSIX-compliant.
if [ "$0" = "${BASH_SOURCE}" ]; then
  >&2 echo "ERROR: Trying sourcing the file instead: . $0" && exit 1
fi
