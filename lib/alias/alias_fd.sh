#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# 2020-09-26: -H/--hidden: Include hidden files and directories
# 2021-11-10: -I/--no-ignore: Ignore .gitignore, .ignore or .fdignore rules.
# 2023-01-25: - I want to use -H and -I because I use ignore rules to avoid
#               duplicate grep results caused by symlinks, but I don't want
#               `fd` to ignore those symlinks. (Another way to consider this:
#               my `fd` rules are different than my `rg` rules, but I do not
#               want to have to maintain two sets of rules.)
#               - Anyway, here's that basic command:
#                   alias fd="fd -H -I"
#               - However, you'll end up with some obvious noise, like any
#                 .git/ directory.
#               - Fortunately, a little `fd` noise is not a big deal (I don't
#                 run `fd` often), but seeing a bunch of .git/ hits (e.g., in
#                 .git/refs branch names) that are obviously uninteresting to
#                 any user is certainly beyond the pale (and users can just
#                 `cd` into .git/ dir if they really want to search it).
#               - So let's inject some hardcoded business logic here, but it's
#                 generally pretty universal business logic, so no worries,
#                 there is no coupling concern (by which I mean, for now it's
#                 just one rule to ignore .git/ dirs, but maybe we'll identify
#                 more rules later, and perhaps then we'll want to make this
#                 setting customizable; but for now `-E .git/` is too easy).
#             -E/--exclude pattern: I think this is the easiest approch
#               (note: "This overrides any other ignore logic." but we're
#                also using -I so doesn't matter).
#             --ignore-file path: Alternative approach
#               (e.g., `/usr/bin/env fd -H -I --ignore-file <(echo .git/) <term>`
home_fries_aliases_wire_fd () {
  if command -v fd > /dev/null; then
    alias fd="fd -H -I -E .git/ -E __pycache__/ -E htmlcov/"
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

unset_f_alias_fd () {
  unset -f home_fries_aliases_wire_fd
  # So meta.
  unset -f unset_f_alias_fd
}

# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ #

if [ "$0" = "${BASH_SOURCE[0]}" ]; then
  >&2 echo "ERROR: Trying sourcing the file instead: . $0" && exit 1
fi

