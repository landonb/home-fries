#!/bin/bash
# Last Modified: 2017.10.03
# vim:tw=0:ts=2:sw=2:et:norl:

# File: array_util.sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project Page: https://github.com/landonb/home-fries
# Summary: Generic Bash function library.
# License: GPLv3

# Usage: Source this script. Call its functions. Use its exports.

# ============================================================================
# *** Bash array contains

# Named after flashclient.utils.misc.Collection.array_in:
# and graciously c/x/p/d/ed from
#   http://stackoverflow.com/questions/3685970/bash-check-if-an-array-contains-a-value
# Usage: if `array_in "some key" "${some_array[@]}"`; then ... fi
array_in () {
  local elem
  for elem in "${@:2}"; do
    if [[ "$elem" == "$1" ]]; then
      return 0
    fi
  done
  # WATCH_OUT: If the calling script is using 'set -e' it's going to exit!
  # MAYBE: Can we call 'set +e' here, before returning? Or warn?
  return 1
}

# ============================================================================
# *** Bash array multidimensionalization

# In Bash, arrays are one-dimensional, though they allow multiple word entries.
# But when you pass an array as a function parameter, it gets flattened.
#
# Consider an array of names and ages. You cannot use =() when entries have
# multiple words. E.g., this is wrong,
#
#   people=("'chester a. arthur' 45" "'maurice moss' 26")
#
# because ${people[1][0]} => 'maurice moss' 26
#
# And you cannot set another list (multidimensionality); this doesn't work,
#
#   people[0]=("chester a. arthur" 45)
#
# But you can make a long, flat list.
#
#   people=("chester a. arthur" "45"
#           "maurice moss" "26")
#
# where ${people[2]} => maurice moss
#
# So this fcn. wraps a flat list and treats it as a 2-dimensional array,
# using the elements in each sub-array as arguments to the function on
# which we're iterating.

arr2_fcn_iter () {
  local the_fcn=$1
  local cols_per_row=$2
  # This is a sneaky way to pass an array in Bash -- pass it's name.
  # The bang operator here resolves a name to a variable value.
  local two_dim_arr=("${!3}")
  local arr_total_rows=$((${#two_dim_arr[@]} / ${cols_per_row}))
  for arr_index in $(seq 0 $((${arr_total_rows} - 1))); do
    local beg_index=$((${arr_index} * ${cols_per_row}))
    local fin_index=$((${beg_index} + ${cols_per_row}))
    # This doesn't work:
    #   the_fcn ${two_dim_arr[*]:${beg_index}:${fin_index}}
    # because if you have spaces in any one param the fcn. will get
    # words around the spaces as multiple params.
    # WHATEVER: [lb] doesn't care anymore. Ignoring $cols_per_row
    #                                      and hard-coding))]}.
    if [[ ${cols_per_row} -lt 10 ]]; then
      ${the_fcn} "${two_dim_arr[$((${beg_index} + 0))]}" \
                 "${two_dim_arr[$((${beg_index} + 1))]}" \
                 "${two_dim_arr[$((${beg_index} + 2))]}" \
                 "${two_dim_arr[$((${beg_index} + 3))]}" \
                 "${two_dim_arr[$((${beg_index} + 4))]}" \
                 "${two_dim_arr[$((${beg_index} + 5))]}" \
                 "${two_dim_arr[$((${beg_index} + 6))]}" \
                 "${two_dim_arr[$((${beg_index} + 7))]}" \
                 "${two_dim_arr[$((${beg_index} + 8))]}" \
                 "${two_dim_arr[$((${beg_index} + 9))]}"
    else
      echo "Too many arguments for arr2_fcn_iter, sorry!" 1>&2
      exit 1
    fi
  done
}

main() {
  #alias elem_in_arr=array_in
  :
}

main "$@"

