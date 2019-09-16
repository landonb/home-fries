#!/bin/bash
# vim:tw=0:ts=2:sw=2:et:norl:

# File: paths_util.sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project Page: https://github.com/landonb/home-fries
# Summary: Generic Bash function library.
# License: GPLv3

# Usage: Source this script. Call its functions. Use its exports.

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

source_deps () {
  local curdir=$(dirname -- "${BASH_SOURCE[0]}")
  # FIXME/2018-06-04: (lb): Move device_on_which_file_resides out of trash_util.sh?
  # Load device_on_which_file_resides.
  source ${curdir}/trash_util.sh
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# *** PATH builder commands.

path_prepend_lazy () {
  # DEAD_PATH/2019-09-16: Included for posterity, but this fcn. not used.
  #                 (lb): I want to show off the ``:${}: != *:${}:*`` trick.
  echo "ERROR: path_prepend_lazy() not called"

  local path_part="$1"
  if [[ -d "${path_part}" ]]; then
    # Only bother if the path is not already indicated in PATH.
    if [[ ":${PATH}:" != *":${path_elem}:"* ]]; then
      PATH="${path_elem}:${PATH}"
      export PATH
    fi
  fi
}

path_part_remove () {
  local path_part="$1"
  # Substitute: s/^prefix://
  PATH=${PATH#${path_part}:}
  # Substitute: s/:suffix$//
  PATH=${PATH%:${path_part}}
  # Substitute: s/^sole-path$//
  if [[ ${PATH} == ${path_part} ]]; then
    PATH=""
  fi
  # Substitute: s/:inside:/:/
  PATH=${PATH/:${path_part}:/:}
  export PATH
}

path_add_part_prepend () {
  local path_part="$1"
  if [[ -d "${path_part}" ]]; then
    # Remove the path from PATH.
    path_part_remove "${path_part}"
    # Prepend the new path to PATH.
    PATH="${path_part}:${PATH}"
    # Make PATH available to subsequently executed commands.
    export PATH
  # else, do nothing if dir not found. (We could warn, but noise.)
  fi
}

path_add_part () {
  path_add_part_prepend "$1"
}

path_add_part_append () {
  local path_part="$1"
  if [[ -d "${path_part}" ]]; then
    path_part_remove "${path_part}"
    PATH="${PATH}:${path_part}"
    export PATH
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# MEH/2019-09-16: Some of these paths are author-specific.
# But they're also paths to commands installed via Zoidy Pooh.
# So it's not that much of a stretch to include them herein, as
# opposed to moving to the author's private startup script.

home_fries_set_path_environ () {
  # 2016-12-06: To avoid making PATH super long -- mostly just an annoyance
  # if you want to look at, but not a performance issue or anything -- which
  # happens if you reload your .bashrc by running /bin/bash from a terminal,
  # collect all the PATH additions and then add them only if not added.
  local path_prefix=()
  local path_suffix=()

  # Binary fries.
  path_prefix+=("${HOMEFRIES_DIR}/bin")

  # 2017-10-03: Make sourcing files easy!
  path_prefix+=("${HOMEFRIES_DIR}/lib")

  # ~/.local/bin is where, e.g., `pip install --user blah` installs.
  # And also where zoidy_home-fries installs non-apt/-snap applications.
  path_prefix+=("${HOME}/.local/bin")

  # Ansible Zoidy Pooh-installed Node/NPM executables.
  path_prefix+=("${HOME}/.local/node_modules/.bin")

  # Android Studio.
  export JAVA_HOME=${HOME}/.downloads/jdk
  export JRE_HOME=${JAVA_HOME}/jre
  if [[ -d ${JAVA_HOME} ]]; then
    path_prefix+=("${JAVA_HOME}/bin:${JRE_HOME}/bin")
  fi
  if [[ -d ${OPT_BIN}/android-studio/bin ]]; then
    path_suffix+=("${OPT_BIN}/android-studio/bin")
  fi
  if [[ -d ${OPT_BIN}/android-sdk/platform-tools ]]; then
    path_suffix+=("${OPT_BIN}/android-sdk/platform-tools")
  fi
  # 2017-02-25: Have I been missing ANDROID_HOME for this long??
  export ANDROID_HOME=${HOME}/Android/Sdk
  if [[ ":${PATH}:" != *":${ANDROID_HOME}/tools:"* ]]; then
    export PATH=${PATH}:${ANDROID_HOME}/tools
  fi

  # No whep. 2016.04.28 and this is the first time I've seen this.
  #   $ ifconfig
  #   Command 'ifconfig' is available in '/sbin/ifconfig'
  #   The command could not be located because '/sbin' is not included in the PATH environment variable.
  #   This is most likely caused by the lack of administrative privileges associated with your user account.
  #   ifconfig: command not found
  path_suffix+=("/sbin")

  # 2016-07-11: Google Go, for Google Drive `drive`.
  #
  # The latest go binary.
  if [[ -d /usr/local/go/bin ]]; then
    # 2018-12-23: Symlinking go from ~/.local/bin, so no sudo needed/not sitewide.
    # MAYBE/2018-12-23: Remove this PATH part.
    path_prefix+=("/usr/local/go/bin")
  fi
  if [[ ! -d ${HOME}/.gopath ]]; then
    # 2016-10-03: Why not?
    mkdir ${HOME}/.gopath
  fi
  if [[ -d ${HOME}/.gopath ]]; then
    # Local go projects you install.
    export GOPATH=${HOME}/.gopath
    # Check with: `go env`

    path_prefix+=("${GOPATH}:${GOPATH}/bin")
  fi

  # OpenShift Origin server.
  if [[ -d ${OPT_BIN}/openshift-origin-server ]]; then
    path_suffix+=("${OPT_BIN}/openshift-origin-server")

    # OpenShift development.
    #  https://github.com/openshift/origin/blob/master/CONTRIBUTING.adoc#develop-locally-on-your-host
    # Used in one place:
    #  /exo/clients/openshift/origin/hack/common.sh
    export OS_OUTPUT_GOPATH=1
  fi


  # 2017-04-27: Added by Bash script at https://get.rvm.io:
  #   "Add RVM to PATH for scripting. Make sure this is the last PATH variable change."
  if [[ -d ${HOME}/.rvm/bin ]]; then
    path_suffix+=("${HOME}/.rvm/bin")
  fi

  # ============================
  # Cleanup PATH before export
  # ============================

  # 2016-12-06: Check if directory in PATH or not (so PATH doesn't
  # just become really long if you run /bin/bash from a shell).
  #   https://stackoverflow.com/questions/1396066/
  #     detect-if-users-path-has-a-specific-directory-in-it
  #   "Using grep is overkill, and can cause trouble if you're searching for
  #   anything that happens to include RE metacharacters. This problem can be
  #   solved perfectly well with bash's builtin [[ command:" [... see below.]

  local path_elem=""

  for ((i = 0; i < ${#path_prefix[@]}; i++)); do
    path_elem="${path_prefix[$i]}"
    # Similar to:
    #  path_add_part "${path_elem}"
    if [[ ":${PATH}:" != *":${path_elem}:"* ]]; then
      PATH="${path_elem}:${PATH}"
    fi
  done

  for ((i = 0; i < ${#path_suffix[@]}; i++)); do
    path_elem="${path_suffix[$i]}"
    if [[ ":${PATH}:" != *":${path_elem}:"* ]]; then
      PATH="${PATH}:${path_elem}"
    fi
  done

  export PATH
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# 2018-06-04: (lb): Suddenly (not gradually), and on just one machine
# (mobile, not desktop), `man {}` is now really slow!
#
# Using \`man -d {}\`, it appears that a particular path is slow to
# search -- and man searches each path multiple times, each time
# looking for a difference man page "section". So just one slow path
# *really* slows down the whole operation.
#
# Ha! It looks like the slow path is on a CryFS device, which I set
# up recently... and I'll say that I do not recall this happeneing
# when that path was previously on an EncFS mount. (I switched to CryFS
# because the EncFS kept randomly "going away" -- remaining seemingly
# mounted, but not being accessible, like the inode was ripped away
# but the path was still referenceable.)
#
# NOTE: If we set MANPATH, than `manpath` will report:
#
#         manpath: warning: $MANPATH set, ignoring /etc/manpath.config
#
#       Which makes it seem like setting MANPATH is a bad idea.
#       But I cannot imagine `manpath` returning anything different
#       later in the session; after we setup PATH, manpath should keep
#       returning the same paths. So just take that output and edit it.
home_fries_configure_manpath () {
  # We could warn and not mangle manpath if already set, e.g.,
  #
  #   local warn_check=$(manpath 2>&1 > /dev/null)
  #   # E.g.,
  #   #   manpath: warning: $MANPATH set, ignoring|inserting /etc/manpath.config
  #   if [[ ${warn_check} != '' || -n ${MANPATH} ]]; then
  #     >&2 echo "Skipping MANPATH setup: MANPATH already set! (${warn_check})"
  #     return
  #   fi
  #
  # but I think it makes more sense to clean MANPATH and recreate from scratch.
  export MANPATH=

  local newpath=''
  candidates=$(echo $(manpath) | tr ":" "\n")
  for prospect in ${candidates}; do
    # Check the directory's owning device, e.g.,
    #
    #   $ device_on_which_file_resides /path/on/root
    #   /dev/mapper/mint--vg-root
    #
    #   $ device_on_which_file_resides /dev
    #   udev
    #
    #   $ device_on_which_file_resides /boot
    #   /dev/sda2
    #
    #   $ device_on_which_file_resides /my/private/idaho
    #   cryfs@/home/user/privates/cryfs-mount
    local whereat
    whereat="$(device_on_which_file_resides ${prospect})"
    if [[ ! $(echo ${whereat} | grep -E "^cryfs@") ]]; then
      [[ -n ${newpath} ]] && newpath="${newpath}:"
      newpath="${newpath}${prospect}"
    fi
  done

  # NOTE: If you start MANPATH with a colon ':', or end it wth one ':',
  #       then `manpath` will combine with paths from /etc/manpath.config.
  #       So make sure MANPATH does not start or end with a colon, so that
  #       it overrides `manpath`.
  export MANPATH="${newpath}"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main () {
  source_deps
  unset -f source_deps
}

main "$@"

