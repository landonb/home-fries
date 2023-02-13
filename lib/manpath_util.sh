#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
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
      [ -n "${newpath}" ] && newpath="${newpath}:"
      newpath="${newpath}${prospect}"
    fi
  done

  local local_man_path="${HOME}/.local/share/man"
  # Doesn't hurt to add path that doesn't exist, which supports
  # user later `mr install`'ing man docs and not having to fiddle
  # with the man path. So skipping directory check:
  #   if [ -d "${local_man_path}" ] ...
  if [[ ! "${newpath}" == *${local_man_path}* ]]; then
    newpath="${newpath}:${local_man_path}"
  fi

  # NOTE: If you start MANPATH with a colon ':', or end it wth one ':',
  #       then `manpath` will combine with paths from /etc/manpath.config.
  #       So make sure MANPATH does not start or end with a colon, so that
  #       it overrides `manpath`.
  export MANPATH="${newpath}"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# *** Colorful `man`.

# Original inspiration, from 2016-08-29:
#
# - "Want colored man pages?"
#
#   http://boredzo.org/blog/archives/2016-08-15/colorized-man-pages-understood-and-customized
#
#   https://superuser.com/questions/452034/bash-colorized-man-page

# Refreshed inspiration, 2020-09-19 (mostly just notes):
#
# - "Colorize Your CLI" [2020-07-26] DanySpin97
#
#   https://danyspin97.org/blog/colorize-your-cli/#man
#
# - First, remember that `home_fries_wire_export_less` in file_util.sh sets:
#
#     export LESS="-iMx2"
#
#   But this article simply sets:
#
#     export LESS="--RAW-CONTROL-CHARS"
#
#   - However, when I added the "-R" flag and test, I did not see
#     any change from the solution I already had plubmed.
#
#     E.g., when I add the "-R" flag, then
#
#       export LESS="-iMRx2"
#
#     draws man pages no different than:
#
#       export LESS="-iMx2"
#
#   - Says `man less`:
#
#       -R or --RAW-CONTROL-CHARS
#
#         Like -r, but only ANSI "color" escape sequences are output
#         in "raw" form.
#
#     Compared to the -r option, ANSI escapes do not move the cursor,
#     so artifacts like line-wrapping too early should not happen.
#     (But, like I said, without with -r or -R, I see color,
#     and no weird line wrapping.)
#
# - The article also moves the variables to a separate file and just
#   sources that. Which doesn't seem like a bad idea. Unless the
#   variables might interfere with other apps that use `less`?
#
#   But if we source a settings file before every `man` call, it
#   means the user can tweak `man` colors without reloading Bash.
#   So we'll give it a shot. Seems more robust.
#
#   See:
#
#     ~/.config/less/termcap
#
#     ~/.homefries/lib/less_termcap.sh

# Note: We don't need to explicitly set the "loaded" indicator,
#       but by doing so, the user can source this file again to
#       to reset the man mechanism (MANPATH).
#
_LOADED_HF_MANPATH_UTIL_MAN=false

home_fries_colorman () {
  # This is used if a less/termcap or less_termcap.sh file not found.
  env \
    LESS_TERMCAP_mb="$(printf "\e[1;31m")" \
    LESS_TERMCAP_md="$(printf "\e[1;31m")" \
    LESS_TERMCAP_me="$(printf "\e[0m")" \
    LESS_TERMCAP_se="$(printf "\e[0m")" \
    LESS_TERMCAP_so="$(printf "\e[1;44;33m")" \
    LESS_TERMCAP_ue="$(printf "\e[0m")" \
    LESS_TERMCAP_us="$(printf "\e[1;32m")" \
    /usr/bin/man "$@"
}

# `man` lazy-loader. Sneaky sneaky. Shaves tenth sec. or so off session start.
man () {
  ! ${_LOADED_HF_MANPATH_UTIL_MAN:-false} &&
    home_fries_configure_manpath
  _LOADED_HF_MANPATH_UTIL_MAN=true

  local try_path_1="${HOME}/.config/less/termcap"
  local try_path_2="${HOMEFRIES_LIB:-${HOME}/.homefries/lib}/less_termcap.sh"
  local loaded_less_termcap=false

  if [ -f "${try_path_1}" ]; then
    # QUESTION/2020-09-19: Now that we persist the LESS_TERMCAP_*
    # variables (and don't just set them for the `man` command
    # being called), will it affect any other commands (like `less`)?
    . "${try_path_1}"
    loaded_less_termcap=true
  elif [ -f "${try_path_2}" ]; then
    . "${try_path_2}"
    loaded_less_termcap=true
  fi

  if ${loaded_less_termcap}; then
    /usr/bin/man "$@"
  else
    home_fries_colorman "$@"
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main () {
  check_deps
  unset -f check_deps
}

main "$@"
unset -f main

