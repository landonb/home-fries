#!/bin/bash
# Last Modified: 2016.11.05
# vim:tw=0:ts=2:sw=2:et:norl:

set -e
function errexit_cleanup () {
  echo
  echo "ERROR: The script failed!!"
  # No exit necessary, unless we want to specify status.
  exit 1
}
trap errexit_cleanup EXIT

# ***

# Enable a little more echo, if you want.
# You can also add this to cfg/sync_repos.sh.
DEBUG=false
#DEBUG=true

# ***

# Start a timer.
setup_time_0=$(date +%s.%N)

# ***

# Load: colorful logging
if [[ -e ${HOME}/.fries/lib/logger.sh ]]; then
  source ${HOME}/.fries/lib/logger.sh
elif [[ -e logger.sh ]]; then
  source logger.sh
else
  echo "WARNING: Missing logger.sh"
fi

# Load: setup_users_curly_path
if [[ -e ${HOME}/.fries/lib/util.sh ]]; then
  source ${HOME}/.fries/lib/util.sh
elif [[ -e util.sh ]]; then
  source util.sh
else
  echo "WARNING: Missing util.sh"
fi
# Set USERS_CURLY and USERS_BNAME.
setup_users_curly_path
PRIVATE_REPO="${USERS_BNAME}"
# In case ${PRIVATE_REPO} has a dot prefix, remove it for some friendlier representations.
PRIVATE_REPO_=${PRIVATE_REPO#.}

# Load: git_commit_generic_file, et al
if [[ -e ${HOME}/.fries/lib/git_util.sh ]]; then
  source ${HOME}/.fries/lib/git_util.sh
elif [[ -e git_util.sh ]]; then
  source git_util.sh
else
  echo "WARNING: Missing git_util.sh"
fi

# ***

# ~/.curly/setup.sh makes symlinks in the user's private dotfiles destination,
# which means this script could be running as a symlink, and we gotta dance.

SCRIPT_ABS_PATH="$(readlink -f ${BASH_SOURCE[0]})"

find_git_parent ${SCRIPT_ABS_PATH}
FRIES_ABS_DIRN=${REPO_PATH}

# ***

# Get lists of things for unpack and packme from the machine specs file.
CRAPWORD=""
PLAINTEXT_ARCHIVES=()
ENCFS_GIT_REPOS=()
ENCFS_GIT_ITERS=()
SOURCED_SYNC_REPOS=true
SYNC_REPOS_PATH=""
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
if [[ -n ${SYNC_REPOS_PATH} ]]; then
  source "${SYNC_REPOS_PATH}"
else
  echo "NOTICE: sync_repos.sh not found"
  SOURCED_SYNC_REPOS=false
fi

# ***

# By default, plaintext archives unpack to, e.g., ~/Documents/${PRIVATE_REPO_}-unpackered
# You can change this path by setting STAGING_DIR in ${USERS_CURLY}/cfg/sync_repos.sh.
if [[ -z ${STAGING_DIR+x} ]]; then
  STAGING_DIR=/home/${USER}/Documents
fi

# Unpack plaintext archives to the unpackered directory,
# under the subdirectory named after the originating
# machine.
UNPACKERED_PATH=${STAGING_DIR}/${PRIVATE_REPO_}-unpackered
UNPACK_TBD=${UNPACKERED_PATH}-TBD-${UNIQUE_TIME}

# ***

# Load packme and unpack hooks to run during packme and unpack, respk.
SOURCED_TRAVEL_TASKS=true
TRAVEL_TASKS_PATH=""
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
  echo "NOTICE: travel_tasks.sh not found"
  echo ${USERS_CURLY}/cfg/travel_tasks.sh
  SOURCED_TRAVEL_TASKS=false
fi

# ***

echod () {
  set +e
  ${DEBUG} && echo $*
  set -e
}

echod "SOURCED_SYNC_REPOS: ${SOURCED_SYNC_REPOS}"

echod "SOURCED_TRAVEL_TASKS: ${SOURCED_TRAVEL_TASKS}"

# ***

HAMSTERING=false
if [[ -d ${USERS_CURLY}/home/.local/share/hamster-applet ]]; then
  HAMSTERING=true
  echo "Hamster found under: ${USERS_CURLY}/home/.local/share/hamster-applet"
else
  #echo "No hamster at: ${USERS_CURLY}/home/.local/share/hamster-applet"
  :
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

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

TRAVEL_CMD=""

function set_travel_cmd () {
  if [[ -z ${TRAVEL_CMD} ]]; then
    TRAVEL_CMD="$1"
  else
    TRAVEL_CMD="too_many_travel_cmds"
  fi
}

COPY_PRIVATE_REPO_PLAIN=false
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
TAR_VERBOSE=""
UNKNOWN_ARG=false

function soups_on () {

  local ASKED_FOR_HELP=false
  local DETERMINE_TRAVEL_DIR=false
  local CAN_IGNORE_TRAVEL_DIR=false

  echod 'Soups on!: ' $*

  while [[ "$1" != "" ]]; do
    case $1 in
      -h)
        ASKED_FOR_HELP=true
        shift
        ;;
      --help)
        ASKED_FOR_HELP=true
        shift
        ;;
      -\?)
        # Need the escape the ? or it hits any single character option.
        ASKED_FOR_HELP=true
        shift
        ;;
      help)
        ASKED_FOR_HELP=true
        shift
        ;;
      chase_and_face)
        set_travel_cmd "chase_and_face"
        shift
        ;;
      init_travel)
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
        REQUIRES_CRAPPDWORD=true
        set_travel_cmd "prepare_shim"
        shift
        ;;
      mount)
        PLEASE_CHOOSE_PART="to which to pack"
        DETERMINE_TRAVEL_DIR=true
        REQUIRES_CRAPPDWORD=true
        set_travel_cmd "mount_curly_emissary_gooey"
        shift
        ;;
      umount)
        PLEASE_CHOOSE_PART="to which to pack"
        DETERMINE_TRAVEL_DIR=true
        REQUIRES_CRAPPDWORD=true
        set_travel_cmd "umount_curly_emissary_gooey"
        shift
        ;;
      -I)
        COPY_PRIVATE_REPO_PLAIN=true
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
      --no-shim)
        SKIP_UNPACK_SHIM=true
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
      *)
        UNKNOWN_ARG=true
        echo "ERROR: Unrecognized argument: $1"
        shift
        ;;
    esac
  done

  if [[ ${TRAVEL_CMD} == "too_many_travel_cmds" ]]; then
    echo
    echo "FATAL: Please specify just one travel command."
    echo
  fi
  if [[ ${ASKED_FOR_HELP} = true || (${TRAVEL_CMD} == "too_many_travel_cmds") ]]; then
    echo
    echo "sync-stick helps you roam amongst dev machines"
    echo
    echo "USAGE: $0 [options] {command} [options]"
    #echo
    #echo "Commands: packme | unpack | mount | umount | chase_and_face | init_travel"
    echo
    TRAVEL_CMD=""
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
    echo "      update_git        update to the latest git, at least 2.9"
    echo "                          (else \`git pull --rebase --autostash\` isn't a thing)"
    #echo
    echo "Uncommon commands:"
    #echo
    echo "      mount             mount encfs at .../gooey/ # for poking around travel repos"
    echo "      umount            unmount travel encfs at \$TRAVEL_DIR/${PRIVATE_REPO_}-emissary/gooey"
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
    echo "      -I                /bin/cp cfg/sync_repos.sh to travel device [BEWARE: unencrypted!]"
    echo "                          (to setup a new machine *locally* without worrying about encfs)"
    #echo
    echo "unpack options:"
    echo "      -d STAGING_DIR    specify the unpack path for incoming plaintext tar stuff"
    echo "      -v                to \`tar v\` (if you have problems detarring)"
    echo "      --no-shim         use local travel.sh for unpack and not what's on travel"
    echo "                          (local travel.sh is used always if it's git-dirty)"
  fi

  if ${DETERMINE_TRAVEL_DIR}; then
    determine_stick_dir "${PLEASE_CHOOSE_PART}"
    # So that sync_repos.sh can use, e.g., ${EMISSARY}.
    source "${SYNC_REPOS_PATH}"
  fi

  if [[ ${REQUIRES_CRAPPDWORD} && -z ${CRAPWORD} ]]; then
    echo
    echo "FATAL: Please set CRAPWORD. Maybe in repo_syncs.sh"
    trap - EXIT
    exit 1
  fi

  if [[ ${REQUIRES_SYNC_REPOS} && ! ${SOURCED_SYNC_REPOS} ]]; then
    echo
# FIXME: repo_syncs repositioned
    echo "WARNING: Missing repo_syncs.sh."
    trap - EXIT
    exit 1
  fi

  # Make sure the staging/destination exists.
  mkdir -p ${STAGING_DIR}

  echod
  #echo "Two-way travel directory: ${TRAVEL_DIR}"
  if [[ -z ${EMISSARY} && ${DETERMINE_TRAVEL_DIR} == false ]]; then
    echo "Two-way travel directory: ${EMISSARY} [not needed for this command]"
  else
    echo "Two-way travel directory: ${EMISSARY}"
  fi
  echo "One-way unpack (staging): ${STAGING_DIR}"

  if [[ -n ${TRAVEL_CMD} && ${UNKNOWN_ARG} = false ]]; then
    # Run the command.
    eval "$TRAVEL_CMD"
    local setup_time_n=$(date +%s.%N)
    time_elapsed=$(echo "scale=2; ($setup_time_n - $setup_time_0) * 100 / 100" | bc -l)
    #echo
    echo "Elapsed: $time_elapsed secs."
  elif ! ${ASKED_FOR_HELP}; then
    echo 'Nothing to do!'
  fi

} # end: soups_on

function determine_stick_dir () {

  local PLEASE_CHOOSE_PART=$1

  shopt -s dotglob
  shopt -s nullglob
  local MOUNTED_DIRS=(/media/${USER}/*)
  shopt -u dotglob
  shopt -u nullglob
  if [[ ${#MOUNTED_DIRS[@]} -eq 0 ]]; then
    echo "Nothing mounted under /media/${USER}/"
    echo -n "Please specify the dually-accessible sync directory: "
    read -e TRAVEL_DIR
  elif [[ ${#MOUNTED_DIRS[@]} -eq 1 ]]; then
    TRAVEL_DIR=${MOUNTED_DIRS[0]}
  else
    CANDIDATES=()
    for fpath in "${MOUNTED_DIRS[@]}"; do
      # Use -r to check that path is readable. Just because.
      if [[ -r ${fpath}/ ]]; then
        echod "Examining mounted path: ${fpath}"
        if [[ -d ${fpath}/${PRIVATE_REPO_}-emissary ]]; then
          echod "Adding candidate: ${fpath}"
          CANDIDATES+=(${fpath})
        fi
      else
        echod "Skipin' unreadable path: ${fpath}"
      fi
    done
    if [[ ${#CANDIDATES[@]} -eq 1 ]]; then
      TRAVEL_DIR=${CANDIDATES[0]}
    else
      echo "More than one path found under /media/${USER}/"
      echo "Please choose the correct path ${PLEASE_CHOOSE_PART}."
      echo "(You also just might need to mount your sync stick.)"
      for fpath in "${MOUNTED_DIRS[@]}"; do
        echo -n "Is this your path?: ${fpath} [y/n] "
        read -n 1 -e YES_OR_NO
        if [[ ${YES_OR_NO^^} == "Y" ]]; then
          TRAVEL_DIR=${fpath}
          break
        fi
      done
    fi
  fi

  if [[ ! -d ${TRAVEL_DIR} ]]; then
    if ! ${CAN_IGNORE_TRAVEL_DIR}; then
      echo 'The specified stick path does not exist. Sorry! Try again!!'
      exit 1
    fi
  fi

  EMISSARY="${TRAVEL_DIR}/${PRIVATE_REPO_}-emissary"
  PLAINPATH=${EMISSARY}/plain-$(hostname)
  PLAIN_TBD=${PLAINPATH}-TBD-${UNIQUE_TIME}

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
        /bin/rm user-current-project
      fi
      /bin/ln -s ${USERS_CURLY}/work/oopsidoodle user-current-project
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

setup_private_vim_bundle_dubs_all () {

  if [[ -e ${HOME}/.vim/bundle/dubs_all ]]; then

    pushd ${HOME}/.vim/bundle/dubs_all &> /dev/null

    /bin/ln -sf ../../bundle_/dubs_file_finder/cmdt_paths
    /bin/ln -sf ../../bundle_/dubs_project_tray/dubs_cuts

    /bin/ln -sf ../../bundle_/dubs_edit_juice/dubs_tagpaths.vim
    /bin/ln -sf ../../bundle_/dubs_grep_steady/dubs_projects.vim

    /bin/ln -sf ${USERS_CURLY}/home/.vim/bundle/dubs_all/one_time_setup.sh
    /bin/ln -sf ${USERS_CURLY}/home/.vim/bundle/dubs_all/plugin-info.json
    /bin/ln -sf ${USERS_CURLY}/home/.vim/bundle/dubs_all/.vimprojects
    /bin/ln -sf ${USERS_CURLY}/home/.vim/bundle/dubs_all/.vimrc.bundle_

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

setup_private_vim_bundle_dubs () {

  if [[ -e ${HOME}/.vim/bundle/dubs_all ]]; then

    mkdir -p ${HOME}/.vim/bundle-dubs

    pushd ${HOME}/.vim/bundle-dubs &> /dev/null

    /bin/ln -sf ${USERS_CURLY}/home/.vim/bundle-dubs/generate.sh
    /bin/ln -sf ${USERS_CURLY}/home/.vim/bundle-dubs/git-st-all.sh

    /bin/ln -sf ../.agignore

    ./generate.sh

    popd &> /dev/null

  fi

} # end: setup_private_vim_bundle_dubs

setup_private_dot_files () {

  pushd ${HOME} &> /dev/null

  # Common dotfiles are symlinked below.
  # Feel free to add to this list; just
  #  respect the isn't-there-don't-care policy.

  if [[ ! -e .cookiecutterrc ]]; then
    if [[ -f ${USERS_CURLY}/home/.cookiecutterrc ]]; then
      /bin/ln -s ${USERS_CURLY}/home/.cookiecutterrc
    fi
  fi

  if [[ ! -e .ctags ]]; then
    if [[ -f ${USERS_CURLY}/home/.ctags ]]; then
      /bin/ln -s ${USERS_CURLY}/home/.ctags
    fi
  fi

  if [[ ! -e .gitconfig ]]; then
    NORMALD_GITCONFIG="${USERS_CURLY}/home/.gitconfig"
    MACHINE_GITCONFIG="${NORMALD_GITCONFIG}-$(hostname)"
    if [[ -e ${MACHINE_GITCONFIG} ]]; then
      /bin/ln -s ${MACHINE_GITCONFIG} .gitconfig
    elif [[ -e ${NORMALD_GITCONFIG} ]]; then
      /bin/ln -s ${NORMALD_GITCONFIG}
    # else, user has not set up their .gitconfig, whatever.
    fi
  fi

  if [[ ! -e .inputrc ]]; then
    if [[ -f ${USERS_CURLY}/home/.inputrc ]]; then
      /bin/ln -s ${USERS_CURLY}/home/.inputrc
    fi
  fi

  # Skipping: .local/share/hamster-applet/
  # See: setup_private_hamster_db

  if [[ ! -e mm.cfg ]]; then
    if [[ -f ${USERS_CURLY}/home/mm.cfg ]]; then
      /bin/ln -s ${USERS_CURLY}/home/mm.cfg
    fi
  fi

  # Skipping: Pictures/
  #  You could do something like:
  #    gsettings set org.mate.background picture-filename \
  #      ${USERS_CURLY}/home/Pictures/.backgrounds/nice_pic.jpg

  if [[ ! -e .psqlrc ]]; then
    if [[ -f ${USERS_CURLY}/home/.psqlrc ]]; then
      /bin/ln -s ${USERS_CURLY}/home/.psqlrc
    fi
  fi

  if [[ ! -e .sqliterc ]]; then
    MACHINE_SQLITERC="${USERS_CURLY}/home/.sqliterc-$(hostname)"
    if [[ -e ${MACHINE_SQLITERC} ]]; then
      /bin/ln -s ${MACHINE_SQLITERC} .sqliterc
    elif [[ -e ${USERS_CURLY}/home/.sqliterc ]]; then
      /bin/ln -s ${USERS_CURLY}/home/.sqliterc
    # else, same as above, whatever, deal.
    fi
  fi

  popd &> /dev/null

} # end: setup_private_dot_files

setup_private_ssh_directory () {
  if [[ -d ${USERS_CURLY}/.ssh ]]; then
    # A symlink works for outgoing conns but not incomms.
    #/bin/ln -sf ${USERS_CURLY}/.ssh ~/.ssh
    # Cannot create hard links on directories.
    #/bin/ln -f ${USERS_CURLY}/.ssh ~/.ssh
    mkdir -p ${HOME}/.ssh
    pushd ${HOME}/.ssh &> /dev/null
    # Remove symlinks from ~/.ssh/
    find . -maxdepth 1 -type l -exec /bin/rm {} +
    # Replace with symlinks from private repo .ssh/
    find ${USERS_CURLY}/.ssh -maxdepth 1 -type f -not -iname "known_hosts-*" -exec /bin/ln -s {} \;
    if [[ -e ${USERS_CURLY}/.ssh/known_hosts-$(hostname) ]]; then
      /bin/ln -s ${USERS_CURLY}/.ssh/known_hosts-$(hostname) known_hosts
    # else, you'll get a real file at ~/.ssh/known_hosts
    fi
    popd &> /dev/null

    # Ssh is so particular about permissions.
    chmod g-w ~
    chmod g-w ${USERS_CURLY}
    chmod 700 ~/.ssh
    # Also git doesn't store permissions
    # [3rd party tools do:
    #  git-cache-meta
    #   https://gist.github.com/andris9/1978266
    #  metastore
    #   https://david.hardeman.nu/software.php#metastore
    # But we've already got our solution.
    chmod 400 ~/.ssh/*
    chmod 440 ~/.ssh/*.pub
    chmod 600 ~/.ssh/config ~/.ssh/known_hosts* ~/.ssh/authorized_keys ~/.ssh/environment
  fi
} # end: setup_private_ssh_directory

setup_private_hamster_db () {

  if ${HAMSTERING}; then
    # Set up the hamster.db -- each machine gets its own database file,
    # since you'll want to deliberately merge hamster files together.
    # (2016-04-26: I had earlier tried using Dropbox to manage a single
    # file, but that approach doesn't make things easier and introduces
    # its own syncing and merging nuances.)
    if [[ -e ~/.local/share/hamster-applet/hamster.db \
          && ! -h ~/.local/share/hamster-applet/hamster.db ]]; then
      echo "WARNING: hamster.db exists / moving it outta the way"
      echo "(If you just installed the OS, hamster.db contains 10 example activities.)"
      /bin/mv -i \
        ~/.local/share/hamster-applet/hamster.db \
        ~/.local/share/hamster-applet/hamster.db-${BACKUP_POSTFIX}
    fi
    if [[ ! -e ${USERS_CURLY}/home/.local/share/hamster-applet/hamster-$(hostname).db ]]; then
      echo "Using the canon hamster.db as a template for this machine."
      /bin/cp -aL \
        ${USERS_CURLY}/home/.local/share/hamster-applet/hamster.db \
        ${USERS_CURLY}/home/.local/share/hamster-applet/hamster-$(hostname).db
    fi
    if [[ ! -h ~/.local/share/hamster-applet/hamster.db ]]; then
      /bin/ln -sf \
        ${USERS_CURLY}/home/.local/share/hamster-applet/hamster-$(hostname).db \
        ~/.local/share/hamster-applet/hamster.db
    fi
  fi

} # end: setup_private_hamster_db

setup_private_anacron () {

  # Anacron backup script.
  # The author uses .anacron just to back up data on the main, master_chef, machine.
  # So just setup anacron on the main development machine, but not on satellites.
  # NOTE: Only applies to main desktop machine.
  if [[ -e ${USERS_CURLY}/master_chef ]]; then
    if [[ -d ${USERS_CURLY}/home/.anacron ]]; then
      if [[ -e ~/.anacron ]]; then
        echo "  Skipping: Already exists: ~/.anacron"
      else
        /bin/ln -sf ${USERS_CURLY}/home/.anacron ~/.anacron
      fi
    fi
  fi
} # end: setup_private_anacron

setup_private_etc_fstab () {
  if [[ -f ${USERS_CURLY}/dev/$(hostname)/etc/fstab ]]; then
    set +e
    diff ${USERS_CURLY}/dev/$(hostname)/etc/fstab /etc/fstab &> /dev/null
    ECODE=$?
    set -e
    if [[ ${ECODE} -ne 0 ]]; then
      echo "BKUPPING: /etc/fstab"
      sudo /bin/mv /etc/fstab /etc/fstab-${BACKUP_POSTFIX}
      sudo /bin/cp -a ${USERS_CURLY}/dev/$(hostname)/etc/fstab /etc/fstab
      sudo chmod 644 /etc/fstab
    fi
  else
    echo "Skipping: No fstab for $(hostname)"
  fi
} # end: setup_private_etc_fstab

setup_private_update_db_conf () {
  if [[ -f ${USERS_CURLY}/dev/$(hostname)/etc/updatedb.conf ]]; then
    set +e
    diff ${USERS_CURLY}/dev/$(hostname)/etc/updatedb.conf /etc/updatedb.conf &> /dev/null
    ECODE=$?
    set -e
    if [[ ${ECODE} -ne 0 ]]; then
      if [[ -e /etc/updatedb.conf ]]; then
        echo "BKUPPING: /etc/updatedb.conf"
        sudo /bin/mv /etc/updatedb.conf /etc/updatedb.conf-${BACKUP_POSTFIX}
      fi
      echo "Placing: /etc/updatedb.conf"
      sudo /bin/cp -a ${USERS_CURLY}/dev/$(hostname)/etc/updatedb.conf /etc/updatedb.conf
      sudo chmod 644 /etc/updatedb.conf
    fi
  else
    echo "Skipping: No updatedb.conf for $(hostname)"
  fi
} # end: setup_private_update_db_conf

locate_and_clone_missing_repo () {
  check_repo=$1
  remote_orig=$2
  echod "  CHECK: ${check_repo}"
  echod "   REPO: ${remote_orig}"
  if [[ -d ${check_repo} ]]; then
    if [[ -d ${check_repo}/.git ]]; then
      echo "  EXISTS: ${check_repo}"
    else
      echo
      echo "WARNING: Where's .git/ ? at: ${check_repo}"
      echo "   REPO: ${remote_orig}"
      echo
    fi
  else
    echo "  MISSING: ${check_repo}"
    echo "     REPO: ${remote_orig}"
    parent_dir=$(dirname ${check_repo})
    if [[ -d ${parent_dir} ]]; then
      echo "           fetching!"
      pushd ${parent_dir} &> /dev/null
      git clone ${remote_orig}
      popd &> /dev/null
    else
      echo
      echo "WARNING: repo path not ready: ${check_repo} / because not dir: ${parent_dir}"
      echo
    fi
  fi
} # end: locate_and_clone_missing_repo

locate_and_clone_missing_repos () {
  if [[ ${#GIT_REPO_SEEDS[@]} -gt 0 ]]; then
    #echo "No. of GIT_REPO_SEEDS: ${#GIT_REPO_SEEDS[@]}"
    for key in "${!GIT_REPO_SEEDS[@]}"; do
      #echo "key  : $key"
      #echo "value: ${GIT_REPO_SEEDS[$key]}"
      locate_and_clone_missing_repo $key ${GIT_REPO_SEEDS[$key]}
    done
  fi

} # end: locate_and_clone_missing_repos

function chase_and_face () {

  #echo
  echo "Refacing ~/${PRIVATE_REPO}..."

  if ${HAMSTERING}; then
    echo " killing hamsters"
    set +e
    #sudo killall hamster-service hamster-indicator
    killall hamster-service hamster-indicator
    set -e
  fi

  echo " setup_private_fries_bash..."
  setup_private_fries_bash

  echo " setup_private_curly_work"
  setup_private_curly_work

  echo " setup_private_vim_spell"
  setup_private_vim_spell

  echo " setup_private_vim_bundle"
  setup_private_vim_bundle

  echo " setup_private_vim_bundle_dubs_all"
  setup_private_vim_bundle_dubs_all

  echo " setup_private_vim_bundle_dubs_edit_juice"
  setup_private_vim_bundle_dubs_edit_juice

  echo " setup_private_vim_bundle_dubs"
  setup_private_vim_bundle_dubs

  echo " setup_private_dot_files"
  setup_private_dot_files

  echo " setup_private_ssh_directory"
  setup_private_ssh_directory

  echo " setup_private_hamster_db"
  setup_private_hamster_db

  echo " setup_private_anacron"
  setup_private_anacron

  echo " setup_private_etc_fstab"
  setup_private_etc_fstab

  echo " setup_private_update_db_conf"
  setup_private_update_db_conf

  echo " locate_and_clone_missing_repos"
  locate_and_clone_missing_repos

  echo " user_do_chase_and_face"
  # Call private fcns. from user's ${PRIVATE_REPO}/cfg/travel_tasks.sh
  set +e
  command -v user_do_chase_and_face &> /dev/null
  EXIT_CODE=$?
  set -e
  if [[ ${EXIT_CODE} -eq 0 ]]; then
    user_do_chase_and_face
  fi

  #echo "DONE"

  if ${HAMSTERING}; then
    echo "Unleashing the hamster"
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

function mount_curly_emissary_gooey () {
  # Make the gooey candy center.
  mkdir -p ${EMISSARY}/gooey
  mkdir -p ${EMISSARY}/.gooey
  # Flavor it.
  if [[ ! -e ${EMISSARY}/.gooey ]]; then
    /bin/cp -a ${USERS_CURLY}/.encfs6.xml ${EMISSARY}/.gooey
  fi
  set +e
  mount | grep ${EMISSARY}/gooey &> /dev/null
  retval=$?
  set -e
  # Lick it.
  if [[ $retval -ne 0 ]]; then
    echo "${CRAPWORD}" | \
      encfs -S ${EMISSARY}/.gooey ${EMISSARY}/gooey
  else
    # else, already mounted; maybe the last operation failed?
    echo "Looks like gooey is already mounted."
  fi
}

function umount_curly_emissary_gooey () {
  sleep 0.1 # else umount fails.
  set +e
  fusermount -u ${EMISSARY}/gooey
  if [[ $? -ne 0 ]]; then
    echo
    echo "MEH: Could not umount the encfs. Try:"
    echo "  fuser -c ${EMISSARY}/gooey 2>&1"
    echo " and you can get the process ID with: echo \$\$"
  fi
  set -e
}

function init_travel () {

  if [[ -z ${TRAVEL_DIR} ]]; then
    echo
    echo "FAIL: TRAVEL_DIR not defined"
    exit 1
  fi

  if [[ -d ${EMISSARY} ]]; then
    echo
    echo "EMISSARY already exists at ${EMISSARY}"
    echo
    echo "You can use the existing directory or start anew."
    echo
    echo -n "Replace it and start over?: [y/N] "
    read -e YES_OR_NO
    if [[ ${YES_OR_NO^^} == "Y" ]]; then
      echo -n "Are you _absolutely_ *SURE*?: [y/N] "
      read -e YES_OR_NO
      if [[ ${YES_OR_NO^^} == "Y" ]]; then
        /bin/rm -rf ${EMISSARY}
      fi
    fi
  elif [[ -e ${EMISSARY} ]]; then
    echo
    echo "FAIL: EMISSARY exists and is not a directory: ${EMISSARY}"
    exit 1
  fi

  if [[ ! -e ${EMISSARY} ]]; then
    echo "Creating emissary at ${EMISSARY}"
    mkdir -p ${EMISSARY}
  else
    echo "Found emissary at ${EMISSARY}"
  fi

  mount_curly_emissary_gooey

  pushd ${EMISSARY}/gooey &> /dev/null

  # Remember that sync_repos.sh file you edited?
  #   PLAINTEXT_ARCHIVES
  #   ENCFS_GIT_REPOS
  #   ENCFS_GIT_ITERS

  # Skipping: PLAINTEXT_ARCHIVES (nothing to preload)

  # 2016-09-28: So, like, Bash 4 seems pretty rad, if not ((kludged)).
  #             Decades and decades of cruft! I absolutely love it!!!
  echo "Populating singular git repos..."
  for ((i = 0; i < ${#ENCFS_GIT_REPOS[@]}; i++)); do
    ENCFS_REL_PATH=$(echo ${ENCFS_GIT_REPOS[$i]} | /bin/sed s/^.//)
    if [[ ! -e "${ENCFS_REL_PATH}/.git" ]]; then
      #echo " ${ENCFS_GIT_REPOS[$i]}"
      echo " ${ENCFS_REL_PATH}"
      echo "  \$ git clone ${ENCFS_GIT_REPOS[$i]} ${ENCFS_REL_PATH}"
      git clone ${ENCFS_GIT_REPOS[$i]} ${ENCFS_REL_PATH}
    else
      echo " skipping (already got?): ${ENCFS_REL_PATH}"
    fi
  done

  echo "Populating gardened git repos..."
  for ((i = 0; i < ${#ENCFS_GIT_ITERS[@]}; i++)); do
    #echo " ${ENCFS_GIT_ITERS[$i]}"
    ENCFS_REL_PATH=$(echo ${ENCFS_GIT_ITERS[$i]} | /bin/sed s/^.//)
    echo " ${ENCFS_REL_PATH}"
    # We don't -type d so that you can use symlinks.
    while IFS= read -r -d '' fpath; do
      TARGET_PATH="${ENCFS_REL_PATH}/$(basename ${fpath})"
      if [[ -d ${fpath}/.git ]]; then
        if [[ ! -e ${TARGET_PATH}/.git ]]; then
          echo " $fpath"
          echo "  \$ git clone ${fpath} ${TARGET_PATH}"
          git clone ${fpath} ${TARGET_PATH}
        else
          echo " skipping (got .git?): +${TARGET_PATH}+"
        fi
      else
        echo " skipping (not .git/): -${TARGET_PATH}-"
      fi
    done < <(find ${ENCFS_GIT_ITERS[$i]} -maxdepth 1 ! -path . -print0)
  done

  popd &> /dev/null

  set +e
  command -v user_do_init_travel &> /dev/null
  EXIT_CODE=$?
  set -e
  if [[ ${EXIT_CODE} -eq 0 ]]; then
    user_do_init_travel
  fi

  umount_curly_emissary_gooey

} # end: init_travel

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# update_git

function update_git () {

  echo "Installing/Updating git"
  sudo add-apt-repository -y ppa:git-core/ppa
  sudo apt-get update
  sudo apt-get install -y git

} # end: update_git

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# packme

function create_umount_script () {
  echo "umount ${TRAVEL_DIR}" > ${USERS_CURLY}/cleanup.sh
  chmod 775 ${USERS_CURLY}/cleanup.sh

  # 2016-11-04: Oh, yerp.
  echo "umount ${TRAVEL_DIR}" > ${HOME}/.fries/recipe/bin/packup.sh
  chmod 775 ${HOME}/.fries/recipe/bin/packup.sh
}

# git_status_porcelain sets GIT_DIRTY_FILES_FOUND accordingly.
GIT_DIRTY_FILES_FOUND=false

function git_commit_hamster () {
  if ${HAMSTERING}; then
    HAMSTER_DB_REL="home/.local/share/hamster-applet/hamster-$(hostname).db"
    HAMSTER_DB_ABS="${USERS_CURLY}/${HAMSTER_DB_REL}"
    if [[ -e ${HAMSTER_DB_ABS} ]]; then
      echo "Checking Hamster.db..."
      git_commit_generic_file \
        "${HAMSTER_DB_ABS}" \
        "Update hamster-$(hostname).db during packme."
    else
      echo
      echo "WARNING: Skipping hamster.db: No hamster.db at:"
      echo "  ${HAMSTER_DB_ABS}"
      echo
    fi
  else
    echo "Not Hamstering."
  fi
} # end: git_commit_hamster

function git_commit_vim_spell () {
  VIM_SPELL_REL="home/.vim/spell/en.utf-8.add"
  VIM_SPELL_ABS="${USERS_CURLY}/${VIM_SPELL_REL}"
  if [[ -e ${VIM_SPELL_ABS} ]]; then
    echo "Checking Vim spell..."

    # Sort the spell file, for easy diff'ing, meld'ing, or better yet merging.
    # The .vimrc startup file will remake the .spl file when you restart Vim.
    # NOTE: cat'ing and sort'ing to the cat'ed file results in a 0-size file!?
    #       So we use an intermediate file.
    /bin/cat ${VIM_SPELL_ABS} | /usr/bin/sort > ${VIM_SPELL_ABS}.tmp
    /bin/mv -f ${VIM_SPELL_ABS}.tmp ${VIM_SPELL_ABS}

    git_commit_generic_file \
      "${VIM_SPELL_ABS}" \
      "Commit Vim spell during packme."
  else
    echo
    echo "WARNING: Skipping .vim/spell: No en.utf-8.add at:"
    echo "  ${VIM_SPELL_ABS}"
    echo
  fi
} # end: git_commit_vim_spell

function git_commit_vimprojects () {
  VIMPROJECTS_REL="home/.vim/bundle/dubs_all/.vimprojects"
  VIMPROJECTS_ABS="${USERS_CURLY}/${VIMPROJECTS_REL}"
  if [[ -e ${VIMPROJECTS_ABS} ]]; then
    echo "Checking .vimprojects..."
      git_commit_generic_file \
        "${VIMPROJECTS_ABS}" \
        "Commit .vimprojects during packme."
  else
    echo
    echo "WARNING: Skipping .vimprojects: Nothing at:"
    echo "  ${VIMPROJECTS_ABS}"
    echo
  fi
} # end: git_commit_vimprojects

function git_commit_dirty_sync_repos () {

  echo "Checking single dirty files..."
  for ((i = 0; i < ${#AUTO_GIT_ONE[@]}; i++)); do
    echo " ${AUTO_GIT_ONE[$i]}"
    DIRTY_BNAME=$(basename ${AUTO_GIT_ONE[$i]})
    git_commit_generic_file "${AUTO_GIT_ONE[$i]}" "Update ${DIRTY_BNAME}."
  done

  echo "Checking all repos' dirty files..."
  for ((i = 0; i < ${#AUTO_GIT_ALL[@]}; i++)); do
    echo " ${AUTO_GIT_ALL[$i]}"
    git_commit_all_dirty_files "${AUTO_GIT_ALL[$i]}" "Update all of ${AUTO_GIT_ALL[$i]}."
  done

} # end: git_commit_dirty_sync_repos

# *** Git: check 'n fail

function check_repos_statuses () {

  # Skipping: PLAINTEXT_ARCHIVES

  echo "Checking one-level repos..."
  for ((i = 0; i < ${#ENCFS_GIT_REPOS[@]}; i++)); do
    echo " ${ENCFS_GIT_REPOS[$i]}"
    pushd ${ENCFS_GIT_REPOS[$i]} &> /dev/null
    GREPPERS=''
    if [[ ${SKIP_THIS_DIRTY} = true && ${ENCFS_GIT_REPOS[$i]} == ${FRIES_ABS_DIRN} ]]; then
      # Tell git_status_porcelain to ignore this dirty file, travel.sh.
      THIS_SCRIPT_NAME="$(basename ${SCRIPT_ABS_PATH})"
      #GREPPERS='| grep -v " travel.sh$"'
      GREPPERS="${GREPPERS} | grep -v \" ${THIS_SCRIPT_NAME}\$\""
      GREPPERS="${GREPPERS} | grep -v \" util.sh\$\""
      echo "GREPPERS: ${GREPPERS}"
    fi
    git_status_porcelain "$(basename ${ENCFS_GIT_REPOS[$i]})"
    popd &> /dev/null
  done

  echo "Checking gardened repos..."
  for ((i = 0; i < ${#ENCFS_GIT_ITERS[@]}; i++)); do
    echo " top-level: ${ENCFS_GIT_ITERS[$i]}"
    while IFS= read -r -d '' fpath; do
      if [[ -d ${fpath}/.git ]]; then
        echo "  ${fpath}"
        pushd ${fpath} &> /dev/null
        git_status_porcelain "${fpath}"
        popd &> /dev/null
      else
        #echo "Skipping non-.git/ ${fpath}"
        :
      fi
    done < <(find ${ENCFS_GIT_ITERS[$i]} -maxdepth 1 ! -path . -print0)
  done

  git_issues_review
}

function git_issues_review {
  if ${GIT_ISSUES_DETECTED}; then
    echo "FIZATAL: One or more git issues was detected. See prior log."
    echo "Could be dirty files, untracted files, and/or behind branches."
    echo "Please fix. Or run with -D (skip all git warnings)"
    echo "            or run with -DD (skip warnings about $0)"
    echo
    echo "#################"
    echo " Give this a try "
    echo "#################"
    echo
    for ((i = 0; i < ${#GIT_ISSUES_RESOLUTIONS[@]}; i++)); do
      RESOLUTION_CMD="  ${GIT_ISSUES_RESOLUTIONS[$i]}"
      echo "${RESOLUTION_CMD}"
    done
    exit 1
  fi
}

# *** Git: pull

function git_dir_check () {
  REPO_PATH=$1
  if [[ ! -d ${REPO_PATH} ]]; then
    SKIP_GIT_PULL=true
    echo
    echo "WARNING: Not a directory: ${REPO_PATH}"
  elif [[ ! -d ${REPO_PATH}/.git ]]; then
    SKIP_GIT_PULL=true
    echo
    echo "WARNING: No .git/ found at: ${REPO_PATH}/.git"
  fi
}

function pull_git_repos () {

  if [[ $1 == 'emissary' ]]; then
    TO_EMISSARY=true
    PREFIX=""
    pushd ${EMISSARY}/gooey &> /dev/null
  elif [[ $1 == 'dev-machine' ]]; then
    TO_EMISSARY=false
    PREFIX="${EMISSARY}/gooey"
    pushd / &> /dev/null
  else
    echo "WHAT: pull_git_repos excepted argument 'emissary' or 'dev-machine'."
    exit 1
  fi

  echo "Pulling singular git repos..."
  for ((i = 0; i < ${#ENCFS_GIT_REPOS[@]}; i++)); do
    ABS_PATH="${ENCFS_GIT_REPOS[$i]}"
    ENCFS_REL_PATH=$(echo ${ABS_PATH} | /bin/sed s/^.//)
    echo " ${ENCFS_REL_PATH}"
    git_pull_hush ${PREFIX}${ABS_PATH} ${ENCFS_REL_PATH}
  done

  echo "Pulling gardened git repos..."
  for ((i = 0; i < ${#ENCFS_GIT_ITERS[@]}; i++)); do
    ABS_PATH="${ENCFS_GIT_ITERS[$i]}"
    ENCFS_REL_PATH=$(echo ${ABS_PATH} | /bin/sed s/^.//)
    echo " ${ENCFS_REL_PATH}"
    while IFS= read -r -d '' fpath; do
      TARGET_PATH="${ENCFS_REL_PATH}/$(basename ${fpath})"
      if [[ -d ${TARGET_PATH}/.git ]]; then
        echo "  $fpath"
        git_pull_hush ${PREFIX}${ABS_PATH}/$(basename ${fpath}) ${TARGET_PATH}
      else
        #echo " skipping (not .git/): $fpath"
        :
      fi
    done < <(find /${ENCFS_REL_PATH} -maxdepth 1 ! -path . -print0)
  done

  popd &> /dev/null

} # end: pull_git_repos

# *** Plaintext: archive

function make_plaintext () {

  if [[ -e ${PLAINPATH} ]]; then
    if [[ ! -d ${PLAINPATH} ]]; then
      echo
      echo "UNEXPECTED: PLAINPATH not a directory: ${PLAINPATH}"
      exit 1
    fi
    if [[ -e ${PLAIN_TBD} ]]; then
      echo
      echo "FATALLY UNEXPECTED: plain intermediate exists at"
      echo "  ${PLAIN_TBD}"
      exit 1
    fi
    # We'll delete the old archives later.
    /bin/mv ${PLAINPATH} ${PLAIN_TBD}
  fi

  mkdir -p ${PLAINPATH}
  # Plop the hostname in the packedpathwhynot.
  echo $(hostname) > ${PLAINPATH}/packered_hostname
  echo ${USER} > ${PLAINPATH}/packered_username

  echo "Packing plainly to: ${PLAINPATH}"

  for ((i = 0; i < ${#PLAINTEXT_ARCHIVES[@]}; i++)); do

    # FIXME/MAYBE: Enforce rule: Starts with leading '/'.
    ARCHIVE_SRC=${PLAINTEXT_ARCHIVES[$i]}
    ARCHIVE_NAME=$(basename ${ARCHIVE_SRC})

    # Resolve to real full path, if symlink. (I can't remember why I do this.
    # And I only ever did it for /ccp/dev/cp.)
    if [[ -h ${ARCHIVE_SRC} ]]; then
      ARCHIVE_SRC=$(readlink -f ${ARCHIVE_SRC})
    fi

    ARCHIVE_REL=$(echo ${ARCHIVE_SRC} | /bin/sed s/^.//)

    if [[ -e ${ARCHIVE_SRC} ]]; then
      echo -n " tarring: ${ARCHIVE_SRC}"
      pushd / &> /dev/null
      # Note: Missing files cause tar errors. If this happens, consider:
      #         --ignore-failed-read

# FIXME/2016-09-29: Test packing to the encfs -- you're just worried about performance, right?
#                   Because really everything should be encrypted.

      tar czf ${PLAINPATH}/${ARCHIVE_NAME}.tar.gz \
        --exclude=".~lock.*.ods#" \
        --exclude="*/TBD-*" \
         ${ARCHIVE_REL}
      popd &> /dev/null
      echo "ok"
    else
      echo
      echo "FATAL: Indicated plaintext archive not found at: ${ARCHIVE_SRC}"
      exit 1
    fi
  done

} # end: make_plaintext 

function packme () {

  #echo "Let's count"'!'
  #echo "- # of. PLAINTEXT_ARCHIVES: ${#PLAINTEXT_ARCHIVES[@]}"
  #echo "- # of.    ENCFS_GIT_REPOS: ${#ENCFS_GIT_REPOS[@]}"
  #echo "- # of.    ENCFS_GIT_ITERS: ${#ENCFS_GIT_ITERS[@]}"

  # We can be smart about certain files that change often and
  # don't need meaningful commit messages and automatically
  # commit them for the user. That's you, chum!
  git_commit_hamster
  git_commit_vim_spell
  git_commit_vimprojects

  if ! ${SKIP_DIRTY_CHECK}; then

    # Commit whatever's listed in user's privatey cfg/sync_repos.sh.
    git_commit_dirty_sync_repos

    # If any of the repos listed in repo_syncs.sh are dirty, fail
    # now and force the user to meaningfully commit those changes.
    # (This is repos like: home-fries, ${PRIVATE_REPO_}, dubsacks vim,
    #  and other personal- and work-related repositories.)
    check_repos_statuses

  fi

  if [[ ! -d ${EMISSARY} ]]; then
    echo
    echo "FAIL: No \${EMISSARY} defined."
    echo "Have you run \`$0 init_travel\`?"
    exit 1
  fi

  if ${SKIP_PULL_REPOS}; then

    # Just pull ${USERS_CURLY}.
    mount_curly_emissary_gooey
    echo "Pulling into: ${EMISSARY}/gooey${USERS_CURLY}"
    git_pull_hush ${USERS_CURLY} ${EMISSARY}/gooey${USERS_CURLY}
    umount_curly_emissary_gooey

  else

    mount_curly_emissary_gooey
    pull_git_repos 'emissary'
    umount_curly_emissary_gooey

    # Sets: ${PLAIN_TBD}
    make_plaintext

    # Call private fcns. from user's ${PRIVATE_REPO}/cfg/travel_tasks.sh
    set +e
    command -v user_do_packme &> /dev/null
    EXIT_CODE=$?
    set -e
    if [[ ${EXIT_CODE} -eq 0 ]]; then
      user_do_packme
    fi

    if [[ -d ${PLAIN_TBD} ]]; then
      /bin/rm -rf ${PLAIN_TBD}
    fi

    if ${COPY_PRIVATE_REPO_PLAIN}; then
      # BEWARE: Enabling COPY_PRIVATE_REPO_PLAIN is dangerous because it exposes
      #         the ENCFS pwd for the ${USERS_CURLY} project.
      #         I.e., this script in plain text can be read to get encfs pwd.
      echo
      echo "WARNING: Copying *unencrypted* ${USERS_CURLY}s."
      echo
      echo -n "Copying travel scripts... "
      mkdir -p ${TRAVEL_DIR}/e-scripts
      /bin/cp -aLf ${USERS_CURLY}/*.sh ${TRAVEL_DIR}/e-scripts
      /bin/cp -arf ${USERS_CURLY}/cfg ${TRAVEL_DIR}/e-scripts
    fi

  fi

  create_umount_script

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
  echo "  packup"
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

    if [[ -f ${fpath}/packered_hostname ]]; then
      PACKED_DIR_HOSTNAME=$(cat ${fpath}/packered_hostname)
    else
      echo "WARNING: Not found: ${fpath}/packered_hostname"
      PACKED_DIR_HOSTNAME=''
    fi

    if [[ -f ${fpath}/packered_username ]]; then
      PACKED_DIR_USERNAME=$(cat ${fpath}/packered_username)
    else
      echo "WARNING: Not found: ${fpath}/packered_username"
      PACKED_DIR_USERNAME=''
    fi

    # Does the unpack target already exist? If so, move it to delete it.
    TARGETPATH=${UNPACKERED_PATH}/$(basename ${fpath})
    if [[ -e ${TARGETPATH} ]]; then
      /bin/mv ${TARGETPATH} ${UNPACK_TBD}
    fi

    mkdir -p ${TARGETPATH}
    pushd ${TARGETPATH} &> /dev/null
    echo "Unpacking plain to: ${TARGETPATH}"

    # Unpack all plaintext archives.
    # And include dot-prefixed files.
    shopt -s dotglob

    for zpath in ${fpath}/*.tar.gz; do
      if [[ $(basename ${zpath}) != '*.tar.gz' ]]; then
        echo " tar xzf${TAR_VERBOSE} ${zpath}"
        tar xzf${TAR_VERBOSE} ${zpath}
      # else, No such file or directory
      fi
    done

    # Reset dotglobbing.
    shopt -u dotglob

    /bin/rm -rf ${UNPACK_TBD}

    popd &> /dev/null

  done < <(find ${EMISSARY} -maxdepth 1 -path */plain-* ! -path . ! -path */plain-*-TBD-* -print0)

} # end: unpack_plaintext_archives

function update_hamster_db () {

  if ${HAMSTERING}; then

    echo "update_hamster_db: HAMSTERING"

    set +e
    command -v hamster_love.sh > /dev/null
    RET_VAL=$?
    set -e
    if [[ ${RET_VAL} -eq 0 ]]; then

      #pushd ${USERS_CURLY}/bin &> /dev/null

      # 2016-09-28: I've used Dropbox in the past, but now I just USB stick
      # FIXME: Make USB vs. Dropbox optionable.
      #ensure_dropbox_running

      # A simple search procedure for finding the best more recent hamster.db.

      CURLY_PATH=${USERS_CURLY}/home/.local/share/hamster-applet

      CANDIDATES=()

      # Consider any hamster.dbs in ${USERS_CURLY}, now that it's been git pull'ed.
      shopt -s nullglob
      CANDIDATES+=(${USERS_CURLY}/home/.local/share/hamster-applet/hamster-*)
      shopt -u nullglob

      # Consider any hamster.dbs at the root of the travel directory.
      if [[ -n ${TRAVEL_DIR} && -d ${TRAVEL_DIR} ]]; then
        shopt -s nullglob
        CANDIDATES+=(${TRAVEL_DIR}/hamster-*)
        shopt -u nullglob
      fi

      # Consider any hamster.dbs in the dropbox.
      if [[ -d ${HOME}/Dropbox ]]; then
        while IFS= read -r -d '' file; do
          CANDIDATES+=("${file}")
        done < <(find ${HOME}/Dropbox -maxdepth 1 -type f -name 'hamster-*' -print0)
      fi

      LATEST_HAMMY=''
      for candidate in "${CANDIDATES[@]}"; do
        #echo "candidate: ${candidate}"
        if [[ -z ${LATEST_HAMMY} ]]; then
          #echo "first candidate: ${candidate}"
          LATEST_HAMMY="${candidate}"
        elif [[ ${candidate} -nt ${LATEST_HAMMY} ]]; then
          #echo "newer candidate: ${candidate}"
          LATEST_HAMMY="${candidate}"
        fi
      done
      # FIXME/2016-10-27: Weird. After an unpack at home, the older
      # hamster-larry.db was touched somehow and shows up newer than. dahfuh?
      echo "LATEST_HAMMY: ${LATEST_HAMMY}"

      if [[ -n ${LATEST_HAMMY} ]]; then
        echo
        echo "hamster love says:"
        echo
        hamster_love.sh ${LATEST_HAMMY} ${CURLY_PATH}/hamster-$(hostname).db
        echo
        echo 'hamstered!'
      else
        #echo
        echo "Skipping hamster-love: did not find appropriately most recent replacement."
        #echo
      fi

      #popd &> /dev/null

    else

      echo "WARNING: Hamster found but not hamster_love.sh"

    fi

  else

    #echo "update_hamster_db: not HAMSTERING"
    :

  fi

} # end: update_hamster_db

function unpack () {

  if [[ ! -d ${EMISSARY} ]]; then
    echo "FATAL: The emissary directory was not found at ${EMISSARY}."
    exit 1
  fi

  mkdir -p ${UNPACKERED_PATH}

  unpack_plaintext_archives

  mount_curly_emissary_gooey
  # pull_git_repos knows 'emissary' and 'dev-machine'.
  pull_git_repos 'dev-machine'
  umount_curly_emissary_gooey

  update_hamster_db

  # 2016-10-09: Save yourself a step reface automatically on unpack.
  chase_and_face

  set +e
  command -v user_do_unpack &> /dev/null
  EXIT_CODE=$?
  set -e
  if [[ ${EXIT_CODE} -eq 0 ]]; then
    user_do_unpack
  fi

  create_umount_script

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
  echo "  packup"
  echo

} # end: unpack

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# prepare_shim

function prepare_shim () {

  if [[ ! -d ${EMISSARY} ]]; then
    echo "FATAL: The emissary directory was not found at ${EMISSARY}."
    exit 1
  fi

  #echo "Making: ${USERS_CURLY}/TBD-shim"

  mkdir -p ${USERS_CURLY}/TBD-shim

  pushd ${USERS_CURLY}/TBD-shim &> /dev/null

  echo "In: ${USERS_CURLY}/TBD-shim"

  # git_check_generic_file sets ${git_result} to 0 if file is dirty.
  git_check_generic_file ${SCRIPT_ABS_PATH}

  USE_GOOEY=true
  if [[ $git_result -eq 0 ]]; then
    # travel.sh is dirty; use it and not the travel one.
    USE_GOOEY=false
    echo "Using local $(basename ${SCRIPT_ABS_PATH})"
  else
    echo "Using gooey $(basename ${SCRIPT_ABS_PATH})"
  fi

  PREFIX=""
  if ${USE_GOOEY}; then
    PREFIX="${EMISSARY}/gooey"
    mount_curly_emissary_gooey
  fi

  echo "Copying: ${PREFIX}/${SCRIPT_ABS_PATH}"

  /bin/cp -aLf ${PREFIX}/${SCRIPT_ABS_PATH} travel_shim.sh
  chmod 775 travel_shim.sh

  echo "Copying: ${PREFIX}/${FRIES_ABS_DIRN}/.fries/lib/util.sh"
  /bin/cp -aLf ${PREFIX}/${FRIES_ABS_DIRN}/.fries/lib/util.sh .

  echo "Copying: ${PREFIX}/${FRIES_ABS_DIRN}/.fries/lib/logger.sh"
  /bin/cp -aLf ${PREFIX}/${FRIES_ABS_DIRN}/.fries/lib/logger.sh .

  echo "Copying: ${PREFIX}/${FRIES_ABS_DIRN}/.fries/lib/git_util.sh"
  /bin/cp -aLf ${PREFIX}/${FRIES_ABS_DIRN}/.fries/lib/git_util.sh .

  echo "Copying: ${PREFIX}/${SYNC_REPOS_PATH}"
  /bin/cp -aLf ${PREFIX}/${SYNC_REPOS_PATH} .

  echo "Copying: ${PREFIX}/${TRAVEL_TASKS_PATH}"
  /bin/cp -aLf ${PREFIX}/${TRAVEL_TASKS_PATH} .

  if ${USE_GOOEY}; then
    umount_curly_emissary_gooey
  fi

  popd &> /dev/null

  set +e
  command -v user_do_prepare_shim &> /dev/null
  EXIT_CODE=$?
  set -e
  if [[ ${EXIT_CODE} -eq 0 ]]; then
    user_do_prepare_shim
  fi

  echo ${USERS_CURLY}

} # end: prepare_shim

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# Run the script.
soups_on $*

#echo
#echo 'Success!'

# Unhook errexit_cleanup.
trap - EXIT

exit 0

