#!/bin/bash
# vim:tw=0:ts=2:sw=2:et:norl:spell:ft=sh
# Project: https://github.com/landonb/home-fries
# License: GPLv3

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# USAGE: Source this file. Call its functions, e.g., in `echo -e` calls,
# such as:
#
#   echo -e "$(fg_pink)Hello!$(attr_reset) $(attr_underlined)Goodbye!$(attr_reset)"

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# (lb): Hrmmm. What's better, Opt-in, or Opt-out?
# - I wouldn't want people *not* to have a good experience by default.

HOMEFRIES_NO_COLOR=${HOMEFRIES_NO_COLOR:-false}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# Ref:
# - "Bash tips: Colors and formatting (ANSI/VT100 Control sequences)"
#   https://misc.flogisoft.com/bash/tip_colors_and_formatting

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# NOTE:
# - We cannot rely on normal interactive terminal checking, e.g.,
#     [ -z "$PS1" ] && return 0 || return 1
#     # Or:
#     [[ "$-" =~ .*i.* ]] && return 1 || return 0
#   because user-run scripts can themselves run scripts, but
#   the latter-run scripts would not be considered interactive.
# - As specified in the bash manual::
#     PS1 is set and $- includes i if bash is interactive, allowing
#     a shell script or a startup file to test this state.
# - More to the point:
#   $ [[ "$-" =~ .*i.* ]] && echo YES || echo NO
#   YES
#   $ /bin/bash -c '[[ "$-" =~ .*i.* ]] && echo YES || echo NO'
#   NO
#   $ echo -e "#!/bin/bash\n[[ \"\$-\" =~ .*i.* ]] && echo YES || echo NO\n" \
#     > /tmp/test.sh
#   $ chmod 775 /tmp/test.sh
#   $ /tmp/test.sh
#   NO
# Same goes for PS1. I.e.,
#   $ echo $PS1
#   \[\e...
#   $ /bin/bash -c 'echo $PS1'
#   # EMPTY
#   $ echo -e '#!/bin/bash\necho $PS1' > /tmp/test.sh && /tmp/test.sh
#   # EMPTY
# NOTE:
# - That said, home-fries does check $- once -- in _export_homefries_no_color,
#   on startup -- so that it can set (export) HOMEFRIES_NO_COLOR.
#   - Such that, while $- will not indicate 'i' for subshell processes,
#     the user's HOMEFRIES_NO_COLOR environ will be set.
# - This means that whatever the user does from the terminal will be
#   inherently colorful. But whatever user scripts run from anacron or
#   similar will have to explicitly ask for color.

_hofr_no_color () {
  # User/Caller may set HOMEFRIES_NO_COLOR=false to disable color.
  ( [ -z ${HOMEFRIES_NO_COLOR+x} ] || ${HOMEFRIES_NO_COLOR} ) && return 0 || return 1
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# (lb): In Bash, the escape sequences \e, \033 and \x1b can be used
#       interchangeably, but \033 is the more portable of the 3.
# - The `\e` is a character escape sequence; the other two are Oct.
#   and Hex. reps., respect. (See also ^[, i.e., you can hit Ctrl-[
#   to send ESCAPE sequence. And also 27, the decimal equivalent.)
# - Because the `\e` representation feels more Bashy (and probably is
#   less universal), we'll use either the octal or hexadecimal format.
#   - Let's use the octal format.
#     - A search on "\033" returns 255,000 hits,
#     - A search on "\x1b" returns 74,100 results.
#     - (And on "\e", 4,970,000 results, but that includes
#       "\E NO. 316 - City of Drain" in the top 100 results
#       (AN ORDINANCE FIXING ELECTRICAL RATES).)
#     - Not that we should not always be sheep and follow the
#       masses, but we gotta decide somehow.
# tl,dr: Prefer `\033` below, not `\e` or `\x1b`.

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# NOTE: tmux doesn't show all the ANSI color codes, but maps some to other colors
#       (like pink and orange to red).
#       - E.g., for lightorange, when TERM=*-256color:
#           echo "\033[38;5;215m"
#         works.
#       - But in tmux, when TERM=tmux, lightorange maps to red.
#       - So use RGB format.
# R,G,B Formats:
#   \033[38;2;<r>;<g>;<b>m  # RGB foreground color.
#   \033[48;2;<r>;<g>;<b>m  # RGB background color.
# (lb): I used Gimp to extract RGB from
#   https://i.stack.imgur.com/KTSQa.png
# via
#   https://en.wikipedia.org/wiki/ANSI_escape_code

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

fg_pink () {
  _hofr_no_color && return
  ### === HIGH-COLOR === compatible with most terms including putty
  ### for windows... use colors that don't make your eyes bleed :)
  # NOTE/2017-05-03: Single quotes do not work. What's up with that?
  #   E.g., export PINK='\\033[38;5;211m'
  # Via TERM=*-256color:
  #   echo "\033[38;5;211m"
  echo "\033[38;2;255;135;175m"
}

fg_orange () {
  _hofr_no_color && return
  # Via TERM=*-256color:
  #   echo "\033[38;5;203m"
  echo "\033[38;2;255;95;95m"
}

# 2016-10-09: FG_SKYBLUE broken.
fg_skyblue () {
  _hofr_no_color && return
  # Via TERM=*-256color:
  #   echo "\033[38;5;111m"
  echo "\033[38;2;135;175;255m"
}

fg_mediumgrey () {
  _hofr_no_color && return
  # Via TERM=*-256color:
  #   echo "\033[38;5;246m"
  echo "\033[38;2;148;148;148m"
}

fg_lavender () {
  _hofr_no_color && return
  # Via TERM=*-256color:
  #   echo "\033[38;5;183m"
  echo "\033[38;2;215;175;255m"
}

fg_tan () {
  _hofr_no_color && return
  # Via TERM=*-256color:
  #   echo "\033[38;5;179m"
  echo "\033[38;2;215;175;95m"
}

fg_forest () {
  _hofr_no_color && return
  # Via TERM=*-256color:
  #   echo "\033[38;5;22m"
  echo "\033[38;2;0;95;0m"
}

fg_maroon () {
  _hofr_no_color && return
  # Via TERM=*-256color:
  #   echo "\033[38;5;52m"
  echo "\033[38;2;95;0;0m"
}

fg_hotpink () {
  _hofr_no_color && return
  # Via TERM=*-256color:
  #   echo "\033[38;5;198m"
  echo "\033[38;2;255;0;135m"
}

fg_mintgreen () {
  _hofr_no_color && return
  # Via TERM=*-256color:
  #   echo "\033[38;5;121m"
  echo "\033[38;2;135;255;175m"
}

fg_lightorange () {
  _hofr_no_color && return
  # Via TERM=*-256color:
  #   echo "\033[38;5;215m"
  echo "\033[38;2;255;175;95m"
}

fg_lightred () {
  _hofr_no_color && return
  # Via TERM=*-256color:
  #   echo "\033[38;5;203m"
  echo "\033[38;2;255;95;95m"
}

fg_jade () {
  _hofr_no_color && return
  # Via TERM=*-256color:
  #   echo "\033[38;5;35m"
  echo "\033[38;2;0;175;95m"
}

fg_lime () {
  _hofr_no_color && return
  # Via TERM=*-256color:
  #   echo "\033[38;5;154m"
  echo "\033[38;2;175;255;0m"
}

### background colors

bg_pink () {
  _hofr_no_color && return
  # Via TERM=*-256color:
  #   echo "\033[48;5;211m"
  echo "\033[48;2;255;135;175m"
}

bg_orange () {
  _hofr_no_color && return
  # Via TERM=*-256color:
  #   echo "\033[48;5;203m"
  echo "\033[48;2;255;95;95m"
}

bg_skyblue () {
  _hofr_no_color && return
  # Via TERM=*-256color:
  #   echo "\033[48;5;111m"
  echo "\033[48;2;135;175;255m"
}

bg_mediumgrey () {
  _hofr_no_color && return
  # Via TERM=*-256color:
  #   echo "\033[48;5;246m"
  echo "\033[48;2;148;148;148m"
}

bg_lavender () {
  _hofr_no_color && return
  # Via TERM=*-256color:
  #   echo "\033[48;5;183m"
  echo "\033[48;2;215;175;255m"
}

bg_tan () {
  _hofr_no_color && return
  # Via TERM=*-256color:
  #   echo "\033[48;5;179m"
  echo "\033[48;2;215;175;95m"
}

bg_forest () {
  _hofr_no_color && return
  # Via TERM=*-256color:
  #   echo "\033[48;5;22m"
  echo "\033[48;2;0;95;0m"
}

bg_maroon () {
  _hofr_no_color && return
  # Via TERM=*-256color:
  #   echo "\033[48;5;52m"
  echo "\033[48;2;95;0;0m"
}

bg_hotpink () {
  _hofr_no_color && return
  # Via TERM=*-256color:
  #   echo "\033[48;5;198m"
  echo "\033[48;2;255;0;135m"
}

bg_mintgreen () {
  _hofr_no_color && return
  # Via TERM=*-256color:
  #   echo "\033[48;5;121m"
  echo "\033[48;2;135;255;175m"
}

bg_lightorange () {
  _hofr_no_color && return
  # Via TERM=*-256color:
  #   echo "\033[48;5;215m"
  echo "\033[48;2;255;175;95m"
}

bg_lightred () {
  _hofr_no_color && return
  # Via TERM=*-256color:
  #   echo "\033[48;5;203m"
  echo "\033[48;2;255;95;95m"
}

bg_jade () {
  _hofr_no_color && return
  # Via TERM=*-256color:
  #   echo "\033[48;5;35m"
  echo "\033[48;2;0;175;95m"
}

bg_lime () {
  _hofr_no_color && return
  # Via TERM=*-256color:
  #   echo "\033[48;5;154m"
  echo "\033[48;2;175;255;0m"
}

# ***

fg_black () {
  _hofr_no_color && return
  echo "\033[30m"
}

fg_red () {
  _hofr_no_color && return
  echo "\033[31m"
}

fg_green () {
  _hofr_no_color && return
  echo "\033[32m"
}

fg_yellow () {
  _hofr_no_color && return
  echo "\033[33m"
}

fg_blue () {
  _hofr_no_color && return
  echo "\033[34m"
}

fg_magenta () {
  _hofr_no_color && return
  echo "\033[35m"
}

fg_cyan () {
  _hofr_no_color && return
  echo "\033[36m"
}

fg_lightgray () {
  _hofr_no_color && return
  echo "\033[37m"
}

fg_darkgray () {
  _hofr_no_color && return
  echo "\033[90m"
}

fg_lightred () {
  _hofr_no_color && return
  echo "\033[91m"
}

fg_lightgreen () {
  _hofr_no_color && return
  echo "\033[92m"
}

fg_lightyellow () {
  _hofr_no_color && return
  echo "\033[93m"
}

fg_lightblue () {
  _hofr_no_color && return
  echo "\033[94m"
}

fg_lightmagenta () {
  _hofr_no_color && return
  echo "\033[95m"
}

fg_lightcyan () {
  _hofr_no_color && return
  echo "\033[96m"
}

fg_white () {
  _hofr_no_color && return
  echo "\033[97m"
}

bg_black () {
  _hofr_no_color && return
  echo "\033[40m"
}

bg_red () {
  _hofr_no_color && return
  echo "\033[41m"
}

bg_green () {
  _hofr_no_color && return
  echo "\033[42m"
}

bg_yellow () {
  _hofr_no_color && return
  echo "\033[43m"
}

bg_blue () {
  _hofr_no_color && return
  echo "\033[44m"
}

bg_magenta () {
  _hofr_no_color && return
  echo "\033[45m"
}

bg_cyan () {
  _hofr_no_color && return
  echo "\033[46m"
}

bg_lightgray () {
  _hofr_no_color && return
  echo "\033[47m"
}

bg_darkgray () {
  _hofr_no_color && return
  echo "\033[100m"
}

bg_lightred () {
  _hofr_no_color && return
  echo "\033[101m"
}

bg_lightgreen () {
  _hofr_no_color && return
  echo "\033[102m"
}

bg_lightyellow () {
  _hofr_no_color && return
  echo "\033[103m"
}

bg_lightblue () {
  _hofr_no_color && return
  echo "\033[104m"
}

bg_lightmagenta () {
  _hofr_no_color && return
  echo "\033[105m"
}

bg_lightcyan () {
  _hofr_no_color && return
  echo "\033[106m"
}

bg_white () {
  _hofr_no_color && return
  echo "\033[107m"
}

# ***

# Note that you can also use tput to clear formatting, e.g.,
#   $ echo -e "$(fg_green)$(attr_underline)Hello$(tput sgr0), Whirl"
#   Hello, Whirl
#   -----
# (where the "Hello" is formatted).
# However, tput does not appear to inject into the output stream:
#   $ echo "$(fg_green)$(attr_underline)Hello$(tput sgr0), Whirl"
#   \033[32m\033[4mHello, Whirl
# so just to be safe -- so that this function can be used to build
# a string -- use the escape code.
attr_reset () {
  _hofr_no_color && return
  echo "\033[0m"
}

attr_bold () {
  _hofr_no_color && return
  # See also:
  #   echo "$(tput bold)"
  echo "\033[1m"
}

attr_dim () {
  _hofr_no_color && return
  echo "\033[2m"
}

attr_emphasis () {
  _hofr_no_color && return
  echo "\033[3m"
}

attr_italic () {
  attr_emphasis
}

attr_underline () {
  _hofr_no_color && return
  echo "\033[4m"
}

attr_underlined () {
  attr_underline
}

attr_strikethrough () {
  _hofr_no_color && return
  echo "\033[9m"
}

# ***

# Gnome/Mate do not support blink, <sigh>.
font_blink () {
  _hofr_no_color && return
  echo "\033[5m"
}

font_invert () {
  _hofr_no_color && return
  echo "\033[7m"
}

font_hidden () {
  _hofr_no_color && return
  echo "\033[8m"
}

reset_bold () {
  _hofr_no_color && return
  echo "\033[21m"
}

reset_dim () {
  _hofr_no_color && return
  echo "\033[22m"
}

reset_emphasis () {
  _hofr_no_color && return
  echo "\033[23m"
}

reset_italic () {
  reset_emphasis
}

reset_underline () {
  _hofr_no_color && return
  echo "\033[24m"
}

reset_underlined () {
  reset_underline
}

reset_blink () {
  _hofr_no_color && return
  echo "\033[25m"
}

reset_reverse () {
  _hofr_no_color && return
  echo "\033[27m"
}

reset_hidden () {
  _hofr_no_color && return
  echo "\033[28m"
}

# *** Convenience aliases.
res_dim () { reset_dim; }
res_emphasis () { reset_emphasis; }
res_italic () { reset_italic; }
res_underline () { reset_underline; }
res_underlined () { reset_underlined; }
res_blink () { reset_blink; }
res_reverse () { reset_reverse; }
res_hidden () { reset_hidden; }

