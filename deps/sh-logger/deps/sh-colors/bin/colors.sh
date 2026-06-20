#!/bin/sh
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Project: https://github.com/landonb/sh-colors#💥
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# USAGE: Source this file. Call its functions, e.g., in `echo -e` calls,
# such as:
#
#   echo -e "$(fg_pink)Hello!$(attr_reset) $(attr_underlined)Goodbye!$(attr_reset)"

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# REFER:
# - "Bash tips: Colors and formatting (ANSI/VT100 Control sequences)"
#   https://misc.flogisoft.com/bash/tip_colors_and_formatting

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# *** Color On/Off controls.

# USAGE: To deliberately control whether to color or not, set:
#
#   SHCOLORS_OFF=false|true
#
#  otherwise, [ -t 1 ] is used when this script is sourced to
#  determine if color should be used.
#
#  (More specifically, [ -t 1 ] determines whether to inject
#   ANSI control codes into the output or not, based on whether
#   stdout (1) is attached to a terminal.)

# Set color flag globally, because _shcol_no_col is called in a pipeline
# from within this script, e.g., `_shcol_no_col && return`. And [ -t 1 ]
# won't work therein (will always be falsey).
if [ -z ${SHCOLORS_OFF+x} ]; then
  [ -t 0 ] && [ -t 1 ] &&
    SHCOLORS_OFF=false ||
    SHCOLORS_OFF=true
fi

_shcol_no_col() {
  if [ -z ${SHCOLORS_OFF+x} ]; then
    # Note that in a pipeline, e.g., `_shcol_no_col && return`, [ -t 1 ]
    # will always be false, so generally SHCOLORS_OFF will be set,
    # and this check won't be called. But it's here just in case.
    ! [ -t 1 ]
  else
    ${SHCOLORS_OFF}
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# REFER: In Bash, the escape sequences \e, \033 and \x1b can be used
#        interchangeably, but \033 is the more portable of the three.
# [DUNNO/2020-09-18: If they're interchangeable, how is one more portable?
#  I think years ago I had issues using \e but I didn't document the issue.]
# - The `\e` is a character escape sequence; the other two are Oct.
#   and Hex. reps., respectively. (See also ^[, i.e., you can hit Ctrl-[
#   to send ESCAPE sequence. And also 27, the decimal equivalent.)
# - Because the `\e` representation feels more Bashy (and probably is
#   less universal), we'll use either the octal or hexadecimal format.
#   - Let's use the octal format.
#     - A search on "\033" returns 255,000 hits,
#     - A search on "\x1b" returns  74,100 results.
#     - (And on "\e", 4,970,000 results, but that includes
#       "\E NO. 316 - City of Drain" in the top 100 results
#       (AN ORDINANCE FIXING ELECTRICAL RATES).)
#     - Not that we should not always be sheep and follow the
#       masses, but we gotta decide somehow.
# tl,dr: Prefer `\033` below, not `\e` or `\x1b`.
# - And let's not talk about double- versus single-quotes. Single
#   is technically more responsible to signal that you want nothing
#   interpolated, but double looks nicer, IMHO. Though single is
#   easier to type. Such difficult decisions! (And not that shfmt
#   does not enforce '' vs. "".)

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# REFER: Wrap escape sequences with \001...\002 or \[...\] to avoid
# column width issue when SSH'd into a terminal.
#
# - E.g., when author uses SSH to connect to a remote host, if I use
#   <Up> to cycle through Bash history, when it populates the prompt
#   with a long command, the prompt becomes misaligned.
#
#   For instance, assume that I ran these commands in order:
#
#     echo foo
#     echo Lorem ipsum dolor sit amet, consectetur adipisicing elit
#     echo bar
#
#   And then, on a fresh prompt, I cycle through Bash history.
#
#   The issue is that, after recalling the long command, the start
#   of the long command is left on the command line, and the cursor
#   is shifted rightward, like this:
#
#     user@host:dir $ <Up>
#     user@host:dir $ echo bar <Up>
#     user@host:dir $ echo Lorem ipsum dolor sit amet, consectetur adipisicing elit<Up>
#     user@host:dir $ echo Lorem ipsum dolor sit ametecho foo
#
#   Where the start of the prompt is now here .......↑
#
#   And then clearing the prompt doesn't clear all the way to the "$"
#   symbol (where <Ctrl-U> clears all text to the left of the cursor):
#
#     user@host:dir $ echo Lorem ipsum dolor sit ametecho foo<Ctrl-U>
#     user@host:dir $ echo Lorem ipsum dolor sit amet
#
#   Where the cursor is now here ....................↑
#
#   even though the current command is technically cleared (such that
#   the "echo Lorem ipsum dolor sit amet" artifact isn't part of the
#   current command, it's just cruft that wasn't properly cleared).
#
# This problem doesn't seem to affect a local shell, but it does affect
# an SSH session, seemingly because the terminal does not correctly
# identify widths, e.g., it misinterprets escape sequences in the PS1
# prompt ("user@host:dir $") as having actual width.
#
# - Fortunately, we can avoid this issue by wrapping escape sequences
#   with either \001 and \002, or \[ and \].
#
# - THANX: I found the answer in this thread, although I haven't found
#   the canonical documentation for using \001..\002 or \[..\]:
#     https://unix.stackexchange.com/questions/105958/terminal-prompt-not-wrapping-correctly
#   - And while I haven't found a difference between \001..\002 or \[..\],
#     one less-upvoted (buried) comment says to use \001..\002 not \[..\].
#   - BEGET:
#     https://www.google.com/search?q=ps1+prompt+ssh+not+aligned
#
# - For example, this simple underline sequence causes the misalignment
#   issue:
#
#     attr_underline() { printf "\033[4m"; }
#
#   But then any one of these three alternatives that use the wrapper
#   sequence avoid the misalignment issue:
#
#     attr_underline() { printf "\[\033[4m\]"; }
#     attr_underline() { printf "\001\033[4m\002"; }
#     attr_underline() { printf "\001$(tput smul)\002"; }
#
# - As an aside, note that \[...\] is not the same byte sequence
#   as \001...\002:
#
#     $ printf "\001\002" | hd
#     00000000  01 02                     |..|
#
#     $ printf "\[\]" | hd
#     00000000  5c 5b 5c 5d               |\[\]|
#
#   But author has not noticed a difference between which one is used.
#
# BWARE: The SOX and STX bytes cause issue with `bat` and `less -R`,
# e.g.,
#   $ ( printf "\001\033[32m\002foo\n" | less -R )
# Shows:
#   ^A^Bfoo

# SOH: Start of Non-printing ‖ \x01 Start of Header ‖ tells shell
#      line-editor to start ignoring width counting.
# STX: End of Non-printing ‖ \x02 Start of Text ‖ tells shell to
#      resume counting chars towards the visible len. of the prompt.

_shcol_prepare_non_printing_signals() {
  SHCOLORS_SOH=""
  SHCOLORS_STX=""

  # HSTRY/2026-06-10: Only if over SSH, otherwise `less -R` and `bat` complain.
  if [ -n "${SSH_CLIENT}" ] || [ -n "${SSH_TTY}" ] || [ -n "${SSH_CONNECTION}" ]; then
    SHCOLORS_SOH="\001"
    SHCOLORS_STX="\002"
  fi
}
_shcol_prepare_non_printing_signals
unset -f _shcol_prepare_non_printing_signals

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# SAVVY: tmux does not show all ANSI 256 color codes, but
# maps some to other colors (like pink and orange to red).
#
# - For example, when TERM=*-256color, using the
#   256-color lightorange code:
#     printf "\033[38;5;215m"
#   works.
#
# - But in tmux, when TERM=tmux, that lightorange
#   code maps to red.
#
# - So we use RGB color formats below, e.g.,
#   for lightorange:
#
#     printf "\033[38;2;255;175;95m"
#
# - R,G,B Formats:
#
#     \033[38;2;<r>;<g>;<b>m  # RGB foreground color.
#     \033[48;2;<r>;<g>;<b>m  # RGB background color.
#
# - REFER: I used Gimp to extract RGB from
#
#     https://i.stack.imgur.com/KTSQa.png
#     # BEGET:
#     https://en.wikipedia.org/wiki/ANSI_escape_code

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

fg_pink() {
  _shcol_no_col && return
  # Via TERM=*-256color:
  #   printf "\033[38;5;211m"
  printf "${SHCOLORS_SOH}\033[38;2;255;135;175m${SHCOLORS_STX}"
}

fg_orange() {
  _shcol_no_col && return
  # Via TERM=*-256color:
  #   printf "\033[38;5;203m"
  printf "${SHCOLORS_SOH}\033[38;2;255;95;95m${SHCOLORS_STX}"
}

fg_skyblue() {
  _shcol_no_col && return
  # Via TERM=*-256color:
  #   printf "\033[38;5;111m"
  printf "${SHCOLORS_SOH}\033[38;2;135;175;255m${SHCOLORS_STX}"
}

fg_mediumgrey() {
  _shcol_no_col && return
  # Via TERM=*-256color:
  #   printf "\033[38;5;246m"
  printf "${SHCOLORS_SOH}\033[38;2;148;148;148m${SHCOLORS_STX}"
}

fg_lavender() {
  _shcol_no_col && return
  # Via TERM=*-256color:
  #   printf "\033[38;5;183m"
  printf "${SHCOLORS_SOH}\033[38;2;215;175;255m${SHCOLORS_STX}"
}

fg_tan() {
  _shcol_no_col && return
  # Via TERM=*-256color:
  #   printf "\033[38;5;179m"
  printf "${SHCOLORS_SOH}\033[38;2;215;175;95m${SHCOLORS_STX}"
}

fg_forest() {
  _shcol_no_col && return
  # Via TERM=*-256color:
  #   printf "\033[38;5;22m"
  printf "${SHCOLORS_SOH}\033[38;2;0;95;0m${SHCOLORS_STX}"
}

fg_maroon() {
  _shcol_no_col && return
  # Via TERM=*-256color:
  #   printf "\033[38;5;52m"
  printf "${SHCOLORS_SOH}\033[38;2;95;0;0m${SHCOLORS_STX}"
}

fg_hotpink() {
  _shcol_no_col && return
  # Via TERM=*-256color:
  #   printf "\033[38;5;198m"
  printf "${SHCOLORS_SOH}\033[38;2;255;0;135m${SHCOLORS_STX}"
}

fg_mintgreen() {
  _shcol_no_col && return
  # Via TERM=*-256color:
  #   printf "\033[38;5;121m"
  printf "${SHCOLORS_SOH}\033[38;2;135;255;175m${SHCOLORS_STX}"
}

fg_lightorange() {
  _shcol_no_col && return
  # Via TERM=*-256color:
  #   printf "\033[38;5;215m"
  printf "${SHCOLORS_SOH}\033[38;2;255;175;95m${SHCOLORS_STX}"
}

fg_lightred() {
  _shcol_no_col && return
  # Via TERM=*-256color:
  #   printf "\033[38;5;203m"
  printf "${SHCOLORS_SOH}\033[38;2;255;95;95m${SHCOLORS_STX}"
}

fg_jade() {
  _shcol_no_col && return
  # Via TERM=*-256color:
  #   printf "\033[38;5;35m"
  printf "${SHCOLORS_SOH}\033[38;2;0;175;95m${SHCOLORS_STX}"
}

fg_lime() {
  _shcol_no_col && return
  # Via TERM=*-256color:
  #   printf "\033[38;5;154m"
  printf "${SHCOLORS_SOH}\033[38;2;175;255;0m${SHCOLORS_STX}"
}

### background colors

bg_pink() {
  _shcol_no_col && return
  # Via TERM=*-256color:
  #   printf "\033[48;5;211m"
  printf "${SHCOLORS_SOH}\033[48;2;255;135;175m${SHCOLORS_STX}"
}

bg_orange() {
  _shcol_no_col && return
  # Via TERM=*-256color:
  #   printf "\033[48;5;203m"
  printf "${SHCOLORS_SOH}\033[48;2;255;95;95m${SHCOLORS_STX}"
}

bg_skyblue() {
  _shcol_no_col && return
  # Via TERM=*-256color:
  #   printf "\033[48;5;111m"
  printf "${SHCOLORS_SOH}\033[48;2;135;175;255m${SHCOLORS_STX}"
}

bg_mediumgrey() {
  _shcol_no_col && return
  # Via TERM=*-256color:
  #   printf "\033[48;5;246m"
  printf "${SHCOLORS_SOH}\033[48;2;148;148;148m${SHCOLORS_STX}"
}

bg_lavender() {
  _shcol_no_col && return
  # Via TERM=*-256color:
  #   printf "\033[48;5;183m"
  printf "${SHCOLORS_SOH}\033[48;2;215;175;255m${SHCOLORS_STX}"
}

bg_tan() {
  _shcol_no_col && return
  # Via TERM=*-256color:
  #   printf "\033[48;5;179m"
  printf "${SHCOLORS_SOH}\033[48;2;215;175;95m${SHCOLORS_STX}"
}

bg_forest() {
  _shcol_no_col && return
  # Via TERM=*-256color:
  #   printf "\033[48;5;22m"
  printf "${SHCOLORS_SOH}\033[48;2;0;95;0m${SHCOLORS_STX}"
}

bg_maroon() {
  _shcol_no_col && return
  # Via TERM=*-256color:
  #   printf "\033[48;5;52m"
  printf "${SHCOLORS_SOH}\033[48;2;95;0;0m${SHCOLORS_STX}"
}

bg_hotpink() {
  _shcol_no_col && return
  # Via TERM=*-256color:
  #   printf "\033[48;5;198m"
  printf "${SHCOLORS_SOH}\033[48;2;255;0;135m${SHCOLORS_STX}"
}

bg_mintgreen() {
  _shcol_no_col && return
  # Via TERM=*-256color:
  #   printf "\033[48;5;121m"
  printf "${SHCOLORS_SOH}\033[48;2;135;255;175m${SHCOLORS_STX}"
}

bg_lightorange() {
  _shcol_no_col && return
  # Via TERM=*-256color:
  #   printf "\033[48;5;215m"
  printf "${SHCOLORS_SOH}\033[48;2;255;175;95m${SHCOLORS_STX}"
}

bg_lightred() {
  _shcol_no_col && return
  # Via TERM=*-256color:
  #   printf "\033[48;5;203m"
  printf "${SHCOLORS_SOH}\033[48;2;255;95;95m${SHCOLORS_STX}"
}

bg_jade() {
  _shcol_no_col && return
  # Via TERM=*-256color:
  #   printf "\033[48;5;35m"
  printf "${SHCOLORS_SOH}\033[48;2;0;175;95m${SHCOLORS_STX}"
}

bg_lime() {
  _shcol_no_col && return
  # Via TERM=*-256color:
  #   printf "\033[48;5;154m"
  printf "${SHCOLORS_SOH}\033[48;2;175;255;0m${SHCOLORS_STX}"
}

# ***

fg_black() {
  _shcol_no_col && return
  printf "${SHCOLORS_SOH}\033[30m${SHCOLORS_STX}"
}

fg_red() {
  _shcol_no_col && return
  printf "${SHCOLORS_SOH}\033[31m${SHCOLORS_STX}"
}

fg_green() {
  _shcol_no_col && return
  printf "${SHCOLORS_SOH}\033[32m${SHCOLORS_STX}"
}

fg_yellow() {
  _shcol_no_col && return
  printf "${SHCOLORS_SOH}\033[33m${SHCOLORS_STX}"
}

fg_blue() {
  _shcol_no_col && return
  printf "${SHCOLORS_SOH}\033[34m${SHCOLORS_STX}"
}

fg_magenta() {
  _shcol_no_col && return
  printf "${SHCOLORS_SOH}\033[35m${SHCOLORS_STX}"
}

fg_cyan() {
  _shcol_no_col && return
  printf "${SHCOLORS_SOH}\033[36m${SHCOLORS_STX}"
}

fg_lightgray() {
  _shcol_no_col && return
  printf "${SHCOLORS_SOH}\033[37m${SHCOLORS_STX}"
}

fg_darkgray() {
  _shcol_no_col && return
  printf "${SHCOLORS_SOH}\033[90m${SHCOLORS_STX}"
}

fg_lightred() {
  _shcol_no_col && return
  printf "${SHCOLORS_SOH}\033[91m${SHCOLORS_STX}"
}

fg_lightgreen() {
  _shcol_no_col && return
  printf "${SHCOLORS_SOH}\033[92m${SHCOLORS_STX}"
}

fg_lightyellow() {
  _shcol_no_col && return
  printf "${SHCOLORS_SOH}\033[93m${SHCOLORS_STX}"
}

fg_lightblue() {
  _shcol_no_col && return
  printf "${SHCOLORS_SOH}\033[94m${SHCOLORS_STX}"
}

fg_lightmagenta() {
  _shcol_no_col && return
  printf "${SHCOLORS_SOH}\033[95m${SHCOLORS_STX}"
}

fg_lightcyan() {
  _shcol_no_col && return
  printf "${SHCOLORS_SOH}\033[96m${SHCOLORS_STX}"
}

fg_white() {
  _shcol_no_col && return
  printf "${SHCOLORS_SOH}\033[97m${SHCOLORS_STX}"
}

bg_black() {
  _shcol_no_col && return
  printf "${SHCOLORS_SOH}\033[40m${SHCOLORS_STX}"
}

bg_red() {
  _shcol_no_col && return
  printf "${SHCOLORS_SOH}\033[41m${SHCOLORS_STX}"
}

bg_green() {
  _shcol_no_col && return
  printf "${SHCOLORS_SOH}\033[42m${SHCOLORS_STX}"
}

bg_yellow() {
  _shcol_no_col && return
  printf "${SHCOLORS_SOH}\033[43m${SHCOLORS_STX}"
}

bg_blue() {
  _shcol_no_col && return
  printf "${SHCOLORS_SOH}\033[44m${SHCOLORS_STX}"
}

bg_magenta() {
  _shcol_no_col && return
  printf "${SHCOLORS_SOH}\033[45m${SHCOLORS_STX}"
}

bg_cyan() {
  _shcol_no_col && return
  printf "${SHCOLORS_SOH}\033[46m${SHCOLORS_STX}"
}

bg_lightgray() {
  _shcol_no_col && return
  printf "${SHCOLORS_SOH}\033[47m${SHCOLORS_STX}"
}

bg_darkgray() {
  _shcol_no_col && return
  printf "${SHCOLORS_SOH}\033[100m${SHCOLORS_STX}"
}

bg_lightred() {
  _shcol_no_col && return
  printf "${SHCOLORS_SOH}\033[101m${SHCOLORS_STX}"
}

bg_lightgreen() {
  _shcol_no_col && return
  printf "${SHCOLORS_SOH}\033[102m${SHCOLORS_STX}"
}

bg_lightyellow() {
  _shcol_no_col && return
  printf "${SHCOLORS_SOH}\033[103m${SHCOLORS_STX}"
}

bg_lightblue() {
  _shcol_no_col && return
  printf "${SHCOLORS_SOH}\033[104m${SHCOLORS_STX}"
}

bg_lightmagenta() {
  _shcol_no_col && return
  printf "${SHCOLORS_SOH}\033[105m${SHCOLORS_STX}"
}

bg_lightcyan() {
  _shcol_no_col && return
  printf "${SHCOLORS_SOH}\033[106m${SHCOLORS_STX}"
}

bg_white() {
  _shcol_no_col && return
  printf "${SHCOLORS_SOH}\033[107m${SHCOLORS_STX}"
}

### Colors inspired by Vim dubs_after_dark

# DiffAdd
# -------
#
# https://www.htmlcsscolor.com/hex/00CC00
fg_free_speech_green() {
  _shcol_no_col && return
  printf "${SHCOLORS_SOH}\033[38;2;0;204;0m${SHCOLORS_STX}"
}
#
# https://www.htmlcsscolor.com/hex/002200
bg_myrtle() {
  _shcol_no_col && return
  printf "${SHCOLORS_SOH}\033[48;2;0;34;0m${SHCOLORS_STX}"
}

# DiffChange
# ----------
#
# https://www.htmlcsscolor.com/hex/FF9955
fg_sunshade() {
  _shcol_no_col && return
  printf "${SHCOLORS_SOH}\033[38;2;255;153;85m${SHCOLORS_STX}"
}
#
# https://www.htmlcsscolor.com/hex/220000
bg_seal_brown() {
  _shcol_no_col && return
  printf "${SHCOLORS_SOH}\033[48;2;34;0;0m${SHCOLORS_STX}"
}

# DiffDelete
# ----------
#
# [See: fg_red]
#
# [See: bg_seal_brown]

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# CALSO: We use completion to find func. names. Naïve alt: Grep this file:
#   grep "() {$" ~/.kit/sh/sh-colors/bin/colors.sh \
#   | sed 's/^\(.*\)() {$/  export -f \1/' \
_shcol_export() {
  for func_prefix in "_shcol_" "bg_" "fg_" "attr_" "res_"; do
    for func_name in $(compgen -A function "${func_prefix}"); do
      export -f "${func_name}"
    done
  done
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# REFER: It's probably more "responsible" to use `tput` to generate
# escape sequences for formatting options, e.g.,
#
#   tput smul
#
# Vs.
#
#   printf "\033[4m"
#
# But author has never had an issue not using tput.
#
# - I think with modern terminals, if an escape sequence is not
#   supported, it's simply ignored.
#
#   - And using tput would ensure that no escape seqence is
#     generated (AFAIK).
#
#     - E.g., most terminals support underlining:
#
#         $ echo -e "$(tput smul)foo$(attr_reset)"
#         f̲o̲o̲
#
#       And you can pipe to hexdump to inspect the sequence:
#
#         # Generate 'begin underline mode' sequence
#         $ tput smul | hd
#         00000000  1b 5b 34 6d               |.[4m|
#
#     - But your terminal probably doesn't support subscripting:
#
#         $ tput ssubm | hd
#
#       And it probably doesn't support blink, either:
#
#         $ echo -e "$(tput blink)foo$(attr_reset)"
#         foo
#
#       Although that option probably does generate an escape seq.:
#
#         $ tput blink | hd
#         00000000  1b 5b 35 6d               |.[5m|
#
# - INERT/2025-11-15: And because this library has never used `tput`,
#   we're not going to add it. (But be aware of it, just in case we
#   have an issue not using it in the future.)
#
# - In any case, you can verify that the sequences below are the same
#   as the tput sequences, e.g.,
#
#     $ printf "\001$(tput sitm)\002" | hd
#     00000000  01 1b 5b 33 6d 02             |..[3m.|
#
#     $ printf "\001\033[3m\002" | hd
#     00000000  01 1b 5b 33 6d 02             |..[3m.|
#
# REFER: For list of tput cap-codes, see:
#   man 5 terminfo

# ***

# Note that you can also use tput to clear formatting, e.g.,
#   $ echo -e "$(fg_green)$(attr_underline)Hello$(tput sgr0), Whirl"
#   Hello, Whirl
#   -----
# (where the "Hello" is formatted).
# However, tput does not appear to inject into the output stream:
#   $ echo "$(fg_green)$(attr_underline)Hello$(tput sgr0), Whirl"
#   \033[32m\033[4mHello, Whirl
# so just to be safe -- so that this function can be used to build
# a string -- use the escape code.
attr_reset() {
  _shcol_no_col && return
  printf "${SHCOLORS_SOH}\033[0m${SHCOLORS_STX}"
}

# ***

attr_bold() {
  _shcol_no_col && return
  # See also:
  #   printf "$(tput bold)"
  # - but like noted above, prefer this escape code.
  printf "${SHCOLORS_SOH}\033[1m${SHCOLORS_STX}"
}

# CALSO:
#   $ tput dim | hd
#   00000000  1b 5b 32 6d               |.[2m|
attr_dim() {
  _shcol_no_col && return
  printf "${SHCOLORS_SOH}\033[2m${SHCOLORS_STX}"
}

# CALSO:
#   $ tput sitm | hd
#   00000000  1b 5b 33 6d               |.[3m|
attr_emphasis() {
  _shcol_no_col && return
  printf "${SHCOLORS_SOH}\033[3m${SHCOLORS_STX}"
}

attr_italic() {
  attr_emphasis
}

# CALSO:
#   $ tput smul | hd
#   00000000  1b 5b 34 6d               |.[4m|
attr_underline() {
  _shcol_no_col && return
  printf "${SHCOLORS_SOH}\033[4m${SHCOLORS_STX}"
}

attr_underlined() {
  attr_underline
}

# gnome-terminal/mate-terminal does not support blink, <sigh>.
# - Nor does Alacritty, or macOS Terminal.
# CALSO:
#   $ tput blink | hd
#   00000000  1b 5b 35 6d               |.[5m|
attr_blink() {
  _shcol_no_col && return
  printf "${SHCOLORS_SOH}\033[5m${SHCOLORS_STX}"
}

# CALSO: Aka begin standout mode:
#   $ tput smso | hd
#   00000000  1b 5b 37 6d               |.[7m|
attr_invert() {
  # Aka negative image.
  _shcol_no_col && return
  printf "${SHCOLORS_SOH}\033[7m${SHCOLORS_STX}"
}

# CALSO:
#   $ tput invis | hd
#   00000000  1b 5b 38 6d               |.[8m|
attr_hidden() {
  # Aka invisible image.
  _shcol_no_col && return
  printf "${SHCOLORS_SOH}\033[8m${SHCOLORS_STX}"
}

# CALSO:
#   $ tput smxx | hd
#   00000000  1b 5b 39 6d               |.[9m|
# - THANX: tput cap-code 'smxx' not documented in `man 5 terminfo`,
#   but found via search:
#     https://github.com/tmux/tmux/issues/1137
attr_strikethrough() {
  _shcol_no_col && return
  printf "${SHCOLORS_SOH}\033[9m${SHCOLORS_STX}"
}

# ***

res_all() { attr_reset; }

# CALSO:
#   $ tput sitm | hd
#   00000000  1b 5b 33 6d               |.[3m|
res_bold() {
  _shcol_no_col && return
  printf "${SHCOLORS_SOH}\033[22m${SHCOLORS_STX}"
}

# (lb): I do not recall what 'dim' means.
res_dim() { res_bold; }

# CALSO:
#   $ tput ritm | hd
#   00000000  1b 5b 32 33 6d            |.[23m|
res_emphasis() {
  _shcol_no_col && return
  printf "${SHCOLORS_SOH}\033[23m${SHCOLORS_STX}"
}

res_italic() {
  res_emphasis
}

# CALSO:
#   $ tput rmul | hd
#   00000000  1b 5b 32 34 6d            |.[24m|
res_underline() {
  _shcol_no_col && return
  printf "${SHCOLORS_SOH}\033[24m${SHCOLORS_STX}"
}

res_underlined() {
  res_underline
}

# DUNNO: `man 5 terminfo` does not show cap-code to reset 'blink'.
res_blink() {
  _shcol_no_col && return
  printf "${SHCOLORS_SOH}\033[25m${SHCOLORS_STX}"
}

# DUNNO: `man 5 terminfo` does not show cap-code to reset 'smso'.
res_reverse() {
  # Aka negative image.
  _shcol_no_col && return
  printf "${SHCOLORS_SOH}\033[27m${SHCOLORS_STX}"
}

# DUNNO: `man 5 terminfo` does not show cap-code to reset 'invis'.
res_hidden() {
  # Aka invisible image.
  _shcol_no_col && return
  printf "${SHCOLORS_SOH}\033[28m${SHCOLORS_STX}"
}

# *** Convenience aliases.
if ${SHCOLORS_INCL_RESET_VARIETY:-false}; then
  reset_all() { attr_reset; }
  reset_bold() { res_bold; }
  reset_dim() { res_bold; }
  reset_emphasis() { res_emphasis; }
  reset_italic() { res_italic; }
  reset_underline() { res_underline; }
  reset_underlined() { res_underline; }
  reset_blink() { res_blink; }
  reset_reverse() { res_reverse; }
  reset_hidden() { res_hidden; }
fi
