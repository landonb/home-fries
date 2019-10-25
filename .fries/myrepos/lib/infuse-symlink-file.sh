# vim:tw=0:ts=2:sw=2:et:norl:nospell:ft=sh

_info_infuse_symlink_file () {
  local testing=false
  # Uncomment to spew vars and exit:
  # testing=true
  if $testing; then
    info "MR_REPO=${MR_REPO}"
    info "MR_CONFIG=${MR_CONFIG}"
    info "relative_path=${relative_path}"
    info "dignore_fpath=${dignore_fpath}"
    info "current dir: $(pwd)"
    return 1
  fi
}

params_check_force () {
  for arg in "$@"; do
    if [ "${arg}" = "-f" ] || [ "${arg}" = "--force" ] ; then
      return 0
    fi
  done
  return 1
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
  local dignore_fpath
  relative_path=${MR_REPO#"$(dirname ${MR_CONFIG})"/}
  dignore_fpath="$(dirname ${MR_CONFIG})/.mrinfuse/${relative_path}/${lnkfile}"
  canonicalized=$(readlink -m "${dignore_fpath}")

  _info_infuse_symlink_file

  if [ ! -f "${canonicalized}" ]; then
    error "mrt: Failed to create symbolic link!"
    error "  Did not find linkable source file at:"
    error "  ${canonicalized}"
    return 1
  fi

  local noforce=1
  params_check_force "${@}" && noforce=0 || true

  if [ -e "${lnkfile}" ] && [ ! -h "${lnkfile}" ] && [ ${noforce} -ne 0 ]; then
    error "mrt: Failed to create symbolic link!"
    error "  Target exists and is not a symlink at:"
    error "  ${canonicalized}"
    error "Use -f/--force, or remove the file, and try again, or stop trying."
    return 1
  fi

  # CAREFUL: This clobbers!
  /bin/ln -sf "${canonicalized}" "${lnkfile}"

  info "Wired .ignore"
}

