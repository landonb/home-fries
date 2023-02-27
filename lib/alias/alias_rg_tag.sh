#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

check_deps () {
  # Verify sh-logger/bin/logger.sh loaded.
  check_dep '_sh_logger_log_msg'
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

home_fries_aliases_wire_rg_tag () {
  home_fries_create_aliases_rg_tag_wrap
  home_fries_create_aliases_rg_options
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# 2018-03-26: Fancy ag/rg wrapper makes jumping to search result seamless!
#
#   https://github.com/aykamko/tag
#
#   OPTIONS             Default/Choices
#   ------------------  --------------------------------------------------------
#   TAG_SEARCH_PROG     ag | rg
#   TAG_ALIAS_FILE      /tmp/tag_aliases
#   TAG_ALIAS_PREFIX    e                 [e.g., ``e1`` opens first match]
#   TAG_CMD_FMT_STRING  vim \
#                         -c 'call cursor({{.LineNumber}}, {{.ColumnNumber}})' \
#                         '{{.Filename}}'

home_fries_create_aliases_rg_tag_wrap () {
  local rg_cmd='rg'

  if ! hash ${rg_cmd} 2>/dev/null; then
    warn "ERROR: Rip Grep not found"

    return 1
  fi

  # Choices: ag, rg
  export TAG_SEARCH_PROG=${rg_cmd}

  tag () {
    local aliases="${TAG_ALIAS_FILE:-/tmp/tag_aliases}"
    /bin/rm -f "${aliases}"

    # See: ${HOME}/.gopath/bin/tag
    command tag "$@"

    # The tag command does not set $? on error, not sure why.
    [ -s "${aliases}" ] || return 1
    . "${aliases}" 2>/dev/null
  }

  # [lb] 2019-01-06: BEWARE: --no-ignore-parent can be used to ignore .ignore's
  #   up the path. I mention it because the feature is easily forgotton when one
  #   is tracking down which .ignore file is resposible for a file being ignored.
  local rg_wrap_with_options=" \
    tag \
      --smart-case \
      --hidden \
      --follow \
      --no-ignore-vcs \
      --no-ignore-parent \
      --colors 'path:fg:yellow' \
      --colors 'path:style:bold' \
      --colors 'line:fg:green' \
      --colors 'line:style:bold' \
      --colors 'match:bg:white'"

  # `rgt` will search and wire the `e*` commands to open
  #       each search result in Vim in current *terminal*.
  #
  # NOTE: So that other scripts can source this script and call `rgt`,
  #       define as a function, and not as an alias. Note the eval,
  #       which is necessary to expand ${rg_wrap_with_options}.
  eval "rgt () {
    TAG_CMD_FMT_STRING='vim -c \"call cursor({{.LineNumber}}, {{.ColumnNumber}})\" \"{{.Filename}}\"' \
      ${rg_wrap_with_options} \"\${@}\"
  }"

  # `rg` (yes, this replaces, but still uses, ripgrep's rg!)
  #      will search and wire the `e*` result commands to open
  #      each search result in a GVim window, and switch to it.

  # See the gvim-open-kindness script: It uses an environment
  # variable, $GVIM_OPEN_SERVERNAME, to indicate which GVim
  # instance to use. If you do not set or change this value, each
  # file will be opened in the same instance of GVim. Or, you
  # could set GVIM_OPEN_SERVERNAME to something different to
  # specify different instances, e.g.,
  #   $ rg `some term`
  #   foo/bar.bat
  #   [1] 1:1 some term
  #   [2] 2:1 some term
  #   $ GVIM_OPEN_SERVERNAME=gvim1 e1
  #   $ GVIM_OPEN_SERVERNAME=gvim2 e2

  # TRICK: Add this as the first line to the environ
  #        to view the command when tag is invoked:
  #   echo \"TAG_CMD_FMT_STRING=\${TAG_CMD_FMT_STRING}\" && \

  TAG_CMD_FMT_STRING=" \
    gvim-open-kindness \
      \"''\" \
      \"{{.LineNumber}}\" \
      \"{{.ColumnNumber}}\" \
      \"{{.Filename}}\" \
  "
  export TAG_CMD_FMT_STRING

  alias rg="${rg_wrap_with_options}"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

home_fries_create_aliases_rg_options () {
  # 2017-09-13: ripgrep!
  # https://github.com/BurntSushi/ripgrep
  # I'm only doing this because The Silver Searcher is identifying
  # one of my reST files as binary, and I don't care to figure out
  # why.
  #alias rg="rg --smart-case --hidden"
  # 2017-10-16: Output is difficult to read. Emulate The Silver Searcher.
  #  Colors: red, blue, green, cyan, magenta, yellow, white, black.
  #  Styles: nobold, bold, nointense, intense.
  #  Format is {type}:{attribute}:{value}.
  #    {type}: path, line, column, match.
  #    {attribute}: fg, bg style.
  #    {value} is either a color (for fg and bg) or a text style.
  claim_alias_or_warn "rgn" "\
    rg \
      --smart-case \
      --hidden \
      --colors 'path:fg:yellow' \
      --colors 'path:style:bold' \
      --colors 'line:fg:green' \
      --colors 'line:style:bold' \
      --colors 'match:bg:white' \
    "

  # DELETE/2018-01-29: This fcn., rg_peek, is not called.
  # 2018-01-29: Obsolete. In Vim, idea to `set grepprg=rg_peek`, but didn't work.
  function rg_peek () {
    rg -A 0 -B 0 --hidden --follow --max-count 1 $* 2> /dev/null
  }
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

unset_f_alias_rg_tag () {
  unset -f check_deps
  unset -f home_fries_aliases_wire_rg_tag
  unset -f home_fries_create_aliases_rg_tag_wrap
  unset -f home_fries_create_aliases_rg_options
  # So meta.
  unset -f unset_f_alias_rg_tag
}

# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ #

_homefries_warn_on_execute () {
  >&2 echo "ERROR: Trying sourcing the file instead: . $0" && exit 1
}

main () {
  check_deps
  unset -f check_deps
}

if [ "$0" = "${BASH_SOURCE[0]}" ]; then
  _homefries_warn_on_execute
else
  main "$@"
fi
unset -f _homefries_warn_on_execute
unset -f main

