# vim:tw=0:ts=2:sw=2:et:norl:nospell:ft=sh

source_deps () {
  # Load: warn, etc.
  . ${HOME}/.fries/lib/logger.sh
}

reveal_biz_vars () {
  # 2019-10-21: (lb): Because myrepos uses subprocesses, our best bet for
  # maintaining data across all repos is to use temporary files.
  MR_TMP_RNTIME_FILE='/tmp/home-fries-myrepos.rntime-ieWeich9kaph5eiR'
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

git_any_command_started () {
  date +%s.%N > "${MR_TMP_RNTIME_FILE}"
}

git_any_command_stopped () {
  local SETUP_TIME_0=$(cat "${MR_TMP_RNTIME_FILE}")
  [ -z ${SETUP_TIME_0} ] && error "ERROR:" \
    "Missing start time! Be sure to call \`git_status_cache_setup\`."
  local SETUP_TIME_N="$(date +%s.%N)"
  local time_elapsed=$(\
    echo "scale=2; ($SETUP_TIME_N - $SETUP_TIME_0) * 100 / 100" | bc -l
  )
  # We could only show elapsed time if greater than a specific duration. E.g.,
  #   # NOTE: Use `bc` to output 0 or 1, and use ``(( ... ))`` so the shell
  #   #       interprets the result as false or true respectively.
  #   if (( $(echo "${time_elapsed} > 0.25" | bc -l) )); then
    info
    info "$(attr_bold)$(bg_lime)$(fg_black)Elapsed: ${time_elapsed} secs.$(attr_reset)"
    info
  #   fi
  /bin/rm "${MR_TMP_RNTIME_FILE}"
}

git_any_cache_setup () {
  git_any_command_started
}

git_any_cache_teardown () {
  git_any_command_stopped
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main () {
  source_deps
  reveal_biz_vars
}

main "$@"

