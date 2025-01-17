# vim:tw=0:ts=2:sw=2:et:norl:ft=bash
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# BWARE: Since 2024, Dash `command -v` no longer finds non-executable
# files on PATH. But Bash still does.
# - Author previously used this as a kludgy hack to source dependencies
#   (i.e., the code doesn't need to know the path to the dependency,
#   but it can assume the caller setup PATH so the dependency will
#   be found).
# - So now, for POSIX-compliance, when a script needs to source a
#   dependency, it either needs to use a full path, or it needs to
#   assume the caller set the current working directory so that the
#   script can use a relative path instead to find its dependencies.

# For sourced files to ensure things setup as expected, too.
check_dep () {
  local cname="$1"
  local ahint="$2"

  local found_cmd

  if ! found_cmd="$(command -v "${cname}")"; then
    >&2 printf '\r%s\n' "ALERT: Missing dependency: ${cname}"
    [ -n "${ahint}" ] \
      && >&2 echo "${ahint}"

    false
  else
    # See BWARE comment above re: Dash vs. Bash behavior.
    # - Gripe if the command is not executable, to subtle encourage
    #   the user (you!) to make their dependency loading code to be
    #   Dash-friendly (just as a good practice, because oftentimes
    #   you'll find that you want some code work with /bin/sh).
    local abspath
    abspath="$( \
      (unset -f ${cname}; unalias ${cname}; command -v ${cname}) \
        2> /dev/null )" \
      || true

    if [ "${abspath}" = "${found_cmd}" ] \
      && ! test -x "${abspath}" \
    ; then
      >&2 echo "GAFFE: Dependency located via \`command -v\` is not executable: ${abspath}"
      >&2 echo "- ALERT: This technique works in Bash, not it no longer works in Dash"
    fi

    true
  fi
}

