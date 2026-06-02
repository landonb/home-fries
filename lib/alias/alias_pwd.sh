#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=bash
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# [Author] uses `pwd` frequently: to see where I am;
# or to copy the current path to paste somewhere (in
# notes, in a Save dialog, etc.).
# - HSTRY: I originally made a simple `alias p=pwd`.
#   - But I found myself double-click-copying a lot,
#     so eventually I had it update the clipboard.
#   - I also found myself often shortening the path
#     with "~", so ultimately I made an option to
#     replace the user home prefix with "~".
# - UCASE(tilde): The author usually wants the tilde
#   path (it's shorter, and it works across hosts,
#   regardless of the home directory path or username
#   (i.e., /home/user vs. /User/home)).
# - UCASE(full): At least for the macOS Save dialog,
#   you'll want the full path (if you paste a tilde
#   path, the macOS input shows "/~/path").
#   - ASIDE: In the macOS Save dialog, if the file list
#     has focus, pressing "/" key (and only that key,
#     AFAIK; and pasting doesn't work) prompts you to
#     enter a path to the target directory, to which
#     you can paste a full path.

home_fries_aliases_wire_pwd() {
  claim_alias_or_warn "P" "pwd | _hf_clip_echo"

  claim_alias_or_warn "p" 'pwd | tilde_for_home'

  # SAVVY/2022-11-04: Clip curr. dir. w/ tilde prefix.
  # - Prints current directory to stdout and copies to
  #   clipboard, after replacing leading home path with
  #   tilde.

  # REFER: On macOS, /usr/bin/pp is a Perl tool,
  # pp - PAR Packager — sorry if you use this, but
  # I don't so I'm gonna steal its coveted two-char
  # command name.
  #   @macOS $ fdp -V
  #   fdp - graphviz version 9.0.0 (20230911.1827)
  local force=false
  if [ "$(type -t /usr/bin/pp)" = "file" ] &&
    pp --version | head -1 | grep -q -e "^PAR Packager" \
    ; then

    force=true
  fi
  claim_alias_or_warn "pp" "_hf_realpath_logical_tilded_clip_echo" ${force}
  claim_alias_or_warn "pP" "_hf_realpath_logical_clip_echo" ${force}
}

home_fries_aliases_wire_rp() {
  # Copy realpath output, but don't sub. tilde for HOME.
  # - Note the final capital "P" in `rpP`, which matches
  #   the `P` alias above that copies pwd output without
  #   sub'ing tilde for HOME.
  claim_alias_or_warn "rpP" "_hf_realpath_clip_echo"

  # The main, most often-used realpath-related clipboard
  # command, `rp` substitutes "~" for the user home path
  # prefix, and copies and prints the result.
  # - AHINT: If you can remember the `rp` command, you'll
  #   be able to figure out `rpp` and `rpP`.
  #   - E.g., in author's DepoXy on Debian 13 environment,
  #     `rp<Tab>` shows 13 completions, but only two of
  #     them are three characters, `rpp` and `rpP`. (So if
  #     you've forgotten 'em, type `rp<Tab>` and you'll
  #     figure it out).
  claim_alias_or_warn "rp" "_hf_realpath_tilded_clip_echo"

  # Special `rp --no-symlinks` variant.
  claim_alias_or_warn "rpp" "_hf_realpath_strip_tilded_clip_echo"
}

# ***

# Print fullpath to current directory or arg, but without
# resolving symlinks.
# - So work like `realpath -s` works on full paths,
#   but do the same for relative paths.
# - Akin to `pwd -L`.
#
# E.g., consider current directory entered via symlink:
#
#   $ pwd -L
#   /symlink/path
#   $ pwd -P
#   /actual/path
#   $ realpath -s .
#   /actual/path
#   $ realpath "$(pwd -L)"
#   /actual/path
#   $ realpath -s "$(pwd -L)"
#   /symlink/path
#
# - Such that our `rp` alias resolves the symlinks,
#   but our `pp` alias will not, e.g.,:
#
#   $ rp .
#   /actual/path
#   $ pp .
#   /symlink/path

_hf_realpath_logical_clip_echo() {
  _hf_realpath_logical_tilded "$@" | _hf_clip_echo
}

_hf_realpath_logical_tilded_clip_echo() {
  _hf_realpath_logical_tilded "$@" | tilde_for_home | _hf_clip_echo
}

_hf_realpath_logical_tilded() {
  if [ $# -eq 0 ]; then
    pwd
  else
    for path in "$@"; do
      local basedir="${path}"
      local filename=""
      if [ ! -d "${path}" ]; then
        basedir="$(dirname -- "${path}")"
        filename="/$(basename -- "${path}")"
      fi
      if [ -d "${basedir}" ]; then
        echo "$(cd -- "${basedir}" && pwd -L)${filename}"
      else
        echo "$(pwd -L)/${basedir}${filename}"
      fi
    done
  fi
}

# ***

# `realpath` clipper.
_hf_realpath_clip_echo() {
  if [ $# -eq 0 ]; then
    # Don't see why not, vs.:
    #   realpath: missing operand
    #   Try 'realpath --help' for more information.
    set -- "."
  fi

  realpath "$@" | _hf_clip_echo
}

# tilde'd `realpath` clipper.
_hf_realpath_tilded_clip_echo() {
  if [ $# -eq 0 ]; then
    set -- "."
  fi

  realpath "$@" | tilde_for_home | _hf_clip_echo
}

# -s|--strip|--no-symlinks: don't expand symlinks
_hf_realpath_strip_tilded_clip_echo() {
  if [ $# -eq 0 ]; then
    set -- "."
  fi

  realpath --no-symlinks "$@" | tilde_for_home | _hf_clip_echo
}

# ***

# HSTRY/2026-06-02: Upstreamed to logger.sh:
#   sed -E "s#^${HOME}(/|$)#~\1#"
# - Cxref: logger.sh sourced by: source_homefries_libs_all
tilde_for_home() { _sh_tilde_for_home "$@"; }

# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ #

if [ "$0" = "${BASH_SOURCE[0]}" ]; then
  >&2 echo "ERROR: Trying sourcing the file instead: . $0" && exit 1
fi
