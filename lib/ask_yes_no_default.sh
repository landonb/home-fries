#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

check_deps () {
  # Verify process_util.sh loaded.
  check_dep 'tweak_errexit'
}

# ============================================================================
# *** Question Asker and Input Taker.

# USAGE:
#   # Source this file.
#   . ask_yes_no_default.sh
#
#   # Ask user to "press [Y]/n".
#   ask_yes_no_default "y"
#
#   # This is the same as:
#   ask_yes_no_default "y" 15 "n"
#
#   # If user presses "y", "Y", or <ENTER>, an environment variable
#   # named ${the_choice} is set to "Y". If user presses "n" or "N",
#   # ${the_choice} is set to "N". If user does nothing for 15 seconds,
#   # the timer expires, and ${the_choice} is set to "Y". Any other key
#   # and the script complains, resets the countdown, and prompts user
#   # again.
#
#   # To make the default be "N", not "Y", specify "N" first, e.g.,
#   ask_yes_no_default "n"
#
#   # You can alternatively use other single-character keys, e.g.,
#   ask_yes_no_default "a" 15 "b"

# Ask a yes/no question and take just one key press as answer
# (not waiting for user to press Enter), and complain if answer
# is not y or n (or one of some other two characters).
ask_yes_no_default () {
  local default_choice="$1"
  local choice_timeout="$2"
  local other_choice="$3"

  # Don't exit on error, since `read` returns $? != 0 on timeout.
  tweak_errexit +eE
  # Also -x prints commands that are run, which taints the output.
  set +x

  # POSIX-friendly uppercase (cmp. Bash v4+ ${var^^})
  #            and lowercase (cmp. Bash v4+ ${var,,}).
  to_upper () { printf "$1" | tr '[:lower:]' '[:upper:]'; }
  to_lower () { printf "$1" | tr '[:upper:]' '[:lower:]'; }

  local choice1_u=$(to_upper ${default_choice})
  local choice1_l=$(to_lower ${default_choice})
  local choice2_u=$(to_upper ${other_choice})
  local choice2_l=$(to_lower ${other_choice})
  # Use default second choice if yes-or-no question.
  if [ -z "${choice2_u}" ]; then
    if [ "${choice1_u}" = 'Y' ]; then
      choice2_u='N'
      choice2_l='n'
    elif [ "${choice1_u}" = 'N' ]; then
      choice2_u='Y'
      choice2_l='y'
    else
      echo "ERROR: ask_yes_no_default: cannot infer second choice."
      exit 1
    fi
  fi
  # Make sure the choices are really just single-character strings.
  if [ ${#choice1_u} -ne 1 ] || [ ${#choice2_u} -ne 1 ]; then
    echo "ERROR: ask_yes_no_default: choices should be single letters."
    exit 1
  fi
  # Last check: uniqueness.
  if [ "${choice1_u}" = "${choice2_u}" ]; then
    echo "ERROR: ask_yes_no_default: choices should be unique."
    exit 1
  fi

  if [ "${choice1_u}" = 'Y' ] && [ "${choice2_u}" = 'N' ]; then
    local choices='[Y]/n'
  elif [ "${choice1_u}" = 'N' ] && [ "${choice2_u}" = 'Y' ]; then
    local choices='y/[N]'
  else
    local choices="[${choice1_u}]/${choice2_l}"
  fi

  if [ -z "${choice_timeout}" ]; then
    # Default timeout: 15 seconds.
    local timeo=15
  else
    local timeo=${choice_timeout}
  fi
  local timedout=true

  # https://stackoverflow.com/questions/2388090/
  #   how-to-delete-and-replace-last-line-in-the-terminal-using-bash
  # $ seq 1 1000000 | while read i; do echo -en "\r$i"; done

  local valid_answers="${choice1_u}${choice1_l}${choice2_u}${choice2_l}"

  # Don't use local on the_choice; caller expects it.
  unset -v the_choice
  # Note: The while-pipe trick causes `read` to return immediately with junk.
  #  Nope: seq 1 5 | while read i; do
  local not_done=true
  while $not_done; do
    not_done=false
    local elaps
    for elaps in `seq 0 $((timeo - 1))`; do
      printf '%s' \
        "[Default in $((timeo - elaps)) seconds...] Please press ${choices} "
      read -n 1 -t 1 the_choice
      if [ $? -eq 0 ]; then
        # Thanks for the hint, stoverflove.
        # https://stackoverflow.com/questions/8063228/
        #   how-do-i-check-if-a-variable-exists-in-a-list-in-bash
        # NOTE: This might be the only line preventing this script
        #       from being POSIX-compliant.
        #       - Could probably use `grep` instead if we wanted
        #         to make this script not rely on Bash.
        # NOTE: This test passes when user presses <ENTER>.
        if [[ ${valid_answers} =~ ${the_choice} ]]; then
          # The user answered the call correctly.
          # Unless user pressed <ENTER>, print a newline.
          [ -z "${the_choice}" ] || echo
          # So that we don't print another newline below,
          # indicate not timed out.
          timedout=false
          break
        else
          echo
          # echo "Please try answering with a Y/y/N/n answer!"
          echo "That's not the answer I was hoping for..."
          echo "Let's try this again, shall we?"
          sleep 1
          not_done=true
          break
        fi
      fi
      if [ ${elaps} -lt $((timeo - 1)) ]; then
        # Return to the start of the line.
        printf '\r'
      fi
    done
  done

  # If `read` did not set ${the_choice}, means timeout, so choose default.
  if [ -z "${the_choice}" ]; then
    the_choice="${choice1_u}"
    # If user presses a key (including <ENTER>), there's a newline, so
    # always print a newline if the countdown timer expired.
    ${timedout} && echo
  fi

  # Uppercase the return character. Which we return in a variable.
  the_choice="$(to_upper ${the_choice})"

  reset_errexit

} # end: ask_yes_no_default

# Test:
#  ask_yes_no_default 'Y'
#  echo $the_choice

# ============================================================================

main () {
  check_deps
  unset -f check_deps
}

main "$@"
unset -f main

