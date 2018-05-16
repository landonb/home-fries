#!/bin/bash
# vim:tw=0:ts=2:sw=2:et:norl:

# File: trash_util.sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project Page: https://github.com/landonb/home-fries
# Summary: Generic Bash function library.
# License: GPLv3

# Usage: Source this script. Call its functions. Use its exports.

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

source_deps() {
  :
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

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
  local device_path=""
  for device_path in `mount \
    | grep \
      -e " type fuse.encfs (" \
      -e " type ext4 (" \
    | awk '{print $3}'`; \
  do
    local trash_path=""
    if [[ "${device_path}" == "/" ]]; then
      trash_path="$trashdir/.trash"
    else
      trash_path="$device_path/.trash"
    fi
    YES_OR_NO="N"
    if [[ -d $trash_path ]]; then
      # FIXME/MAYBE/LATER: Disable asking if you find this code solid enough.
      local yes_or_no=""
      echo -n "Empty trash at ‘$trash_path’? [y/n] "
      read -e yes_or_no
      if [[ ${yes_or_no^^} == "Y" ]]; then
        if [[ -d $trash_path-TBD ]]; then
          /bin/rm -rf $trash_path-TBD
        fi
        /bin/mv $trash_path $trash_path-TBD
        touch $trash_path-TBD
        mkdir $trash_path
      else
        echo "Skipping: User said not to empty ‘$trash_path’"
      fi
    else
      echo "Skipping: No trash at ‘$trash_path’"
    fi
  done
}

function device_on_which_file_resides() {
  local owning_device=""
  if [[ -d "$1" || -f "$1" ]]; then
    owning_device=$(df "$1" | awk 'NR == 2 {print $1}')
  elif [[ -h "$1" ]]; then
    # A symbolic link, so don't use the linked-to file's location, and don't
    # die if the link is dangling (df says "No such file or directory").
    owning_device=$(df $(dirname -- "$1") | awk 'NR == 2 {print $1}')
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

function device_filepath_for_file() {
  local device_path=""
  local usage_report=$(df "$1")
  if [[ $? -eq 0 ]]; then
    device_path=$(echo "$usage_report" | awk 'NR == 2 {for(i=7;i<=NF;++i) print $i}')
  else
    if [[ ! -L "$1" ]]; then
      # df didn't find file, and file not a symlink.
      echo "WARNING: Using relative path because not a file: $1"
    # else, df didn't find symlink because it points at non existant file.
    fi
    device_path=$(df $(dirname -- "$1") | awk 'NR == 2 {for(i=7;i<=NF;++i) print $i}')
  fi
  echo $device_path
}

function ensure_trashdir() {
  local device_trashdir="$1"
  local trash_device="$2"
  local ensured=0
  if [[ -f ${device_trashdir}/.trash ]]; then
    ensured=0
    # MAYBE: Suppress this message, or at least don't show multiple times
    #        for same ${trash_device}.
    echo "Trash is disabled on device ‘${trash_device}’"
  else
    if [[ ! -e ${device_trashdir}/.trash ]]; then
      echo "Trash directory not found on ‘${trash_device}’"
      sudo_prefix=""
      if [[ ${device_trashdir} == "/" ]]; then
        # The file being deleted lives on the root device but the default
        # trash directory is not on the same device. This could mean the
        # user has an encrypted home directory. Rather than moving files
        # to the encryted space, use an unencrypted trash location, but
        # make the user do it.
        echo
        echo "There's no /.trash directory for the root device."
        echo
        echo "This probably means you have an encrypted home directory."
        echo
        sudo_prefix="sudo"
      fi
      echo "Create a new trash at ‘${device_trashdir}/.trash’ ?"
      echo -n "Please answer [y/n]: "
      read the_choice
      if [[ ${the_choice} != "y" && ${the_choice} != "Y" ]]; then
        ensured=0
        echo "To suppress this message, run: touch ${device_trashdir}/.trash"
      else
        ${sudo_prefix} /bin/mkdir -p ${device_trashdir}/.trash
        if [[ -n ${sudo_prefix} ]]; then
          sudo chgrp staff /.trash
          sudo chmod 2775 /.trash
        fi
      fi
    fi
    if [[ -d ${device_trashdir}/.trash ]]; then
      ensured=1
    fi
  fi
  return ${ensured}
}

function rm_safe() {
  if [[ ${#*} -eq 0 ]]; then
    echo "rm_safe: missing operand"
    echo "Try '/bin/rm --help' for more information."
    return 1
  fi
  # The trash can way!
  # You can disable the trash by running
  #   /bin/rm -rf ~/.trash && touch ~/.trash
  # You can make the trash with rmtrash or mkdir ~/.trash,
  #   or run the command and you'll be prompted.
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
    local trash_device=$(device_on_which_file_resides "${trashdir}")
    if [[ $? -ne 0 || ${trash_device} == "" ]]; then
      echo "rm_safe(): ERROR: No device for trashdir: ${trashdir}"
      return 1
    fi
    #echo "trash_device: ${trash_device}"
    local fpath_device=$(device_on_which_file_resides "${fpath}")
    if [[ $? -ne 0 || ${fpath_device} == "" ]]; then
      if [[ ! -d "${fpath}" && ! -f "${fpath}"  &&! -h "${fpath}" ]]; then
        echo "rm_safe(): cannot remove ‘$1’: No such file or directory"
      else
        echo "rm_safe(): ERROR: No device for fpath: ${fpath}"
      fi
      return 1
    fi
    #echo "fpath_device: ${fpath_device}"
    local device_trashdir=""
    if [[ ${trash_device} = ${fpath_device} ]]; then
      # MAYBE: Update this fcn. to support specific trash
      # directories on each device. For now you can specify
      # one specific dir for one drive (generally /home/$USER/.trash)
      # and then all other drives it's assumed to be at, e.g.,
      # /media/XXX/.trash.
      device_trashdir="${trashdir}"
    else
      device_trashdir=$(device_filepath_for_file "${fpath}")
      trash_device=${fpath_device}
    fi
    ensure_trashdir "${device_trashdir}" "${trash_device}"
    if [[ $? -eq 1 ]]; then
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
    else
      # Ye olde original rm alias, now the unpreferred method.
      /bin/rm -i "${fpath}"
    fi
  done
  IFS=$old_IFS
}

function rm_safe_deprecated() {
  /bin/mv --target-directory ${trashdir}/.trash "$*"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# Fix rm to be a respectable trashcan
#####################################

home_fries_create_aliases_trash() {
  alias rm='rm_safe'
  # DANGER: Will Robinson. Be careful when you repeat yourself, it'll be gone.
  alias rmrm='/bin/rm -rf'

  # Remove aliases (where "Remove" is a noun, not a verb! =)
  $DUBS_TRACE && echo "Setting trashhome"
  if [[ -z "$DUB_TRASHHOME" ]]; then
    # Path is ~/.trash
    trashdir=$HOME
  else
    trashdir=$DUB_TRASHHOME
  fi

  # 2016-04-26: Beef up your trash takeout with Beefy Brand Disposal.
  #   Too weak: alias rmtrash='/bin/rm -rf $trashdir/.trash ; mkdir $trashdir/.trash'
  alias rmtrash='empty_trashes'
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main() {
  : #source_deps
}

main "$@"

