#!/bin/bash
# Last Modified: 2017.12.19
# vim:tw=0:ts=2:sw=2:et:norl:

# FIXME/2017-02-08: Conflicts are not being caught!
#   Created autostash: c5e49bb
#   HEAD is now at d50bb90 Update hamster-mnemosyne.db during packme.
#   First, rewinding head to replay your work on top of it...
#   Fast-forwarded master to 8520b78e68c90a7615770aeb2ba83c9e83751bc5.
#   Applying autostash resulted in conflicts.
#   Your changes are safe in the stash.
#   You can run "git stash pop" or "git stash drop" at any time.

set -e

# FIXME/2018-03-23 12:53: TRY THESE:
#Use set -o nounset (a.k.a. set -u) to exit when your script tries to use undeclared variables.
#set -u
#set -o pipefail

# FIXME/2018-03-23 12:53: Compare these to how you do it elsewhere.
## Set magic variables for current file & dir
#__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#__file="${__dir}/$(basename "${BASH_SOURCE[0]}")"
#__base="$(basename ${__file} .sh)"
#__root="$(cd "$(dirname "${__dir}")" && pwd)" # <-- change this as it depends on your app
#arg1="${1:-}"

# ***

# Start a timer.
SETUP_TIME_0="$(date +%s.%N)"
SETUP_TIME_N=''

UNIQUE_TIME="$(date +%Y%m%d-%Hh%Mm%Ss)"

function soups_finished_dinners_over_report_time {
  if [[ -n "${SETUP_TIME_N}" ]]; then
    # Already been in through here and printed elapsed time.
    # (We want plain echoes to be last output, not run time.)
    return
  fi

  SETUP_TIME_N="$(date +%s.%N)"
  local time_elapsed=$(\
    echo "scale=2; ($SETUP_TIME_N - $SETUP_TIME_0) * 100 / 100" | bc -l
  )
  # Only show elapsed time if more than a split second, or whatever.
  # Use `bc` to output 0 or 1, and use ``(( ... ))`` so Bash interprets
  # the result as false or true respectively.
  if (( $(echo "${time_elapsed} > 0.25" | bc -l) )); then
    info "${FONT_BOLD}${BG_FOREST}Elapsed: ${time_elapsed} secs."
  fi
}

# ***

function errexit_cleanup () {
  echo
  echo "ERROR: The script failed!!"
  soups_finished_dinners_over_report_time
  # No exit necessary, unless we want to specify status.
  # Also note that a stacktrace (where) is useless here,
  # as a trap function has nothing above it (other than
  # Bash, I suppose).
  exit 1
}
trap errexit_cleanup EXIT

# ***

# FIXME/2018-03-24: You're sourcing these here, and then later,
#   but here is first and has less flexibility! (I'm guessing I
#   added source_deps last; but I'm confused why I don't try
#   harder to make sure these are available -- assumes you got
#   your Bash and your Home Fries all set up appropriately!)
#
# FIXME/EXPLAIN/2018-03-24: Or does this have to do with the .waffle/TBD-shim??
#   i.e., source what's around you.... UNDERSTAND THIS BETTER.
#
source_deps () {
  # NOTE: We symlink ~/.fries/recipe/bin from ~/.fries/bin
  #       so cannot rely on ${BASH_SOURCE[0]} to figure out
  #       source path. Or, we could try multiple relative
  #       paths and see which one works. Or, we could just
  #       assume the user will have ~/.fries/lib on their
  #       PATH and then we can just call `source` with the
  #       filename and not worry about the directory path.
  source bash_base.sh
  # Load: ssh_agent_kick
  source ssh_util.sh
  # Load: tweak_errexit, reset_errexit, etc.
  source process_util.sh
  # Load: is_mount_type_crypt
  source crypt_util.sh
}
source_deps

# ***

# Enable a little more echo, if you want.
# You can also add this to cfg/sync_repos.sh.
DEBUG=${DEBUG:-false}
DEBUG=${DEBUG:-true}

echod () {
  tweak_errexit
  ${DEBUG} && echo "$@"
  reset_errexit
}

# WHATEVER: 2016-11-14: I enabled these to help
#       debug but they're not work as expected.
#set +v
#set +x
#set +E
#set +T

# ***

# Load: Useful Bash functions.
if [[ -e "${HOME}/.fries/lib/bash_base.sh" ]]; then
  source "${HOME}/.fries/lib/bash_base.sh"
elif [[ -e bash_base.sh ]]; then
  source bash_base.sh
else
  echo "WARNING: Missing bash_base.sh"
fi

# Load: Colorful logging.
if [[ -e "${HOME}/.fries/lib/logger.sh" ]]; then
  source "${HOME}/.fries/lib/logger.sh"
elif [[ -e logger.sh ]]; then
  source logger.sh
else
  echo "WARNING: Missing logger.sh"
fi
#LOG_LEVEL=${LOG_LEVEL_ERROR}
LOG_LEVEL=${LOG_LEVEL:-${LOG_LEVEL_DEBUG}}

# Load: setup_users_curly_path
if [[ -e "${HOME}/.fries/lib/curly_util.sh" ]]; then
  source "${HOME}/.fries/lib/curly_util.sh"
elif [[ -e curly_util.sh ]]; then
  source curly_util.sh
else
  echo "WARNING: Missing curly_util.sh"
fi
# Set USERS_CURLY and USERS_BNAME.
setup_users_curly_path
PRIVATE_REPO="${USERS_BNAME}"
# In case ${PRIVATE_REPO} has a dot prefix, remove it for some friendlier representations.
PRIVATE_REPO_="${PRIVATE_REPO#.}"
#echo "PRIVATE_REPO_: ${PRIVATE_REPO_}"

# Load: git_commit_generic_file, et al
if [[ -e "${HOME}/.fries/lib/git_util.sh" ]]; then
  source "${HOME}/.fries/lib/git_util.sh"
elif [[ -e git_util.sh ]]; then
  source git_util.sh
else
  echo "WARNING: Missing git_util.sh"
fi

# ***

# ~/.curly/setup.sh makes symlinks in the user's private dotfiles destination,
# which means this script could be running as a symlink, and we gotta dance.

SCRIPT_ABS_PATH=$(readlink -f -- "${BASH_SOURCE[0]}")

find_git_parent "${SCRIPT_ABS_PATH}"
FRIES_ABS_DIRN="${REPO_PATH}"

# ***

# Setup things sync_repos.sh will probably overwrite.
PLAINTEXT_ARCHIVES=()
ENCFS_GIT_REPOS=()
ENCFS_GIT_ITERS=()
ENCFS_VIM_ITERS=()
AUTO_GIT_ONE=()
AUTO_GIT_ALL=()
AUTO_GIT_NEW=()

declare -A GIT_REPO_SEEDS_0
declare -A GIT_REPO_SEEDS_1
declare -A VIM_REPO_SEEDS_0
declare -A VIM_REPO_SEEDS_1

# Look for sync_repos.sh.
SYNC_REPOS_PATH=''
if [[ -f "${USERS_CURLY}/cfg/sync_repos.sh-$(hostname)" ]]; then
  # You can set up per-hostname sync_repos lists, or you can use
  # master_chef and probably get away with just one sync_repos.sh.
  SYNC_REPOS_PATH="${USERS_CURLY}/cfg/sync_repos.sh-$(hostname)"
elif [[ -f "${USERS_CURLY}/cfg/sync_repos.sh" ]]; then
  # This is what gets sourced when you run from ${USERS_CURLY}.
  SYNC_REPOS_PATH="${USERS_CURLY}/cfg/sync_repos.sh"
elif [[ -f "${USERS_CURLY}/sync_repos.sh" ]]; then
  # This is what gets sourced when unpack does it little dance.
  SYNC_REPOS_PATH="${USERS_CURLY}/sync_repos.sh"
elif [[ -f "sync_repos.sh" ]]; then
  SYNC_REPOS_PATH="sync_repos.sh"
fi
if [[ -n "${SYNC_REPOS_PATH}" ]]; then
  # Source this now so that sync_repos.sh can use, e.g., ${EMISSARY}.
  SYNC_REPOS_AGAIN=false
  echod "Sourcing: ${SYNC_REPOS_PATH}"
  source "${SYNC_REPOS_PATH}"
  SOURCED_SYNC_REPOS=true
else
  error
  error "==============================="
  error "NOTICE: sync_repos.sh not found"
  error "==============================="
  error
  SOURCED_SYNC_REPOS=false
fi

# ***

# By default, plaintext archives unpack to, e.g., ~/Documents/${PRIVATE_REPO_}-unpackered
# You can change this path by setting STAGING_DIR in ${USERS_CURLY}/cfg/sync_repos.sh.
if [[ -z "${STAGING_DIR+x}" ]]; then
  STAGING_DIR=/home/${USER}/Documents
fi

# Unpack plaintext archives to the unpackered directory,
# under the subdirectory named after the originating
# machine.
UNPACKERED_PATH="${STAGING_DIR}/${PRIVATE_REPO_}-unpackered"
UNPACK_TBD="${UNPACKERED_PATH}-TBD-${UNIQUE_TIME}"

# ***

# Load packme and unpack hooks to run during packme and unpack, respk.
SOURCED_TRAVEL_TASKS=true
TRAVEL_TASKS_PATH=''
if [[ -f "${USERS_CURLY}/cfg/travel_tasks.sh-$(hostname)" ]]; then
  TRAVEL_TASKS_PATH="${USERS_CURLY}/cfg/travel_tasks.sh-$(hostname)"
elif [[ -f "${USERS_CURLY}/cfg/travel_tasks.sh" ]]; then
  TRAVEL_TASKS_PATH="${USERS_CURLY}/cfg/travel_tasks.sh"
elif [[ -f "${USERS_CURLY}/travel_tasks.sh" ]]; then
  TRAVEL_TASKS_PATH="${USERS_CURLY}/travel_tasks.sh"
elif [[ -f "travel_tasks.sh" ]]; then
  TRAVEL_TASKS_PATH="travel_tasks.sh"
fi
if [[ -n ${TRAVEL_TASKS_PATH} ]]; then
  source "${TRAVEL_TASKS_PATH}"
else
  warn "NOTICE: travel_tasks.sh not found"
  warn "${USERS_CURLY}/cfg/travel_tasks.sh"
  SOURCED_TRAVEL_TASKS=false
fi

# ***

echod "SOURCED_SYNC_REPOS: ${SOURCED_SYNC_REPOS}"

echod "SOURCED_TRAVEL_TASKS: ${SOURCED_TRAVEL_TASKS}"

# ***

HAMSTERING=false

# FIXME/2018-12-24: Replace with dob. (And also move out of Travel/Trippy.)
if false; then

  if [[ -d "${USERS_CURLY}/home/.local/share/hamster-applet" ]]; then
    HAMSTERING=true
    echod "Hamster found under: ${USERS_CURLY}/home/.local/share/hamster-applet"
  else
    #echo "No hamster at: ${USERS_CURLY}/home/.local/share/hamster-applet"
    :
  fi
fi

# ***

BACKUP_POSTFIX=$(date +%Y.%m.%d.%H.%M.%S)
echod "This run's BACKUP_POSTFIX: ${BACKUP_POSTFIX}"

# ***

if ${DEBUG}; then                             # E.g.,
  echo "SCRIPT_ABS_PATH: $SCRIPT_ABS_PATH"    #  /home/usernom/.fries/recipe/bin/travel.sh
  echo " FRIES_ABS_DIRN: $FRIES_ABS_DIRN"     #  /home/usernom
  echo "    USERS_CURLY: $USERS_CURLY"        #  /home/user/.theirs
  echo "    USERS_BNAME: $USERS_BNAME"        #  .theirs
  echo "  PRIVATE_REPO : $PRIVATE_REPO"       #  .theirs
  echo "  PRIVATE_REPO_: $PRIVATE_REPO_"      #  theirs
fi

# ***

# Don't set EMISSARY, so caller can set it.
#  EMISSARY=

# These variables' values will be calculated.
PLAINPATH=
PLAIN_TBD=
CANDIDATES=()

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

TRAVEL_CMD=''

function set_travel_cmd () {
  if [[ -z ${TRAVEL_CMD} ]]; then
    TRAVEL_CMD="$1"
  else
    TRAVEL_CMD='too_many_travel_cmds'
  fi
}

SKIP_DIRTY_CHECK=false
# -DD
SKIP_THIS_DIRTY=false
# -D Argh, this bothers me a little. It's used in git_util.sh.
#    Like, rather than sending it as a param, it's just part
#    of the environment. Which works because we source git_util.sh.
#    It still feels icky though, like a bash hack.
SKIP_GIT_DIRTY=false
AUTO_COMMIT_FILES=false
SKIP_PULL_REPOS=false
SKIP_UNPACK_SHIM=false
NO_NETWORK_OKAY=false
TAR_VERBOSE=''
INCLUDE_ENCFS_OFF_REPOS=false
SKIP_INTERNETS=false

DEVICE_LABEL=''

UNKNOWN_ARG=false

function soups_on () {

  local ASKED_FOR_HELP=false
  local DETERMINE_TRAVEL_DIR=false
  local CAN_IGNORE_TRAVEL_DIR=false

  echod 'Soups on!: ' "$@"

  while [[ "$1" != '' ]]; do
    case $1 in
      -h)
        ASKED_FOR_HELP=true
        shift
        ;;
      --help)
        ASKED_FOR_HELP=true
        shift
        ;;
      # Need to escape the ? or it hits any single character option.
      -\?)
        ASKED_FOR_HELP=true
        shift
        ;;
      help)
        ASKED_FOR_HELP=true
        shift
        ;;
      chase_and_face)
        PLEASE_CHOOSE_PART="to which to chase and face"
        DETERMINE_TRAVEL_DIR=true
        REQUIRES_SYNC_REPOS=true
        set_travel_cmd "chase_and_face"
        shift
        ;;
      init_travel)
        PLEASE_CHOOSE_PART="to which to init"
        DETERMINE_TRAVEL_DIR=true
        REQUIRES_SYNC_REPOS=true
        set_travel_cmd "init_travel"
        shift
        ;;
      packme)
        PLEASE_CHOOSE_PART="to which to pack"
        DETERMINE_TRAVEL_DIR=true
        REQUIRES_SYNC_REPOS=true
        set_travel_cmd "packme"
        shift
        ;;
      unpack)
        PLEASE_CHOOSE_PART="from which to unpack"
        DETERMINE_TRAVEL_DIR=true
        REQUIRES_SYNC_REPOS=true
        set_travel_cmd "unpack"
        shift
        ;;
      prepare-shim)
        PLEASE_CHOOSE_PART="from which to copy"
        DETERMINE_TRAVEL_DIR=true
        set_travel_cmd "prepare_shim"
        shift
        ;;
      mount)
        PLEASE_CHOOSE_PART="to which to pack"
        DETERMINE_TRAVEL_DIR=true
        set_travel_cmd "mount_curly_emissary_gooey_explicit"
        shift
        ;;
      umount)
        PLEASE_CHOOSE_PART="to which to pack"
        DETERMINE_TRAVEL_DIR=true
        CAN_IGNORE_TRAVEL_DIR=true
        set_travel_cmd "umount_curly_emissary_gooey"
        shift
        ;;
      -O)
        INCLUDE_ENCFS_OFF_REPOS=true
        shift
        ;;
      -s)
        SKIP_INTERNETS=true
        shift
        ;;
      -DDDD)
        SKIP_PULL_REPOS=true
        shift
        ;;
      -DDD)
        SKIP_DIRTY_CHECK=true
        shift
        ;;
      -DD)
        SKIP_THIS_DIRTY=true
        shift
        ;;
      -D)
        SKIP_GIT_DIRTY=true
        shift
        ;;
      -X)
        SKIP_DIRTY_CHECK=true
        #SKIP_GIT_DIRTY=true
        SKIP_PULL_REPOS=true
        shift
        ;;
      -WW)
        AUTO_COMMIT_FILES=true
        shift
        ;;
      # --no-shim is not implemented here, but in unpack.sh wrapper.
      # But pull arg so it's not flagged as illegal.
      --no-shim)
        SKIP_UNPACK_SHIM=true
        shift
        ;;
      --no-net)
        NO_NETWORK_OKAY=true
        shift
        ;;
      -v)
        TAR_VERBOSE="v"
        shift
        ;;
      -d)
        STAGING_DIR=$2
        shift 2
        ;;
      -d=?*)
        STAGING_DIR=${1#-d=}
        shift
        ;;
      --staging)
        STAGING_DIR=$2
        shift 2
        ;;
      --staging=?*)
        STAGING_DIR=${1#--staging=}
        shift
        ;;
      -L)
        DEVICE_LABEL=$2
        shift 2
        ;;
      -L=?*)
        DEVICE_LABEL=${1#-L=}
        shift
        ;;
      --label)
        DEVICE_LABEL=$2
        shift 2
        ;;
      --label=?*)
        DEVICE_LABEL=${1#--label=}
        shift
        ;;
      *)
        UNKNOWN_ARG=true
        echo "ERROR: Unrecognized argument: $1"
        shift
        ;;
    esac
  done

  if [[ ${TRAVEL_CMD} == 'too_many_travel_cmds' ]]; then
    echo
    echo "FATAL: Please specify just one travel command."
    echo
  fi
  if [[ ${ASKED_FOR_HELP} = true || (${TRAVEL_CMD} == 'too_many_travel_cmds') ]]; then
    echo
    echo "sync-stick helps you roam amongst dev machines"
    echo
    echo "USAGE: $0 [options] {command} [options]"
    #echo
    #echo "Commands: packme | unpack | mount | umount | chase_and_face | init_travel"
    echo
    TRAVEL_CMD=''
  fi

  if [[ -z ${TRAVEL_CMD} ]]; then
    echo "Everyday commands:"
    #echo
    # Omitted to avoid confusion:
    #   On a machine that's not ${USERS_CURLY}/master_chef, packme tars plaintext stuff.
    #   And on a machine that is the master_chef, unpack untars that stuff.
    #   But not anything else otherwise.
    echo "      packme            rebase the secure travel repos"
    echo "                          (run when you leave a machine)"
    #echo "                          * on satellite machines, tars non-repo stuff"
    echo "      unpack            rebase the local machine repos"
    echo "                          (run when you enter a machine)"
    #echo "                          * on master_chef, untars unimportant stuff"
    #echo
    echo "One-time commands:"
    #echo
    echo "      init_travel       create or update secure travel repos"
    echo "                          (run on new USB stick or new Dropbox,"
    echo "                           or after editing cfg/sync_repos.sh)"
    echo "                    -O   include normally not copied repos"
    echo "      update_git        update to the latest git, at least 2.9"
    echo "                          (else \`git pull --rebase --autostash\` isn't a thing)"
    #echo
    echo "Uncommon commands:"
    #echo
    echo "      mount             mount crypt at .../gooey/ # for poking around travel repos"
    echo "      umount            unmount travel crypt at \$TRAVEL_DIR/${PRIVATE_REPO_}-emissary/gooey"
    echo "                        * mount, then umount, are called on packme and unpack"
    echo "      chase_and_face    apply private overlays to local machine"
    echo "                          (maintain symlinks to ${USERS_CURLY}/* files)"
    echo "                        * chase_and_face is called on unpack"
    #echo ""
    echo "packme options:"
    echo "      -D                packme even if dirty/untracked/ahead git conditions detected"
    echo "      -DD               packme even if this script is dirty [otherwise, yo, check it in]"
    echo "      -DDD              don't waste time checking if things are git-dirty"
    echo "      -WW               wait, wait, check in all my files, please"
    echo "      -DDDD             skip git-pull; to auto-commit hamster and git-check repos only"
    echo "      -X                check in hamster: -DDD [skip dirty check] | -DDDD [skip git pull]"
    echo "      -L/--label LABEL  use LABEL for popoff script"
    echo "      -s                skip check that remote tracking branch is up to date (if offline)"
    #echo
    echo "unpack options:"
    echo "      -d STAGING_DIR    specify the unpack path for incoming plaintext tar stuff"
    echo "      -v                to \`tar v\` (if you have problems detarring)"
    echo "      --no-shim         use local travel.sh for unpack and not what's on travel"
    echo "                          (local travel.sh is always used if it's git-dirty)"
    echo "      --no-net          set if git failure on net connection okay"
  fi

  if ${DETERMINE_TRAVEL_DIR}; then
    tweak_errexit
    determine_stick_dir "${PLEASE_CHOOSE_PART}"
    reset_errexit
  fi

  if [[ ${REQUIRES_SYNC_REPOS} && ! ${SOURCED_SYNC_REPOS} ]]; then
    error
    error "ERROR: Missing repo_syncs.sh."
    trap - EXIT
    exit 1
  fi
  if ${SOURCED_SYNC_REPOS}; then
    SYNC_REPOS_AGAIN=true
    # Source this again so that sync_repos.sh can use, e.g., ${EMISSARY}.
    source "${SYNC_REPOS_PATH}"
  fi

  # Make sure the staging/destination exists.
  mkdir -p ${STAGING_DIR}

  if [[ -z "${EMISSARY}" ]]; then
    if ! ${DETERMINE_TRAVEL_DIR}; then
      info "Two-way travel directory: <not present> [not needed for this command]"
    elif ${CAN_IGNORE_TRAVEL_DIR}; then
      info "Two-way travel directory: <not present> [not needed & can be skipped]"
    else
      info "Two-way travel directory: <not present> [AND PROBABLY GONNA BE ISSUE]"
    fi
  else
    info "Two-way travel directory: ${FG_LAVENDER}${EMISSARY}"
  fi
  info "One-way unpack (staging): ${FG_LAVENDER}${STAGING_DIR}"

  if [[ -n ${TRAVEL_CMD} && ${UNKNOWN_ARG} = false ]]; then
    # Run the command.
    eval "$TRAVEL_CMD"
    soups_finished_dinners_over_report_time
  elif ! ${ASKED_FOR_HELP}; then
    warn 'Nothing to do!'
  fi
} # end: soups_on

function deduce_travel_dir () {
  local please_choose_part=$1

  shopt -s dotglob
  shopt -s nullglob

  # FIXME/2018-03-26: Also checked attached but unmounted devices!
  #   E.g., if I attach sync-stick, packme, then popoff, but do not
  #   physically remove device, if I packme again, and if there's a
  #   local alternative (with a -gooey directory), travel will pack
  #   to the local place and not tell you there's a stick attached
  #   that potentially might be the locker you want!
  local mounted_dirs=(/media/${USER}/*)

  shopt -u dotglob
  shopt -u nullglob
  if [[ ${#mounted_dirs[@]} -eq 0 ]]; then
    if ${CAN_IGNORE_TRAVEL_DIR}; then
      return 1
    else
      echo "Nothing mounted under /media/${USER}/"
      echo -n "Please specify the dually-accessible sync directory: "
      read -e TRAVEL_DIR
    fi
  elif [[ ${#mounted_dirs[@]} -eq 1 ]]; then
    TRAVEL_DIR="${mounted_dirs[0]}"
  else
    CANDIDATES=()
    for fpath in "${mounted_dirs[@]}"; do
      # Use -r to check that path is readable. Just because.
      if [[ -r "${fpath}" ]]; then
        echod "Examining mounted path: ${fpath}"
        if [[ -d "${fpath}/${PRIVATE_REPO_}-emissary" ]]; then
          echod "Adding candidate: ${fpath}"
          CANDIDATES+=(${fpath})
        fi
      else
        echod "Skipin' unreadable path: ${fpath}"
      fi
    done

    if [[ ${#CANDIDATES[@]} -eq 1 ]]; then
      TRAVEL_DIR="${CANDIDATES[0]}"
    elif ${CAN_IGNORE_TRAVEL_DIR}; then
      return 1
    else
      # FIXME/2018-03-26: YA KNOW! You could just use all CANDIDATES,
      # since they all have -emissary path and are all Travel lockers!

      echo "More than one path found under /media/${USER}/"
      echo "Please choose the correct path ${please_choose_part}."
      echo "(You also just might need to mount your sync stick.)"
      for fpath in "${mounted_dirs[@]}"; do
        echo -n "Is this your path?: ${fpath} [y/n] "
        read -n 1 -e YES_OR_NO
        if [[ ${YES_OR_NO^^} == "Y" ]]; then
          TRAVEL_DIR=${fpath}
          break
        fi
      done
    fi
  fi

  return 0
} # end: deduce_travel_dir

function determine_stick_dir () {
  if [[ -z "${EMISSARY}" ]]; then
    TRAVEL_DIR=''
    deduce_travel_dir
    [[ $? -ne 0 ]] && return
    EMISSARY="${TRAVEL_DIR}/${PRIVATE_REPO_}-emissary"
  else
    TRAVEL_DIR=$(dirname ${EMISSARY})
  fi

  if [[ ! -d "${TRAVEL_DIR}" ]]; then
    if ! ${CAN_IGNORE_TRAVEL_DIR}; then
      echo 'The specified stick path does not exist. Sorry! Try again!!'
      exit 1
    fi
  fi

  # 2019-04-16: It's time we stored this where it belongs!!
  #   PLAINPATH="${EMISSARY}/plain-$(hostname)"
  PLAINPATH="${EMISSARY}/gooey/plain-$(hostname)"
  PLAIN_TBD=$(mktemp --suffix='.plain' --tmpdir 'TRVL-XXXXXXXXXX')

  #echo "EMISSARY: ${EMISSARY}"
  #echo "PLAINPATH: ${PLAINPATH}"
  #echo "PLAIN_TBD: ${PLAIN_TBD}"
} # end: determine_stick_dir

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# chase_and_face

setup_private_fries_bash () {

  if [[ -f ${USERS_CURLY}/home/.fries/.bashrc/bashrx.private.${USER}.sh ]]; then

    pushd ${HOME}/.fries/.bashrc &> /dev/null

    /bin/ln -sf \
      ${USERS_CURLY}/home/.fries/.bashrc/bashrx.private.${USER}.sh \
      bashrx.private.${USER}.sh

    popd &> /dev/null

  fi

} # end: setup_private_fries_bash

setup_private_curly_work () {

  # This is just a lame hack so Open Terms defaults to your latest
  # working directory. But that changes so often it makes a function
  # such as this smell like a joke.

  if [[ -d ${USERS_CURLY}/work ]]; then

    pushd ${USERS_CURLY}/work &> /dev/null

    if [[ ! -e user-current-project ]]; then
      if [[ -h user-current-project ]]; then
        # dead link
        /bin/rm -- "user-current-project"
      fi
      /bin/ln -s "${USERS_CURLY}/work/oopsidoodle" "user-current-project"
    fi

    popd &> /dev/null

  fi

} # end: setup_private_curly_work

setup_private_vim_spell () {

  if [[ -e ${USERS_CURLY}/home/.vim/spell/en.utf-8.add ]]; then

    mkdir -p ${HOME}/.vim/spell

    pushd ${HOME}/.vim/spell &> /dev/null

    # Vim spell file.
    if [[ ! -h en.utf-8.add ]]; then
      if [[ -e en.utf-8.add ]]; then
        echo "BKUPPING: en.utf-8.add"
        /bin/mv en.utf-8.add en.utf-8.add-${BACKUP_POSTFIX}
      fi
      /bin/ln -sf ${USERS_CURLY}/home/.vim/spell/en.utf-8.add
    fi

    popd &> /dev/null

  fi

} # end: setup_private_vim_spell

setup_private_vim_bundle () {

  if [[ -e ${HOME}/.vim/bundle/dubs_all ]]; then

    pushd ${HOME}/.vim/bundle &> /dev/null

    if [[ ! -e dubs_core ]]; then
      /bin/ln -sf dubs_all dubs_core
    fi

    popd &> /dev/null

  fi

} # end: setup_private_vim_bundle

# FIXME/2019-04-15: Move to private ZP infuser task.
setup_private_vim_bundle_dubs_all () {

  if [[ -e ${HOME}/.vim/bundle/dubs_all ]]; then

    pushd ${HOME}/.vim/bundle/dubs_all &> /dev/null

    /bin/ln -sf ../../bundle_/dubs_file_finder/cmdt_paths

# FIXME/2016-11-30: Missing: bundle_/dubs_project_tray
    /bin/ln -sf ../../bundle_/dubs_project_tray/dubs_cuts

    /bin/ln -sf ../../bundle_/dubs_edit_juice/dubs_tagpaths.vim
    /bin/ln -sf ../../bundle_/dubs_grep_steady/dubs_projects.vim

    /bin/ln -sf ${USERS_CURLY}/home/.vim/bundle/dubs_all/one_time_setup.sh
    /bin/ln -sf ${USERS_CURLY}/home/.vim/bundle/dubs_all/plugin-info.json
    /bin/ln -sf ${USERS_CURLY}/home/.vim/bundle/dubs_all/.vimprojects
    /bin/ln -sf ${USERS_CURLY}/home/.vim/bundle/dubs_all/.vimrc.bundle_

    popd &> /dev/null

  fi

  if [[ -e ${HOME}/.vim/bundle_/dubs_file_finder ]]; then

    pushd ${HOME}/.vim/bundle_/dubs_file_finder &> /dev/null

    /bin/ln -sf ${USERS_CURLY}/home/.vim/bundle_/dubs_file_finder/cmdt_paths

    cd cmdt_paths
    ./generate_links.sh

    popd &> /dev/null
  fi

  if [[ -e ${HOME}/.vim/bundle_/dubs_edit_juice ]]; then
    pushd ${HOME}/.vim/bundle_/dubs_edit_juice &> /dev/null
    /bin/ln -sf ${USERS_CURLY}/home/.vim/bundle_/dubs_edit_juice/dubs_tagpaths.vim
    popd &> /dev/null
  fi

  if [[ -e ${HOME}/.vim/bundle_/dubs_grep_steady ]]; then
    pushd ${HOME}/.vim/bundle_/dubs_grep_steady &> /dev/null
    /bin/ln -sf ${USERS_CURLY}/home/.vim/bundle_/dubs_grep_steady/dubs_projects.vim
    popd &> /dev/null
  fi

} # end: setup_private_vim_bundle_dubs_all

setup_private_vim_bundle_dubs_edit_juice () {

  if [[ -e ${HOME}/.vim/bundle/dubs_edit_juice ]]; then

    pushd ${HOME}/.vim/bundle/dubs_edit_juice &> /dev/null

    /bin/ln -sf ${USERS_CURLY}/home/.vim/bundle/dubs_edit_juice/dubs_tagpaths.vim

    popd &> /dev/null

  fi

} # end: setup_private_vim_bundle_dubs_edit_juice

# FIXME/2018-03-13: Move to private ZP infuser task.
setup_private_vim_bundle_dubs () {

  if [[ -e ${HOME}/.vim/bundle/dubs_all ]]; then

    mkdir -p ${HOME}/.vim/bundle-dubs

    pushd ${HOME}/.vim/bundle-dubs &> /dev/null

    /bin/ln -sf ${USERS_CURLY}/home/.vim/bundle-dubs/generate.sh
    /bin/ln -sf ${USERS_CURLY}/home/.vim/bundle-dubs/git-st-all.sh

    /bin/ln -sf ../.ignore

    ./generate.sh

    popd &> /dev/null

  fi

} # end: setup_private_vim_bundle_dubs

setup_private_vim_bundle_dubs_project_tray () {

  if [[ -f ${HOME}/.vim/bundle-dubs/dubs_project_tray/dubs_cuts ]]; then

    pushd ${HOME}/.vim/bundle-dubs/dubs_project_tray/dubs_cuts &> /dev/null

    ./generate_links.sh

    popd &> /dev/null

  fi

} # end: setup_private_vim_bundle_dubs_project_tray

setup_private_etc_fstab () {
  if [[ -f ${USERS_CURLY}/dev/$(hostname)/etc/fstab ]]; then
    tweak_errexit
    diff ${USERS_CURLY}/dev/$(hostname)/etc/fstab /etc/fstab &> /dev/null
    local exit_code=$?
    reset_errexit
    if [[ ${exit_code} -ne 0 ]]; then
      echo "BKUPPING: /etc/fstab [to replace with: ${USERS_CURLY}/dev/$(hostname)/etc/fstab]"
      sudo /bin/mv /etc/fstab /etc/fstab-${BACKUP_POSTFIX}
      sudo /bin/cp -a ${USERS_CURLY}/dev/$(hostname)/etc/fstab /etc/fstab
      sudo chmod 644 /etc/fstab
    fi
  else
    debug "  Skipping: No fstab for ${FG_LAVENDER}$(hostname)"
  fi
} # end: setup_private_etc_fstab

setup_private_update_db_conf () {
  if [[ -f "${USERS_CURLY}/dev/$(hostname)/etc/updatedb.conf" ]]; then
    tweak_errexit
    diff \
      "${USERS_CURLY}/dev/$(hostname)/etc/updatedb.conf" \
      /etc/updatedb.conf \
      &> /dev/null
    local exit_code=$?
    reset_errexit
    if [[ ${exit_code} -ne 0 ]]; then
      if [[ -e /etc/updatedb.conf ]]; then
        echo "BKUPPING: /etc/updatedb.conf"
        sudo /bin/mv /etc/updatedb.conf /etc/updatedb.conf-${BACKUP_POSTFIX}
      fi
      echo "Placing: /etc/updatedb.conf"
      sudo /bin/cp -a \
        "${USERS_CURLY}/dev/$(hostname)/etc/updatedb.conf" \
        /etc/updatedb.conf
      sudo chmod 644 /etc/updatedb.conf
    fi
  else
    debug "Skipping: No updatedb.conf for ${FG_LAVENDER}$(hostname)"
  fi
} # end: setup_private_update_db_conf

locate_and_clone_missing_repo () {
  local check_repo="$1"
  local remote_orig="$2"
  echod "    CHECK: ${check_repo}"
  echod "     REPO: ${remote_orig}"
  if [[ -d "${check_repo}" ]]; then
    if [[ -d "${check_repo}/.git" ]]; then
      echod "   EXISTS: ${check_repo}"
    else
      echo
      echo "ERROR: Where's .git/ ? at: ${check_repo}"
      echo " REPO: ${remote_orig}"
      exit 1
    fi
  else
    local check_syml="${check_repo}"
    while [[ "${check_syml}" != '/' && "${check_syml}" != '.' ]]; do
      echod "check_syml: ${check_syml}"
      if [[ -h "${check_syml}" && ! -e "${check_syml}" ]]; then
        # This checks if the destination is under a symlink,
        # and that symlink is broken!
        echo
        echo "  ==================================================== "
        echo "  DEAD LINK: ${check_repo}"
        echo "       REPO: ${remote_orig}"
        echo "       SYML: ${check_syml}"
        echo
        echo "  Is that link pointing at an umounted filesystem?"
        echo
        break
      fi
      local check_syml=$(dirname "${check_syml}")
    done
    if [[ "${check_syml}" == '/' || "${check_syml}" == '.' ]]; then
      echo
      echo "  ==================================================== "
      echo "  MISSING: ${check_repo}"
      echo "     REPO: ${remote_orig}"
      local parent_dir=$(dirname -- "${check_repo}")
      local repo_name=$(basename -- "${check_repo}")
      if [[ ! -d "${parent_dir}" ]]; then
        echo
        echo "  MKDIR: Creating new parent_dir: ${parent_dir}"
        echo
        mkdir -p "${parent_dir}"
      fi
      if [[ -d "${parent_dir}" ]]; then
        echo "           fetching!"
        local ret_code
        if [[ "${parent_dir}" == '/' ]]; then
          if [[ ! -e "${check_repo}" ]]; then
            echod "mkdir -p ${HOME}/.elsewhere"
            # FIXME/2016-11-14: Is this okay? It's the first ~/.elsewhere usage herein.
            mkdir -p ${HOME}/.elsewhere
          else
            echo
            echo "  ALERT: EXISTS: ~/.elsewhere/${check_repo}"
            echo
          fi
          # Checkout the source.
          pushd ${HOME}/.elsewhere &> /dev/null
          local git_resp
          if [[ ! -d "${repo_name}" ]]; then
            echod "git clone ${remote_orig} ${repo_name}"
            ##git clone ${remote_orig} ${check_repo}
            #git clone ${remote_orig} ${repo_name}
            #git_resp=$(git clone ${remote_orig} ${repo_name} 2>&1)
            # 2017-02-27: Taking a while on work laptop. Wanting to see progress.
            git_resp=$(git clone "${remote_orig}" "${repo_name}") && true
          else
            echod "cd ${repo_name} && git pull"
            cd "${repo_name}"
            git_resp=$(git pull 2>&1) && true
          fi
          ret_code=$?
          check_git_clone_or_pull_error "${ret_code}" "${git_resp}"
          popd &> /dev/null
          # Create the symlink from the root dir.
          pushd / &> /dev/null
          sudo /bin/ln -sf "${HOME}/.elsewhere/${repo_name}"
          popd &> /dev/null
        else
          pushd "${parent_dir}" &> /dev/null
          # Use associate array key so user can choose different name than repo.
          ##git clone ${remote_orig}
          #git clone ${remote_orig} ${check_repo}
          #git_resp=$(git clone ${remote_orig} ${check_repo} 2>&1)
          # 2017-02-27: Taking a while on work laptop. Wanting to see progress.
          echod "git clone ${remote_orig} ${check_repo}"
          git_resp=$(git clone "${remote_orig}" "${check_repo}") && true
          ret_code=$?
          check_git_clone_or_pull_error "${ret_code}" "${git_resp}"
          popd &> /dev/null
        fi
      else
        echo
        echo "WARNING: repo path not ready: ${check_repo} / because not dir: ${parent_dir}"
        echo
        echo "Maybe just try:"
        echo
        echo "      mkdir -p ${parent_dir}"
        echo
        # 2016-11-14: I added a mkdir above, so this shouldn't happen.
        exit 1
      fi
    fi
    echo " ==================================================== "
    echo
  fi
} # end: locate_and_clone_missing_repo

locate_and_clone_missing_repos_helper () {
  # How you receive a passed associate array.
  declare -n GIT_REPO_SEEDS=$1

  if [[ ${#GIT_REPO_SEEDS[@]} -gt 0 ]]; then
    debug "---------------------------------------------------"
    debug "No. of git repos in group $1: ${#GIT_REPO_SEEDS[@]}"
    debug "---------------------------------------------------"
    # NOTE: The keys are unordered.
    for key in "${!GIT_REPO_SEEDS[@]}"; do
      echod " key  : $key"
      echod " value: ${GIT_REPO_SEEDS[$key]}"
      locate_and_clone_missing_repo $key ${GIT_REPO_SEEDS[$key]}
    done
  fi
} # end: locate_and_clone_missing_repos_helper

locate_and_clone_missing_repos_header () {
  tweak_errexit
  command -v user_locate_and_clone_missing_repos_header &> /dev/null
  local exit_code=$?
  reset_errexit
  if [[ ${exit_code} -eq 0 ]]; then
    # This is just a dumb override so I can include my private
    # repo lookups in the total count. So clunky.
    user_locate_and_clone_missing_repos_header
  else
    TOTES_REPOS=$((0 \
      + ${#GIT_REPO_SEEDS_0[@]} \
      + ${#GIT_REPO_SEEDS_1[@]} \
      + ${#VIM_REPO_SEEDS_0[@]} \
      + ${#VIM_REPO_SEEDS_1[@]} \
    ))
    info "==================================================="
    info "Number of git repository seeds: ${TOTES_REPOS}"
    info "==================================================="
  fi
}

locate_and_clone_missing_repos () {
  locate_and_clone_missing_repos_header

  echod "Cloning project in GIT_REPO_SEEDS_0"
  locate_and_clone_missing_repos_helper GIT_REPO_SEEDS_0
  echod "Cloning project in GIT_REPO_SEEDS_1"
  locate_and_clone_missing_repos_helper GIT_REPO_SEEDS_1
  echod "Cloning project in VIM_REPO_SEEDS_0"
  locate_and_clone_missing_repos_helper VIM_REPO_SEEDS_0
  echod "Cloning project in VIM_REPO_SEEDS_1"
  locate_and_clone_missing_repos_helper VIM_REPO_SEEDS_1

  # See if there's a user callback.
  # Some general rules:
  # - Meta repos should be cloned before any descendent repos
  #   (repos that live within repos), otherwise things fail
  #   (or we could improve this script to clone to a temporary
  #   location and then apply that repo to the existing location,
  #   but that seems like it could be messy and I don't want to
  #   get my hands dirty).
  # - You could not write a custom function and just put everything
  #   else in GIT_REPO_SEEDS_1, really, unless you want to group your
  #   repos (for cosmetic purposes, e.g., logging), in which case make
  #   a custom fcn., user_locate_and_clone_missing_repos, and call
  #   locate_and_clone_missing_repos_helper on your own.
  debug " user_locate_and_clone_missing_repos"
  # Call private fcns. from user's ${PRIVATE_REPO}/cfg/travel_tasks.sh
  tweak_errexit
  command -v user_locate_and_clone_missing_repos &> /dev/null
  local exit_code=$?
  reset_errexit
  if [[ ${exit_code} -eq 0 ]]; then
    user_locate_and_clone_missing_repos
  fi

} # end: locate_and_clone_missing_repos

function chase_and_face () {
  info "Refacing ~/${PRIVATE_REPO}..."

  if ${HAMSTERING}; then
    debug " killing hamsters"
    tweak_errexit
    #sudo killall hamster-service hamster-indicator
    killall hamster-service hamster-indicator
    reset_errexit
  fi

  mount_curly_emissary_gooey

  debug " setup_private_fries_bash..."
  setup_private_fries_bash

  debug " setup_private_curly_work"
  setup_private_curly_work

  debug " setup_private_vim_spell"
  setup_private_vim_spell

  debug " setup_private_vim_bundle"
  setup_private_vim_bundle

  debug " setup_private_vim_bundle_dubs_all"
  setup_private_vim_bundle_dubs_all

  debug " setup_private_vim_bundle_dubs_edit_juice"
  setup_private_vim_bundle_dubs_edit_juice

  debug " setup_private_vim_bundle_dubs_project_tray"
  setup_private_vim_bundle_dubs_project_tray

  debug " setup_private_vim_bundle_dubs"
  setup_private_vim_bundle_dubs

  debug " setup_private_etc_fstab"
  setup_private_etc_fstab

  debug " setup_private_update_db_conf"
  setup_private_update_db_conf

  debug " locate_and_clone_missing_repos"
  locate_and_clone_missing_repos

  debug " user_do_chase_and_face"
  # Call private fcns. from user's ${PRIVATE_REPO}/cfg/travel_tasks.sh
  tweak_errexit
  command -v user_do_chase_and_face &> /dev/null
  local exit_code=$?
  reset_errexit
  if [[ ${exit_code} -eq 0 ]]; then
    user_do_chase_and_face
  fi

  umount_curly_emissary_gooey

  if ${HAMSTERING}; then
    info "${FONT_UNDERLINE}Unleashing the hamster${FONT_NORMAL}!"
    #hamster-indicator &
    # Blather warning.
    #   $ hamster-indicator &
    #   WARNING:root:Could not import gnomeapplet. Defaulting to upper panel
    #   /usr/lib/python2.7/dist-packages/hamster/lib/graphics.py:1255: PangoWarning:
    #   pango_layout_set_markup_with_accel: Error on line 1: Entity did not end with
    #   a semicolon; most likely you used an ampersand character without intending to
    #   start an entity - escape ampersand as &amp;
    #    layout.set_markup(text)
    hamster-indicator &> /dev/null &
  fi
} # end: chase_and_face

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# init_travel

function travel_dir_is_mount_type_crypt () {
  local is_crypt=1
  if is_mount_type_crypt "${TRAVEL_DIR}"; then
    is_crypt=0
    info "A crypt mount was identified at ‘${TRAVEL_DIR}’"
  fi
  return ${is_crypt}
}

function mount_curly_emissary_gooey_explicit () {
  mount_curly_emissary_gooey
  info "gooey mounted at: ${FG_LAVENDER}${EMISSARY}/gooey"
}

function mount_curly_emissary_gooey () {
  # Make the gooey candy center.
  mkdir -p "${EMISSARY}/.gooey"
  mkdir -p "${EMISSARY}/gooey"

  # Skip mounting ${TRAVEL_DIR}/${EMISSARY}/gooey if TRAVEL_DIR mounted as
  # crypt. (lb): I.e., my /media/${USER}/travel usage.
  travel_dir_is_mount_type_crypt && return

  tweak_errexit
  mount | grep "${EMISSARY}/gooey" &> /dev/null
  retval=$?
  reset_errexit
  if [[ $retval -ne 0 ]]; then
    mount_curly_emissary_gooey_crypt
  else
    info "Looks like gooey is already mounted."
  fi
}

mount_curly_emissary_gooey_crypt () {
  # 2019-04-16: Legacy hack- If caller specifies wonky environ PWD, use encfs.
  if [[ -n ${CRAPWORD} ]]; then
    # 2017-04-05: Ha! You get segfault without the --standard flag!
    #   Zero length password not allowed
    #   Segmentation fault
    # (Though I'd swear it used to work... but I probably didn't notice it didn't!)
    echo "${CRAPWORD}" | encfs -S --standard "${EMISSARY}/.gooey" "${EMISSARY}/gooey"
  else
    must_resemble_gocryptfs_directory
    # FIXME/2019-04-16: For now, CONVENTION: device label maps to pass key.
    local passkey="phy/travel-$(basename ${TRAVEL_DIR})"
    # FIXME/2019-04-16: May need to do better error handling here.
    # NOTE: User will be prompted by pinentry unless gpg-agent fresh.
    pass "${passkey}" |
      head -1 |
        gocryptfs -q -masterkey=stdin "${EMISSARY}/.gooey" "${EMISSARY}/gooey"
  fi
}

must_resemble_gocryptfs_directory () {
  [[ -f "${EMISSARY}/.gooey/gocryptfs.conf" ]] && return

  error
  error "FAIL: Not a gocryptfs cache at ‘${EMISSARY}/.gooey/’"
  info
  info "YOU: Manually prepare the crypt cache:"
  info
  info "  gocryptfs -init \"${EMISSARY}/.gooey\""
  info
  info "And then record the password and master key, and store under:"
  info
  info "  pass phy/travel-<DEVICE_LABEL>"
  info
  exit 1
}

function umount_curly_emissary_gooey () {
  travel_dir_is_mount_type_crypt && return

  if [[ -n "${EMISSARY}" ]]; then
    umount_curly_emissary_gooey_one "${EMISSARY}"
  elif [[ \
    ${TRAVEL_CMD} == 'umount_curly_emissary_gooey' \
    && ${#CANDIDATES[@]} -gt 0 \
  ]]; then
    local emissary
    for lemissary in "${CANDIDATES[@]}"; do
      umount_curly_emissary_gooey_one "${lemissary}/${PRIVATE_REPO_}-emissary"
    done
  else
    info "EMISSARY not set, so nothing to unmount, sucker."
    return 1
  fi
}

function umount_curly_emissary_gooey_one () {
  local lemissary="$1"
  local gooey_mntpt="${lemissary}/gooey"
  mount | grep "${gooey_mntpt}" > /dev/null && true
  local exit_code=$?
  if [[ ${exit_code} -eq 0 ]]; then
    sleep 0.1 # else umount fails.
    local umntput
    umntput=$(fusermount -u "${gooey_mntpt}" 2>&1) && true
    local exit_code=$?
    if [[ ${exit_code} -eq 0 ]]; then
      info "Unmounted: ${FG_LAVENDER}${gooey_mntpt}"
    else
      warn "${umntput}"
      soups_finished_dinners_over_report_time

      echo
      echo "MEH: Travel could not umount the crypt using:"
      echo
      echo "    fusermount -u ${gooey_mntpt}"
      echo
      echo " You could identify the processes keeping it open:"
      echo
      echo "    fuser -c ${gooey_mntpt} 2>&1"
      echo
      echo " and then can get the process ID using:"
      echo
      echo "    echo \$\$"
      echo
      echo " Or try instead:"
      echo
      echo "    lsof | grep ${gooey_mntpt}"
      lsof | grep ${gooey_mntpt}
    fi
  else
    info "No fuse mount point for: ${FG_LAVENDER}${gooey_mntpt}"
  fi
}

function populate_singular_repo () {
  ENCFS_GIT_REPO=$1
  local ENCFS_REL_PATH=$(echo ${ENCFS_GIT_REPO} | /bin/sed s/^.//)
  if [[ ! -e "${ENCFS_REL_PATH}/.git" ]]; then
    #echo " ${ENCFS_GIT_REPO}"
    echo " ${ENCFS_REL_PATH}"
    echo "  \$ git clone ${ENCFS_GIT_REPO} ${ENCFS_REL_PATH}"
    git clone "${ENCFS_GIT_REPO}" "${ENCFS_REL_PATH}"
  else
    echo " skipping ( exists): ${ENCFS_REL_PATH}"
  fi
}

function populate_gardened_repo () {
  ENCFS_GIT_ITER="$1"
  echo " ENCFS_GIT_ITER: ${ENCFS_GIT_ITER}"
  local ENCFS_REL_PATH=$(echo ${ENCFS_GIT_ITER} | /bin/sed s/^.//)
  echo " ${ENCFS_REL_PATH}"
  # We don't -type d so that you can use symlinks.
  while IFS= read -r -d '' fpath; do
    local TARGET_BASE=$(basename -- "${fpath}")
    TARGET_PATH="${ENCFS_REL_PATH}/${TARGET_BASE}"
    if [[ ! -d "${fpath}/.git" ]]; then
      echo " skipping (no .git): $(pwd -P)/${TARGET_PATH}"
      :
    elif [[ -e "${TARGET_PATH}/.git" ]]; then
      echo " skipping ( exists): $(pwd -P)/${TARGET_PATH}"
      :
    elif [[ -h "${fpath}" ]]; then
      echo " skipping (symlink): $(pwd -P)/${TARGET_PATH}"
      :
    elif [[ "${TARGET_BASE#TBD-}" != "${TARGET_BASE}" ]]; then
      echo " skipping (    tbd): $(pwd -P)/${TARGET_PATH}"
      :
    else
      echo " $fpath"
      echo "  \$ git clone ${fpath} ${TARGET_PATH}"
      git clone "${fpath}" "${TARGET_PATH}"
    fi
  done < <(find "${ENCFS_GIT_ITER}" -maxdepth 1 ! -path . -print0)
}

function init_travel () {
  if [[ -z "${TRAVEL_DIR}" ]]; then
    error
    error "FAIL: TRAVEL_DIR not defined"
    exit 1
  fi

  if [[ -z "${EMISSARY}" ]]; then
    error
    error "FAIL: EMISSARY not defined"
    exit 1
  elif [[ -d "${EMISSARY}" ]]; then
    echo
    echo "NOTE: EMISSARY already exists at ${EMISSARY}"
    echo
    echo "If you want to start anew, try:"
    echo
    echo "    /bin/rm -rf -- \"${EMISSARY}\""
    echo
    echo "and then run this script again."
    #echo -n "Replace it and start over?: [y/N] "
    #read -e YES_OR_NO
    #if [[ ${YES_OR_NO^^} == "Y" ]]; then
    #  echo -n "Are you _absolutely_ *SURE*?: [y/N] "
    #  read -e YES_OR_NO
    #  if [[ ${YES_OR_NO^^} == "Y" ]]; then
    #    /bin/rm -rf -- "${EMISSARY}"
    #  fi
    #fi
  elif [[ -e "${EMISSARY}" ]]; then
    error
    error "FAIL: EMISSARY exists and is not a directory: ${EMISSARY}"
    exit 1
  fi

  if [[ ! -e "${EMISSARY}" ]]; then
    info "Creating emissary at ${EMISSARY}"
    mkdir -p "${EMISSARY}"
  else
    info "Found emissary at ${EMISSARY}"
  fi

  mount_curly_emissary_gooey

  pushd "${EMISSARY}/gooey" &> /dev/null

  # Skipping: PLAINTEXT_ARCHIVES (nothing to preload)

  # 2016-09-28: So, like, Bash 4 seems pretty rad, if not ((kludged)).
  #             Decades and decades of cruft! I absolutely love it!!!
  debug "Populating singular git repos..."
  for ((i = 0; i < ${#ENCFS_GIT_REPOS[@]}; i++)); do
    populate_singular_repo "${ENCFS_GIT_REPOS[$i]}"
  done
  if ${INCLUDE_ENCFS_OFF_REPOS}; then
    debug "Populating singular OFF repos..."
    for ((i = 0; i < ${#ENCFS_OFF_REPOS[@]}; i++)); do
      populate_singular_repo "${ENCFS_OFF_REPOS[$i]}"
    done
  fi

  debug "Populating gardened git repos..."
  for ((i = 0; i < ${#ENCFS_GIT_ITERS[@]}; i++)); do
    populate_gardened_repo "${ENCFS_GIT_ITERS[$i]}"
  done
  debug "Populating gardened vim repos..."
  for ((i = 0; i < ${#ENCFS_VIM_ITERS[@]}; i++)); do
    populate_gardened_repo "${ENCFS_VIM_ITERS[$i]}"
  done

  popd &> /dev/null

  tweak_errexit
  command -v user_do_init_travel &> /dev/null
  local exit_code=$?
  reset_errexit
  if [[ ${exit_code} -eq 0 ]]; then
    user_do_init_travel
  fi

  # FIXME/2018-03-28: Make special command just for this. Or delete.
  if false; then
    if ${INCLUDE_ENCFS_OFF_REPOS}; then
      info "Calculating travel size..."
      du_cmd="du -m -d 1 ${EMISSARY}/gooey | sort -nr"
      info "${du_cmd}"
      eval "${du_cmd}"
    fi
  fi

  umount_curly_emissary_gooey

} # end: init_travel

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# update_git

function update_git () {

  info "Installing/Updating git"
  sudo add-apt-repository -y ppa:git-core/ppa
  sudo apt-get update
  sudo apt-get install -y git

} # end: update_git

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# packme

function create_umount_script () {
  #debug "umount ${TRAVEL_DIR}" > ${USERS_CURLY}/popoff.sh
  #chmod 775 ${USERS_CURLY}/popoff.sh

  # FIXME/2018-03-26: (Or fix in Travel 2.0): Not all TRAVEL_DIRs are mounted,
  # i.e., when testing locally. So don't add `umount` below if doesn't apply.
  #   Might also want to reset the popoff script and remove umount later.
  #   Also, why do I need the umount? Doesn't the travel-umount command do that??

  # NOTES/2018-03-26: Slowly remembering: popoff is an ENCFS and USB unmount,
  # whereas Travel itself normally just mounts/unmounts the ENCFS.
  # E.g., you plug in the USB, and it's either mounted automatically, or
  # the user does in manually. So Travel does not mount the device; but it
  # can unmount it! So there's a little mis-parity happening.

  # 2016-11-04: Oh, yerp.
  #debug "umount ${TRAVEL_DIR}" > ${HOME}/.fries/recipe/bin/popoff.sh
  cat > ${HOME}/.fries/recipe/bin/popoff.sh << EOF
#!/bin/bash
# NOTE: This is a generated file.
#
#  DO NOT CHECK IN
#
#    See:
#
#      create_umount_script

source_deps () {
  source "${HOME}/.fries/lib/logger.sh"
}

main () {
  source_deps

  local script_dir="\$(dirname \${BASH_SOURCE[0]})"
  EMISSARY="${EMISSARY}" \${script_dir}/travel umount

  if [[ -d "${TRAVEL_DIR}" ]]; then
    mount | grep "${TRAVEL_DIR}" &> /dev/null && true
    retval=\$?
    if [[ \${retval} -eq 0 ]]; then
      umount "${TRAVEL_DIR}"
      info "Umountd travel directory: ${FG_LAVENDER}${TRAVEL_DIR}"
    else
      info "No travel dir to unmount: ${FG_LAVENDER}${TRAVEL_DIR}"
    fi
  else
    info "Last-used travel not mnt: ${FG_LAVENDER}${TRAVEL_DIR}"
  fi
}

main "\$@"
EOF

  chmod 775 ${HOME}/.fries/recipe/bin/popoff.sh
}

# git_status_porcelain sets GIT_DIRTY_FILES_FOUND accordingly.
GIT_DIRTY_FILES_FOUND=false

function git_commit_hamster () {
  if ${HAMSTERING}; then
    HAMSTER_DB_REL="home/.local/share/hamster-applet/hamster-$(hostname).db"
    HAMSTER_DB_ABS="${USERS_CURLY}/${HAMSTER_DB_REL}"
    if [[ -e "${HAMSTER_DB_ABS}" ]]; then
      debug "Checking Hamster.db..."
      git_commit_generic_file \
        "${HAMSTER_DB_ABS}" \
        "Update hamster-$(hostname).db during packme."
    else
      warn
      warn "WARNING: Skipping hamster.db: No hamster.db at:"
      warn "  ${HAMSTER_DB_ABS}"
      warn
    fi
  else
    warn "Not Hamstering."
  fi
} # end: git_commit_hamster

function git_commit_vim_spell () {
  VIM_SPELL_REL="home/.vim/spell/en.utf-8.add"
  VIM_SPELL_ABS="${USERS_CURLY}/${VIM_SPELL_REL}"

  if [[ -e "${VIM_SPELL_ABS}" ]]; then
    debug "Checking Vim spell..."

    # Sort the spell file, for easy diff'ing, meld'ing, or better yet merging.
    # The .vimrc startup file will remake the .spl file when you restart Vim.
    # NOTE: cat'ing and sort'ing to the cat'ed file results in a 0-size file!?
    #       So we use an intermediate file.
    /bin/cat "${VIM_SPELL_ABS}" | /usr/bin/sort > "${VIM_SPELL_ABS}.tmp"
    /bin/mv -f "${VIM_SPELL_ABS}.tmp" "${VIM_SPELL_ABS}"

    # FIXME/2017-05-09/TRANSITION-TO-TRAVEL: Should indicate from what machine
    #   and maybe what operation (unless it's always packme).
    git_commit_generic_file \
      "${VIM_SPELL_ABS}" \
      "Commit Vim spell during packme."
  else
    warn
    warn "WARNING: Skipping .vim/spell: No en.utf-8.add at:"
    warn "  ${VIM_SPELL_ABS}"
    warn
  fi
} # end: git_commit_vim_spell

function git_commit_vimprojects () {
  VIMPROJECTS_REL="home/.vim/bundle/dubs_all/.vimprojects"
  VIMPROJECTS_ABS="${USERS_CURLY}/${VIMPROJECTS_REL}"
  if [[ -e "${VIMPROJECTS_ABS}" ]]; then
    debug "Checking .vimprojects..."
      # FIXME/2017-05-09/TRANSITION-TO-TRAVEL: Should indicate from what machine
      #   and maybe what operation (unless it's always packme).
      git_commit_generic_file \
        "${VIMPROJECTS_ABS}" \
        "Commit .vimprojects during packme."
  else
    warn
    warn "WARNING: Skipping .vimprojects: Nothing at:"
    warn "  ${VIMPROJECTS_ABS}"
    warn
  fi
} # end: git_commit_vimprojects

function git_commit_dirty_sync_repos () {
  debug "Checking single dirty files for auto-consumability..."

  for ((i = 0; i < ${#AUTO_GIT_ONE[@]}; i++)); do
    trace " ${AUTO_GIT_ONE[$i]}"
    local dirty_bname=$(basename -- "${AUTO_GIT_ONE[$i]}")
    git_commit_generic_file "${AUTO_GIT_ONE[$i]}" "Update ${dirty_bname}."
  done

  debug "Auto-committing all repos' consumable dirty files..."
  for ((i = 0; i < ${#AUTO_GIT_ALL[@]}; i++)); do
    trace " ${AUTO_GIT_ALL[$i]}"
    git_commit_all_dirty_files "${AUTO_GIT_ALL[$i]}" "Update all of ${AUTO_GIT_ALL[$i]}."
  done

  debug "Auto-committing some directories' dirty and/or untracked files..."
  for ((i = 0; i < ${#AUTO_GIT_NEW[@]}; i++)); do
    trace " ${AUTO_GIT_NEW[$i]}"
    git_commit_dirty_or_untracked "${AUTO_GIT_NEW[$i]}" "Add dirty or untracked from ${AUTO_GIT_NEW[$i]}."
  done
} # end: git_commit_dirty_sync_repos

# *** Git: check 'n fail

function git_pre_status_auto_commit () {
  # MAYBE: Does this commits of known knowns feel awkward here?
  #   [2018-03-23 00:08: I think perhaps I meant, use an infuser/plugin?]

  # Be helpful! We can take care of the known knowns.

  git_commit_generic_file \
    ".ignore" \
    "Update .ignore."
    #"Update .ignore during packme."

  git_commit_generic_file \
    ".agignore" \
    "Update .agignore."
    #"Update .agignore during packme."

  git_commit_generic_file \
    ".gitignore" \
    "Update .gitignore."
    #"Update .gitignore during packme."
}

function git_status_porcelain_wrap () {
  local working_dir="$1"
  tweak_errexit
  USING_ERREXIT=false
  git_pre_status_auto_commit
  git_status_porcelain "${working_dir}" ${SKIP_INTERNETS}
  local exit_code=$?
  USING_ERREXIT=true
  reset_errexit
  if [[ ${exit_code} -ne 0 ]]; then
    error "ERROR: git_status_porcelain failed."
    #error "exit_code: ${exit_code}"
    if [[ ${exit_code} -eq 2 ]]; then
      local script_name=$(basename -- "$0")
      warn "Are you internetted? If not, try:"
      warn "  ${script_name} packme -s"
    fi
    exit ${exit_code}
  fi
}

function check_gardened_repo () {
  ENCFS_GIT_ITER=$1
  trace " top-level: ${ENCFS_GIT_ITER}"
  while IFS= read -r -d '' fpath; do
    # 2016-12-08: Adding ! -h, should be fine, and faster.
    if [[ -h "${fpath}" ]]; then
      verbose "  - Skipping symlinked something: ${fpath}"
      :
    elif [[ ! -d "${fpath}/.git" ]]; then
      verbose "  - Skipping .git-less directory: ${fpath}"
      :
    else
      local TARGET_BASE=$(basename -- "${fpath}")
      if [[ ${TARGET_BASE#TBD-} != ${TARGET_BASE} ]]; then
        verbose "  - Skipping resource with TBD-*: ${fpath}"
        :
      else
        trace "  ${fpath}"
        pushd "${fpath}" &> /dev/null
        git_status_porcelain_wrap "${fpath}"
        popd &> /dev/null
      fi
    fi
  done < <(find "${ENCFS_GIT_ITER}" -maxdepth 1 ! -path . -print0)
}

function check_repos_statuses () {

  # Skipping: PLAINTEXT_ARCHIVES

  local i

  debug "Checking one-level repos..."
  for ((i = 0; i < ${#ENCFS_GIT_REPOS[@]}; i++)); do
    trace " ${ENCFS_GIT_REPOS[$i]}"
    pushd "${ENCFS_GIT_REPOS[$i]}" &> /dev/null
    GREPPERS=''
    if [[ \
      ${SKIP_THIS_DIRTY} = true && \
      "${ENCFS_GIT_REPOS[$i]}" == "${FRIES_ABS_DIRN}" \
    ]]; then
      # FIXME/2018-03-26: Ermmmmm... this is really Travel-specific

      # Tell git_status_porcelain to ignore this dirty file, travel.sh.
      THIS_SCRIPT_NAME=$(basename -- "${SCRIPT_ABS_PATH}")
      #GREPPERS='| grep -v " travel.sh$"'
      #
      GREPPERS="${GREPPERS} | grep -v \" ${THIS_SCRIPT_NAME}\$\""
      GREPPERS="${GREPPERS} | grep -v \" .fries/recipe/bin/travel.sh$\""
      #
      GREPPERS="${GREPPERS} | grep -v \" curly_util.sh\$\""
      GREPPERS="${GREPPERS} | grep -v \" .fries/lib/curly_util.sh\$\""
      #
      GREPPERS="${GREPPERS} | grep -v \" git_util.sh\$\""
      GREPPERS="${GREPPERS} | grep -v \" .fries/lib/git_util.sh\$\""
      #
      #debug "GREPPERS: ${GREPPERS}"
    fi
    #git_status_porcelain_wrap "$(basename -- "${ENCFS_GIT_REPOS[$i]}")"
    git_status_porcelain_wrap "${ENCFS_GIT_REPOS[$i]}"
    popd &> /dev/null
  done

  if ${INCLUDE_ENCFS_OFF_REPOS}; then
    debug "Checking one-level OFF repos..."
    for ((i = 0; i < ${#ENCFS_OFF_REPOS[@]}; i++)); do
      trace " ${ENCFS_OFF_REPOS[$i]}"
      pushd "${ENCFS_OFF_REPOS[$i]}" &> /dev/null
      git_status_porcelain_wrap "${ENCFS_OFF_REPOS[$i]}"
      popd &> /dev/null
    done
  fi

  debug "Checking gardened git repos..."
  if [[ ${#ENCFS_GIT_ITERS[@]} -gt 0 ]]; then
    for ((i = 0; i < ${#ENCFS_GIT_ITERS[@]}; i++)); do
      check_gardened_repo "${ENCFS_GIT_ITERS[$i]}"
    done
  else
    trace " ** No git repos gardened"
  fi

  debug "Checking gardened Vim repos..."
  if [[ ${#ENCFS_VIM_ITERS[@]} -gt 0 ]]; then
    for ((i = 0; i < ${#ENCFS_VIM_ITERS[@]}; i++)); do
      check_gardened_repo "${ENCFS_VIM_ITERS[$i]}"
    done
  else
    trace " ** No git repos gardened"
  fi

  # Call private fcns. from user's ${PRIVATE_REPO}/cfg/travel_tasks.sh
  tweak_errexit
  command -v user_do_check_repos_statuses &> /dev/null
  local exit_code=$?
  reset_errexit
  if [[ ${exit_code} -eq 0 ]]; then
    user_do_check_repos_statuses
  fi

  git_issues_review
} # end: check_repos_statuses

function git_issues_review {
  # NOTE/2018-03-23: This method often called twice, once after the initial
  # repo check step, and then again after syncing. I'm curious if it really
  # needs to run both times, or if it should just run once, at the end of the
  # script.
  if ${FRIES_GIT_ISSUES_DETECTED} || \
    [[ ${#FRIES_GIT_ISSUES_RESOLUTIONS[@]} -gt 0 ]] \
  ; then
    soups_finished_dinners_over_report_time

    echo
    warn "GRIZZLY! Travel encountered one or more git issues."
    notice
    notice "It could be dirty files, untracted files, behind branches, rebase issues, etc."
    notice "Helpful commands to fix the issue(s) should follow. If not, scroll up."
    notice
    notice "Please fix. Or run with -D (skip all git warnings)"
    notice "            or run with -DD (skip warnings about $0)"
    notice
    if [[ ${#FRIES_GIT_ISSUES_RESOLUTIONS[@]} -gt 0 ]]; then
      notice "Give this a try:"
      echo
      for ((i = 0; i < ${#FRIES_GIT_ISSUES_RESOLUTIONS[@]}; i++)); do
        RESOLUTION_CMD="  ${FRIES_GIT_ISSUES_RESOLUTIONS[$i]}"
        echo "${RESOLUTION_CMD}"
      done
      echo
    fi
    trap - EXIT
    exit 1
  fi
}

# *** Git: pull

function pull_gardened_repo () {
  ENCFS_GIT_ITER="$1"
  PREFIX="$2"
  local ABS_PATH="${ENCFS_GIT_ITER}"
  local ENCFS_REL_PATH="$(echo ${ABS_PATH} | /bin/sed s/^.//)"
 #trace " ${ENCFS_REL_PATH}"
  trace "├ ${ENCFS_REL_PATH}"
  #trace "─ ${ENCFS_REL_PATH}"
  while IFS= read -r -d '' fpath; do
    local TARGET_BASE=$(basename -- "${fpath}")
    TARGET_PATH="${ENCFS_REL_PATH}/${TARGET_BASE}"
    if [[ -d "${TARGET_PATH}/.git" && ! -h "${TARGET_PATH}" ]]; then
      if [[ "${TARGET_BASE#TBD-}" == "${TARGET_BASE}" ]]; then
       #trace "  ${fpath}"
        trace "├┼─${fpath}"
        SOURCE_PATH="${PREFIX}${ABS_PATH}/$(basename -- "${fpath}")"
        #trace "\${SOURCE_PATH}: ${SOURCE_PATH}"
        #trace "\${TARGET_PATH}: ${TARGET_PATH}"
        git_pull_hush "${SOURCE_PATH}" "${TARGET_PATH}" "${fpath}"
      else
        trace "  skipping (TBD-*): ${fpath}"
      fi
    else
      #trace "  skipping (not .git/, or symlink): $fpath"
      :
    fi
  done < <(find "/${ENCFS_REL_PATH}" -maxdepth 1 ! -path . -print0)
}

function pull_git_repos () {
  if [[ "$1" == 'emissary' ]]; then
    #TO_EMISSARY=true
    PREFIX=''
    pushd "${EMISSARY}/gooey" &> /dev/null
  elif [[ "$1" == 'dev-machine' ]]; then
    #TO_EMISSARY=false
    PREFIX="${EMISSARY}/gooey"
    pushd / &> /dev/null
  else
    error "WHAT: pull_git_repos excepted argument 'emissary' or 'dev-machine'."
    exit 1
  fi

  debug "Pulling singular git repos..."
  if [[ ${#ENCFS_GIT_REPOS[@]} -gt 0 ]]; then
    for ((i = 0; i < ${#ENCFS_GIT_REPOS[@]}; i++)); do
      ABS_PATH="${ENCFS_GIT_REPOS[$i]}"
      local ENCFS_REL_PATH="$(echo ${ABS_PATH} | /bin/sed s/^.//)"
      # MAYBE/2016-12-12: Ignore symlinks?
      #if [[ -d ${ENCFS_REL_PATH} && ! -h ${ENCFS_REL_PATH} ]]; then
        #trace " SOURCE_PATH: ${PREFIX}${ABS_PATH}"
        #trace " TARGET_PATH: ${ENCFS_REL_PATH}"
        #trace " ${ENCFS_REL_PATH}"
        trace "├ ${ENCFS_REL_PATH}"
        git_pull_hush "${PREFIX}${ABS_PATH}" "${ENCFS_REL_PATH}" "${ABS_PATH}"
      #else
      #  trace " not dir/symlink: ${ENCFS_REL_PATH}"
      #fi
    done
  else
    trace " ** No git repos singular"
  fi

  debug "Pulling gardened git repos..."
  if [[ ${#ENCFS_GIT_ITERS[@]} -gt 0 ]]; then
    for ((i = 0; i < ${#ENCFS_GIT_ITERS[@]}; i++)); do
      pull_gardened_repo "${ENCFS_GIT_ITERS[$i]}" "${PREFIX}"
    done
  else
    trace " ** No git repos gardened"
  fi

  debug "Pulling gardened Vim repos..."
  if [[ ${#ENCFS_VIM_ITERS[@]} -gt 0 ]]; then
    for ((i = 0; i < ${#ENCFS_VIM_ITERS[@]}; i++)); do
      pull_gardened_repo "${ENCFS_VIM_ITERS[$i]}" "${PREFIX}"
    done
  else
    trace " ** No Vim repos gardened"
  fi

  if ${INCLUDE_ENCFS_OFF_REPOS}; then
    debug "Pulling singular OFF repos..."
    if [[ ${#ENCFS_OFF_REPOS[@]} -gt 0 ]]; then
      for ((i = 0; i < ${#ENCFS_OFF_REPOS[@]}; i++)); do
        ABS_PATH="${ENCFS_OFF_REPOS[$i]}"
        local ENCFS_REL_PATH="$(echo ${ABS_PATH} | /bin/sed s/^.//)"
        trace " ${ENCFS_REL_PATH}"
        git_pull_hush "${PREFIX}${ABS_PATH}" "${ENCFS_REL_PATH}" "${ABS_PATH}"
      done
    else
      trace " ** No OFF repos singular"
    fi
  fi

  popd &> /dev/null
} # end: pull_git_repos

# *** Plaintext: archive

function make_plaintext () {
  if [[ -e "${PLAINPATH}" ]]; then
    if [[ ! -d "${PLAINPATH}" ]]; then
      error
      error "UNEXPECTED: PLAINPATH not a directory: ${PLAINPATH}"
      exit 1
    fi
  fi

  mkdir -p "${PLAINPATH}"
  # Plop the hostname in the packedpathwhynot.
  echo -n $(hostname) > "${PLAINPATH}/packered_hostname"
  echo -n ${USER} > "${PLAINPATH}/packered_username"

  info "Packing plainly to: ${FG_LAVENDER}${PLAINPATH}"

  for ((i = 0; i < ${#PLAINTEXT_ARCHIVES[@]}; i++)); do

    # FIXME/MAYBE: Enforce rule: Starts with leading '/'.
    ARCHIVE_SRC="${PLAINTEXT_ARCHIVES[$i]}"
    ARCHIVE_NAME=$(basename -- "${ARCHIVE_SRC}")

    # Resolve to real full path, if symlink. (I can't remember why I do this.
    # And I only ever did it for /ccp/dev/cp.)
    if [[ -h "${ARCHIVE_SRC}" ]]; then
      ARCHIVE_SRC=$(readlink -f -- "${ARCHIVE_SRC}")
    fi

    ARCHIVE_REL="$(echo ${ARCHIVE_SRC} | /bin/sed s/^.//)"

    if [[ -e "${ARCHIVE_SRC}" ]]; then
      trace " tarring: ${FG_LAVENDER}${ARCHIVE_SRC}"
      pushd / &> /dev/null
      # Note: Missing files cause tar errors. If this happens, consider:
      #         --ignore-failed-read

      /bin/tar czf "${PLAIN_TBD}/${ARCHIVE_NAME}.tar.gz" \
        --exclude=".~lock.*.ods#" \
        --exclude="*/TBD-*" \
        "${ARCHIVE_REL}"

      /bin/mv -f \
        "${PLAIN_TBD}/${ARCHIVE_NAME}.tar.gz" \
        "${PLAINPATH}/${ARCHIVE_NAME}.tar.gz"

      popd &> /dev/null
    else
      info
      info "NOTICE: Mkdir'ing plaintext archive not found at: ${ARCHIVE_SRC}"
      info
      mkdir "${ARCHIVE_SRC}"
    fi
  done

} # end: make_plaintext

function print_popoff_command_for_later () {
  local popoff_cmd
  if [[ -z ${DEVICE_LABEL} ]]; then
    # popoff_cmd='popoff'
    popoff_cmd="${HOME}/.fries/recipe/bin/popoff.sh"
  else
    popoff_cmd="popoff-${DEVICE_LABEL}"
  fi
  echo "${popoff_cmd}"
}

function packme () {

  #debug "Let's count"'!'
  #debug "- # of. PLAINTEXT_ARCHIVES: ${#PLAINTEXT_ARCHIVES[@]}"
  #debug "- # of.    ENCFS_GIT_REPOS: ${#ENCFS_GIT_REPOS[@]}"
  #debug "- # of.    ENCFS_GIT_ITERS: ${#ENCFS_GIT_ITERS[@]}"
  #debug "- # of.    ENCFS_VIM_ITERS: ${#ENCFS_VIM_ITERS[@]}"

  # We can be smart about certain files that change often and
  # don't need meaningful commit messages and automatically
  # commit them for the user. That's you, chum!
  git_commit_hamster
  git_commit_vim_spell
  git_commit_vimprojects

  if ! ${SKIP_DIRTY_CHECK}; then
    info "${BG_PINK}${FG_MAROON}" \
      "🏄  🌠  🌠   Looking for dirt!  🏄  🌠  🌠  "

    # Commit whatever's listed in user's privatey cfg/sync_repos.sh.
    git_commit_dirty_sync_repos

    # If any of the repos listed in repo_syncs.sh are dirty, fail
    # now and force the user to meaningfully commit those changes.
    # (This is repos like: home-fries, ${PRIVATE_REPO_}, dubs vim,
    #  and other personal- and work-related repositories.)
    # FIXME/2018-03-23: Split out side effect here: git_commit_generic_file
    check_repos_statuses

    info "${BG_PINK}${FG_MAROON}" \
      "🍁  🍁  🍁   Done checking repos for dirt  🍁  🍁  🍁  "
  fi

  if [[ ! -d "${EMISSARY}" ]]; then
    error
    error "FAIL: No \${EMISSARY} defined."
    error "Have you run \`$0 init_travel\`?"
    exit 1
  fi

  if ${SKIP_PULL_REPOS}; then

    # Just pull ${USERS_CURLY}.
    mount_curly_emissary_gooey
    debug "Pulling into: ${EMISSARY}/gooey${USERS_CURLY}"
    git_pull_hush "${USERS_CURLY}" "${EMISSARY}/gooey${USERS_CURLY}" "${USERS_CURLY}"
    umount_curly_emissary_gooey

  else

    mount_curly_emissary_gooey

    pull_git_repos 'emissary'

    make_plaintext

    # Call private fcn. from user's ${PRIVATE_REPO}/cfg/travel_tasks.sh
    tweak_errexit
    command -v user_do_packme &> /dev/null
    local exit_code=$?
    reset_errexit
    if [[ ${exit_code} -eq 0 ]]; then
      user_do_packme
    fi

    umount_curly_emissary_gooey

    if [[ -d "${PLAIN_TBD}" ]]; then
      /bin/rm -rf -- "${PLAIN_TBD}"
    fi
  fi

  create_umount_script

  soups_finished_dinners_over_report_time

  echo
  echo "Plaintext on the stick:"
  echo
  echo "  ll ${PLAINPATH}"
  echo
  echo "Encfs-git on the stick:"
  echo
  echo "  travel mount"
  echo "  ll ${EMISSARY}/gooey"
  echo "  travel umount"
  echo
  # The Cylons said it first.
  echo "Unmount by your command:"
  echo
  echo "  $(print_popoff_command_for_later)"
  echo

  # WISHFUL_THING: Add to the tail of the Bash history.
  #                But Bash loads a terminal's history on session
  #                open and writes it to ~/.bash_history on session
  #                close, and there's nothing you can do to influence
  #                it from within a script. Not even exec or eval. AFAIK.
  # 2016-09-28/TESTME/MAYBE: Could xdotool do this? Hrmm.
  #history -ps "umount ${TRAVEL_DIR}" # unfortunately, a no-op

  git_issues_review
} # end: packme

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# unpack

function unpack_plaintext_archives () {

  # Gather all plaintext archive dumps.
  while IFS= read -r -d '' fpath; do

    if [[ -f "${fpath}/packered_hostname" ]]; then
      PACKED_DIR_HOSTNAME=$(cat ${fpath}/packered_hostname)
    else
      echo "WARNING: Not found: ${fpath}/packered_hostname"
      PACKED_DIR_HOSTNAME=''
    fi

    if [[ -f "${fpath}/packered_username" ]]; then
      PACKED_DIR_USERNAME=$(cat ${fpath}/packered_username)
    else
      echo "WARNING: Not found: ${fpath}/packered_username"
      PACKED_DIR_USERNAME=''
    fi

    # Does the unpack target already exist? If so, move it to delete it.
    TARGETPATH=${UNPACKERED_PATH}/$(basename -- "${fpath}")
    if [[ -e "${TARGETPATH}" ]]; then
      /bin/mv "${TARGETPATH}" "${UNPACK_TBD}"
    fi

    mkdir -p "${TARGETPATH}"
    pushd "${TARGETPATH}" &> /dev/null
    info "Unpacking plain to: ${FG_LAVENDER}${TARGETPATH}"

    # Unpack all plaintext archives.
    # And include dot-prefixed files.
    shopt -s dotglob

    for zpath in "${fpath}/*.tar.gz"; do
      if [[ $(basename -- "${zpath}") != '*.tar.gz' ]]; then
        trace " tar xzf${TAR_VERBOSE} ${zpath}"
        tar xzf${TAR_VERBOSE} "${zpath}"
      # else, No such file or directory
      fi
    done

    # Reset dotglobbing.
    shopt -u dotglob

    /bin/rm -rf -- "${UNPACK_TBD}"

    popd &> /dev/null

  done < <(find "${EMISSARY}" -maxdepth 1 -path */plain-* ! -path . ! -path */plain-*-TBD-* -print0)

} # end: unpack_plaintext_archives

function update_hamster_db () {
  if ! ${HAMSTERING}; then
    info "update_hamster_db: not HAMSTERING"
    return
  fi

  notice "update_hamster_db: ${BG_GREEN} 🐹  🐹  🐹  << HAMSTER TIME! >> 🐹  🐹  🐹  "

  # FIXME/2018-03-23: Replace tweak_errexit hacks with $(subshell) && true
  tweak_errexit
  command -v hamster-love > /dev/null
  local ret_val=$?
  reset_errexit

  if [[ ${ret_val} -ne 0 ]]; then
    warn "WARNING: Hamstering enabled but hamster-love not found"
    return
  fi

  #pushd ${USERS_CURLY}/bin &> /dev/null

  # 2016-09-28: I've used Dropbox in the past, but now I just USB stick
  # FIXME: Make USB vs. Dropbox optionable.
  #ensure_dropbox_running

  # A simple search procedure for finding the best more recent hamster.db.

  CURLY_PATH="${USERS_CURLY}/home/.local/share/hamster-applet"

  local candidates=()

  # Consider any hamster.dbs in ${USERS_CURLY}, now that it's been git pull'ed.
  shopt -s nullglob
  candidates+=(${USERS_CURLY}/home/.local/share/hamster-applet/hamster-*)
  shopt -u nullglob

  # Consider any hamster.dbs at the root of the travel directory.
  if [[ -n "${TRAVEL_DIR}" && -d "${TRAVEL_DIR}" ]]; then
    shopt -s nullglob
    candidates+=(${TRAVEL_DIR}/hamster-*)
    shopt -u nullglob
  fi

  # Consider any hamster.dbs in the dropbox.
  if [[ -d "${HOME}/Dropbox" ]]; then
    while IFS= read -r -d '' file; do
      candidates+=("${file}")
    done < <(find "${HOME}/Dropbox" -maxdepth 1 -type f -name 'hamster-*' -print0)
  fi

  LATEST_HAMMY=''
  local candidate
  for candidate in "${candidates[@]}"; do
    #trace "candidate: ${candidate}"
    if [[ -z "${LATEST_HAMMY}" ]]; then
      #trace "first candidate: ${candidate}"
      LATEST_HAMMY="${candidate}"
    elif [[ "${candidate}" -nt "${LATEST_HAMMY}" ]]; then
      #trace "newer candidate: ${candidate}"
      LATEST_HAMMY="${candidate}"
    fi
  done
  # FIXME/2016-10-27: Weird. After an unpack at home, the older
  # hamster-larry.db was touched somehow and shows up newer than. dahfuh?
  info "LATEST_HAMMY: ${FG_LAVENDER}${LATEST_HAMMY}"

  if [[ -n "${LATEST_HAMMY}" ]]; then
#        echo
#        echo "hamster love says:"
#        echo
#        hamster-love ${LATEST_HAMMY} ${CURLY_PATH}/hamster-$(hostname).db
#        echo
#        echo 'hamstered!'
#    echo "love_says=\$(hamster-love ${LATEST_HAMMY} ${CURLY_PATH}/hamster-$(hostname).db)"

    # FIXME: hamster-love --option to not ask to replace, maybe --no
    if false; then
      local love_says=$(hamster-love "${LATEST_HAMMY}" "${CURLY_PATH}/hamster-$(hostname).db")
      #info "hamster love says:\n${love_says}"
      #info "hamster love says:\n${BG_PINK}${FG_MAROON}${love_says}"
      info \
        "${BG_PINK}${FG_MAROON}🍁  🍁  🍁   hamster love says:  🍁  🍁  🍁                ${FONT_NORMAL}" \
        "\n${love_says}" \
        "\n ${BG_PINK}${FG_MAROON}                                                                               "
    fi
# FOR NOW, cannot pretty-print in color...
    info "${BG_PINK}${FG_MAROON}🍁  🍁  🍁   hamster love says:  🍁  🍁  🍁                ${FONT_NORMAL}"
    hamster-love "${LATEST_HAMMY}" "${CURLY_PATH}/hamster-$(hostname).db"
    info " ${BG_PINK}${FG_MAROON}                                                                               "


  else
    info "Skipping hamster-love: did not find appropriately most recent replacement."
  fi
#  echo
  #popd &> /dev/null
} # end: update_hamster_db

function unpack () {

  if [[ ! -d "${EMISSARY}" ]]; then
    error "FATAL: The emissary directory was not found at ${EMISSARY}."
    exit 1
  fi

  mkdir -p "${UNPACKERED_PATH}"

  if [[ -f "${USERS_CURLY}/master_chef" ]]; then
    unpack_plaintext_archives
  fi

  mount_curly_emissary_gooey

  # pull_git_repos knows 'emissary' and 'dev-machine'.
  pull_git_repos 'dev-machine'

  tweak_errexit
  command -v user_do_unpack &> /dev/null
  local exit_code=$?
  reset_errexit
  if [[ ${exit_code} -eq 0 ]]; then
    user_do_unpack
  fi

  umount_curly_emissary_gooey

  update_hamster_db

  # 2016-10-09: Save yourself a step reface automatically on unpack.
  chase_and_face

  create_umount_script

  soups_finished_dinners_over_report_time

  #echo
  #echo "encrypted repos rebased from emissaries."
  #echo
  #echo " throwaway plaintext archives unpacked."
  echo
  echo "To locate unpacked plaintext archives:"
  echo
  echo " ll ${UNPACKERED_PATH}"
  echo
  echo "To unmount the stick when done:"
  echo
  echo "  $(print_popoff_command_for_later)"
  echo

  git_issues_review
} # end: unpack

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# prepare_shim

function prepare_shim () {

  if [[ ! -d "${EMISSARY}" ]]; then
    echo "FATAL: The emissary directory was not found at ${EMISSARY}."
    exit 1
  fi

  info "Making: ${USERS_CURLY}/TBD-shim"

  mkdir -p "${USERS_CURLY}/TBD-shim"

  pushd "${USERS_CURLY}/TBD-shim" &> /dev/null

  # git_check_generic_file sets ${git_result} to 0 if file is dirty.
  git_check_generic_file "${SCRIPT_ABS_PATH}"

  USE_GOOEY=true
  if [[ $git_result -eq 0 ]]; then
    # travel.sh is dirty; use it and not the travel one.
    USE_GOOEY=false
    debug " Using local $(basename -- "${SCRIPT_ABS_PATH}")"
  else
    debug " Using gooey $(basename -- "${SCRIPT_ABS_PATH}")"
  fi

  PREFIX=''
  if ${USE_GOOEY}; then
    PREFIX="${EMISSARY}/gooey/"
    mount_curly_emissary_gooey
  fi

  trace "  Copying: ${PREFIX}${SCRIPT_ABS_PATH}"

  /bin/cp -aLf "${PREFIX}${SCRIPT_ABS_PATH}" travel_shim.sh
  chmod 775 travel_shim.sh

  # MAINTAIN/2018-03-24: Keep these copies updated with whatever libs you add!
  # FIXME/EXPLAIN/2018-03-24: Are these missing from the shim-shim?
  #     source bash_base.sh
  #     source ssh_util.sh
  #     source process_util.sh

  trace "  Copying: ${PREFIX}${FRIES_ABS_DIRN}/.fries/lib/curly_util.sh"
  /bin/cp -aLf "${PREFIX}${FRIES_ABS_DIRN}/.fries/lib/curly_util.sh" .

  trace "  Copying: ${PREFIX}${FRIES_ABS_DIRN}/.fries/lib/color_util.sh"
  /bin/cp -aLf "${PREFIX}${FRIES_ABS_DIRN}/.fries/lib/color_util.sh" .

  trace "  Copying: ${PREFIX}${FRIES_ABS_DIRN}/.fries/lib/logger.sh"
  /bin/cp -aLf "${PREFIX}${FRIES_ABS_DIRN}/.fries/lib/logger.sh" .

  trace "  Copying: ${PREFIX}${FRIES_ABS_DIRN}/.fries/lib/git_util.sh"
  /bin/cp -aLf "${PREFIX}${FRIES_ABS_DIRN}/.fries/lib/git_util.sh" .

  trace "  Copying: ${PREFIX}${SYNC_REPOS_PATH}"
  /bin/cp -aLf "${PREFIX}${SYNC_REPOS_PATH}" .

  trace "  Copying: ${PREFIX}${TRAVEL_TASKS_PATH}"
  /bin/cp -aLf "${PREFIX}${TRAVEL_TASKS_PATH}" .

  tweak_errexit
  command -v user_do_prepare_shim &> /dev/null
  local exit_code=$?
  reset_errexit
  if [[ ${exit_code} -eq 0 ]]; then
    user_do_prepare_shim
  fi

  if ${USE_GOOEY}; then
    umount_curly_emissary_gooey
  fi

  popd &> /dev/null
} # end: prepare_shim

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# Run the script.
soups_on "$@"

#echo
#echo 'Success!'

# Unhook errexit_cleanup.
trap - EXIT
# 2018-03-05: Weird. I put an echo here because popoff can be slow
# to run, and I wanted to trace the lag. It brought me here. After
# the echo, the script can still take a second or two to wrap up.

exit 0

