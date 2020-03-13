#!/bin/bash
# vim:tw=0:ts=2:sw=2:et:norl:
# Project: https://github.com/landonb/home-fries
# License: GPLv3

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

source_deps () {
  # When sourced from ~/.homefries/.bashrc-bin/bashrc.core.sh, you cannot
  # import other files from this script's dir relatively, e.g., not:
  #   . path_util.sh
  # Note that, when sourced from said script:
  #  $0: /bin/bash
  #  ${BASH_SOURCE[0]}: /home/user/.homefries/lib/bash_base.sh
  # because /bin/bash is sourced bashrc.core.sh -- it's the owning
  # process. So here we use BASH_SOURCE to get path relative to us.
  local curdir=$(dirname -- "${BASH_SOURCE[0]}")
  . ${curdir}/path_util.sh
  . ${curdir}/process_util.sh
}

# ============================================================================
# *** Internal setup.

# Enable HOMEFRIES_WARNINGS for more blather.
default_homefries_warnings () {
  # Usage, e.g.:
  #   HOMEFRIES_WARNINGS=true bash
  [ -z ${HOMEFRIES_WARNINGS+x} ] &&
    HOMEFRIES_WARNINGS=false
}

# ============================================================================
# *** Chattiness

default_debug_trace () {
  # If the user is running from a terminal (and not from cron), always be chatty.
  # But don't change the debug trace flag if caller set it before calling us.
  # NOTE -z is false if DEBUG_TRACE is true or false and true if it's unset.
  if [[ -z $DEBUG_TRACE ]]; then
    if [[ "dumb" != "${TERM}" ]]; then
      DEBUG_TRACE=true
    else
      DEBUG_TRACE=false
    fi
  fi
}

# Say hello to the user.
introduce_user_to_self () {
  trace "Hello, ${LOGNAME}. (From: bash_base!)"
  trace ""
}

trace () {
  $DEBUG_TRACE && echo $1
}

# ============================================================================
# *** Script timering

script_finished_print_time () {
  local time_1=$(date +%s.%N)
  #$DEBUG_TRACE && echo ""
  $DEBUG_TRACE && printf "All done: Elapsed: %.2F mins.\n" \
      $(echo "($time_1 - $script_time_0) / 60.0" | bc -l)
}

# ============================================================================
# *** Script paths.

# Make it easy to reference the script name and relative or absolute path.
gather_script_meta () {
  # NOTE: This script gets sourced, not run, so $0 is the name of the sourcer.
  #
  #       On `bash`, when sourced from a bash startup script,
  #       e.g., from ${HOMEFRIES_DIR}/.bashrc/bashrc.core.sh,
  #       $0 is '/bin/bash'.
  #
  #       Or, if you sudo'd, e.g., `sudo su - some_user`, then
  #       $0 is '-su'. (Test: ${0:0:1} == '-') ([lb] has also seen '-bash')
  #
  #       From `man bash`:
  #         INVOCATION
  #           A login shell is one whose first character of argument zero is a -,
  #           or one started with the --login option.
  #       Also, ref:
  #         https://unix.stackexchange.com/questions/38175/
  #           difference-between-login-shell-and-non-login-shell

  # NOTE: Using $0 and not ${BASH_SOURCE[0]} because BASH_SOURCE[0] is
  #       this file, and $0 is the calling process that sourced us.
  local SCRIPT_NAME=$(basename -- "$0")

  # Symlinks are more reliable using absolute paths, in my experience,
  #   so we encourage using the absolute path.
  local script_dir_absolute=$(dirname -- $(readlink -f -- "$0"))
  # And here's another way to do it:
  #   local script_dir_relative=$(dirname -- "$0")
  #   pushd ${script_dir_relative} &> /dev/null
  #   local script_dir_absolute=$(pwd -P)
  #   popd &> /dev/null
  SCRIPT_DIR="${script_dir_absolute}"

  if false; then
    # Show just once.
    if [[ "${HOMEFRIES_LOADED_BASH_BASE:-false}" != true ]]; then
      # E.g., on `bash`,
      #   0: /bin/bash
      #   BASH_SOURCE[0]: /home/${LOGNAME}/.homefries/lib/bash_base.sh
      #   SCRIPT_NAME: bash
      #   script_dir_relative: /bin
      #   script_dir_absolute: /bin
      # E.g., on `/kit/playground/selflink/my_script_that_sources_bash_base.sh`,
      #    #!/bin/bash
      #    HOMEFRIES_LOADED_BASH_BASE=
      #    . "bash_base.sh"
      # you get,
      #    0: /kit/playground/my_script_that_sources_bash_base.sh
      #    BASH_SOURCE[0]: /home/user/.homefries/lib/bash_base.sh
      #    SCRIPT_NAME: my_script_that_sources_bash_base.sh
      #    script_dir_relative: /kit/playground/selflink
      #    script_dir_absolute: /kit/playground
      echo "0: $0"
      echo "BASH_SOURCE[0]: ${BASH_SOURCE[0]}"
      echo "SCRIPT_NAME: ${SCRIPT_NAME}"
      #echo "script_dir_relative: ${script_dir_relative}"
      echo "script_dir_absolute: ${script_dir_absolute}"
    fi
  fi
}

# ============================================================================
# *** End of bashy goodness.

main () {
  source_deps
  unset -f source_deps

  must_sourced ${BASH_SOURCE[0]}

  # 2017-10-03: Earlier I was thinking of skipping this file if it was
  # already loaded (as it takes a pause to load), but then I just split
  # everything out to other files.
  # FIXME/2017-10-03: I'm sure I broke other files that just load
  #   bash_base, but it was good to break this apart.
  # So I probably don't need this:
  #if [[ "${HOMEFRIES_LOADED_BASH_BASE}" == true ]]; then
  #  return
  #fi

  # Time this script
  export script_time_0=$(date +%s.%N)

  # Default:
  #   HOMEFRIES_WARNINGS=false
  default_homefries_warnings
  unset -f default_homefries_warnings

  default_debug_trace
  unset -f default_debug_trace

  #introduce_user_to_self
  unset -f introduce_user_to_self

  gather_script_meta
  unset -f gather_script_meta

  export HOMEFRIES_LOADED_BASH_BASE=true
}

main "$@"
unset -f main

