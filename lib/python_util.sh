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

  # E.g., "/opt/homebrew/Cellar/pyenv/2.3.5/completions/pyenv.bash"
  local pyenv_bash="${cellar_path}/pyenv/"*"/completions/pyenv.bash"

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

#  $ po env info
#
#  Virtualenv
#  Python:         3.10.8
#  ...
#  Executable:     /home/user/.cache/pypoetry/virtualenvs/easy-as-pypi-appdirs-_M-chTHi-py3.10/bin/python
#  Valid:          True
#
#  System
#  Platform:   linux
#  ...
#  Executable: /usr/bin/python3.10
_hf_poetry_env_bin () {
  dirname "$(
    poetry env info --no-ansi --no-interaction \
      | grep -e "^Executable: " \
      | head -1 \
      | awk '{ print $2 }'
  )"
}

# SPIKE/2022-11-20: How is sourcing activate different than `poetry shell`?
# - Is it just because a subprocess cannot change the parent process, so
#   `poetry shell` has to open a new terminal session and inject the source
#   command therein?
# - But here we can use an alias, which'll run in the session context, so
#   we can avoid opening a new shell...
#   - Albeit now you need to call `deactivate`, instead of `exit` (which
#     I kinda liked about `poetry shell` usage)...
#     - Though we can always wrap `exit`...
_hf_python_util_poetry_alias_activate () {
  # claim_alias_or_warn "poactivate" ". \$(_hf_poetry_env_bin)/activate"
  claim_alias_or_warn "poactivate" \
    ". \$(_hf_poetry_env_bin)/activate && exit () { echo deactivate; deactivate; unset -f exit; }"
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

home_fries_setup_poetry () {
  _hf_python_util_poetry_alias_activate
  unset -f _hf_python_util_poetry_alias_activate
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main () {
  :
}

main "$@"
unset -f main

