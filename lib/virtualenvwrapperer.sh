#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# 2020-03-15: Deferred-load virtualenvwrapper.sh, 'cause it takes ~0.15 secs.
# - That is, I just day retooling Bashrc, might as well make it zippy, too.
# - Wow, the first time I ran this function, says it took ~1.04 secs. to
#   source the wrapper, so slow! And supports reasoning this wrapper should
#   be lazily sourced. (Second time I ran it: 0.55 secs. Pretty wide range,
#   but consistently slow!)

source_virtualenvwrapper () {
  local time_outer_0=$(home_fries_nanos_now)

  # Before sourcing the virturalenv wrapper, remove remnants from PATH.
  # That is, if you `workon <venv>` and than run `bash` or `tmux`, the
  # venv binaries will still be on PATH. Then, when sourcing the wrapper
  # on bash (home-fries) startup, you'd see:
  #
  #   /home/<user>/.virtualenvs/<venv>/bin/python:
  #     Error while finding module specification for 'virtualenvwrapper.hook_loader'
  #       (ModuleNotFoundError: No module named 'virtualenvwrapper')
  #   virtualenvwrapper.sh: There was a problem running the initialization hooks.
  #
  #   If Python could not import the module virtualenvwrapper.hook_loader,
  #     check that virtualenvwrapper has been installed for
  #       VIRTUALENVWRAPPER_PYTHON=/home/landonb/.virtualenvs/dob3x/bin/python
  #         and that PATH is set properly.
  #
  # Note the wrapper checks $WORKON_HOME, which defaults to ".virtualenvs"
  # if blank, to form the path, e.g., workon_home_dir="$HOME/$WORKON_HOME".
  # - Here we convert PATH separators to newlines;
  # - ignore any line starting with WORKON; and
  # - reform the path, converting newlines back to colons.
  # Note, too, the inner-$, in <$'\n'>, is ANSI-C Quoting.
  # https://www.gnu.org/software/bash/manual/html_node/ANSI_002dC-Quoting.html
  PATH="$(echo "${PATH//:/$'\n'}" | grep -v -e "^${HOME}/.virtualenvs/" | tr '\n' ':')"
  export PATH

  if [ -f "${HOME}/.local/bin/virtualenvwrapper.sh" ]; then
    . "${HOME}/.local/bin/virtualenvwrapper.sh"
  elif [ -f "/usr/local/bin/virtualenvwrapper.sh" ]; then
    . "/usr/local/bin/virtualenvwrapper.sh"
  fi

  # You: Remove HOMEFRIES_PROFILING=false (or set =true) to confirm that
  # sourcing virtualenvwrapper takes a noticeable amount of time.
  # 2020-03-18: Now that venv-wrap deferred, print_elapsed_time has been unset.
  if command -v "print_elapsed_time" > /dev/null; then
    HOMEFRIES_PROFILING=false print_elapsed_time \
      "${time_outer_0}" \
      "Sourced virtualenvwrapper.sh." \
      "Sourced: "
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

_homefries_venv_unset_lazy_loaders () {
  unset -f mkvirtualenv
  unset -f workon
  unset -f _homefries_venv_unset_lazy_loaders
}

# `workon` lazy-loader.
workon () {
  _homefries_venv_unset_lazy_loaders

  source_virtualenvwrapper
  unset -f source_virtualenvwrapper

  workon "$@"
}

# So that you don't have to run `workon` before `mkvirtualenv`.
# `workon` lazy-loader.
mkvirtualenv () {
  _homefries_venv_unset_lazy_loaders

  source_virtualenvwrapper
  unset -f source_virtualenvwrapper

  mkvirtualenv "$@"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main () {
  :
}

main "$@"

