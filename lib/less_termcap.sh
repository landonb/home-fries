# vim:tw=0:ts=2:sw=2:et:norl:ft=bash

# - Colors inspired by: "Want colored man pages?"
#   http://boredzo.org/blog/archives/2016-08-15/colorized-man-pages-understood-and-customized
#   https://superuser.com/questions/452034/bash-colorized-man-page
export LESS_TERMCAP_mb="$(printf "\e[1;31m")"
export LESS_TERMCAP_md="$(printf "\e[1;31m")"
export LESS_TERMCAP_me="$(printf "\e[0m")"
export LESS_TERMCAP_se="$(printf "\e[0m")"
export LESS_TERMCAP_so="$(printf "\e[1;44;33m")"
export LESS_TERMCAP_ue="$(printf "\e[0m")"
export LESS_TERMCAP_us="$(printf "\e[1;32m")"

# - Colors inspired by: "Colorize Your CLI"
#   https://danyspin97.org/blog/colorize-your-cli/#man
# (lb): These colors are less harsh than the ones above,
# but they're also a little too light, perhaps (especially
# the cyan). So disabled (for now).
if false; then
  export LESS_TERMCAP_mb=$(tput bold; tput setaf 2) # green
  export LESS_TERMCAP_md=$(tput bold; tput setaf 6) # cyan
  export LESS_TERMCAP_me=$(tput sgr0)
  export LESS_TERMCAP_so=$(tput bold; tput setaf 3; tput setab 4) # yellow on blue
  export LESS_TERMCAP_se=$(tput rmso; tput sgr0)
  export LESS_TERMCAP_us=$(tput smul; tput bold; tput setaf 7) # white
  export LESS_TERMCAP_ue=$(tput rmul; tput sgr0)
fi
# - Other settings from *Colorize Your CLI*.
#   - Albeit I don't see any different with or without these.
export LESS_TERMCAP_mr=$(tput rev)
export LESS_TERMCAP_mh=$(tput dim)
export LESS_TERMCAP_ZN=$(tput ssubm)
export LESS_TERMCAP_ZV=$(tput rsubm)
export LESS_TERMCAP_ZO=$(tput ssupm)
export LESS_TERMCAP_ZW=$(tput rsupm)
export GROFF_NO_SGR=1 # For Konsole and Gnome-terminal

