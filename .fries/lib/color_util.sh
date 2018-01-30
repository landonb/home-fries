# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries
# License: GPLv3
# vim:tw=0:ts=2:sw=2:et:norl:spell:ft=sh

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# From: https://github.com/ginatrapani/todo.txt-cli/wiki/Tips-and-Tricks
# See also hex-to-xterm converter: http://www.frexx.de/xterm-256-notes/

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
}

create_ornaments() {
  # 2016-08-15: `tput` discovers the right sequences to send to the terminal:
  export TPUT_BOLD=$(tput bold)
  export TPUT_NORMAL=$(tput sgr0)
  export TPUT_NORM=${TPUT_BOLD}

  # 2018-01-30: (lb): Still not sure the best way to name these. I like
  # FONT_ or TERM_ prefix best, I suppose. Or shorter MK_ for brevity?
  export FONT_NORMAL="\033[0m"
  export FONT_BOLD="\033[1m"
  export FONT_UNDERLINE="\033[4m"
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

