# vim:tw=0:ts=2:sw=2:et:norl:nospell:ft=sh

_info_link_private_ignore () {
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

link_private_ignore () {
  local dignore_fpath
  local relative_path
  # CONVENTION: Store .ignore files under a directory named
  # .mrinfuse located in the same directory as the .mrconfig file whose
  # repo config calls this function. Under the .mrinfuse directory, mimic
  # the directory alongside the .mrconfig file. For instance, suppose you
  # had a config file at:
  #   /my/work/projects/.mrconfig
  # and you had a public repo underneath that project space at:
  #   /my/work/projects/cool/product/
  # you would store your private .ignore file at:
  #   /my/work/projects/.mrinfuse/cool/product/.ignore
  relative_path=${MR_REPO#"$(dirname ${MR_CONFIG})"/}
  dignore_fpath="$(dirname ${MR_CONFIG})/.mrinfuse/${relative_path}/.ignore"

  _info_link_private_ignore

  if [ ! -f "${dignore_fpath}" ]; then
    error "Repo says it wires its own private .ignore file, but none found at: “${dignore_fpath}”"
    return 1
  fi

  local noforce=1
  params_check_force "${@}" && noforce=0 || true

  if [ -e '.ignore' ] && [ ! -h '.ignore' ] && [ ${noforce} -ne 0 ]; then
    error "Ignore file exists and is not a link at:"
    error "  “${MR_REPO}/.ignore”"
    error "Use -f/--force or remove the file, and try again, or stop trying."
    return 1
  fi

  # CAREFUL: This clobbers!
  /bin/ln -sf "${dignore_fpath}" '.ignore'

  info "Wired .ignore"
}

