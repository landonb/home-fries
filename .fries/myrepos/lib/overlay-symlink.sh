#!/bin/sh
# vim:tw=0:ts=2:sw=2:et:norl:nospell:ft=sh

#source_deps () {
#  # Load: warn, etc.
#  . ${HOME}/.fries/lib/logger.sh
#}
source_deps () {
  # Load: warn, etc.
  . ${HOME}/.fries/lib/logger.sh
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

if false; then
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

  myrepostravel_opts_parse () {
    MRT_LINK_SAFE=1
    params_check_safe "${@}" && MRT_LINK_SAFE=0 || true

    MRT_LINK_FORCE=1
    params_check_force "${@}" && MRT_LINK_FORCE=0 || true
  }
fi

# ***

params_register_defaults () {
  MRT_LINK_SAFE=1
  MRT_LINK_FORCE=1
  MRT_AUTO_YES=1
  MRT_INFUSE_DIR=".mrinfuse"
}

params_register_switches () {
  while [ "$1" != '' ]; do
    case $1 in
      -f)
        MRT_LINK_FORCE=0
        shift
        ;;
      --force)
        MRT_LINK_FORCE=0
        shift
        ;;
      -s)
        MRT_LINK_SAFE=0
        shift
        ;;
      --safe)
        MRT_LINK_SAFE=0
        shift
        ;;
      -y)
        MRT_AUTO_YES=0
        shift
        ;;
      --yes)
        MRT_AUTO_YES=0
        shift
        ;;
      *)
        fatal "ERROR: Unrecognized argument: $1"
        shift
        exit 1  # Be mean.
        ;;
    esac
  done
}

myrepostravel_opts_parse () {
  params_register_defaults "${@}"
  params_register_switches "${@}"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# FIXME/2019-10-26 15:20: Should move this to new lib file.

_debug_spew_and_die () {
  #
  local testing=false
  # Uncomment to spew vars and exit:
  testing=true
  if $testing; then
    >&2 echo "MR_REPO=${MR_REPO}"
    >&2 echo "MR_CONFIG=${MR_CONFIG}"
    >&2 echo "MRT_LINK_SAFE=${MRT_LINK_SAFE}"
    >&2 echo "MRT_LINK_FORCE=${MRT_LINK_FORCE}"
    >&2 echo "current dir: $(pwd)"
    exit 1
  fi
}

infuser_set_envs () {
  local repodir="${1:-"${MR_REPO}"}"

  # Ensure MR_REPO set so script can be called manually,
  # outside context of myrepos.
  MR_REPO="${repodir}"

  # Note that if '.vim/.mrconfig' is absent, myrepos will have most likely set
  # MR_CONFIG=~/.mrconfig; but if it's present, then MR_CONFIG=~/.vim/.mrconfig.
  # So that the rest of the script works properly, force the MR_CONFIG value.
  MR_CONFIG="${MR_CONFIG:-"${MR_REPO}/.mrconfig"}"
}

# 2019-10-26: This does not belong here. But all my infusers at least
# include this file. So. Being lazy.
repo_highlight () {
  echo "$(fg_mintgreen)${1}$(attr_reset)"
}

infuser_prepare () {
  local repodir="${1:-"${MR_REPO}"}"
  shift

  infuser_set_envs "${repodir}"
  info "Infusing $(repo_highlight ${repodir})"
  myrepostravel_opts_parse "${@}"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

font_emphasize () {
  echo "$(attr_emphasis)${1}$(attr_reset)"
}

font_highlight () {
  echo "$(fg_lightorange)${1}$(attr_reset)"
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

file_exists_and_not_symlink () {
  [ -e "${1}" ] && [ ! -h "${1}" ]
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# Source verification.

symlink_verify_source () {
  local sourcep="$1"
  local srctype="$2"

  if [ "${srctype}" = 'file' ]; then
    if [ ! -f "${sourcep}" ]; then
      error "mrt: Failed to create symbolic link!"
      error "  Did not find linkable source file at:"
      error "  ${sourcep}"
      exit 1
    fi
  elif [ "${srctype}" = 'dir' ]; then
    if [ ! -d "${sourcep}" ]; then
      error "mrt: Failed to create symbolic link!"
      error "  Did not find linkable source directory at:"
      error "  ${sourcep}"
      exit 1
    fi
  else
    fatal "Not a real srctype: ${srctype}"
    exit 2
  fi
}

ensure_source_file_exists () {
  symlink_verify_source "$1" 'file'
}

ensure_source_dir_exists () {
  symlink_verify_source "$1" 'dir'
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# Target verification.

safe_backup_existing_target () {
  local targetp="$1"
  local targetf="$(basename "${targetp}")"
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

  if [ ${MRT_LINK_SAFE:-1} -eq 0 ]; then
    safe_backup_existing_target "${targetp}"
  elif [ ${MRT_LINK_FORCE:-1} -ne 0 ]; then
    fail_target_exists_not_link "${targetp}"
  fi
}

# ***

ensure_target_writable () {
  local targetp="$1"
  shift

  file_exists_and_not_symlink "${targetp}" || return 0

  safely_backup_or_die_if_not_forced "${targetp}"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# Symlink creation.

symlink_create_informative () {
  local srctype="$1"
  local sourcep="$2"
  local targetp="$3"

  # Caller guarantees (via ! -e and ! -h) that $targetp does not exist.

  local targetd="$(dirname "${targetp}")"
  mkdir -p "${targetd}"

  /bin/ln -s "${sourcep}" "${targetp}"
  if [ $? -ne 0 ]; then
    error "Failed to create symlink at: ${targetp}"
    exit 1
  fi

  info " Created fresh $(font_emphasize ${srctype}) symlink $(font_highlight ${targetp})"
}

symlink_update_informative () {
  local srctype="$1"
  local sourcep="$2"
  local targetp="$3"

  local info_msg
  if [ -h "${targetp}" ]; then
    local targetd
    [ "${srctype}" = 'dir' ] && targetd='/' || true
    # Overwriting existing symlink.
    info_msg=" Updated $(font_emphasize ${srctype}) symlink $(font_highlight ${targetp}${targetd})"
  elif [ -f "${targetp}" ]; then
    # For how this function is used, the code would already have checked
    # that the user specified -f/--force; or else the code didn't care to
    # ask. See:
    #   safely_backup_or_die_if_not_forced.
    info_msg=" Clobbered file with symlink $(font_highlight ${targetp})"
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
    exit 1
  fi

  info "${info_msg}"
}

# ***

# WONKY, SORRY: If source is relative, we verified source exists from the
# current directory ($(pwd)), but the symlink being created might exist in
# a subdirectory of this directory, i.e., the relative path for the symlink
# is different that the one the user specified (because the user specified
# the path relative to the project directory, not to the target's directory).
#
# If the target is also relative, we can count how many subdirectories away
# it is and prefix the source path accordingly.
#
# - For example, suppose user's ~/.vim/.mrconfig infuser specifices
#         symlink_mrinfuse_file 'spell/en.utf-8.add'
#   Then this function is called from ~/.vim with
#          source=.mrinfuse/spell/en.utf-8.add
#   and with
#          target=spell/en.utf-8.add,
#   which is accurate from the current ~/.vim directory's perspective.
#   But the actual symlink that's placed either needs to be fully
#   resolved, or it needs to be relative to the target directory, e.g.,
#          ~/.vim/spell/en.utf-8.add → ../.mrinfuse/spell/en.utf-8.add
#       or ~/.vim/spell/en.utf-8.add → ~/.vim/.mrinfuse/spell/en.utf-8.add
#
# This is not too hard (a little wonky, IMHO, but makes the .mrconfig saner,
# I suppose).
# - (lb): But if target path is absolute, I did not go to the trouble of
#         accommodating that (other than to raise an error-issue).
#         (There's not much of a use case for handling relative source
#         but specifying an absolute target; if the target needs to be
#         an absolute path, there's no reason not to also specify an
#         absolute path for the source.)
symlink_adjust_source_relative () {
  local srctype="$1"
  local sourcep="$2"
  local targetp="$3"

  if ! is_relative_path "${sourcep}"; then
    echo "${sourcep}"
    return 0
  fi

  if ! is_relative_path "${targetp}"; then
    local msg="Not coded for relative source but absolute target"
    >&2 echo "ERROR: symlink_clobber_typed: ${msg}"
    >&2 echo "        source: ${sourcep}"
    >&2 echo "        target: ${targetp}"
    return 1
  fi

  # "Walk off" the release target path, directory by directory, ignoring
  # any '.' current directory in the path, and complaining on '..'
  # (because hard and unnecessary). For each directory, accumulate an
  # additional '..' to the source prefix, to walk from the target location
  # back to the current directory perspective (which is the perspective of
  # sourcep as specified by the user, which we need to modify here).

  local walk_off
  walk_off="${targetp}"
  if [ "${srctype}" = 'file' ]; then
    walk_off="$(dirname -- "${targetp}")"
  fi

  local prent_walk
  while [ "${walk_off}" != '.' ]; do
    local curname="$(basename -- "${walk_off}")"
    if [ "${curname}" = '..' ]; then
      local msg="Not coded that way! relative target should not dot dot: ${targetp}"
      >&2 echo "ERROR: symlink_clobber_typed: ${msg}"
      return 1
    fi
    [ "${curname}" != '.' ] && prent_walk="../${prent_walk}"
    walk_off="$(dirname -- "${walk_off}")"
  done

  if [ "${srctype}" = 'dir' ]; then
    # Remove one step for the target file itself! I.e., the first time through
    # the while loop above was for the target itself, which we did not want to
    # overlook with a $(dirname -- ...) first, because we still wanted to sanity
    # check that the target itself is not '.' or '..'! So we consider the target
    # directory in the while loop, but then we retract that consideration here.
    prent_walk="${prent_walk#../}"
  fi

  sourcep="${prent_walk}${sourcep}"
  # >&2 echo "sourcep: $sourcep / targetp: ${targetp} / cwd: $(pwd)"
  echo "${sourcep}"
}

symlink_adjusted_source_verify_target () {
  local targetp="$1"
  # Double-check that symlink_adjust_source_relative worked!
  if [ ! -e "${targetp}" ]; then
    >&2 echo "ERROR: targetp symlink is broken!: ${targetp}"
    return 1
  fi
  return 0
}

# Informative because calls info and warn.
symlink_clobber_typed () {
  local srctype="$1"
  local sourcep="$2"
  local targetp="$3"
  # LATER/2020-01-23: Remove development cruft.
  # >&2 echo "srctype: ${srctype} / sourcep: ${sourcep} / targetp: ${targetp}"

  # Check that the source file or directory exists.
  # This may interrupt the flow if errexit.
  symlink_verify_source "${sourcep}" "${srctype}"

  sourcep="$(symlink_adjust_source_relative "${srctype}" "${sourcep}" "${targetp}")"

  local errcode
  # Check if target does not exist (and be sure not broken symlink).
  if [ ! -e "${targetp}" ] && [ ! -h "${targetp}" ]; then
    symlink_create_informative "${srctype}" "${sourcep}" "${targetp}"
  else
    symlink_update_informative "${srctype}" "${sourcep}" "${targetp}"
  fi
  errcode=$?
  # Will generally be 0, as errexit would trip on nonzero earlier.
  [ ${errcode} -ne 0 ] && return ${errcode}

  symlink_adjusted_source_verify_target "${targetp}"
}

# ***

symlink_file_clobber () {
  local sourcep="$1"
  local targetp="${2:-$(basename "${sourcep}")}"
  symlink_clobber_typed 'file' "${sourcep}" "${targetp}"
}

symlink_dir_clobber () {
  local sourcep="$1"
  local targetp="${2:-$(basename "${sourcep}")}"
  symlink_clobber_typed 'dir' "${sourcep}" "${targetp}"
}

# FIXME/2019-10-26 13:47: delete these:
#
#symlink_local_file () {
#  return symlink_file_clobber "$1/$2" "${3:-$2}"
#}
#
#symlink_local_dir () {
#  return symlink_dir_clobber "$1/$2" "${3:-$2}"
#}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

symlink_overlay_typed () {
  local srctype="$1"
  local sourcep="$2"
  local targetp="${3:-$(basename "${sourcep}")}"

  # Caller cd'ed us to "${MR_REPO}".

  # Uses CLI params to check -s/--safe or -f/--force.
  ensure_target_writable "${targetp}"

  symlink_clobber_typed "${srctype}" "${sourcep}" "${targetp}"
}

symlink_overlay_file () {
  symlink_overlay_typed 'file' "${@}"
}

symlink_overlay_dir () {
  symlink_overlay_typed 'dir' "${@}"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

symlink_overlay_file_first () {
  local targetp="$1"
  shift

  local found_one=false

  local sourcep
  for sourcep in "${@}"; do
    if [ -e ${sourcep} ]; then
      symlink_overlay_file "${sourcep}" "${targetp}"
      found_one=true
      break
    fi
  done

  if ! ${found_one}; then
    warn "Did not find existing source file to symlink as: ${targetp}"
    exit 1
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# Resolving magic .mrinfuse/ path.

_info_path_resolve () {
  local relative_path="$1"
  local mrinfuse_path="$2"
  local canonicalized="$3"
  #
  local testing=false
  # Uncomment to spew vars and exit:
  # testing=true
  if $testing; then
    >&2 echo "MR_REPO=${MR_REPO}"
    >&2 echo "MR_CONFIG=${MR_CONFIG}"
    >&2 echo "relative_path=${relative_path}"
    >&2 echo "mrinfuse_path=${mrinfuse_path}"
    >&2 echo "canonicalized=${canonicalized}"
    >&2 echo "current dir: $(pwd)"
    >&2 echo "MRT_LINK_FORCE=${MRT_LINK_FORCE}"
    >&2 echo "MRT_LINK_SAFE=${MRT_LINK_SAFE}"
    exit 1
  fi
}

# ***

mrinfuse_findup_canonic () {
  # Search from parent of this directory (which is probably $MR_REPO)
  # up to the .mrconfig-containing directory looking for .mrinfuse/.
  local dirpath mr_root
  dirpath="$(dirname -- "$(readlink -m "$(pwd)")")"
  mr_root="$(dirname -- "$(readlink -m "${MR_CONFIG}")")"
  while [ "${dirpath}" != '/' ]; do
    local trypath="${dirpath}/${MRT_INFUSE_DIR}"
    if [ -d "${trypath}" ]; then
      echo "${dirpath}"
      break
    elif [ "${dirpath}" = "${mr_root}" ]; then
      break
    fi
    dirpath="$(dirname -- "${dirpath}")"
  done
}

mrinfuse_findup () {
  # Search from parent of this directory (which is probably $MR_REPO)
  # up to the .mrconfig-containing directory looking for .mrinfuse/.
  local dirpath=""
  while [ -z "${dirpath}" -o "$(readlink -m \"${dirpath}\")" != '/' ]; do
    if [ -d "${dirpath}${MRT_INFUSE_DIR}" ]; then
      echo "${dirpath}"
      return 0
    fi
    dirpath="${dirpath}../"
  done
  return 1
}

path_to_mrinfuse_resolve () {
  local fpath="$1"
  # CONVENTION: Store private files under a directory named .mrinfuse,
  # located in the same directory as the .mrconfig file whose repo config
  # calls this function, or located along the oath between the root and repo.
  # Under the .mrinfuse directory, mimic the directory alongside the .mrconfig
  # file. For instance, suppose you had a config file at:
  #   /my/work/projects/.mrconfig
  # and you had a public repo underneath that project space at:
  #   /my/work/projects/cool/product/
  # you would store your private .ignore file at:
  #   /my/work/projects/.mrinfuse/cool/product/.ignore
  # then your infuse function would be specified in your .mrconfig as:
  #   [cool/product]
  #   symlink_mrinfuse_file '.ignore'
  local canonicalized
  if is_relative_path "${fpath}"; then
    local relative_path
    local mrinfuse_root
    local mrinfuse_path
    local repo_path_n_sep
    repo_path_n_sep="${MR_REPO}/"
    # This produces longer, fuller paths:
    #   mrinfuse_root="$(dirname ${MR_CONFIG})"
    # But I like to avoid `ls` output wrapping, when possible.
    mrinfuse_root="$(mrinfuse_findup)"
    [ $? -eq 0 ] || ( >&2 echo "ERROR: Missing .mrinfuse/" && exit 1 )
    if [ -n "${mrinfuse_root}" ]; then
      mrinfuse_full=$(readlink -m "${mrinfuse_root}")
    else
      mrinfuse_full=$(readlink -m '.')
    fi
    relative_path=${repo_path_n_sep#"${mrinfuse_full}"/}
    mrinfuse_path="${mrinfuse_root}${MRT_INFUSE_DIR}/${relative_path}${fpath}"
    # MAYBE/2020-01-23: Option to return full path?
    #                     canonicalized=$(readlink -m "${mrinfuse_path}")
    #                   - I like the shorter relative path.
    canonicalized="${mrinfuse_path}"
    _info_path_resolve "${relative_path}" "${mrinfuse_path}" "${canonicalized}"
  else
    canonicalized="${fpath}"
  fi
  echo "${canonicalized}"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

symlink_mrinfuse_typed () {
  local srctype="$1"
  local lnkpath="$2"
  local targetp="${3:-${lnkpath}}"

  local before_cd="$(pwd -L)"
  cd "${MR_REPO}"

  local sourcep
  sourcep="$(path_to_mrinfuse_resolve ${lnkpath})"

  symlink_overlay_typed "${srctype}" "${sourcep}" "${targetp}"

  cd "${before_cd}"
}

# ***

symlink_mrinfuse_file () {
  symlink_mrinfuse_typed 'file' "${@}"
}

symlink_mrinfuse_dir () {
  symlink_mrinfuse_typed 'dir' "${@}"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

symlink_mrinfuse_file_first () {
  local targetp="$1"
  shift

  local found_one=false

  local lnkpath
  for lnkpath in "${@}"; do
    local sourcep
    sourcep="$(path_to_mrinfuse_resolve ${lnkpath})"
    if [ -e ${sourcep} ]; then
      symlink_overlay_file "${sourcep}" "${targetp}"
      found_one=true
      break
    fi
  done

  if ! ${found_one}; then
    warn "Did not find existing source file to symlink as: ${targetp}"
    exit 1
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main () {
  # Don't do anything other than source dependencies.
  # Caller will call functions explicitly as appropriate.
  source_deps
}

main "$@"

