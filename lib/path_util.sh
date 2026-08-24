#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# So that we don't step on toes of previously defined aliases.

pushd_alias_or_warn() {
  if ! pushd_alias "$@"; then
    >&2 echo "WARNING: Cannot alias: “$1” already assigned"

    return 1
  fi
}

# REFER: The printf below escape-quotes an arbitrary no. of args.
# - CALSO: There's a similar mechanism, which is a Bash4.4+ism:
#     ${@@Q}   "Parameter transformation": ${parameter@operator}
#               Q — The expansion is a string that is the value of param.
#                   quoted in a format that can be reused as input.
#   but that just single-quotes each item, not escaped-doubles.
#   - Also ${@@E} sounds like it might work, but alas no.
# - Fortunately the printf shell built-in repeats the pattern
#   for an arbitrary number of arguments, which is perfect.

pushd_alias() {
  local name="$1"
  shift

  if type "${name}" >/dev/null 2>&1; then

    return 1
  fi

  eval "alias ${name}='_hf_pushd_with_args \"${name}\"$(printf ' \"%s\"' "$@")'"
}

_hf_pushd_with_args() {
  local alias_name="$1"
  local target_dir="$2"
  shift 2

  local curr_dir="$(realpath -- "$(pwd)")"
  local prev_target="${target_dir}"

  # FEATR: If user, when calling the alias, passes a (relative)
  # path, assume they want to enter a subdir of the 1st target.
  if [ $# -gt 0 ]; then
    # Slice array using relative index position.
    # - Altly: Direct index via ${@:$#} or Indirect expansion
    #   via ${!#} which uses $#.
    local final_arg="${@: -1}"
    # Check relative path (using Bashism; Altly: for Posix:
    #   case "${pth}" in
    #       /*) echo "Abso-lutely!" ;;
    #       *)  echo "Relativistical." ;;
    #   esac
    # - Note the tilde-prefix technically doesn't affect
    #   this function's usage, but included for complete-
    #   ness.
    if [[ "${final_arg}" != /* ]] && [[ "${final_arg}" != ~* ]]; then
      target_dir="${target_dir}/${final_arg}"
    else
      # FEATR: If alias made with *multiple* (full) paths, progress
      # through the paths depending on cwd. I.e., consider:
      #   pushd_alias_or_warn cdtest ~/foo ~/bar
      # then cdtest normally cd's to ~/foo, unless
      # current dir is ~/foo, than goes to ~/bar.
      while [ $# -gt 0 ]; do
        if [ "${curr_dir}" = "$(realpath -- "${prev_target}")" ]; then
          target_dir="$1"

          break
        fi

        prev_target="$1"
        shift
      done
    fi
  fi

  if ! test -d "${target_dir}"; then
    # Format error line `cd`, e.g.:
    #   $ cd foo
    #   bash: cd: foo: No such file or directory
    >&2 echo "homefries: ${alias_name}: No such file or directory: ${target_dir}"

    return 1
  fi

  pushd -- "${target_dir}" >/dev/null
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
