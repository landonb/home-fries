#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

_hist_util_hook () {
  # Write/append this session's history to the shared history file.
  # (I know, interleaving, deal with it! -Alternatively, we could
  #    export HISTFILE="$HOME/.bash_historys/$$"
  #  but then we're managing multiple histories, and I'm not sure
  #  the utility.)
  #
  # BWARE: We're not editing the session's in-memory history, so
  # one can still see unredacted passwords, etc., using either
  # `history -a <file>` or `history -w <file>` (the latter to dump
  # history since the last time it was dumped, or the latter to dump
  # all session history).
  # - We're just scrubbing the file that gets writ to user home.
  # - If you really want to clear session history (what's in memory), try:
  #     `history -c`. (Note that `reset` won't do this.)
  # - REFER: `man bash` `history`:
  #     -c     Clear the history list by deleting all the entries.
  #     -a     Append the `new' history lines (history lines entered since
  #            the beginning of the current bash session) to the history file.
  #     -r     Read the contents of the history file and use
  #            them as the current history.
  #     -w     Write the current history to the history file,
  #            overwriting the history file's contents.
  history -a

  local resolved_p=$(realpath -- "${HOME}/.bash_history")

  # Remove any pass-insert commands, looking for a line to match:
  #   ' | pass insert -m
  # This follows a convention I use to insert passwords using the format:
  #   echo 'XXXXXXXXXXXXXXXX
  #   ....
  #   ' | pass insert -m foo/bar
  # CXREF/2024-03-17:
  #   ~/.homefries/bin/.bash_history_filter.awk
  awk -f "${HOMEFRIES_BIN:-${HOME}/.homefries/bin}/.bash_history_filter.awk" \
    "${HOME}/.bash_history" > "${HOME}/.bash_history-AWKed"
  command mv -- "${HOME}/.bash_history-AWKed" "${resolved_p}"

  # Redact anything that looks like a (modern, strong) password.
  # Use Perl, because awk does not support look-around assertions,
  # and this wild regex uses lookaheads to match 15- to 24-character
  # words that contain at least one lowercase letter, an uppercase letter,
  # and a number (so we might match non-passwords, like AcronymsBooYeah1,
  # but we also match weaker passwords that do not use punctuation).
  # REFER: `perldoc perlrun`
  # CXREF: Note the `pwgen` aliases specifically omit '-' and '/' chars.
  #     ~/.homefries/lib/alias/alias_pwgen.sh
  #   - Use case, e.g.,
  #     $ echo this-file-is-NUMBER-01 \
  #     | perl -p -e \
  #       's/(^|\s)(?=[^\s]*[a-z][^\s]*)(?=[^\s]*[A-Z][^\s]*)(?=[^\s]*[0-9][^\s]*)[^\s-\/]{15,24}(\s|\n|$)/\1XXXX_REDACT_XXXX\2/g'
  #     this-file-is-NUMBER-01
  #     # And not, e.g., XXXX_REDACT_XXXX
  #   - Note that 'thisfileisNUMBER01' -> 'XXXX_REDACT_XXXX' but at least
  #     the substitution is not as aggressive as it previously was.
  perl -p -i.hist_util_hook -e 's/(^|\s|[^a-zA-Z0-9])(?=[^\s]*[a-z][^\s]*)(?=[^\s]*[A-Z][^\s]*)(?=[^\s]*[0-9][^\s]*)[^\s-\/]{15,24}(\s|\n|$)/\1XXXX_REDACT_XXXX\2/g' -- "${resolved_p}"

  command rm -f -- "${HOME}/.bash_history.hist_util_hook"
}

home_fries_configure_history () {
  # History Options
  #################

  # `history` shell variables
  # -------------------------

  # Don't put duplicate lines in the history.
  # HISTCONTROL: colon-separated list of:
  #  ignorespace, ignoredups, or ignoreboth; erasedups.
  # 2017-11-19: Disabling. Point is to retain all!
  #   export HISTCONTROL="ignoredups"

  # $HISTFILE: ~/.bash_history
  # 2019-03-15: (lb): We could use separate files, e.g.,
  #   export HISTFILE="$HOME/.bash_history_$$"
  # And then we could hook session exit, and add the
  # session's history to the shared history, e.g.,
  #   history -w
  #   cat $HISTFILE >> .bash_history
  # but I'm not sure the benefit. So I'm sticking with
  # a PROMPT_COMMAND hook just to be sure to clean passwords
  # from the history, but otherwise I'm happy if all history
  # from all sessions just gets dumped and interleaved in one
  # file.

  if [[ ! $PROMPT_COMMAND =~ "_hist_util_hook" ]]; then
    PROMPT_COMMAND="_hist_util_hook;${PROMPT_COMMAND}"
  fi

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
  #         ~/.homefries/bin/.bash_history_filter.awk
  #       for more advanced filtering.

  # 2017-11-19: More, please!
  # "When a shell with history enabled exits, the last $HISTSIZE lines
  #  are copied from the history list to $HISTFILE."
  # "The shell sets the default value to 500 after reading any startup files."
  # -1: "Numeric values less than zero result in every command being saved on
  #      the history list (there is no limit)." (Bash v4+)
  #
  # BWARE/2024-08-22: Such BUGGN: There's a weird bug on macOS that'll
  # spin your CPU and requires SIGKILL from a separate shell to recover,
  # when you use certain HISTSIZE values.
  # - E.g,. if you open a bare-bones Bash shell and export HISTSIZE=-1,
  #   then run /bin/bash again (shell within a shell), the command hangs,
  #   the CPU hits 100%, Ctrl-C fails, and you need the PID to kill it.
  #   - TRYME: Run this to see for yourself:
  #       # REFER: -i: The environment inherited by env is ignored completely.
  #       env -i /bin/bash --norc --noprofile
  #       export HISTSIZE=-1
  #       /bin/bash
  #       <HANGS!> <And runs hot>
  # - KLUGE/2024-08-23: Avoid these HISTSIZE values that hang /bin/bash on macOS:
  #     HISTSIZE=500           # Works
  #     HISTSIZE=-1            # Fails
  #     HISTSIZE=999999        # Works
  #     HISTSIZE=9999999       # Works
  #     HISTSIZE=99999999      # Works
  #     HISTSIZE=999999999     # Works
  #     HISTSIZE=1999999999    # Works
  #     HISTSIZE=2147483648    # Hangs (2^31 32-bit unsigned int max)
  #     HISTSIZE=9999999999    # Works (after earlier number hangs)
  #     HISTSIZE=99999999999   # Works (after earlier number hangs)
  #     HISTSIZE=999999999999  # Hangs
  #     HISTSIZE="$(python3 -c "print('9' * 99)")"  # Works!
  #   So we'll just stick w/ 10 million on v3.
  if "$0" --version 2>/dev/null | grep -q -e "^GNU bash, version 3\."; then
    export HISTSIZE=10000000
    # Bash v3 man: "If HISTFILESIZE is not set, no truncation is performed."
    unset -v HISTFILESIZE
  else
    # Modern Bash.
    export HISTSIZE=-1
    # Bash v5: "Non‐numeric values and numeric values less than zero inhibit
    # truncation."
    export HISTFILESIZE=-1
  fi

  # Show timestamps in bash history.
  # - REFER: See `strftime` in `man bash` for format.
  # - E.g.,: export HISTTIMEFORMAT="%d/%m/%y %T "
  # Format like Homefries' `TTT` alias.
  export HISTTIMEFORMAT="%Y-%m-%d %T "

  # Whenever displaying the prompt, write the previous line to disk.
  #  PROMPT_COMMAND="history -a"

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

  # "If the histappend shell option is enabled..., the lines are appended to
  #  the history file, otherwise the history file is overwritten."
  # - Here we enable the feature, to append, not overwrite, the history file.
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

  # ***

  # macOS starts each shell with an empty history.
  # CXREF: Related file: /etc/bashrc_Apple_Terminal
  # - Author not quite sure what /etc/bashrc_Apple_Terminal does,
  #   because when I start a new shell, it's history is empty.
  #   - When I `. /etc/bashrc_Apple_Terminal`, it creates session dumps
  #     when I exit a terminal, e.g.,
  #       $ ll ~/.bash_sessions
  #       w0t0p0:3E091BD9-899D-4B4F-A381-01942BE1F2FA.session
  #       w0t0p0:88A674F3-B546-474D-A275-AEAB48B5CC42.session
  #   - Note that TERM_SESSION_ID is unique on each shell, even if
  #     it uses the same window number (e.g., `w0t0p0`).
  #   - So maybe restore has something to do with System Resume?
  #     - Or is there some other mechanism to use the same
  #       TERM_SESSION_ID as before?
  #   - In any case, you can probably ignore the macOS session history.
  #     - Here we seed every new terminal with the global history
  #       (that _hist_util_hook (via PROMPT_COMMAND) keeps updated).
  if os_is_macos; then
    history -r
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main () {
  :
}

main "$@"
unset -f main

