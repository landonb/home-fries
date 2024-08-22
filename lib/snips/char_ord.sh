# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# REFER: From `man printf`: "If the leading character is a single or double
# quote, the value is the character code of the next character."

print_char_ord () {
  LC_CTYPE=C printf %d "'$1"
}

