# vim:tw=0:ts=2:sw=2:et:norl:nospell:ft=sh

source_deps () {
  # Load: warn, etc.
  . ${HOME}/.fries/lib/logger.sh
}

reveal_biz_vars () {
  MR_TMP_CHORES_FILE='/tmp/home-fries-myrepos.chores-ieWeich9kaph5eiR'
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

git_status_cache_setup () {
  ([ "${MR_ACTION}" != 'status' ] && return 0) || true
#  git_any_cache_setup
  truncate -s 0 ${MR_TMP_CHORES_FILE}
}

git_status_cache_teardown () {
  ([ "${MR_ACTION}" != 'status' ] && return 0) || true
  local ret_code=0
#  git_any_command_stopped
  if [ -s ${MR_TMP_CHORES_FILE} ]; then
    #warn "GRIZZLY! One or more repos need attention."
    local dirty_count=$(cat "${MR_TMP_CHORES_FILE}" | wc -l)
    local infl
    local refl
    [ ${dirty_count} -ne 1 ] && infl='s' || infl=''
    [ ${dirty_count} -eq 1 ] && refl='s' || refl=''
    warn "GRIZZLY! We found ${dirty_count} repo${infl} which need${refl} attention."
    notice
    notice "Here's some copy-pasta if you wanna fix it:"
    echo
    cat ${MR_TMP_CHORES_FILE}
    echo
    # We could return nonzero, which `mr` would see and die on,
    # but the action for each repo that's dirty also indicated
    # failure, so `mr` already knows to exit nonzero. Also, we
    # want to return 0 here so that the stats line is printed.
    # NOPE: ret_code=1
  fi
  /bin/rm ${MR_TMP_CHORES_FILE}
  return ${ret_code}
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

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

git_status_check_report_9chars () {
  status_adj="$1"
  opt_prefix="$2"
  opt_suffix="$3"
  debug " "\
    "${opt_prefix}$(fg_lightorange)$(attr_underline)${status_adj}$(attr_reset)${opt_suffix}" \
    "  $(fg_lightorange)$(attr_underline)${MR_REPO}$(attr_reset)  $(fg_hotpink)✗$(attr_reset)"
}

git_status_check_unstaged () {
  # In this function, and in others below, we use a subprocess and return
  # true, otherwise we'd need to wrap the call with set +e and set -e,
  # otherwise the function would fail if no unstaged changes found.
  #
  local extcd
  # ' M' is modified but not added.
  (git status --porcelain | grep "^ M " >/dev/null 2>&1) || extcd=$?
  if [ -z ${extcd} ]; then
    DIRTY_REPO=true
    git_status_check_report_9chars 'unstaged' ' '
  fi
}

git_status_check_uncommitted () {
  local extcd
  # 'M ' is added but not committed.
  (git status --porcelain | grep "^M  " >/dev/null 2>&1) || extcd=$?
  if [ -z ${extcd} ]; then
    DIRTY_REPO=true
    git_status_check_report_9chars 'uncommitd'
  fi
}

git_status_check_untracked () {
  local extcd
  # '^?? ' is untracked.
  (git status --porcelain | grep "^?? " >/dev/null 2>&1) || extcd=$?
  if [ -z ${extcd} ]; then
    DIRTY_REPO=true
    git_status_check_report_9chars 'untracked'
  fi
}

git_status_check_any_porcelain_output () {
  ${DIRTY_REPO} && return
  local n_bytes=$(git status --porcelain | wc -c)
  if [ ${n_bytes} -gt 0 ]; then
    DIRTY_REPO=true
    warn "UNEXPECTED: \`git status --porcelain\` nonempty output in repo at: “${MR_REPO}”"
    git_status_check_report_9chars 'confusing'
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

