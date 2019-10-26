# vim:tw=0:ts=2:sw=2:et:norl:nospell:ft=sh

source_deps () {
  # Load: warn, etc.
  . ${HOME}/.fries/lib/logger.sh
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

_info_path_resolve () {
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

# ***

path_to_mrinfuse_resolve () {
  local fpath="$1"
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
  #   symlink_mrinfuse_file '.ignore'
  local canonicalized
  if is_relative_path "${fpath}"; then
    local relative_path
    local mrinfuse_path
    local repo_path_n_sep="${MR_REPO}/"
    relative_path=${repo_path_n_sep#"$(dirname ${MR_CONFIG})"/}
    mrinfuse_path="$(dirname ${MR_CONFIG})/.mrinfuse/${relative_path}/${fpath}"
    canonicalized=$(readlink -m "${mrinfuse_path}")
    _info_path_resolve "${relative_path}" "${mrinfuse_path}" "${canonicalized}"
  else
    canonicalized="${fpath}"
  fi
  echo "${canonicalized}"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

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

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

is_relative_path () {
  # POSIX does not support pattern matching, e.g.,
  #   if [[ "$DIR" = /* ]]; then ... fi
  # but we can use a case statement.
  case $1 in
    /*) return 1 ;;
    *) return 0 ;;
  esac
  >&2 echo "Unreachable!"
  exit 1
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

ensure_source_exists () {
  local sourcep="$1"
  if [ ! -f "${sourcep}" ]; then
    error "mrt: Failed to create symbolic link!"
    error "  Did not find linkable source file at:"
    error "  ${sourcep}"
    exit 1
  fi
  return 0
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

file_exists_and_not_symlink () {
  [ -e "${1}" ] && [ ! -h "${1}" ]
}

# ***

safe_backup_existing_target () {
  local targetp="$1"
  local targetf="$(basename ${targetp})"
  local backup_postfix=$(date +%Y.%m.%d.%H.%M.%S)
  local backup_targetp="${targetp}-${backup_postfix}"
  /bin/mv "${targetp}" "${targetp}-${backup_postfix}"
  info "Collision resolved: Moved existing ‘${targetf}’ to: ${backup_targetp}"
}

fail_target_exists_not_link () {
  local targetp="$1"
  error "mrt: Failed to create symbolic link!"
  error "  Target exists and is not a symlink at:"
  error "  ${targetp}"
  error "Use -f/--force, or -s/--safe, or remove the file," \
    "and try again, or stop trying."
  exit 1
}

safely_backup_or_die_if_not_forced () {
  local targetp="$1"
  shift

  local nosafe=1
  params_check_safe "${@}" && nosafe=0 || true

  local noforce=1
  params_check_force "${@}" && noforce=0 || true

  if [ ${nosafe} -eq 0 ]; then
    safe_backup_existing_target "${targetp}"
  elif [ ${noforce} -ne 0 ]; then
    fail_target_exists_not_link "${targetp}"
  fi
}

# ***

ensure_target_writable () {
  local targetp="$1"
  shift

  file_exists_and_not_symlink "${targetp}" || return 0

  safely_backup_or_die_if_not_forced "${targetp}" "${@}"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

symlink_create_informative () {
  local which="$1"
  local sourcep="$2"
  local targetp="$3"

  # Caller guarantees (via ! -e and ! -h) that $targetp does not exist.

  if [ "${which}" = 'file' ]; then
    if [ ! -f "${sourcep}" ]; then
      warn "Symlink reference not a file: ${sourcep}"
      return 1
    fi
  elif [ "${which}" = 'dir' ]; then
    if [ ! -d "${sourcep}" ]; then
      warn "Symlink reference not a directory: ${sourcep}"
      return 1
    fi
  else
    fatal "Not a real which: ${which}"
    exit 1
  fi

  local targetd=$(dirname "${targetp}")
  mkdir -p "${targetd}"

  /bin/ln -s "${sourcep}" "${targetp}"
  if [ $? -ne 0 ]; then
    error "Failed to create symlink at: ${targetp}"
    return 1
  fi

  info "Dropped fresh symlink at: ${targetp}"
}

symlink_update_informative () {
  local which="$1"
  local sourcep="$2"
  local targetp="$3"

  local info_msg
  if [ -h "${targetp}" ]; then
    # Overwriting existing symlink.
    info_msg="Updated symlink at: ${targetp}"
  elif [ -f "${targetp}" ]; then
    # For how this function is used, the code would already have checked
    # that the user specified -f/--force; or else the code didn't care to
    # ask. See:
    #   safely_backup_or_die_if_not_forced.
    info_msg="Clobbered file with symlink at: ${targetp}"
  else
    fatal "Unexpected path: target neither symlink nor file, but exists?"
    exit 1
  fi

  # Note if target symlinks to a file, we can overwrite with force, e.g.,
  #   /bin/ln -sf source/path target/path
  # but if the target exists and is a symlink to a directory instead,
  # the new symlink gets created inside the referenced directory.
  # To handle either situation -- the existing symlink references
  # either a file or a directory -- remove the target first.
  /bin/rm "${targetp}"

  /bin/ln -s "${sourcep}" "${targetp}"
  if [ $? -ne 0 ]; then
    error "Failed to replace symlink at: ${targetp}"
    return 1
  fi

  info "${info_msg}"
}

# Informative because calls info and warn.
symlink_clobber_informative () {
  local which="$1"
  local sourcep="$2"
  local targetp="$3"

  # Check if target does not exist (and be sure not broken symlink).
  if [ ! -e "${targetp}" ] && [ ! -h "${targetp}" ]; then
    symlink_create_informative "${@}"
  else
    symlink_update_informative "${@}"
  fi

  # Will generally return 0, as errexit would trip on nonzero earlier.
  return $?
}

# ***

symlink_file_informative () {
  symlink_clobber_informative 'file' "$1" "$2"
}

symlink_dir_informative () {
  symlink_clobber_informative 'dir' "$1" "$2"
}

#symlink_local_file () {
#  return symlink_file_informative "$1/$2" "${3:-$2}"
#}

#symlink_local_dir () {
#  return symlink_dir_informative "$1/$2" "${3:-$2}"
#}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

symlink_overlay_file2file () {
  local sourcep="$1"
  local targetp="$2"
  shift 2

  local before_cd="$(pwd -L)"
  cd "${MR_REPO}"

  # Check that the source file exists.
  # This may interrupt the flow if errexit.
  ensure_source_exists "${sourcep}"

  # Pass CLI params to check -s/--safe or -f/--force.
  ensure_target_writable "${targetp}" "${@}"

  symlink_file_informative "${sourcep}" "${targetp}"

  cd "${before_cd}"

# FIXME/2019-10-26 02:50: This might be redundant now!
  info "Wired ‘$(basename ${targetp})’"
}

symlink_overlay_file () {
  local sourcep="$1"
  shift

  local targetp=''

  symlink_overlay_file2file "${sourcep}" "${targetp}" "${@}"
}

# ***

symlink_mrinfuse_file2file () {
  local lnkpath="$1"
  shift

  local sourcep
  sourcep="$(path_to_mrinfuse_resolve ${lnkpath})"

  symlink_overlay_file2file "${sourcep}" "${@}"
}

symlink_mrinfuse_file () {
  local sourcep="$1"
  shift

  local targetp=''

  symlink_mrinfuse_file2file "${sourcep}" "${targetp}" "${@}"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

symlink_overlay_first_match () {
  local targetp="$1"
  shift

  local found_one=false

  local source_f
  for sourcep in "${@}"; do
    if [ -e ${sourcep} ]; then
      symlink_overlay_file2file "${sourcep}" "${targetp}" "${@}"
      found_one=true
      break
    fi
  done

  if ! ${found_one}; then
    warn "Did not find existing source file to symlink as: ${targetp}"
    return 1
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main () {
  # Don't do anything other than source dependencies.
  # Caller will call functions explicitly as appropriate.
  source_deps
}

main "$@"

