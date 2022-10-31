#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# Per the pyenv README:
#
#   https://github.com/pyenv/pyenv#set-up-your-shell-environment-for-pyenv
#
# But note that we don't add ~/.pyenv/bin to PATH because there's a symlink
# to pyenv wired under ~/.local/bin (courtesy the DepoXy pyenv project OMR
# infuse command).

_hf_python_util_pyenv_export_environs () {
  export PYENV_ROOT="${HOME}/.pyenv"
}

# Note the `pyenv init -` does the following:
# - Prepends ~/.pyenv/shims to PATH.
# - Sets PYENV_SHELL=bash.
# - Sources /path/to/pyenv/libexec/../completions/pyenv.bash
#   (which is redunant: see ~/.homefries/bin/completions/pyenv.bash).
# - Calls `command pyenv rehash` (to "Rehash pyenv shims").
# - Creates a lightweight pyenv() wrapper.
_hf_python_util_pyenv_eval_init () {
  if command -v pyenv > /dev/null; then
    eval "$(pyenv init -)"
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

_hf_python_util_pyenv_homebrew_load_completions () {
  local brew_home="/opt/homebrew"
  # Otherwise on Intel Macs it's under /usr/local.
  [ -d "${brew_home}" ] || brew_home="/usr/local"

  local cellar_path="${brew_home}/Cellar"

  local pyenv_bash="${cellar_path}/pyenv/2.3.5/completions/pyenv.bash"

  if [ -f "${pyenv_bash}" ]; then
    . "${pyenv_bash}"
  fi
}

_hf_python_util_pyenv_virtualenv_init () {
  if which pyenv-virtualenv-init > /dev/null; then
      eval "$(pyenv virtualenv-init -)"
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

home_fries_setup_pyenv () {
  _hf_python_util_pyenv_export_environs
  unset -f _hf_python_util_pyenv_export_environs

  _hf_python_util_pyenv_eval_init
  unset -f _hf_python_util_pyenv_eval_init

  _hf_python_util_pyenv_homebrew_load_completions
  unset -f _hf_python_util_pyenv_homebrew_load_completions

  _hf_python_util_pyenv_virtualenv_init
  unset -f _hf_python_util_pyenv_virtualenv_init
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main () {
  :
}

main "$@"
unset -f main

