#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

_hist_util_hook() {
  local hist_file
  hist_file=$(realpath -- "${HOME}/.bash_history")

  # If ~/.bash_history is a symlink, create intermediate files and
  # alert file alongside the real history file in the same directory.
  # - Author moved ~/.bash_history to subdir and started using symlink
  #   for two reasons:
  #   - So I had option to keep history file in a Git repo and share
  #     between hosts (I don't).
  #   - Because XX-prefix files started appearing, e.g., "XXW4pWWr",
  #     which were cluttering my home directory. (And I still don't
  #     know where they come from. And that searching the web for a
  #     hint doesn't help suggests they might actually be caused by
  #     *my* (weird =) code.)
  local hist_dir
  hist_dir=$(dirname -- "${hist_file}")

  # Use intermediate files during processing.
  # - REFER: On ext4, `mv` is atomic.
  #   https://unix.stackexchange.com/questions/322038/is-mv-atomic-on-my-fs
  local temp_hist_1="${hist_dir}/.bash_history--TEMP-1"
  local temp_hist_2="${hist_dir}/.bash_history--TEMP-2"

  # ***

  # TRACK/2024-11-16: Look for and report anomalies during the run:
  # - In the past, author has witnessed some odd issues:
  #   1.) "XX"-prefixed files alongside the .bash_history file, on both
  #       macOS and Linux.
  #     - Note the author uses a symlink:
  #         ~/.bash_history -> ~/.noise/home/.bash_history
  #       and I see dozens of such files, e.g.,
  #         @macOS $ /opt/local/bin/gls -lhFa -rt
  #         ... Jul 31 01:29 XXbCjb7T
  #         ... Aug  2 18:02 XXFqsiNb
  #         ... Aug  2 18:02 XXJ3bcfg
  #         ... Aug  2 19:30 XX4msnTa
  #         ... Aug  8 20:42 XXnskXuQ
  #       - Also note I might see multiple from the same day, or
  #         none at all for stretches.
  #       - And I haven't sussed a pattern, or what causes this.
  #         - So let's TRACK!
  #   2.) A blank first line, followed by 65536 null bytes, then
  #       normal-looking history, except the first line of history
  #       is incomplete (its prefix is truncated).
  #       - Note that 65536 is 2^16...
  #       - I wonder if this issue was because overlapping runs?
  #       CPYST: You can use these commands to inspect the file:
  #         # These grep and awk commands output 0 for empty file,
  #         # or number of null bytes plus one for nonempty files.
  #         grep -cz '^' ~/.bash_history
  #         awk -v RS='\0' 'END{print NR}' ~/.bash_history
  #         # This sed command prints nothing for empty file,
  #         # or number of null bytes plus one for nonempty files.
  #         sed -nz '$=' ~/.bash_history
  #   3.) Thousands of leading blank lines.
  #       - A .bash_history_filter.awk comment says ~15,000 lines.
  # We'll check at each significant step of the operation and
  # report if we see anything strange.
  local alert_file
  alert_file="$(_hist_util_print_alert_file_path)"

  start_alert_msg() {
    if [ -s "${alert_file}" ]; then
      echo >>"${alert_file}"
    fi

    echo -e "$(date) | $@" >>"${alert_file}"
  }

  append_alert_msg() {
    echo -e "$@" >>"${alert_file}"
  }

  local prev_num_nulls=0
  local prev_num_blanks=0

  local first_step="preflight"

  # Count new XX* files / Look for nulls / Look for blanks
  check_state() {
    local step_name="$1"

    local timestamp_ref="${lock_dir}"
    if [ "${step_name}" = "${first_step}" ] && [ -e "${alert_file}" ]; then
      # On first check during cleanup operation, use alert file as the
      # reference timestamp for finding new XX* files — which mostly works
      # except if "ALERT: Lock acquire failed" was most recently writ and
      # previous operation didn't fully run. Oh well, no biggie, this
      # alerting mechanism isn't meant to be fullproof, just to mostly help.
      timestamp_ref="${alert_file}"
    fi

    # TRACK: See "1.)", above.
    local new_XX_files=""
    new_XX_files="$(find "${hist_dir}" -name 'XX*' -newer "${timestamp_ref}")"
    # Refresh the reference timestamp for the next check_state.
    touch -- "${lock_dir}"

    # TRACK: See "2.)", above.
    local num_nulls=0
    num_nulls=$(($(grep -cz '^' "${temp_hist_1}") - 1))

    # TRACK: See "3.)", above.
    # Note that `grep -c '^$' will count nulls as blank lines.
    local num_blanks=0
    num_blanks=$(grep -c '^$' "${temp_hist_1}")

    # ***

    local started_alert=false

    start_alert() {
      ! ${started_alert} || return 0

      start_alert_msg "Anomalies detected!\n- State step: ${step_name}"

      started_alert=true
    }

    if [ -n "${new_XX_files}" ]; then
      start_alert
      append_alert_msg "- New XX* files:\n$(
        echo "${new_XX_files}" | xargs ls -lhFa -rt | sed 's/^/  /g'
      )"
    fi

    if [ ${num_nulls} -gt 0 ] && [ ${num_nulls} -ne ${prev_num_nulls} ]; then
      start_alert
      append_alert_msg "- Nulls count: ${num_nulls}"
      prev_num_nulls="${num_nulls}"
    fi

    if [ ${num_blanks} -gt 0 ] && [ ${num_blanks} -ne ${prev_num_blanks} ]; then
      start_alert
      append_alert_msg "- Blank count: ${num_blanks}"
      prev_num_blanks="${num_blanks}"
    fi

  }

  # ***

  # HSTRY/2024-11-16: This hook could previously run concurrently,
  # which could cause interleaved or dropped history (though author
  # had no definitive evidence in practice, just theory).
  # - Here's the old comment:
  #     Write/append this session's history to the shared history file.
  #     (I know, possible interleaving, deal with it!
  #      ALTLY: Alternatively, we could
  #        export HISTFILE="$HOME/.bash_historys/$$"
  #      but then we're managing multiple histories, and I'm not sure
  #      the utility.)
  # But we can use `mkdir` as a mutex to guard against this.
  # - The only downside is *not* scrubbing history on a particular pass.
  #   - But this should rarely happen, and the user will likely interact
  #     with the terminal again and trigger a successful pass.
  local lock_dir="${hist_dir}/.bash_history--LOCK"

  if ! mkdir -- "${lock_dir}" 2>/dev/null; then
    start_alert_msg "ALERT: Lock acquire failed"

    return 0
  fi

  # ***

  # DUNNO/2024-11-18: The lock dir. was abandoned. Why?!
  # - MAYBE: If it happens again and you can't determine why, add kludge:
  #   - Check lock timestamp and remove dir. if older than X minutes.
  #     - But try mkdir again after rmdir so not competing with newer hook.

  clear_traps() {
    trap - EXIT
  }

  set_traps() {
    trap -- trap_exit EXIT
  }

  trap_exit() {
    clear_traps

    start_alert_msg "Trapped exit!"

    exit 0
  }

  set_traps

  # ***

  command cp -f -- "${hist_file}" "${temp_hist_1}"

  # ***

  check_state "${first_step}"

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
  #
  # DUNNO/2024-11-18: On macOS (possibly Linux, too), calling `history -a`
  # has no effect here. I.e., history file is not updated with the latest
  # command. But if we call from PROMPT_COMMAND before calling this hook,
  # then it seems to work...
  #
  #  history -a
  #
  #  check_state "After history -a"

  # TRACK/2024-11-16: Here's another *DUNNO*: Where are the null bytes
  # coming from? They're littering the start of ~/.bash_history file.
  # - MAYBE: Could this be race condition resolved by new lock mechanism?
  # SAVVY: Per `man tr`, 1-3 octal digits w/ \NNN — e.g., \0, \00, or \000.
  tr -d '\000' <"${temp_hist_1}" >"${temp_hist_2}"
  command mv -f -- "${temp_hist_2}" "${temp_hist_1}"

  check_state "After tr -d"

  # Remove any pass-insert commands, looking for a line to match:
  #   ' | pass insert -m
  # This follows a convention I use to insert passwords using the format:
  #   echo 'XXXXXXXXXXXXXXXX
  #   ....
  #   ' | pass insert -m foo/bar
  # CXREF/2024-03-17:
  #   ~/.homefries/bin/.bash_history_filter.awk
  awk -f "${HOMEFRIES_BIN:-${HOME}/.homefries/bin}/.bash_history_filter.awk" \
    "${temp_hist_1}" >"${temp_hist_2}"
  command mv -f -- "${temp_hist_2}" "${temp_hist_1}"

  check_state "After awk -f"

  # Redact anything that looks like a (modern, strong) password.
  # Use Perl, because awk does not support look-around assertions,
  # and this wild regex uses lookaheads to match 15- to 24-character
  # words that contain at least one lowercase letter, an uppercase letter,
  # and a number (so we might match non-passwords, like AcronymsBooYeah1,
  # but we also match weaker passwords that do not use punctuation).
  # REFER: `man perlrun` or `perldoc perlrun`
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
  perl -p -i -e 's/(^|\s|[^a-zA-Z0-9])(?=[^\s]*[a-z][^\s]*)(?=[^\s]*[A-Z][^\s]*)(?=[^\s]*[0-9][^\s]*)[^\s-\/]{15,24}(\s|\n|$)/\1XXXX_REDACT_XXXX\2/g' -- "${temp_hist_1}"

  check_state "After perl -p"

  command mv -f -- "${temp_hist_1}" "${hist_file}"

  # ***

  if ! rmdir -- "${lock_dir}" 2>/dev/null; then
    # Should be an unreachable path (under normal circumstances).
    start_alert_msg "GAFFE: Lock release failed"
  fi

  # Even if there are no alerts, we use the alert file as a timestamp
  # ref. for identifying new XX* files.
  touch -- "${alert_file}"

  clear_traps
}

_hist_util_print_alert_file_path() {
  local hist_file
  hist_file=$(realpath -- "${HOME}/.bash_history")

  local hist_dir
  hist_dir=$(dirname -- "${hist_file}")

  printf "%s" "${hist_dir}/.bash_history--ALERTS"
}

# SAVVY: Calling via (subprocess) inhibits job chatter, e.g.,
#   $ _hist_util_hook &
#   [1] 13014
#   $ [1]+  Done                    _hist_util_hook
_hist_util_hook_bg() {
  # Redir. output just in case the command fails.
  (_hist_util_hook >>"$(_hist_util_print_alert_file_path)" 2>&1 &)
}

home_fries_configure_history() {
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

  # SAVVY/2024-11-18: See command above: Call `history -a` here, because
  # calling from hook (whether or not the hook is backgrounded) has no
  # effect. (Though you could still <Up> to go through history and the
  # commands not appended to the history file are still accessible.)

  if [[ ! $PROMPT_COMMAND =~ "_hist_util_hook_bg" ]]; then
    PROMPT_COMMAND="history -a;_hist_util_hook_bg;${PROMPT_COMMAND}"
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
  export IGNOREEOF=9999999 # Capture and Kill Ctrl-D / ^-D / <C-d>
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
