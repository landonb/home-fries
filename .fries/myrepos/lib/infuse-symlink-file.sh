# vim:tw=0:ts=2:sw=2:et:norl:nospell:ft=sh

_info_infuse_symlink_file () {
  local relative_path="$1"
  local mrinfuse_path="$2"
  local canonicalized="$3"
  #
  local testing=false
  # Uncomment to spew vars and exit:
  # testing=true
  if $testing; then
    info "MR_REPO=${MR_REPO}"
    info "MR_CONFIG=${MR_CONFIG}"
    info "relative_path=${relative_path}"
    info "mrinfuse_path=${mrinfuse_path}"
    info "canonicalized=${canonicalized}"
    info "current dir: $(pwd)"
    return 1
  fi
}

params_has_switch () {
  local short_arg="$1"
  local longr_arg="$2"
  shift 2
  for arg in "$@"; do
    for switch in "${short_arg}" "${longr_arg}"; do
      if [ "${arg}" = "${switch}" ]; then
        return 0
      fi
    done
  done
  return 1
}

params_check_force () {
  params_has_switch '-f' '--force' "${@}"
}

params_check_safe () {
  params_has_switch '-s' '--safe' "${@}"
}

infuse_symlink_file () {
  local lnkpath
  local lnkfile
  lnkpath="$1"
  lnkfile="$(basename ${lnkpath})"
  # CONVENTION: Store private files under a directory named
  # .mrinfuse located in the same directory as the .mrconfig file whose
  # repo config calls this function. Under the .mrinfuse directory, mimic
  # the directory alongside the .mrconfig file. For instance, suppose you
  # had a config file at:
  #   /my/work/projects/.mrconfig
  # and you had a public repo underneath that project space at:
  #   /my/work/projects/cool/product/
  # you would store your private .ignore file at:
  #   /my/work/projects/.mrinfuse/cool/product/.ignore
  # then your infuse function would be specified in your .mrconfig as:
  #   [my/repo]
  #   infuse_symlink_file '.ignore'
  local relative_path
  local mrinfuse_path
  relative_path=${MR_REPO#"$(dirname ${MR_CONFIG})"/}
  mrinfuse_path="$(dirname ${MR_CONFIG})/.mrinfuse/${relative_path}/${lnkpath}"
  canonicalized=$(readlink -m "${mrinfuse_path}")

  _info_infuse_symlink_file "${relative_path}" "${mrinfuse_path}" "${canonicalized}"

  if [ ! -f "${canonicalized}" ]; then
    error "mrt: Failed to create symbolic link!"
    error "  Did not find linkable source file at:"
    error "  ${canonicalized}"
    return 1
  fi

  local nosafe=1
  params_check_safe "${@}" && nosafe=0 || true
  #
  local noforce=1
  params_check_force "${@}" && noforce=0 || true
  #
  if [ -e "${lnkpath}" ] && [ ! -h "${lnkpath}" ]; then
    if [ ${nosafe} -eq 0 ]; then
      local backup_postfix=$(date +%Y.%m.%d.%H.%M.%S)
      local backup_lnkpath="${lnkpath}-${backup_postfix}"
      /bin/mv "${lnkpath}" "${lnkpath}-${backup_postfix}"
      info "Moved existing ‘${lnkfile}’ to: ${MR_REPO}/${backup_lnkpath}"
    elif [ ${noforce} -ne 0 ]; then
      error "mrt: Failed to create symbolic link!"
      error "  Target exists and is not a symlink at:"
      error "  ${canonicalized}"
      error "Use -f/--force, or -s/--safe, or remove the file," \
        "and try again, or stop trying."
      return 1
    fi
  fi

  # CAREFUL: This clobbers!
  /bin/ln -sf "${canonicalized}" "${lnkfile}"

  info "Wired ‘${lnkfile}’"
}

