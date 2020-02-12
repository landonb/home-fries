#!/bin/bash
# vim:tw=0:ts=2:sw=2:et:norl:
# Project: https://github.com/landonb/home-fries
# License: GPLv3

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

source_deps () {
  local curdir=$(dirname -- "${BASH_SOURCE[0]}")
  . "${curdir}/color_funcs.sh"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

echo_boxy=false

# 2016-04-26: I added empty_trashes because, while trashes were being
# created on different devices from rm_safe, rmtrash was only emptying
# the trash in the user's home.
#   Also: I find myself feeling more comfortable moving .trash to .trash-TBD
#   for a while and then deleting the .trash-TBD, just in case I don't, say,
#   in a week realize I deleted something. So here's a two-step trash:
#   if you call rmtrash once, it'll temporarily backup the .trash dirs;
#   when you call rmtrash again, it'll remove the last temporary backups.
#   In this manner, you can call rmtrash periodically, like once a month
#   or whatever, and you won't have to worry about accidentally deleting
#   things.
#   MAYBE: You could do an anacron check on the timestamp of the .trash-TBD
#          and call empty_trashes after a certain amount of time has elapsed.
empty_trashes () {
  # locate .trash | grep "\/\.trash$"
  local device_path=''
  for device_path in $( \
    mount \
      | grep \
        -e " type fuse.encfs (" \
        -e " type fuse.gocryptfs (" \
        -e " type ext4 (" \
      | awk '{print $3}' \
  ); do
    local trash_path=''
    if [[ "${device_path}" == "/" ]]; then
      trash_path="${DUBS_USE_TRASH_DIR}/.trash"
    else
      trash_path="${device_path}/.trash"
    fi
    YES_OR_NO="N"
    if [[ -d "${trash_path}" ]]; then
      # FIXME/MAYBE/LATER: Disable asking if you find this code solid enough.
      local yes_or_no=""
      echo -n "Empty all items from trash at ‘${trash_path}’? [y/n] "
      read -e yes_or_no
      if [[ ${yes_or_no^^} == "Y" ]]; then
        if [[ -d "${trash_path}-TBD" ]]; then
          /bin/rm -rf -- "${trash_path}-TBD"
        fi
        /bin/mv "${trash_path}" "${trash_path}-TBD"
        touch "${trash_path}-TBD"
        mkdir "${trash_path}"
      else
        echo "Skip! User said not to empty ‘${trash_path}’"
      fi
    else
      echo "Skip! No trash at ‘${trash_path}’"
    fi
  done
}

device_on_which_file_resides () {
  local owning_device=""
  if [[ -d "$1" || -f "$1" ]]; then
    owning_device=$(/bin/df -T "$1" | awk 'NR == 2 {print $1}')
  elif [[ -h "$1" ]]; then
    # A symbolic link, so don't use the linked-to file's location, and don't
    # die if the link is dangling (df says "No such file or directory").
    owning_device=$(/bin/df -T $(dirname -- "$1") | awk 'NR == 2 {print $1}')
  else
    owning_device=""
    # 2017-06-03: For some reason, the caller checking $? for nonzero
    # is not working, so echo empty string instead.
    #echo "ERROR: Not a directory, regular file, or symbolic link: $1."
    echo ""
    return 1
  fi
  if [[ $owning_device == "" ]]; then
    echo "WARNING: \`df\` returned empty string but file exists?: $1"
  fi
  echo $owning_device
}

device_filepath_for_file () {
  local device_path=''
  # NOTE: We could use awk to get the second line of output, e.g.,
  #   local usage_report=$(/bin/df -T "$1")
  #   device_path=$(echo "$usage_report" | awk 'NR == 2 {for(i=7;i<=NF;++i) print $i}')
  # but it seems easier to me (lb) -- or at least more intuitive -- to use tail-tr-cut.
  local usage_report=$(/bin/df -T "$1" | tail -1)
  if [[ $? -eq 0 ]]; then
    device_path=$(echo "$usage_report" | tr -s ' ' | cut -d ' ' -f7)
    # >&2 echo "usage_report: ${usage_report}"
    # >&2 echo "device_path: ${device_path}"
  else
    if [[ ! -L "$1" ]]; then
      # df didn't find file, and file not a symlink.
      echo "WARNING: Using relative path because not a file: $1"
    # else, df didn't find symlink because it points at non existant file.
    fi
    device_path=$(/bin/df -T $(dirname -- "$1") | awk 'NR == 2 {for(i=7;i<=NF;++i) print $i}')
  fi
  echo "${device_path}"
}

ensure_trashdir () {
  local device_trashdir="$1"
  local trash_device="$2"
  local ensured=1
  if [[ -z "${device_trashdir}" ]]; then
    >&2 echo "rm_safe: there is no \$device_trashdir specified"
    ensured=1  # So caller does nothing more.
    return ${ensured}
  fi
  if [[ -f "${device_trashdir}/.trash" ]]; then
    ensured=2  # So caller invokes `rm -i`.
    # MAYBE: Suppress this message, or at least don't show multiple times for
    #        same ${trash_device}, i.e., on `rm *.*` would echo for every file.
    >&2 echo "The trash is disabled on device ‘${trash_device}’"
  else
    if [[ ! -e "${device_trashdir}/.trash" ]]; then
      >&2 echo -e "No root trash found for device ‘$(fg_lavender)${trash_device}$(attr_reset)’"
      sudo_prefix=""
      if [[ "${device_trashdir}" == "/" ]]; then
        # The file being deleted lives on the root device but the default
        # trash directory is not on the same device. This could mean the
        # user has an encrypted home directory. Rather than moving files
        # to the encryted space, use an unencrypted trash location, but
        # make the user do it.
        >&2 echo
        >&2 echo "No root trash directory ‘/.trash’ found on root device ‘/’"
        >&2 echo
        >&2 echo "- Possibly because your home is encrypted, good job!"
        >&2 echo
        sudo_prefix="sudo"
        device_trashdir=''
      fi
      if $echo_boxy; then
        #    "┌──────────────────────"                "─────────────┐"
        echo "┌──────────────────────${device_trashdir//?/─}─────────────┐"
        echo "│ Create new trash at ‘${device_trashdir}/.trash’ ?   │"
        #echo -n "Please answer [y/N]: "
        echo -n "│ Create trash? [y/N]:              ${device_trashdir//?/ }│"
        echo -n -e "\r"
        echo -n "│ Create trash? [y/N]: "
      else
        >&2 echo -e "- HINT: You can skip ask with: \`$(fg_lavender)touch ${device_trashdir}/.trash$(attr_reset)\`"
        echo -n -e "rm_safe: create a new trash at ‘$(fg_lavender)${device_trashdir}/.trash$(attr_reset)’? [y/N] "
      fi
      read the_choice
      if [[ ${the_choice} != "y" && ${the_choice} != "Y" ]]; then
        ensured=3  # So caller asks to move to home-trash; or invokes `rm -i`.
        if $echo_boxy; then
          #>&2 echo "│ HINT: Avoid ask using touchfile:${device_trashdir//?/ }│"
          >&2 echo "│ HINT: You can disable this ask:   ${device_trashdir//?/ }│"
          >&2 echo "│          touch ${device_trashdir}/.trash            │"
          #>&2 echo "┏━━┛"
          >&2 echo "└──────────────────────${device_trashdir//?/─}─────────────┘"
          #>&2 echo "├──────────────────────${device_trashdir//?/─}─────────────┤"
        else
          : #>&2 echo "(Set a touchfile to disable this ask: \`touch ${device_trashdir}/.trash\`)"
        fi
      else
        # We'll set ensured=4 in the [[ -d ]], last.
        ${sudo_prefix} /bin/mkdir -p "${device_trashdir}/.trash"
        if [[ -n ${sudo_prefix} ]]; then
          sudo chgrp staff /.trash
          sudo chmod 2775 /.trash
        fi
      fi
    fi
    if [[ -d "${device_trashdir}/.trash" ]]; then
      ensured=4
    fi
  fi
  return ${ensured}
}

# FIXME/2019-12-22 23:06: Split this long fcn. (And send to own repo. home-fries-rm-safe)
# FIXME/2019-12-22 23:15: Honor `--` signalling end of options, to ignore -rf feature
#                         (i.e., treat "-rf" as filename).
rm_safe () {
  local rm_recursive_force=false
  if [[ "-rf" == "${1}" ]]; then
    >&2 echo "rm_safe: ‘/bin/rm -rf’, you got it!"
    #return 1
    shift
    #/bin/rm -rf "$*"
    rm_recursive_force=true
  fi
  if [[ ${#*} -eq 0 ]]; then
    >&2 echo "rm_safe: Missing operand(s)"
    >&2 echo "Try \`/bin/rm --help\` for more information"
    return 1
  fi
  if ${rm_recursive_force}; then
    /bin/rm -rf "$@"
    return 0
  fi
  if [[ -z "${DUBS_USE_TRASH_DIR}" ]]; then
    # We set DUBS_USE_TRASH_DIR in this file, so if here, DEV's fault.
    >&2 echo "rm_safe: No \$DUBS_USE_TRASH_DIR (‘’), what gives?"
    return 1
  fi
  # echo "DUBS_USE_TRASH_DIR: ${DUBS_USE_TRASH_DIR}"
  # The trash can way!
  # You can disable the trash by running
  #   /bin/rm -rf ~/.trash && touch ~/.trash
  # You can make the trash with rmtrash or mkdir ~/.trash,
  #   or run the command and you'll be prompted.
  # EXPLAIN/2019-12-22: (lb): Would $@ instead of $* allow us to avoid IFS?
  local old_IFS=$IFS
  IFS=$'\n'
  local fpath=""
  for fpath in $*; do
    local bname=$(basename -- "${fpath}")
    if [[ ${bname} == '.' || ${bname} == '..' ]]; then
      continue
    fi
    # A little trick to make sure to use the trash can on
    # the right device, to avoid copying files.
    # NOTE/2017-06-03: The device_on_which fcn. returns nonzero on error,
    # for reason the $? -ne 0 isn't seeing it (and I could swear that it
    # used to work!). So check for the empty string, too!
    local trash_device=$(device_on_which_file_resides "${DUBS_USE_TRASH_DIR}")
    if [[ $? -ne 0 || ${trash_device} == "" ]]; then
      >&2 echo "rm_safe: No device for supposed trash dir. ‘${DUBS_USE_TRASH_DIR}’"
      return 1
    fi
    # echo "trash_device: ${trash_device}"
    local fpath_device=$(device_on_which_file_resides "${fpath}")
    if [[ $? -ne 0 || ${fpath_device} == "" ]]; then
      if [[ ! -d "${fpath}" && ! -f "${fpath}"  &&! -h "${fpath}" ]]; then
        >&2 echo "rm_safe: Cannot remove ‘$1’: No such file or directory"
      else
        >&2 echo "rm_safe: ERROR: Could not detect device for item ‘${fpath}’"
      fi
      return 1
    fi
    # echo "fpath_device: ${fpath_device}"  # E.g., "/dev/sdb1"
    # echo "trash_device: ${trash_device}"  # E.g., "/dev/sda2"
    local device_trashdir=""
    if [[ ${trash_device} = ${fpath_device} ]]; then
      # MAYBE: Update this fcn. to support specific trash
      # directories on each device. For now you can specify
      # one specific dir for one drive (generally /home/$LOGNAME/.trash)
      # and then all other drives it's assumed to be at, e.g.,
      # /media/XXX/.trash.
      device_trashdir="${DUBS_USE_TRASH_DIR}"
    else
      device_trashdir=$(device_filepath_for_file "${fpath}")
      trash_device=${fpath_device}
    fi
    ensure_trashdir "${device_trashdir}" "${trash_device}"
    ensured=$?
    if [[ ${ensured} -eq 3 ]]; then
      # Ask if user wants to move file to home-trash instead.
      device_trashdir="${DUBS_USE_TRASH_DIR}"
      if $echo_boxy; then
        echo "┌────────────────────────${device_trashdir//?/─}───────────┐"
        echo "│ Move to main trash at ‘${device_trashdir}/.trash’ ? │"
        echo -n "│ Move item? [y/N]:                 ${device_trashdir//?/ }│"
        echo -n -e "\r"
        echo -n "│ Move item? [y/N]: "
      else
        echo -n -e "rm_safe: move item to trash at ‘$(fg_lavender)${device_trashdir}/.trash$(attr_reset)’? [y/N] "
      fi
      read the_choice
      if $echo_boxy; then
        >&2 echo "└──────────────────────${device_trashdir//?/─}─────────────┘"
      fi
      if [[ ${the_choice} != "y" && ${the_choice} != "Y" ]]; then
        ensured=2
      else
        ensured=4
      fi
    fi
    if [[ ${ensured} -eq 2 ]]; then
      # User specifically not using safety trash on this device; or for this file.
      /bin/rm -i "${fpath}"
    elif [[ ${ensured} -eq 4 ]]; then
      # ensured=4 means the trash directory exists; move 'deleted' files there.
      local fname=${bname}
      if [[ -e "${device_trashdir}/.trash/${fname}" \
         || -h "${device_trashdir}/.trash/${fname}" ]]; then
        fname="${bname}.$(date +%Y_%m_%d_%Hh%Mm%Ss_%N)"
      fi
      # If fpath is a symlink and includes a trailing slash, doing a raw mv:
      #  /bin/mv "${fpath}" "${device_trashdir}/.trash/${fname}"
      # causes the response:
      #  /bin/mv: cannot move ‘symlink/’ to
      #   ‘/path/to/.trash/symlink.2015_12_03_14h26m51s_179228194’: Not a directory
      /bin/mv "$(dirname -- "${fpath}")/${bname}" "${device_trashdir}/.trash/${fname}"
    fi
  done
  IFS=$old_IFS
}

rm_safe_deprecated () {
  /bin/mv --target-directory ${DUBS_USE_TRASH_DIR}/.trash "$*"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# Very. Destructive. Remove.

# 2019-04-08: This used to be a simple alias:
#
#   alias rmrm='/bin/rm -rf'
#
# but I (lb) want to avoid destructive commands from being
# reachable via up-arrow (because sometimes I alt-tab to
# the wrong terminal window, and then I up-arrow-and-enter
# without thinking!).

# 2019-04-08: Note: Sometimes you should run `rmrm -- *`,
#   i.e., if any filenames begin with dashes.

function rmrm () {
  /bin/rm -rf "$@"

  # Disable (by commenting) the `rmrm` command in the terminal's history.
  #
  # (lb): We could simple delete the history entry, e.g.,
  #
  #           history -d $((HISTCMD-1))
  #           # Also works?:
  #           #   history -d $(history 1)
  #           # (But using HISTCMD reads better.)
  #
  #       but we should leave a harmless breadcrumb instead.
  #
  # Add the user's command to history, but commented!
  #
  # (So that the user at least has a record of their delete,
  # but so that the user does not risk repeating the command
  # accidentally, e.g., from a blindless up-arrow-and-Enter.)
  #
  # NOTE: We cannot simply try to recreate the command, e.g.,
  #         history -s "#rmrm \"$@\""
  #       because Bash will have performed expansion, e.g.,
  #         rmrm -- "*"
  #       will be expanded to all the files in the cur. dir.
  #       So parse the last history entry (which is the current
  #       command, which Bash will replace on the `history -s`).
  history -s "#$(
    history 1 | /bin/sed -E 's/^ +[0-9]+ +[-0-9]+ +[:0-9]+ //'
  )"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

ensure_trashhome () {
  if [[ -z "${DUB_TRASHHOME}" ]]; then
    # Path is ~/.trash
    DUBS_USE_TRASH_DIR="${HOME}"
  else
    DUBS_USE_TRASH_DIR="${DUB_TRASHHOME}"
  fi
}

# Fix rm to be a respectable trashcan
#####################################

home_fries_create_aliases_trash () {
  # Remove aliases (where "Remove" is a noun, not a verb! =)
  $DUBS_TRACE && echo "Setting trashhome"
  ensure_trashhome

  alias rm='rm_safe'
  alias rmtrash='empty_trashes'
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

unset_f_trash_util () {
  unset -f source_deps

  unset -f home_fries_create_aliases_trash

  # So meta.
  unset -f unset_f_trash_util
}

main () {
  : #source_deps
  unset -f source_deps
}

main "$@"
unset -f main

