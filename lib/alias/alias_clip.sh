#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma <https://tallybark.com/>
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# USAGE: echo "foo" | clip
#
# - Copies whatever is on stdin to the clipboard, and echoes it.
home_fries_aliases_wire_clip() {
  claim_alias_or_warn "clip" "_hf_clip_echo"
}

# Strips and clips stdin.
_hf_clip() {
  tr -d "\n" | _hf_clip_raw
}

# USYNC: Similar clipboard if-else branching:
# ~/.kit/sh/home-fries/bin/clear
_hf_clip_raw() {
  if os_is_macos && command -v pbcopy >/dev/null; then
    pbcopy
  elif [ -n "${WAYLAND_DISPLAY}" ] && command -v wl-copy >/dev/null; then
    # CALSO: wl-copy --trim-newline
    wl-copy
  elif [ -n "${DISPLAY}" ] && command -v xclip >/dev/null; then
    # Aka: xclip -selection clip
    xclip -selection c
  elif command -v wl-copy >/dev/null; then
    # E.g.,
    #   $ host ${SSH_CONNECTION%% *}
    #   123.1.168.192.in-addr.arpa domain name pointer host.lan.
    # - THANX:
    #   https://askubuntu.com/questions/421033/
    #     determining-the-name-of-the-host-currently-connected-via-ssh
    # INERT/FTREQ: Pass originating host as SSH variable, so you can
    # detect SSH from host1 → host2 → host1, because wl-copy works
    # on host1, even though connected through intermediate remote.
    # - Though not a very likely use case, but we could support it.
    # - For now, this check won't detect that case; it will only
    #   detected SSH from host1 → host1.
    local connected_from
    connected_from="$(
      host ${SSH_CONNECTION%% *} | sed 's/^.* domain name pointer \(.*\)\.lan\.$/\1/'
    )"
    # BWARE: wl-copy hangs when called over SSH from separate host.
    # - When SSH'd to same machine as desktop host, wl-copy works (you
    #   can copy to or clear it).
    # - REFER: But when SSH'd to a difference machine from the desktop
    #   host, wl-copy hangs (until interrupted), which is a known issue:
    #     https://github.com/bugaevc/wl-clipboard/pull/154
    #     - BEGET: https://www.google.com/search?q=wl-copy+hangs+over+ssh
    #   - One suggestion is using 2>/dev/null, but that doesn't work.
    if [ "${connected_from}" = "$(hostname)" ]; then
      wl-copy
    else
      # else, over SSH, so do nothing, you're not in control of that
      # host's clipboard.
      # - ALTLY: We could tell user what they're trying to do is not
      #   supported... but, uh... should we?
      >&2 echo "ERROR: Cannot access clipboard on this host"
    fi
  fi
}

# Echo-clip.
_hf_clip_echo() {
  # SAVVY: >(Bashism)
  tee >(_hf_clip)
}

# ***

# UCASE: Not necessary for homebrew, but allows this script
# to be reused by GNOME Keyshort Shortcuts accelerator.
os_is_macos() {
  [ "$(uname)" = "Darwin" ]
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# Called by `home_fries_bashrc_cleanup`
unset_f_alias_clip() {
  unset -f home_fries_aliases_wire_clip
  # So meta.
  unset -f unset_f_alias_clip
}

# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ #

if [ "$0" = "${BASH_SOURCE[0]}" ]; then
  >&2 echo "ERROR: Trying sourcing the file instead: . $0" && exit 1
fi
