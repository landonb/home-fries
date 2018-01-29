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
  export PINK="\033[38;5;211m"
  export ORANGE="\033[38;5;203m"
  # 2016-10-09: SKYBLUE broken.
  #export SKYBLUE="\033[38;5;111m"
  export MEDIUMGREY="\033[38;5;246m"
  export LAVENDER="\033[38;5;183m"
  export TAN="\033[38;5;179m"
  export FOREST="\033[38;5;22m"
  export MAROON="\033[38;5;52m"
  export HOTPINK="\033[38;5;198m"
  export MINTGREEN="\033[38;5;121m"
  export LIGHTORANGE="\033[38;5;215m"
  export LIGHTRED="\033[38;5;203m"
  export JADE="\033[38;5;35m"
  export LIME="\033[38;5;154m"
  ### background colors
  export PINK_BG="\033[48;5;211m"
  export ORANGE_BG="\033[48;5;203m"
  export SKYBLUE_BG="\033[48;5;111m"
  export MEDIUMGREY_BG="\033[48;5;246m"
  export LAVENDER_BG="\033[48;5;183m"
  export TAN_BG="\033[48;5;179m"
  export FOREST_BG="\033[48;5;22m"
  export MAROON_BG="\033[48;5;52m"
  export HOTPINK_BG="\033[48;5;198m"
  export MINTGREEN_BG="\033[48;5;121m"
  export LIGHTORANGE_BG="\033[48;5;215m"
  export LIGHTRED_BG="\033[48;5;203m"
  export JADE_BG="\033[48;5;35m"
  export LIME_BG="\033[48;5;154m"
}

create_ornaments() {
  # 2016-08-15: `tput` discovers the right sequences to send to the terminal:
  export font_bold_tput=$(tput bold)
  export font_normal_tput=$(tput sgr0)
  export font_bold_bash="\033[1m"
  export font_normal_bash="\033[0m"
  export font_underline_bash="\033[4m"
# FIXME: Better names? Like, TERM_BOLD, TERM_NORMAL, etc.?
  #export UNDERLINE="\033[4m"
}

create_strip_colors() {
  # To strip color codes from Bash stdout whatever.
  # http://stackoverflow.com/questions/17998978/removing-colors-from-output
  alias stripcolors='/bin/sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g"'
}

create_base_color_names() {
  TERM_COLOR_NAMES=()
  TERM_COLOR_NAMES+=('PINK')
  TERM_COLOR_NAMES+=('ORANGE')
  #TERM_COLOR_NAMES+=('SKYBLUE')
  TERM_COLOR_NAMES+=('MEDIUMGREY')
  TERM_COLOR_NAMES+=('LAVENDER')
  TERM_COLOR_NAMES+=('TAN')
  TERM_COLOR_NAMES+=('FOREST')
  TERM_COLOR_NAMES+=('MAROON')
  TERM_COLOR_NAMES+=('HOTPINK')
  TERM_COLOR_NAMES+=('MINTGREEN')
  TERM_COLOR_NAMES+=('LIGHTORANGE')
  TERM_COLOR_NAMES+=('LIGHTRED')
  TERM_COLOR_NAMES+=('JADE')
  TERM_COLOR_NAMES+=('LIME')
  TERM_COLOR_NAMES+=('PINK_BG')
  TERM_COLOR_NAMES+=('ORANGE_BG')
  TERM_COLOR_NAMES+=('SKYBLUE_BG')
  TERM_COLOR_NAMES+=('MEDIUMGREY_BG')
  TERM_COLOR_NAMES+=('LAVENDER_BG')
  TERM_COLOR_NAMES+=('TAN_BG')
  TERM_COLOR_NAMES+=('FOREST_BG')
  TERM_COLOR_NAMES+=('MAROON_BG')
  TERM_COLOR_NAMES+=('HOTPINK_BG')
  TERM_COLOR_NAMES+=('MINTGREEN_BG')
  TERM_COLOR_NAMES+=('LIGHTORANGE_BG')
  TERM_COLOR_NAMES+=('LIGHTRED_BG')
  TERM_COLOR_NAMES+=('JADE_BG')
  TERM_COLOR_NAMES+=('LIME_BG')
  TERM_COLOR_NAMES+=('UNDERLINE')
}

test_colors () {
  create_base_color_names
  for ((i = 0; i < ${#TERM_COLOR_NAMES[@]}; i++)); do
    local color_nom="${TERM_COLOR_NAMES[$i]}"
    # BASH: `!` uses a variable's value as other variable's name.
    echo -e "Some ${!color_nom}COLOR ${font_underline_bash}is ${font_bold_bash}nice${font_normal_bash} surely [${color_nom}]."
  done
}

# Examples:
#
#   - Combining foreground and background
#
#     export PRI_A=${HOTPINK}${MEDIUMGREY_BG}${UNDERLINE}
#
#   - Raw
#
#     echo -e "Some \e[93mCOLOR"
#
#   - Using exported environs
#
#     echo -e "Some ${MINTGREEN}COLOR ${font_underline_bash}is ${font_bold_bash}nice${font_normal_bash} surely."
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

