# vim:tw=0:ts=2:sw=2:et:norl:nospell:ft=config

source_deps () {
  local libdir="${HOME}/.fries/lib"
  if [ -n "${BASH_SOURCE}" ]; then
    libdir="$(dirname -- ${BASH_SOURCE[0]})../../lib/"
  fi

  # Use logger (which loads color_funcs.sh) for colorful, stylized output.
  # NOTE: So that this script is POSIX-compliant, use `.`, not `source`.
  . "${libdir}/logger.sh"
}

reveal_biz_vars () {
  # 2019-10-21: (lb): Because myrepos uses subprocesses, our best bet for
  # maintaining data across all repos is to use temporary files.
  MR_TMP_CHORES_FILE='/tmp/home-fries-myrepos.chores-ieWeich9kaph5eiR'
  MR_TMP_RNTIME_FILE='/tmp/home-fries-myrepos.rntime-ieWeich9kaph5eiR'
}

git_status_command_started () {
  date +%s.%N > "${MR_TMP_RNTIME_FILE}"
}

git_status_command_stopped () {
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

git_status_cache_setup () {
  git_status_command_started
  truncate -s 0 ${MR_TMP_CHORES_FILE}
}

git_status_cache_teardown () {
  local ret_code=0
  git_status_command_stopped
  if [ -s ${MR_TMP_CHORES_FILE} ]; then
    warn "GRIZZLY! One or more repos need attention."
    notice
    notice "Here's some copy-pasta if you wanna fix it:"
    echo
    cat ${MR_TMP_CHORES_FILE}
    echo
    # We could return nonzero, which `mr` would see and die on,
    # but the action for each repo that's dirty also indicated
    # failure, so `mr` already knows to exit nonzero. Also, we
    # want to return 0 here so that the stats line is printed.
    ret_code=0
  fi
  /bin/rm ${MR_TMP_CHORES_FILE}
  return ${ret_code}
}

# NOTE: Parsing --porcelain response should be future-proof.
#
#   $ man git status
#   ...
#     --porcelain[=<version>]
#         Give the output in an easy-to-parse format for scripts. This
#         is similar to the short output, but will remain stable across
#         Git versions and regardless of user configuration.
#
git_status_check_reset () {
  DIRTY_REPO=false
}

git_status_check_unstaged () {
  # In this function, and in others below, we use a subprocess and return
  # true, otherwise we'd need to wrap the call with set +e and set -e,
  # otherwise the function would fail if no unstaged changes found.
  #
  local extcd=0
  # ' M' is modified but not added.
  (git status --porcelain | grep "^ M " >/dev/null 2>&1) || extcd=$? || true
  if [ -z ${extcd} ]; then
    DIRTY_REPO=true
    info "   $(fg_lightorange)$(attr_underline)unstaged$(attr_reset)  " \
      "$(fg_lightorange)$(attr_underline)${MR_REPO}$(attr_reset)  $(fg_hotpink)✗$(attr_reset)"
  fi
}

git_status_check_uncommitted () {
  local extcd=0
  # 'M ' is added but not committed.
  (git status --porcelain | grep "^M  " >/dev/null 2>&1) || extcd=$? || true
  if [ -z ${extcd} ]; then
    DIRTY_REPO=true
    info "  $(fg_lightorange)$(attr_underline)uncommitd$(attr_reset)  " \
      "$(fg_lightorange)$(attr_underline)${MR_REPO}$(attr_reset)  $(fg_hotpink)✗$(attr_reset)"
  fi
}

git_status_check_untracked () {
  local extcd=0
  # '^?? ' is untracked.
  (git status --porcelain | grep "^?? " >/dev/null 2>&1) || extcd=$? || true
  if [ -z ${extcd} ]; then
    DIRTY_REPO=true
    info "  $(fg_lightorange)$(attr_underline)untracked$(attr_reset)  " \
      "$(fg_lightorange)$(attr_underline)${MR_REPO}$(attr_reset)  $(fg_hotpink)✗$(attr_reset)"
  fi
}

git_status_check_any_porcelain_output () {
  ${DIRTY_REPO} && return
  local n_bytes=$(git status --porcelain | wc -c)
  if [ ${n_bytes} -gt 0 ]; then
    DIRTY_REPO=true
    warn "UNEXPECTED: \`git status --porcelain\` nonempty output in repo at: “${MR_REPO}”"
    info "  $(fg_lightorange)$(attr_underline)outpnnmpt$(attr_reset)  " \
      "$(fg_lightorange)$(attr_underline)${MR_REPO}$(attr_reset)  $(fg_hotpink)✗$(attr_reset)"
  fi
}

git_status_porcelain () {
  git_status_check_reset
  git_status_check_unstaged
  git_status_check_uncommitted
  git_status_check_untracked
  git_status_check_any_porcelain_output
  if ${DIRTY_REPO}; then
    # (lb): I don't see an easy way to assemble work to tell user to do
    # other than to use an intermediate file, as this function fun in a
    # subprocess (we cannot pass back anything other than an exit code).
    #echo "  cdd ${MR_REPO} && git add -p" >> ${MR_TMP_CHORES_FILE}
    # Note that sh (e.g., dash; or a POSIX shell) does not define `echo -e`
    # like Bash (and in fact `echo -e "some string" echoes "-e some string).
    echo "  cdd $(fg_lightorange)${MR_REPO}$(attr_reset) && git status" >> ${MR_TMP_CHORES_FILE}
    # Return 1 so `mr` marks repo as failed, and later exits 1.
    # Note that you can reduce a lot of myrepos output with this in your .mrconfig:
    #   [DEFAULT]
    #   # For all actions/any action, do not print line separator/blank line
    #   # between repo actions.
    #   no_print_sep = true
    #   # For mystatus action, do not print action or directory header line.
    #   no_print_action_mystatus = true
    #   no_print_dir_mystatus = true
    #   # For mystatus action, do not print if repo fails (action will do it).
    #   no_print_failed_mystatus = true
    return 1
  fi
  debug "  $(fg_mintgreen)$(attr_emphasis)unchanged$(attr_reset)  " \
    "$(fg_mintgreen)${MR_REPO}$(attr_reset)"
  return 0
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main () {
  source_deps
  reveal_biz_vars
  # git_status_porcelain "$@"
}

main "$@"

