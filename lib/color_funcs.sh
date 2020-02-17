#!/bin/bash
# vim:tw=0:ts=2:sw=2:et:norl:spell:ft=sh
# Project: https://github.com/landonb/home-fries
# License: GPLv3

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

is_headless () {
  # We cannot rely on normal interactive terminal checking, e.g.,
  #   [ -z "$PS1" ] && return 0 || return 1
  #   # Or:
  #   [[ "$-" =~ .*i.* ]] && return 1 || return 0
  # because user-run scripts can themselves run scripts
  # and the latter-run scripts will not be considered
  # interactive. Compare also:
  #   $ /bin/bash -c 'echo "$PS1"'
  #   # EMPTY
  #   $ /bin/bash -c 'echo "$LOGNAME"'
  #   user
  ( [ -n ${FRIES_COLOR} ] && ! ${FRIES_COLOR} ) && return 0 || return 1
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# DX: Hint: Fast downcase: q q v w C-o u <down> q
#           [2020-01-03: Though now <Q> stops on visual select...]

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

fg_pink () {
  is_headless && return
  ### === HIGH-COLOR === compatible with most terms including putty
  ### for windows... use colors that don't make your eyes bleed :)
  # NOTE/2017-05-03: Single quotes do not work. What's up with that?
  #   E.g., export PINK='\\033[38;5;211m'
  # Via TERM=*-256color:
  #   echo "\033[38;5;211m"
  echo "\033[38;2;255;135;175m"
}

fg_orange () {
  is_headless && return
  # Via TERM=*-256color:
  #   echo "\033[38;5;203m"
  echo "\033[38;2;255;95;95m"
}

# 2016-10-09: FG_SKYBLUE broken.
fg_skyblue () {
  is_headless && return
  # Via TERM=*-256color:
  #   echo "\033[38;5;111m"
  echo "\033[38;2;135;175;255m"
}

fg_mediumgrey () {
  is_headless && return
  # Via TERM=*-256color:
  #   echo "\033[38;5;246m"
  echo "\033[38;2;148;148;148m"
}

fg_lavender () {
  is_headless && return
  # Via TERM=*-256color:
  #   echo "\033[38;5;183m"
  echo "\033[38;2;215;175;255m"
}

fg_tan () {
  is_headless && return
  # Via TERM=*-256color:
  #   echo "\033[38;5;179m"
  echo "\033[38;2;215;175;95m"
}

fg_forest () {
  is_headless && return
  # Via TERM=*-256color:
  #   echo "\033[38;5;22m"
  echo "\033[38;2;0;95;0m"
}

fg_maroon () {
  is_headless && return
  # Via TERM=*-256color:
  #   echo "\033[38;5;52m"
  echo "\033[38;2;95;0;0m"
}

fg_hotpink () {
  is_headless && return
  # Via TERM=*-256color:
  #   echo "\033[38;5;198m"
  echo "\033[38;2;255;0;135m"
}

fg_mintgreen () {
  is_headless && return
  # Via TERM=*-256color:
  #   echo "\033[38;5;121m"
  echo "\033[38;2;135;255;175m"
}

fg_lightorange () {
  is_headless && return
  # Via TERM=*-256color:
  #   echo "\033[38;5;215m"
  echo "\033[38;2;255;175;95m"
}

fg_lightred () {
  is_headless && return
  # Via TERM=*-256color:
  #   echo "\033[38;5;203m"
  echo "\033[38;2;255;95;95m"
}

fg_jade () {
  is_headless && return
  # Via TERM=*-256color:
  #   echo "\033[38;5;35m"
  echo "\033[38;2;0;175;95m"
}

fg_lime () {
  is_headless && return
  # Via TERM=*-256color:
  #   echo "\033[38;5;154m"
  echo "\033[38;2;175;255;0m"
}

### background colors

bg_pink () {
  is_headless && return
  # Via TERM=*-256color:
  #   echo "\033[48;5;211m"
  echo "\033[48;2;255;135;175m"
}

bg_orange () {
  is_headless && return
  # Via TERM=*-256color:
  #   echo "\033[48;5;203m"
  echo "\033[48;2;255;95;95m"
}

bg_skyblue () {
  is_headless && return
  # Via TERM=*-256color:
  #   echo "\033[48;5;111m"
  echo "\033[48;2;135;175;255m"
}

bg_mediumgrey () {
  is_headless && return
  # Via TERM=*-256color:
  #   echo "\033[48;5;246m"
  echo "\033[48;2;148;148;148m"
}

bg_lavender () {
  is_headless && return
  # Via TERM=*-256color:
  #   echo "\033[48;5;183m"
  echo "\033[48;2;215;175;255m"
}

bg_tan () {
  is_headless && return
  # Via TERM=*-256color:
  #   echo "\033[48;5;179m"
  echo "\033[48;2;215;175;95m"
}

bg_forest () {
  is_headless && return
  # Via TERM=*-256color:
  #   echo "\033[48;5;22m"
  echo "\033[48;2;0;95;0m"
}

bg_maroon () {
  is_headless && return
  # Via TERM=*-256color:
  #   echo "\033[48;5;52m"
  echo "\033[48;2;95;0;0m"
}

bg_hotpink () {
  is_headless && return
  # Via TERM=*-256color:
  #   echo "\033[48;5;198m"
  echo "\033[48;2;255;0;135m"
}

bg_mintgreen () {
  is_headless && return
  # Via TERM=*-256color:
  #   echo "\033[48;5;121m"
  echo "\033[48;2;135;255;175m"
}

bg_lightorange () {
  is_headless && return
  # Via TERM=*-256color:
  #   echo "\033[48;5;215m"
  echo "\033[48;2;255;175;95m"
}

bg_lightred () {
  is_headless && return
  # Via TERM=*-256color:
  #   echo "\033[48;5;203m"
  echo "\033[48;2;255;95;95m"
}

bg_jade () {
  is_headless && return
  # Via TERM=*-256color:
  #   echo "\033[48;5;35m"
  echo "\033[48;2;0;175;95m"
}

bg_lime () {
  is_headless && return
  # Via TERM=*-256color:
  #   echo "\033[48;5;154m"
  echo "\033[48;2;175;255;0m"
}

# 2018-03-23: Aha!
#   https://misc.flogisoft.com/bash/tip_colors_and_formatting

fg_black () {
  is_headless && return
  echo "\033[30m"
}

fg_red () {
  is_headless && return
  echo "\033[31m"
}

fg_green () {
  is_headless && return
  echo "\033[32m"
}

fg_yellow () {
  is_headless && return
  echo "\033[33m"
}

fg_blue () {
  is_headless && return
  echo "\033[34m"
}

fg_magenta () {
  is_headless && return
  echo "\033[35m"
}

fg_cyan () {
  is_headless && return
  echo "\033[36m"
}

fg_lightgray () {
  is_headless && return
  echo "\033[37m"
}

fg_darkgray () {
  is_headless && return
  echo "\033[90m"
}

fg_lightred () {
  is_headless && return
  echo "\033[91m"
}

fg_lightgreen () {
  is_headless && return
  echo "\033[92m"
}

fg_lightyellow () {
  is_headless && return
  echo "\033[93m"
}

fg_lightblue () {
  is_headless && return
  echo "\033[94m"
}

fg_lightmagenta () {
  is_headless && return
  echo "\033[95m"
}

fg_lightcyan () {
  is_headless && return
  echo "\033[96m"
}

fg_white () {
  is_headless && return
  echo "\033[97m"
}

bg_black () {
  is_headless && return
  echo "\033[40m"
}

bg_red () {
  is_headless && return
  echo "\033[41m"
}

bg_green () {
  is_headless && return
  echo "\033[42m"
}

bg_yellow () {
  is_headless && return
  echo "\033[43m"
}

bg_blue () {
  is_headless && return
  echo "\033[44m"
}

bg_magenta () {
  is_headless && return
  echo "\033[45m"
}

bg_cyan () {
  is_headless && return
  echo "\033[46m"
}

bg_lightgray () {
  is_headless && return
  echo "\033[47m"
}

bg_darkgray () {
  is_headless && return
  echo "\033[100m"
}

bg_lightred () {
  is_headless && return
  echo "\033[101m"
}

bg_lightgreen () {
  is_headless && return
  echo "\033[102m"
}

bg_lightyellow () {
  is_headless && return
  echo "\033[103m"
}

bg_lightblue () {
  is_headless && return
  echo "\033[104m"
}

bg_lightmagenta () {
  is_headless && return
  echo "\033[105m"
}

bg_lightcyan () {
  is_headless && return
  echo "\033[106m"
}

bg_white () {
  is_headless && return
  echo "\033[107m"
}

attr_reset () {
  is_headless && return
  # Does it matter which one? Using tput seems more generic than ANSI code.
  # Similar to:  echo "\033[0m"
  #echo "$(tput sgr0)"
  # 2018-05-31: Actually, I think it does matter. `tput sgr0` seems noop.
  echo "\033[0m"
}

attr_bold () {
  is_headless && return
  # Similar to:  echo "\033[1m"
  echo "\e[1m"
  #echo "$(tput bold)"
}

attr_dim () {
  is_headless && return
  echo "\e[2m"
}

attr_emphasis () {
  is_headless && return
  echo "\e[3m"
}

attr_italic () {
  attr_emphasis
}

attr_underline () {
  is_headless && return
  #echo "\e[4m"
  echo "\033[4m"
}

attr_underlined () {
  attr_underline
}

attr_strikethrough () {
  is_headless && return
  echo "\e[9m"
}

# 2018-06-07 14:21: Hrmmmm... I kind like this:
#  ansi ()          { echo -e "\e[${1}m${*:2}\e[0m"; }
#  bold ()          { ansi 1 "$@"; }
#  italic ()        { ansi 3 "$@"; }
#  underline ()     { ansi 4 "$@"; }
#  strikethrough () { ansi 9 "$@"; }
#  red ()           { ansi 31 "$@"; }
#
# Via:
#  https://askubuntu.com/questions/528928/how-to-do-underline-bold-italic-strikethrough-color-background-and-size-i
#
# Another color table:
#  https://misc.flogisoft.com/bash/tip_colors_and_formatting

# 2018-06-08: Care about cursor movements? I mean, this file is way
# beyond just colors at this point...
#
#   Example cursor-up movements:
#
#        echo -e "\x1b[A"     # 1 row (looks like no-op in Bash, because Enter)
#        echo -e "\x1b[5A"    # 5 rows (run in shell, effectively 3 lines up)
#        echo -e "\u001b[A"   # 1 row
#        echo -e "\u001b[5A"  # 5 rows

# Gnome/Mate do not support blink, <sigh>.
font_blink () {
  is_headless && return
  echo "\033[5m"
}

font_invert () {
  is_headless && return
  echo "\033[7m"
}

font_hidden () {
  is_headless && return
  echo "\033[8m"
}

reset_bold () {
  is_headless && return
  echo "\033[21m"
}

reset_dim () {
  is_headless && return
  echo "\033[22m"
}

reset_emphasis () {
  is_headless && return
  echo "\033[23m"
}

reset_italic () {
  reset_emphasis
}

reset_underline () {
  is_headless && return
  echo "\033[24m"
}

reset_underlined () {
  reset_underline
}

reset_blink () {
  is_headless && return
  echo "\033[25m"
}

reset_reverse () {
  is_headless && return
  echo "\033[27m"
}

reset_hidden () {
  is_headless && return
  echo "\033[28m"
}

res_dim () { reset_dim; }
res_emphasis () { reset_emphasis; }
res_italic () { reset_italic; }
res_underline () { reset_underline; }
res_underlined () { reset_underlined; }
res_blink () { reset_blink; }
res_reverse () { reset_reverse; }
res_hidden () { reset_hidden; }

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# Examples:
#
#   - Combining foreground and background
#
#     export PRI_A=${FG_HOTPINK}${BG_MEDIUMGREY}${MK_UNDERLINE}
#
#   - Raw
#
#     echo -e "Some \e[93mCOLOR"
#
#   - Using exported environs
#
#     echo -e "Some ${MINTGREEN}COLOR ${MK_underline_bash}is ${MK_bold_bash}nice${MK_normal_bash} surely."
#
# Hints:
#
#   - Reset text attributes to normal without clear.
#
#     tput sgr0

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# "Want colored man pages?"
#
#   http://boredzo.org/blog/archives/2016-08-15/colorized-man-pages-understood-and-customized
#
#   https://superuser.com/questions/452034/bash-colorized-man-page

man () {
  # 2018-06-29 12:43: This was fine in a normal terminal, then I tried
  # it in a Terminator, and needs quotes all of a sudden?
  env \
    LESS_TERMCAP_mb="$(printf "\e[1;31m")" \
    LESS_TERMCAP_md="$(printf "\e[1;31m")" \
    LESS_TERMCAP_me="$(printf "\e[0m")" \
    LESS_TERMCAP_se="$(printf "\e[0m")" \
    LESS_TERMCAP_so="$(printf "\e[1;44;33m")" \
    LESS_TERMCAP_ue="$(printf "\e[0m")" \
    LESS_TERMCAP_us="$(printf "\e[1;32m")" \
    /usr/bin/man "$@"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

test_truecolor () {
  # https://jdhao.github.io/2018/10/19/tmux_nvim_true_color/
  awk 'BEGIN{
      s="/\\/\\/\\/\\/\\"; s=s s s s s s s s;
      for (colnum = 0; colnum<77; colnum++) {
          r = 255-(colnum*255/76);
          g = (colnum*510/76);
          b = (colnum*255/76);
          if (g>255) g = 510-g;
          printf "\033[48;2;%d;%d;%dm", r,g,b;
          printf "\033[38;2;%d;%d;%dm", 255-r,255-g,255-b;
          printf "%s\033[0m", substr(s,colnum+1,1);
      }
      printf "\n";
  }'
  echo -e \
    "$(attr_bold)bold$(attr_reset) " \
    "$(attr_italic)italic$(attr_reset) " \
    "$(attr_underline)underline$(attr_reset) " \
    "$(attr_strikethrough)strikethrough$(attr_reset)"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main () {
  :
}

main "$@"
unset -f main

