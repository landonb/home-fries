#!/bin/bash
# vim:tw=0:ts=2:sw=2:et:norl:
# Project: https://github.com/landonb/home-fries
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

check_deps () {
  # Verify sh-rm_safe/bin/path_device loaded (on PATH).
  check_dep 'path_device'
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
    #   $ path_device /path/on/root
    #   /dev/mapper/mint--vg-root
    #
    #   $ path_device /dev
    #   udev
    #
    #   $ path_device /boot
    #   /dev/sda2
    #
    #   $ path_device /my/private/idaho
    #   cryfs@/home/user/privates/cryfs-mount
    local whereat
    whereat="$(path_device ${prospect})"
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

