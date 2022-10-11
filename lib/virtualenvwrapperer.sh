#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# DATED/2022-09-29: The virtualenvwrapper is deprecated,
# because virtualenv itself deprecated as of Python 3.8.
#
#  https://doughellmann.com/projects/virtualenvwrapper/
#  https://bitbucket.org/virtualenvwrapper/virtualenvwrapper/src/master/
#
# Although... the virtualenv docs do not say anything about it being deprecated:
#
#   https://virtualenv.pypa.io/en/latest/
#
# The only place I see that information is these two articles:
#
#   https://www.activestate.com/resources/quick-reads/how-to-manage-python-dependencies-with-virtual-environments/
#   https://cloudbytes.dev/snippets/create-a-python-virtual-environment-using-venv
#
# Nonetheless, virtualenvwrapper is at least very stale, and hasn't been
# developed nor tested against versions greater than Python 3.6 (though
# I've used it successfully with Python 3.8, but not Python 3.10).
#
# LATER/2022-09-29: Remove this file, and its `source_it` from bashrc.core.sh.
# - Note that the author still uses virtualenv for legacy projects, so we won't
#   remove this file for a while, at least not until I've moved my projects to
#   Poetry (or Pipenv, or Conda, or Hatch, or PDM, or pyflow; too many options).
#   Better yet, probably not until Python 3.8 is EOL. (Because virtualenvwrapper
#   still works for me in Python 3.8, but not in Python 3.10; and I didn't test
#   Python 3.9 so not sure about that. So we'll keep this code so long as it
#   might be useful, i.e., so long as Python 3.8 is still supported.)

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# 2020-03-15: Deferred-load virtualenvwrapper.sh, 'cause it takes ~0.15 secs.
# - That is, I just day retooling Bashrc, might as well make it zippy, too.
# - Wow, the first time I ran this function, says it took ~1.04 secs. to
#   source the wrapper, so slow! And supports reasoning this wrapper should
#   be lazily sourced. (Second time I ran it: 0.55 secs. Pretty wide range,
#   but consistently slow!)

source_virtualenvwrapper () {
  local time_outer_0=$(print_nanos_now)

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

