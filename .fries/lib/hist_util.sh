#!/bin/bash
# vim:tw=0:ts=2:sw=2:et:norl:

# File: hist_util.sh
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

home_fries_configure_history() {
  # History Options
  #################

  # `history` shell variables
  # -------------------------

  # Don't put duplicate lines in the history.
  # HISTCONTROL: colon-separated list of:
  #  ignorespace, ignoredups, or ignoreboth; erasedups.
  # 2017-11-19: Disabling. Point is to retain all!
  #export HISTCONTROL="ignoredups"

  # $HISTFILE: ~/.bash_history

  # 2017-02-20: HISTFILESIZE defaults to 500...
  export HISTFILESIZE=-1

  # HISTIGNORE: A colon-separated list of patterns.
  # - Normal shell pattern matching characters.
  # - `&' matches the previous history line.
  # - The second and subsequent lines of a multi-line compound
  #   command are not tested, but are added regardless. [Ha ha!]
  # 2017-11-19: From Someone Else's Dotfiles, I'm supposing:
  #  # Ignore some controlling instructions.
  #  export HISTIGNORE="[   ]*:&:bg:fg:exit"
  # 2018-04-07: Ignore commands that start with whitespace:
  #  export HISTIGNORE="[ \t]*"
  # 2018-04-07: Ignore `pass insert` commands:
  #  export HISTIGNORE="pass insert *"
  # 2018-04-07: Ignore all `pass` commands (don't bleed names).
  # Note that we use 2 patterns because latter pattern doesn't not match
  # space, because the '*' is a glob match (1+ chars), and not a reg ex
  # (0+ of chars inside brackets). However! That means "[ \t]*pass *"
  # matches, e.g., " echo pass word". Ug... I guess we'll just do the
  # basic ignore; so be careful to not prepend your `pass` commands with
  # whitespace.
  #  export HISTIGNORE="pass *:[ \t]*pass *"
  # 2018-08-15: Why bother anymore??
  #export HISTIGNORE="pass *"
  # NOTE: HISTIGNORE only matches against first line of command.
  #       So if you have, e.g., a multi-line pass insert command:
  #         echo '<password>
  #         YYYY-MM-DD / https://<domain> / <login> / <password> / <notes>
  #         ' | pass insert -m 'foo/bar'
  #       You gotta do something more sophisticated. E.g., post-process
  #       the history file before it hits your dotfiles repo. See:
  #         ~/.fries/bin/.bash_history_filter.awk
  #       for more advanced filtering.

  # 2017-11-19: More, please!
  # "When a shell with history enabled exits, the last $HISTSIZE lines
  #  are copied from the history list to $HISTFILE."
  # "The shell sets the default value to 500 after reading any startup files."
  export HISTSIZE=-1

  # Show timestamps in bash history.
  #  See `strftime` in `man bash` for format.
  #export HISTTIMEFORMAT="%d/%m/%y %T "
  # 2017-11-19: How did I overlook this for so long? Should be like `TTT`.
  export HISTTIMEFORMAT="%Y-%m-%d %T "

  # Whenever displaying the prompt, write the previous line to disk.
  # export PROMPT_COMMAND="history -a"

  # Related shell options: cmdhist, lithist.

  # `history` shell varible options
  # -------------------------------

  # 2016-09-24: Seriously? This is what's been hounding me forever?
  #             So that, e.g., `echo "!X"` works.
  #               $ set -o histexpand
  #               $ echo "!X"
  #               bash: !X: event not found
  #               $ echo !b
  #               echo bash
  #               bash
  #               $ set +o histexpand
  #               $ echo "!X"
  #               !X
  #             And I _rarely_ use !n to repeat a history command.
  #             Usually, I just up-arrow.
  #             Recently, I've been Ctrl-R'ing.
  #             But I'm always annoyed when a bang in a paragraph
  #             *confuses* the shell.
  # histexpand/-H: "Enable ! style history substitution.
  #                 On by default when the shell is interactive."
  set +o histexpand

  # Also: `set +/-history`. On by default.

  # `history` "optional shell behavior ... settings"
  # ------------------------------------------------

  # 2017-11-19: Bastards!
  # "If the histappend shell option is enabled..., the lines are appended to
  #  the history file, otherwise the history file is overwritten."
  # So make bash append rather than overwrite the history on disk.
  # 2017-11-19/MAYBE: The history file will only continue to grow! Watch it?
  shopt -s histappend

  # histreedit: "If set, and readline is being used, a user is given
  #  the opportunity to re-edit a failed history substitution."

  # histverify: Documented, but not part of my Bash! [2017-11-19]
  # "If set, and readline is being used, the results of history
  #  substitution are not immediately passed to the shell parser.
  #  Instead, the resulting line is loaded into the readline editing
  #  buffer, allowing further modification."

  #########################

  # 2015.08.30: Well, this is new: [lb] seeing Ctrl-D'ing to get outta
  #             Python propagating to Bash, which didn't usedta happen.
  #             So now force user to type `exit` to close Bash terminal.
  # 2016-09-23: Title better: Prevent Ctrl-D from exiting shell.
  # When you Ctrl-D, you'll see: `Use "exit" to leave the shell.`
  export IGNOREEOF=9999999  # Capture and Kill Ctrl-D / ^-D / <C-d>
  # 2017-11-19: See also `set +ignoreeof` but that sets IGNOREEOF=10. #toofew
  # `set +o ignoreeof` clears IGNOREEOF; `set -o ignoreeof` sets IGNOREEOF=10.
  # 2018-05-28: See also: Ctrl-Shift-Q, to close mate-terminal window.
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main() {
  : #source_deps
}

main "$@"

