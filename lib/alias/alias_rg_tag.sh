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
  local engine='rg'

  if ! hash ${engine} 2>/dev/null; then
    warn "No Silver Searcher or Rip Grep found [${engine}]"
    return 1
  fi

  # Choices: ag, rg
  export TAG_SEARCH_PROG=${engine}

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
      --colors 'path:fg:yellow' \
      --colors 'path:style:bold' \
      --colors 'line:fg:green' \
      --colors 'line:style:bold' \
      --colors 'match:bg:white' \
  "

  # rgt -- Open search result in Vim in current terminal.
  alias rgt="\
    TAG_CMD_FMT_STRING=' \
      vim -c \"call cursor({{.LineNumber}}, {{.ColumnNumber}})\" \"{{.Filename}}\"
    ' \
    ${rg_wrap_with_options} \
  "

  # rgg -- Open search result in specific Gvim window, and switch to it.
  # FIXME/2018-03-26: The servername, SAMPI, is hardcoded: Make Home Fries $var.
  # NOTE: (lb): I could not get "-c 'call cursor()" to work in same call as
  #       --remote-silent, so split into two calls, latter using --remote-send.
  #
  # WEIRD/2020-04-02 22:58: Getting this warning on e* command:
  #                           XGetWindowProperty[_NET_WM_DESKTOP] failed (code=1)
  #                         It's the final call:
  #                           xdotool search --name SAMPI windowactivate
  #                         except without that, Gvim not foregrounded!
  #                         Same happens with hex, e.g.,:
  #                           xdotool windowactivate 0x03e00003
  #                           # Switches to Vim but outputs:
  #                           XGetWindowProperty[_NET_WM_DESKTOP] failed (code=1)
  #                         Can we just ignore it?
  #
  # WEIRD/2020-04-02 23:08: `rgt` works smoothly. `rgg` switches to Gvim and then
  # you see a <blip>, not sure if a bell is being rung or what, but Vim not alerts!

# FIXME/2020-09-26 01:38: macOS: Probably does not support xdotool (search all Hfries)
  alias rgg="\
    TAG_CMD_FMT_STRING=' \
      true \
      && gvim --servername SAMPI --remote-silent \"{{.Filename}}\" \
      && gvim --servername SAMPI --remote-send \
        \"<ESC>:call cursor({{.LineNumber}}, {{.ColumnNumber}})<CR>\" \
      && xdotool search --name SAMPI windowactivate &> /dev/null \
    ' \
    ${rg_wrap_with_options} \
  "
  alias rg="rgg"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

home_fries_create_aliases_rg_options () {
  # 2017-09-13: ripgrep!
  # https://github.com/BurntSushi/ripgrep
  # I'm only doing this because The Silver Searcher is identifying
  # one of my reST files as binary, and I don't care to figure out
  # why.
  #alias rg='rg --smart-case --hidden'
  # 2017-10-16: Output is difficult to read. Emulate The Silver Searcher.
  #  Colors: red, blue, green, cyan, magenta, yellow, white, black.
  #  Styles: nobold, bold, nointense, intense.
  #  Format is {type}:{attribute}:{value}.
  #    {type}: path, line, column, match.
  #    {attribute}: fg, bg style.
  #    {value} is either a color (for fg and bg) or a text style.
  alias rgn="\
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

main () {
  check_deps
  unset -f check_deps
}

main "$@"
unset -f main

