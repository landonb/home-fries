#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

home_fries_aliases_wire_completion () {
  home_fries_create_aliases_tab_completion
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

home_fries_create_aliases_tab_completion () {
  # Helpful Bash Tab Completion aliases.

  # For those (silly) projects that use tabs (I know!) in Bash scripts,
  # you'll want to disable tab autocompletion if you want to copy-and-paste
  # from the script to the terminal, otherwise the autocomplete responses
  # are intertwined with the paste.

  #alias tabsoff="bind 'set disable-completion on'"
  #alias tabson="bind 'set disable-completion off'"

  alias toff="bind 'set disable-completion on'"
  alias ton="bind 'set disable-completion off'"

  # 2017-08-25: You need to disable tab completion to test copy-paste
  #             ``<<-`` here-documents.
  #
  #             E.g.,
  #
  #                 bind 'set disable-completion on'
  #
  #                 cat <<-EOF
  #                 	<Tabdented>
  #                 EOF
  #
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

unset_f_alias_completion () {
  unset -f home_fries_aliases_wire_completion
  unset -f home_fries_create_aliases_tab_completion
  # So meta.
  unset -f unset_f_alias_completion
}

# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ #

main () {
  :
}

main ""
unset -f main

