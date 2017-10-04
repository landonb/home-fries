#!/bin/bash
# Last Modified: 2017.10.03
# vim:tw=0:ts=2:sw=2:et:norl:

# File: bash_base.sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project Page: https://github.com/landonb/home_fries
# Summary: Generic Bash function library.
# License: GPLv3

# Usage: Source this script. Call its functions. Use its exports.

source_deps() {
  # When sourced from ~/.fries/.bashrc/bashrc.core.sh, you cannot
  # import other files from this script's dir relatively, e.g., not:
  #   source path_util.sh
  # Note that, when sourced from said script:
  #  $0: /bin/bash
  #  ${BASH_SOURCE[0]}: /home/landonb/.fries/lib/bash_base.sh
  # because /bin/bash is sourced bashrc.core.sh -- it's the owning
  # process. So here we use BASH_SOURCE to get path relative to us.
  local curdir=$(dirname -- "${BASH_SOURCE[0]}")
  source ${curdir}/path_util.sh
  source ${curdir}/process_util.sh
}

# ============================================================================
# *** Internal setup.

# Enable HOMEFRIES_WARNINGS for more blather.
default_homefries_warnings() {
  if [[ -z ${HOMEFRIES_WARNINGS+x} ]]; then
    # Usage, e.g.:
    #   HOMEFRIES_WARNINGS=true bash
    HOMEFRIES_WARNINGS=false
  fi
}

# ============================================================================
# *** Chattiness

default_debug_trace() {
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
introduce_user_to_self() {
  trace "Hello, ${LOGNAME}. (From: bash_base!)"
  trace ""
}

trace() {
  $DEBUG_TRACE && echo $1
}

# ============================================================================
# *** Script timering

script_finished_print_time () {
  local time_1=$(date +%s.%N)
  $DEBUG_TRACE && echo ""
  $DEBUG_TRACE && printf "All done: Elapsed: %.2F mins.\n" \
      $(echo "($time_1 - $script_time_0) / 60.0" | bc -l)
}

# ============================================================================
# *** Script paths.

# Make it easy to reference the script name and relative or absolute path.
gather_script_meta() {
  # NOTE: This script gets sourced, not run, so $0 is the name of the sourcer.
  #
  #       On `bash`, when sourced from a bash startup script,
  #       e.g., from ${HOMEFRIES_DIR}/.bashrc/bashrc.core.sh,
  #       $0 is '/bin/bash'.
  #
  #       Or, if you sudo'd, e.g., `sudo su - some_user`, then
  #       $0 is '-su'. (Test: ${0:0:1} == '-') ([lb] has also seen '-bash')

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
      #   BASH_SOURCE[0]: /home/${USER}/.fries/lib/bash_base.sh
      #   SCRIPT_NAME: bash
      #   script_dir_relative: /bin
      #   script_dir_absolute: /bin
      # E.g., on `/kit/playground/selflink/my_script_that_sources_bash_base.sh`,
      #    #!/bin/bash
      #    HOMEFRIES_LOADED_BASH_BASE=
      #    source "bash_base.sh"
      # you get,
      #    0: /kit/playground/my_script_that_sources_bash_base.sh
      #    BASH_SOURCE[0]: /home/landonb/.fries/lib/bash_base.sh
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
# *** errexit respect.

# Reset errexit to what it was . If we're not anticipating an error, make
# sure this script stops so that the developer can fix it.
#
# NOTE: You can determine the current setting from the shell using:
#
#        $ set -o | grep errexit | /bin/sed -r 's/^errexit\s+//'
#
#       which returns on or off.
#
#       However, from within this script, whether we set -e or set +e,
#       the set -o always returns the value from our terminal -- from
#       when we started the script -- and doesn't reflect any changes
#       herein. So use a variable to remember the setting.
#
reset_errexit () {
  if $USING_ERREXIT; then
    #set -ex
    set -e
  else
    set +ex
  fi
}

suss_errexit () {
  shell_opts=$SHELLOPTS
  set +e
  echo $shell_opts | grep errexit >/dev/null 2>&1
  if [[ $? -eq 0 ]]; then
    USING_ERREXIT=true
  else
    USING_ERREXIT=false
  fi
  if ${USING_ERREXIT}; then
	  set -e
  fi
}

# ============================================================================
# *** End of bashy goodness.

main() {
  source_deps

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

  default_debug_trace
  #introduce_user_to_self

  gather_script_meta

  suss_errexit

  export HOMEFRIES_LOADED_BASH_BASE=true
}

main "$@"

