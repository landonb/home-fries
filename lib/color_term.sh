#!/bin/bash
# vim:tw=0:ts=2:sw=2:et:norl:spell:ft=sh
# Project: https://github.com/landonb/home-fries
# License: GPLv3

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

source_deps () {
  local curdir=$(dirname -- "${BASH_SOURCE[0]}")
  . ${curdir}/color_envs.sh
  . ${curdir}/color_funcs.sh
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# See long comment atop _hofr_no_color in color_funcs.sh for notes on $-
# and when (and when not) to check it to see if the shell is interactive.
# - Basically, the color_funcs.sh color functions run in subshells, so $-
#   will never not indicate non-interactive. (Otherwise, we could just skip
#   this setup and let the color library decide if it should show color.)
# - We can at least check the interactive flag during Bashrc startup.
#   - As such, in all likelihood, $- will always show interactivity
#     in this function, because this file will only ever be sourced
#     when the user starts an interactive terminal session.

_export_homefries_no_color () {
  HOMEFRIES_NO_COLOR=false
  [[ "$-" =~ .*i.* ]] || HOMEFRIES_NO_COLOR=true
  export HOMEFRIES_NO_COLOR
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

_alias_stripcolors () {
  # - Strip color codes from stream. Ref:
  #   http://stackoverflow.com/questions/17998978/removing-colors-from-output
  alias stripcolors='/bin/sed -E "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g"'
}

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

_unset_f_color_term () {
  unset -f _export_homefries_no_color

  unset -f _alias_stripcolors

  # So meta.
  unset -f unset_f_color_term
}

main () {
  # Set HOMEFRIES_NO_COLOR=true, probably.
  _export_homefries_no_color

  _alias_stripcolors

  # Cleanup after self.
  _unset_f_color_term
}

main "$@"
unset -f main

