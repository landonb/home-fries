#!/bin/bash
# vim:tw=0:ts=2:sw=2:et:norl:spell:ft=sh
# Project: https://github.com/landonb/home-fries
# License: GPLv3

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# From: https://github.com/ginatrapani/todo.txt-cli/wiki/Tips-and-Tricks
# See also hex-to-xterm converter: http://www.frexx.de/xterm-256-notes/

# See also similar libraries:
#
#   https://github.com/paoloantinori/hhighlighter

create_colors () {
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

create_ornaments () {
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

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

create_strip_colors () {
  # - Strip color codes from stream. Ref:
  #   http://stackoverflow.com/questions/17998978/removing-colors-from-output
  alias stripcolors='/bin/sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g"'
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

test_colors () {
  create_base_color_names () {
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

  create_base_color_names

  _echo () {
    [ "$(echo -e)" = '' ] && echo -e "${@}" || echo "${@}"
  }

  for ((i = 0; i < ${#TERM_COLOR_NAMES[@]}; i++)); do
    local nom="${TERM_COLOR_NAMES[$i]}"
    # BASH: `!` uses a variable's value as other variable's name.
    _echo "Some ${!nom}COLOR ${MK_LINE}is ${MK_BOLD}nice${MK_NORM} surely [${nom}]."
  done
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

unset_f_color_util () {
  unset -f create_colors

  unset -f create_ornaments

  unset -f create_strip_colors

  # So meta.
  unset -f unset_f_color_util
}

main () {
  create_colors
  unset -f create_colors

  create_ornaments
  unset -f create_ornaments

  create_strip_colors
  unset -f create_strip_colors

  # DEVS: Uncomment to test, or call yourself after sourcing this file.
  #test_colors
}

main "$@"
unset -f main

