#!/bin/bash
# vim:tw=0:ts=2:sw=2:et:norl:
# Project: https://github.com/landonb/home-fries
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

check_deps () {
  check_dep 'path_prefix'
  check_dep 'path_suffix'
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# MEH/2019-09-16: Some of these paths are author-specific.
# But they're also paths to commands installed via Zoidy Pooh Ansible.
# So it's not that much of a stretch to include them herein, as
# opposed to moving to the author's private startup script.

home_fries_add_to_path_sbin () {
  # No whep. 2016.04.28 and this is the first time I've seen this.
  #   $ ifconfig
  #   Command 'ifconfig' is available in '/sbin/ifconfig'
  #   The command could not be located because '/sbin' is not included in the PATH environment variable.
  #   This is most likely caused by the lack of administrative privileges associated with your user account.
  #   ifconfig: command not found
  path_suffix "/sbin"
}

home_fries_add_to_path_home_fries_lib () {
  # Make sourcing Home Fries files easy.
  path_prefix "${HOMEFRIES_DIR}/lib"
}

home_fries_add_to_path_home_fries_bin () {
  # Make Home Fries commands available.
  path_prefix "${HOMEFRIES_DIR}/bin"
}

home_fries_add_to_path_home_local_bin () {
  # Make commands installed by Zoidy Pooh et al available.
  # E.g., ~/.local/bin is where `pip install --user blah` installs.
  # And where zoidy_home-fries installs non-apt/-snap applications.
  path_prefix "${HOME}/.local/bin"
}

# ++++++++++++++++++++++++++++++ #

# MAYBE/2019-09-16: You could move these Node-, Java-/Android-, and golang-specific
# functions to new language-specific files, e.g., .homefries/lib/node_util.sh,
# and .../java_util.sh, .../golang_util.sh.

home_fries_add_to_path_home_local_node_modules_bin () {
  # Make Ansible Zoidy Pooh-installed Node/NPM executables available.
  path_prefix "${HOME}/.local/node_modules/.bin"
}

home_fries_add_to_path_java_jdk_jre () {
  local install_dir="${HOME}/.downloads"

  local jdk_dir="${install_dir}/jdk"
  if [[ -d "${jdk_dir}" ]]; then
    # FIXME/2019-09-16: Seems like a weird side-effect of updating PATH
    #                   to also be exporting other variables.
    export JAVA_HOME="${jdk_dir}"
    export JRE_HOME="${JAVA_HOME}/jre"

    path_suffix "${JAVA_HOME}/bin"
    path_suffix "${JRE_HOME}/bin"
  fi
}

home_fries_add_to_path_android_studio () {
  local install_dir="${HOME}/.downloads"

  path_suffix "${install_dir}/android-studio/bin"
  path_suffix "${install_dir}/android-sdk/platform-tools"

  # 2017-02-25: Have I been missing ANDROID_HOME for this long??
  local sdk_dir="${install_dir}/Android/Sdk"
  if [[ -d "${sdk_dir}" ]]; then
    # FIXME/2019-09-16: Seems like a weird side-effect of updating PATH
    #                   to also be exporting other variables.
    export ANDROID_HOME=${install_dir}/Android/Sdk
    path_suffix "${ANDROID_HOME}/tools"
  fi
}

home_fries_add_to_path_golang () {
  local go_dir="${HOME}/.gopath"
  if [[ -d "${go_dir}" ]]; then
    # FIXME/2019-09-16: Seems like a weird side-effect of updating PATH
    #                   to also be exporting other variables.
    export GOPATH="${go_dir}"
    # You can check GOPATH with: `go env`.

    path_prefix "${GOPATH}/bin"
    path_prefix "${GOPATH}"
  fi
}

# ++++++++++++++++++++++++++++++ #

home_fries_set_path_environ () {
  home_fries_add_to_path_home_local_node_modules_bin
  unset -f home_fries_add_to_path_home_local_node_modules_bin

  home_fries_add_to_path_java_jdk_jre
  unset -f home_fries_add_to_path_java_jdk_jre

  home_fries_add_to_path_android_studio
  unset -f home_fries_add_to_path_android_studio

  home_fries_add_to_path_golang
  unset -f home_fries_add_to_path_golang

  # ++++++++++++++++++++++++++++++ #

  home_fries_add_to_path_sbin
  unset -f home_fries_add_to_path_sbin

  home_fries_add_to_path_home_fries_lib
  unset -f home_fries_add_to_path_home_fries_lib

  home_fries_add_to_path_home_fries_bin
  unset -f home_fries_add_to_path_home_fries_bin

  home_fries_add_to_path_home_local_bin
  unset -f home_fries_add_to_path_home_local_bin
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
  check_deps
  unset -f check_deps
}

main "$@"
unset -f main

