#!/bin/bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

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

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

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

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# Also remember: In Bash, to handle spaces when iterating over an array, iterate the indices.
echo_list () {
  local list=$1
  if [[ -z ${list} ]]; then
    declare -a list
  fi

  local ix
  for ((ix = 0; ix < ${#list[@]}; ix++)); do
    local elem="${list[$ix]}"
    echo "elem: ${elem}"
  done

  local elem
  for elem in "${list[@]}"; do
    echo "elem: ${elem}"
  done

  # HINT: Not Bash? In POSIX, there's only one array -- the positional arguments --
  # so you could iterate this way:
  set -- ${list}
  while [ "$1" != '' ]; do
    local elem="$1"
    shift
    echo "elem: ${elem}"
  done
}

# MEH: A dict is not an array, but I'm not making a dict_util.sh (yet?). [2018-01-29]
echo_dict () {
  # Per https://www.mail-archive.com/bug-bash@gnu.org/msg01774.html,
  #  and what [Bash's] Chet says: Cannot encode an array var into the env.
  # Meaning: You cannot pass an associate array in bash. E.g., this won't work:
  #   dict=$1
  #   if [[ -z ${dict} ]]; then
  #     declare -A dict
  #   fi
  # [lb] not sure there's a work around, other than, say, using Ruby or Perl
  # to write shell scripts.
  declare -A dict
  local ix
  for ix in "${!dict[@]}"; do
    echo "key  : $ix"
    echo "value: ${dict[$ix]}"
  done
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main () {
  #alias elem_in_arr=array_in
  :
}

main "$@"
unset -f main

