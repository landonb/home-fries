# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries
# License: GPLv3
# vim:tw=0:ts=2:sw=2:et:norl:spell:ft=sh

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# From: https://github.com/ginatrapani/todo.txt-cli/wiki/Tips-and-Tricks
# See also hex-to-xterm converter: http://www.frexx.de/xterm-256-notes/

# See also similar libraries:
#
#   https://github.com/paoloantinori/hhighlighter

create_colors() {
  ### === HIGH-COLOR === compatible with most terms including putty
  ### for windows... use colors that don't make your eyes bleed :)
  # NOTE/2017-05-03: Single quotes do not work. What's up with that?
  #   E.g., export PINK='\\033[38;5;211m'
  export FG_PINK="\033[38;5;211m"
  export FG_ORANGE="\033[38;5;203m"
  # 2016-10-09: FG_SKYBLUE broken.
  #export FG_SKYBLUE="\033[38;5;111m"
  export FG_MEDIUMGREY="\033[38;5;246m"
  export FG_LAVENDER="\033[38;5;183m"
  export FG_TAN="\033[38;5;179m"
  export FG_FOREST="\033[38;5;22m"
  export FG_MAROON="\033[38;5;52m"
  export FG_HOTPINK="\033[38;5;198m"
  export FG_MINTGREEN="\033[38;5;121m"
  export FG_LIGHTORANGE="\033[38;5;215m"
  export FG_LIGHTRED="\033[38;5;203m"
  export FG_JADE="\033[38;5;35m"
  export FG_LIME="\033[38;5;154m"
  ### background colors
  export BG_PINK="\033[48;5;211m"
  export BG_ORANGE="\033[48;5;203m"
  export BG_SKYBLUE="\033[48;5;111m"
  export BG_MEDIUMGREY="\033[48;5;246m"
  export BG_LAVENDER="\033[48;5;183m"
  export BG_TAN="\033[48;5;179m"
  export BG_FOREST="\033[48;5;22m"
  export BG_MAROON="\033[48;5;52m"
  export BG_HOTPINK="\033[48;5;198m"
  export BG_MINTGREEN="\033[48;5;121m"
  export BG_LIGHTORANGE="\033[48;5;215m"
  export BG_LIGHTRED="\033[48;5;203m"
  export BG_JADE="\033[48;5;35m"
  export BG_LIME="\033[48;5;154m"

  # 2018-03-23: Aha!
  #   https://misc.flogisoft.com/bash/tip_colors_and_formatting

  export FG_BLACK="\033[30m"
  export FG_RED="\033[31m"
  export FG_GREEN="\033[32m"
  export FG_YELLOW="\033[33m"
  export FG_BLUE="\033[34m"
  export FG_MAGENTA="\033[35m"
  export FG_CYAN="\033[36m"
  export FG_LIGHTGRAY="\033[37m"
  export FG_DARKGRAY="\033[90m"
  export FG_LIGHTRED="\033[91m"
  export FG_LIGHTGREEN="\033[92m"
  export FG_LIGHTYELLOW="\033[93m"
  export FG_LIGHTBLUE="\033[94m"
  export FG_LIGHTMAGENTA="\033[95m"
  export FG_LIGHTCYAN="\033[96m"
  export FG_WHITE="\033[97m"

  export BG_BLACK="\033[40m"
  export BG_RED="\033[41m"
  export BG_GREEN="\033[42m"
  export BG_YELLOW="\033[43m"
  export BG_BLUE="\033[44m"
  export BG_MAGENTA="\033[45m"
  export BG_CYAN="\033[46m"
  export BG_LIGHTGRAY="\033[47m"
  export BG_DARKGRAY="\033[100m"
  export BG_LIGHTRED="\033[101m"
  export BG_LIGHTGREEN="\033[102m"
  export BG_LIGHTYELLOW="\033[103m"
  export BG_LIGHTBLUE="\033[104m"
  export BG_LIGHTMAGENTA="\033[105m"
  export BG_LIGHTCYAN="\033[106m"
  export BG_WHITE="\033[107m"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# (lb): I know Vim makes doing this fast, but still, why manually generate
# this? Should really use associate array and eval. The whole file.

# Fast downcase: qqvw^ou<down>q

fg_pink() {
  ### === HIGH-COLOR === compatible with most terms including putty
  ### for windows... use colors that don't make your eyes bleed :)
  # NOTE/2017-05-03: Single quotes do not work. What's up with that?
  #   E.g., export PINK='\\033[38;5;211m'
  echo "\033[38;5;211m"
}

fg_orange() {
  echo "\033[38;5;203m"
}

# 2016-10-09: FG_SKYBLUE broken.
#fg_skyblue() {
#  echo "\033[38;5;111m"
#}

fg_mediumgrey() {
  echo "\033[38;5;246m"
}

fg_lavender() {
  echo "\033[38;5;183m"
}

fg_tan() {
  echo "\033[38;5;179m"
}

fg_forest() {
  echo "\033[38;5;22m"
}

fg_maroon() {
  echo "\033[38;5;52m"
}

fg_hotpink() {
  echo "\033[38;5;198m"
}

fg_mintgreen() {
  echo "\033[38;5;121m"
}

fg_lightorange() {
  echo "\033[38;5;215m"
}

fg_lightred() {
  echo "\033[38;5;203m"
}

fg_jade() {
  echo "\033[38;5;35m"
}

fg_lime() {
  echo "\033[38;5;154m"
}

### background colors

bg_pink() {
  echo "\033[48;5;211m"
}

bg_orange() {
  echo "\033[48;5;203m"
}

bg_skyblue() {
  echo "\033[48;5;111m"
}

bg_mediumgrey() {
  echo "\033[48;5;246m"
}

bg_lavender() {
  echo "\033[48;5;183m"
}

bg_tan() {
  echo "\033[48;5;179m"
}

bg_forest() {
  echo "\033[48;5;22m"
}

bg_maroon() {
  echo "\033[48;5;52m"
}

bg_hotpink() {
  echo "\033[48;5;198m"
}

bg_mintgreen() {
  echo "\033[48;5;121m"
}

bg_lightorange() {
  echo "\033[48;5;215m"
}

bg_lightred() {
  echo "\033[48;5;203m"
}

bg_jade() {
  echo "\033[48;5;35m"
}

bg_lime() {
  echo "\033[48;5;154m"
}

# 2018-03-23: Aha!
#   https://misc.flogisoft.com/bash/tip_colors_and_formatting

fg_black() {
  echo "\033[30m"
}

fg_red() {
  echo "\033[31m"
}

fg_green() {
  echo "\033[32m"
}

fg_yellow() {
  echo "\033[33m"
}

fg_blue() {
  echo "\033[34m"
}

fg_magenta() {
  echo "\033[35m"
}

fg_cyan() {
  echo "\033[36m"
}

fg_lightgray() {
  echo "\033[37m"
}

fg_darkgray() {
  echo "\033[90m"
}

fg_lightred() {
  echo "\033[91m"
}

fg_lightgreen() {
  echo "\033[92m"
}

fg_lightyellow() {
  echo "\033[93m"
}

fg_lightblue() {
  echo "\033[94m"
}

fg_lightmagenta() {
  echo "\033[95m"
}

fg_lightcyan() {
  echo "\033[96m"
}

fg_white() {
  echo "\033[97m"
}

bg_black() {
  echo "\033[40m"
}

bg_red() {
  echo "\033[41m"
}

bg_green() {
  echo "\033[42m"
}

bg_yellow() {
  echo "\033[43m"
}

bg_blue() {
  echo "\033[44m"
}

bg_magenta() {
  echo "\033[45m"
}

bg_cyan() {
  echo "\033[46m"
}

bg_lightgray() {
  echo "\033[47m"
}

bg_darkgray() {
  echo "\033[100m"
}

bg_lightred() {
  echo "\033[101m"
}

bg_lightgreen() {
  echo "\033[102m"
}

bg_lightyellow() {
  echo "\033[103m"
}

bg_lightblue() {
  echo "\033[104m"
}

bg_lightmagenta() {
  echo "\033[105m"
}

bg_lightcyan() {
  echo "\033[106m"
}

bg_white() {
  echo "\033[107m"
}

attr_reset () {
  # Does it matter which one? Using tput seems more generic than ANSI code.
  # Similar to:  echo "\033[0m"
  #echo "$(tput sgr0)"
  # 2018-05-31: Actually, I think it does matter. `tput sgr0` seems noop.
  echo "\033[0m"
}

attr_bold() {
  # Similar to:  echo "\033[1m"
  echo "\e[1m"
  #echo "$(tput bold)"
}

attr_dim() {
  echo "\e[2m"
}

attr_emphasis() {
  echo "\e[3m"
}

attr_italic() {
  attr_emphasis
}

attr_underline() {
  #echo "\e[4m"
  echo "\033[4m"
}

attr_underlined() {
  attr_underline
}

attr_strikethrough() {
  echo "\e[9m"
}

# 2018-06-07 14:21: Hrmmmm... I kind like this:
#  ansi()          { echo -e "\e[${1}m${*:2}\e[0m"; }
#  bold()          { ansi 1 "$@"; }
#  italic()        { ansi 3 "$@"; }
#  underline()     { ansi 4 "$@"; }
#  strikethrough() { ansi 9 "$@"; }
#  red()           { ansi 31 "$@"; }
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
font_blink() {
  echo "\033[5m"
}

font_invert() {
  echo "\033[7m"
}

font_hidden() {
  echo "\033[8m"
}

reset_bold() {
  echo "\033[21m"
}

reset_dim() {
  echo "\033[22m"
}

reset_emphasis() {
  echo "\033[23m"
}

reset_italic() {
  reset_emphasis
}

reset_underline() {
  echo "\033[24m"
}

reset_underlined() {
  reset_underline
}

reset_blink() {
  echo "\033[25m"
}

reset_reverse() {
  echo "\033[27m"
}

reset_hidden() {
  echo "\033[28m"
}

res_dim() { reset_dim; }
res_emphasis() { reset_emphasis; }
res_italic() { reset_italic; }
res_underline() { reset_underline; }
res_underlined() { reset_underlined; }
res_blink() { reset_blink; }
res_reverse() { reset_reverse; }
res_hidden() { reset_hidden; }

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

create_ornaments() {
  # 2016-08-15: `tput` discovers the right sequences to send to the terminal:
  # 2018-05-28: Haha. Run `env` and after TPUT_BOLD, everything is bold! Duh!!
  #   export TPUT_BOLD=$(tput bold)
  # I wonder if a function would help?
  # But why not just do, e.g.,
  #   echo "This $(tput bold)is bold$(tput sgr0)!"
  # (lb): Then again, I'll probably never remember the other, obscure codes,
  # like `tput sgr0` for normal mode, or `\033[4m` for underline. So maybe
  # functions are the way to go...
  #export TPUT_BOLD=$(tput bold)
  #export TPUT_NORMAL=$(tput sgr0)
  #export TPUT_NORM=${TPUT_BOLD}
  tput_bold () {
    echo "$(tput bold)"
  }
  tput_normal () {
    echo "$(tput sgr0)"
  }
  export -f tput_bold
  export -f tput_normal
  alias tput_reset=tput_normal

  # 2018-01-30: (lb): Still not sure the best way to name these. I like
  # FONT_ or TERM_ prefix best, I suppose. Or shorter MK_ for brevity?
  export FONT_NORMAL="\033[0m"
  export FONT_BOLD="\033[1m"
  export FONT_UNDERLINE="\033[4m"
  # Gnome/Mate do not support blink, <sigh>.
  export FONT_BLINK="\033[5m"
  export FONT_INVERT="\033[7m"
  export FONT_HIDDEN="\033[8m"

  export RESET_BOLD="\033[21m"
  export RESET_DIM="\033[22m"
  export RESET_UNDERLINED="\033[24m"
  export RESET_BLINK="\033[25m"
  export RESET_REVERSE="\033[27m"
  export RESET_HIDDEN="\033[28m"
  # Aliases.
  #  Ug. I can't decide what I like best.
  #  Trying 4-letter "whats" and also MK_ "For Markup" prefix.
  export FONT_NORM=${FONT_NORMAL}
  export FONT_LINE=${FONT_UNDERLINE}
  export MK_NORM=${FONT_NORMAL}
  export MK_BOLD=${FONT_BOLD}
  export MK_LINE=${FONT_UNDERLINE}
}

create_strip_colors() {
  # To strip color codes from Bash stdout whatever.
  # http://stackoverflow.com/questions/17998978/removing-colors-from-output
  alias stripcolors='/bin/sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g"'
}

create_base_color_names() {
  TERM_COLOR_NAMES=()
  TERM_COLOR_NAMES+=('FG_PINK')
  TERM_COLOR_NAMES+=('FG_ORANGE')
  #TERM_COLOR_NAMES+=('FG_SKYBLUE')
  TERM_COLOR_NAMES+=('FG_MEDIUMGREY')
  TERM_COLOR_NAMES+=('FG_LAVENDER')
  TERM_COLOR_NAMES+=('FG_TAN')
  TERM_COLOR_NAMES+=('FG_FOREST')
  TERM_COLOR_NAMES+=('FG_MAROON')
  TERM_COLOR_NAMES+=('FG_HOTPINK')
  TERM_COLOR_NAMES+=('FG_MINTGREEN')
  TERM_COLOR_NAMES+=('FG_LIGHTORANGE')
  TERM_COLOR_NAMES+=('FG_LIGHTRED')
  TERM_COLOR_NAMES+=('FG_JADE')
  TERM_COLOR_NAMES+=('FG_LIME')

  TERM_COLOR_NAMES+=('BG_PINK')
  TERM_COLOR_NAMES+=('BG_ORANGE')
  TERM_COLOR_NAMES+=('BG_SKYBLUE')
  TERM_COLOR_NAMES+=('BG_MEDIUMGREY')
  TERM_COLOR_NAMES+=('BG_LAVENDER')
  TERM_COLOR_NAMES+=('BG_TAN')
  TERM_COLOR_NAMES+=('BG_FOREST')
  TERM_COLOR_NAMES+=('BG_MAROON')
  TERM_COLOR_NAMES+=('BG_HOTPINK')
  TERM_COLOR_NAMES+=('BG_MINTGREEN')
  TERM_COLOR_NAMES+=('BG_LIGHTORANGE')
  TERM_COLOR_NAMES+=('BG_LIGHTRED')
  TERM_COLOR_NAMES+=('BG_JADE')
  TERM_COLOR_NAMES+=('BG_LIME')

  TERM_COLOR_NAMES+=('FG_BLACK')
  TERM_COLOR_NAMES+=('FG_RED')
  TERM_COLOR_NAMES+=('FG_GREEN')
  TERM_COLOR_NAMES+=('FG_YELLOW')
  TERM_COLOR_NAMES+=('FG_BLUE')
  TERM_COLOR_NAMES+=('FG_MAGENTA')
  TERM_COLOR_NAMES+=('FG_CYAN')
  TERM_COLOR_NAMES+=('FG_LIGHTGRAY')
  TERM_COLOR_NAMES+=('FG_DARKGRAY')
  TERM_COLOR_NAMES+=('FG_LIGHTRED')
  TERM_COLOR_NAMES+=('FG_LIGHTGREEN')
  TERM_COLOR_NAMES+=('FG_LIGHTYELLOW')
  TERM_COLOR_NAMES+=('FG_LIGHTBLUE')
  TERM_COLOR_NAMES+=('FG_LIGHTMAGENTA')
  TERM_COLOR_NAMES+=('FG_LIGHTCYAN')
  TERM_COLOR_NAMES+=('FG_WHITE')

  TERM_COLOR_NAMES+=('BG_BLACK')
  TERM_COLOR_NAMES+=('BG_RED')
  TERM_COLOR_NAMES+=('BG_GREEN')
  TERM_COLOR_NAMES+=('BG_YELLOW')
  TERM_COLOR_NAMES+=('BG_BLUE')
  TERM_COLOR_NAMES+=('BG_MAGENTA')
  TERM_COLOR_NAMES+=('BG_CYAN')
  TERM_COLOR_NAMES+=('BG_LIGHTGRAY')
  TERM_COLOR_NAMES+=('BG_DARKGRAY')
  TERM_COLOR_NAMES+=('BG_LIGHTRED')
  TERM_COLOR_NAMES+=('BG_LIGHTGREEN')
  TERM_COLOR_NAMES+=('BG_LIGHTYELLOW')
  TERM_COLOR_NAMES+=('BG_LIGHTBLUE')
  TERM_COLOR_NAMES+=('BG_LIGHTMAGENTA')
  TERM_COLOR_NAMES+=('BG_LIGHTCYAN')
  TERM_COLOR_NAMES+=('BG_WHITE')
}

test_colors () {
  create_base_color_names
  for ((i = 0; i < ${#TERM_COLOR_NAMES[@]}; i++)); do
    local nom="${TERM_COLOR_NAMES[$i]}"
    # BASH: `!` uses a variable's value as other variable's name.
    echo -e \
      "Some ${!nom}COLOR ${MK_LINE}is ${MK_BOLD}nice${MK_NORM} surely [${nom}]."
  done
}

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

man() {
  env \
    LESS_TERMCAP_mb=$(printf "\e[1;31m") \
    LESS_TERMCAP_md=$(printf "\e[1;31m") \
    LESS_TERMCAP_me=$(printf "\e[0m") \
    LESS_TERMCAP_se=$(printf "\e[0m") \
    LESS_TERMCAP_so=$(printf "\e[1;44;33m") \
    LESS_TERMCAP_ue=$(printf "\e[0m") \
    LESS_TERMCAP_us=$(printf "\e[1;32m") \
    man "$@"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main() {
  create_colors
  create_ornaments
  create_strip_colors
  # DEVS: Uncomment to test, or call yourself after sourcing this file.
  #test_colors
}

main "$@"

