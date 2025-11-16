#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=bash
# Author: Landon Bouma <https://tallybark.com/>
# Project: https://github.com/DepoXy/sh-humble-prompt#🙇
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# USAGE: Configure git-rebase indicator style
# - 0: Off
# - 1: Put parentheses around the host icon, e.g., (🍅)
# - 2: Put parentheses around the prompt terminus, e.g., ($)
HOMEFRIES_PS1_GIT_REBASE_STYLE=${HOMEFRIES_PS1_GIT_REBASE_STYLE:-2}

# USAGE: Configure last-command-failed indicator style
# - 0: Off
# - 1: Color prompt red if last command failed e.g., $ [but in red]
HOMEFRIES_PS1_PREV_CMD_FAILED_STYLE=${HOMEFRIES_PS1_PREV_CMD_FAILED_STYLE:-1}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

_humb_prompt_is_user_logged_on_via_ssh() {
  # https://unix.stackexchange.com/questions/9605/how-can-i-detect-if-the-shell-is-controlled-from-ssh
  # "If one of the variables SSH_CLIENT or SSH_TTY is defined, it's an ssh session.
  #  If the login shell's parent process name is sshd, it's an ssh session."
  if [ -n "${SSH_CLIENT}" ] || [ -n "${SSH_TTY}" ]; then

    return 0
  else
    local command_name
    # E.g., locally on LM MATE:
    #   mate-terminal
    # Or SSH to LM MATE:
    #   sshd
    # Or SSH to macoS:
    #   sshd-session: user@ttys014
    command_name="$(ps -o comm= -p ${PPID} | sed 's/:.*$//')"

    case "${command_name}" in
    sshd | sshd-session)
      # DUNNO/2024-10-28: Not sure this branch ever followed, or
      # if SSH_CLIENT/SSH_TTY checks always followed instead.

      return 0
      ;;
    *)

      return 1
      ;;
    esac
  fi

  return 1
}

# 2015.03.04: I need to know when I'm in chroot hell.
# NOTE: There's a better way using sudo to check if in chroot jail
#       (which is compatible with Mac, BSD, etc.) but we don't want
#       to use sudo, and we know we're on Linux. And on Linux,
#       the inode of the (outermost) root directory is always 2.

_humb_prompt_user_is_trapped_in_chroot() {
  (_humb_prompt_os_is_linux && [ $(stat -c %i /) -ne 2 ]) ||
    (_humb_prompt_os_is_macos && [ $(stat -f %i /) -ne 2 ])
}

# DEVEL: If you need insight into the titlebar function, try logging
# or even xtrace'ing to a tmp file, e.g.,
#
#   echo "BASH_XTRACEFD: ${BASH_XTRACEFD}" >> /tmp/xtrace
#   exec 10> /tmp/xtrace
#   export BASH_XTRACEFD=10
#   set -x
#   ...
#   set +x

_humb_prompt_format_titlebar() {
  # 2012.10.17: Also change the titlebar name for special terminal windows,
  #             like the log-tracing windows.
  # See: http://unix.stackexchange.com/questions/14113/
  # is-it-possible-to-set-gnome-terminals-title-to-userhost-for-whatever-host-i
  # Search: PROMPTING in `man bash`.
  #
  #   \[ ... \] delimit a non-printing sequence w/ control chars and can be
  #               used to embed terminal control sequences into the prompt
  #          \e (or \033, the ASCII escape (ESC) character) starts an escape sequence
  #           ] after \e starts an operating system command (OSC)
  #          0; means "set the title" (xterm)
  #          \a (or \007, the bell (BEL) character) terminates the OSC
  #
  #       \e]0; is like ESC]0; and resets formatting (including color)
  #             since this string is for the window titlebar
  #
  #          \u is the username
  #          \h is the hostname up to the first '.'
  #          \W is the basename of the current working directory,
  #             with $HOME abbreviated with a tilde
  #
  # By default, the title bar is user@host:working-directory
  # REFER:
  # - ANSI escape code
  #    https://en.wikipedia.org/wiki/ANSI_escape_code#OSC_(Operating_System_Command)_sequences
  # - "The escape sequence to use is ESC]2;new titleBEL":
  #    https://wiki.archlinux.org/index.php/Bash/Prompt_customization#Customizing_the_terminal_window_title
  # - See section *... available codes for PS1 variable*:
  #   https://courses.cs.washington.edu/courses/cse374/16wi/lectures/PS1-guide.html
  #
  # Note on MATE you can set the window title using wmctrl, too, e.g.,
  #   wmctrl -r :ACTIVE: -T "The Window Title"
  #
  # Some formats to consider:
  #  titlebar='\[\e]0;\u@\h:\W\a\]'
  # This does the same thing but uses octal ASCII escape chars instead of
  # bash's escape chars:
  #  titlebar='\[\033]2;\u@\h\007\]'
  # Gnome-terminal's default (though it doesn't specify it, it just is):
  #  titlebar='\[\e]0;\u@\h:\w\a\]'

  # 2021-07-16: Add window number to window title.
  # - CXREF: See _humb_print_terminal_window_number for deets.
  # Sets ITERM2_WINDOW_NUMBER
  _humb_set_iterm2_window_number_environ

  local winnum="${ITERM2_WINDOW_NUMBER}"

  # - CXREF: ~/.kit/sh/sh-humble-prompt/lib/show-command-name-in-window-title.sh
  local sh_humble_prompt_lib_dir
  sh_humble_prompt_lib_dir="$(dirname -- "${BASH_SOURCE[0]}")"
  #
  local basename
  # HSTRY/2024-06-25: Previously just showed working directory basename:
  #   basename="\W"
  # - But we can use a function callback to get crafty with the path text.
  # CXREF: ~/.kit/sh/sh-humble-prompt/lib/window-title--fancy-cwd-path
  basename='$('"${sh_humble_prompt_lib_dir}"'/window-title--fancy-cwd-path)'

  local endof_osc='\a'

  # Name this terminal window specially if special.
  # NOTE: This information comes from Gnome, where we've set the Gnome shortcut
  #       to pass this environment variable to us.
  # NOTE: To test gnome-terminal, run it from your home directory, otherwise it
  #       won't find your bash scripts.
  local titlebar

  if ! _humb_prompt_is_user_logged_on_via_ssh; then
    # echo "User not logged on via SSH"
    if [ "${HOMEFRIES_TITLE}" != '' ]; then

      titlebar="\[\e]0;${winnum}${HOMEFRIES_TITLE}\a\]"
    elif _humb_prompt_user_is_trapped_in_chroot; then
      # In chroot jail.
      titlebar="\[\e]0;${winnum}|-${basename}-|\a\]"
    else
      # Not in chroot jail.
      #  titlebar="\[\e]0;\u@\h:\w\a\]"
      #  titlebar="\[\e]0;\w:(\u@\h)\a\]"
      #  titlebar="\[\e]0;\w\a\]"

      titlebar="\[\e]0;${winnum}${basename}\a\]"
    fi
  else
    # echo "User *is* logged on via SSH!"
    local -a choices

    # choices+=("\[\e]0;${winnum}$(hostname) → ${basename}${endof_osc}\]")
    choices+=("\[\e]0;${winnum}$(hostname) 🦉 ${basename}${endof_osc}\]")
    choices+=("\[\e]0;${winnum}$(hostname) 👗 ${basename}${endof_osc}\]")
    choices+=("\[\e]0;${winnum}$(hostname) 🌊 ${basename}${endof_osc}\]")
    choices+=("\[\e]0;${winnum}$(hostname) 🌿 ${basename}${endof_osc}\]")
    choices+=("\[\e]0;${winnum}$(hostname) 🍍 ${basename}${endof_osc}\]")

    # Using RANDOM builtin.
    titlebar="${choices[$RANDOM % 5]}"
  fi

  printf "${titlebar}"
}

_humb_prompt_customize_shell_prompts_and_window_title() {
  # - SAVVY: Note that colors.sh defines similar colors, but without
  #   the `01;` (though author fails to recall what that does).
  # - BWARE: Wrap escape sequences with \001..\002 or \[...\],
  #   otherwise SSH terminal will have issues detecting prompt
  #   width (and then, e.g., using <Up> to cycle through shell
  #   history will mess up the prompt when a long command is
  #   recalled).
  local fg_red='\[\033[01;31m\]'
  local fg_green='\[\033[01;32m\]'
  local fg_yellow='\[\033[01;33m\]'
  local fg_cyan='\[\033[01;36m\]'
  local fg_gray='\[\033[01;37m\]'
  local fg_lightorange='\[\033[38;2;255;175;95m\]'
  local bg_magenta='\[\033[01;45m\]'
  local cur_user='\u'
  local attr_reset='\[\033[00m\]'
  local attr_underlined='\[\033[4m\]'
  local attr_italic='\[\033[3m\]'
  # local attr_bold='\[\033[1m\]'

  # So that you can double-click the working directory to copy it, use
  # non-path characters before and after the path.
  # - The set of path characters is specific to the terminal emulator,
  #   and it's not always adjustable (without building from sources, I
  #   suppose).
  # - Whitespace and Unicode should be universally accepted as not path
  #   characters.
  #   - E.g., rather than use an ASCII colon ":", use a Unicode colon "∶".
  #     - REFER: "Ratio", Unicode Character “∶” (U+2236)
  local unicolon="∶"

  local mach_name
  if [ -n "${HOMEFRIES_TERM_UTIL_PS1_HOST}" ]; then
    mach_name="${HOMEFRIES_TERM_UTIL_PS1_HOST}"
  elif _humb_prompt_os_is_macos; then
    # (lb): 2020-08-24: On Vendor's Mac I use, hostname is 16-character MAC.
    # - Short hostname to 8 characters, in case it's just the MAC.
    mach_name="$(scutil --get LocalHostName | sed -E 's/(.{8}).*/\1/')"
  else
    mach_name='\h'
  fi

  local basename='\W'

  # Configure a colorful prompt of the following format:
  #  user@host:dir
  # See <http://www.termsys.demon.co.uk/vtansi.htm>
  #  for more about colours.
  #  There's a nifty chart at <http://www.frexx.de/xterm-256-notes/>
  # export PS1='\u@\[\033[0;35m\]\h\[\033[0;33m\][\W\[\033[00m\]]: '
  # export PS1='\u@\[\033[0;32m\]\h\[\033[0;36m\][\W\[\033[00m\]]: '
  # A;XYm ==>
  #   A=1 means bright
  #   XY=30 is Black  31 Red      32 Green  33 Yellow
  #      34    Blue   35 Magenta  36 Cyan   37 White
  #   X=3 is Foreground, =4 is Background colors, i.e., 47 is White BG
  # export PS1='\[\033[1;37m\]\u@\[\033[1;33m\]\h\[\033[1;36m\][\W\[\033[00m\]]: '
  #
  # REFER/2025-11-11: From Debian 13 stock ~/.bashrc, which uses value in its PS1:
  #   # set variable identifying the chroot you work in (used in the prompt below)
  #   if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
  #     debian_chroot=$(cat /etc/debian_chroot)
  #   fi
  #   # set a fancy prompt (non-color, unless we know we "want" color)
  #   case "$TERM" in
  #     xterm-color|*-256color) color_prompt=yes;;
  #   esac
  #   # uncomment for a colored prompt, if the terminal has the capability; turned
  #   # off by default to not distract the user: the focus in a terminal window
  #   # should be on the output of commands, not on the prompt
  #   #force_color_prompt=yes
  #   if [ -n "$force_color_prompt" ]; then
  #     if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
  #       # We have color support; assume it's compliant with Ecma-48
  #       # (ISO/IEC-6429). (Lack of such support is extremely rare, and such
  #       # a case would tend to support setf rather than setaf.)
  #       color_prompt=yes
  #     else
  #       color_prompt=
  #     fi
  #   fi
  #   if [ "$color_prompt" = yes ]; then
  #     PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
  #   else
  #     PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
  #   fi
  #   unset color_prompt force_color_prompt
  #   # If this is an xterm set the title to user@host:dir
  #   case "$TERM" in
  #   xterm*|rxvt*)
  #     PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
  #     ;;
  #   *)
  #     ;;
  #   esac

  local titlebar="$(_humb_prompt_format_titlebar)"

  # 2012.10.17: The default bash includes ${debian_chroot:+($debian_chroot)} in
  # the PS1 string, but it really shouldn't be set on any of our systems (it's
  # pretty much obsolete, or at least pertains to a linux usage we're not).
  # "Chroot is a unix feature that lets you restrict a process to a subtree of
  # the filesystem." See:
  #  http://unix.stackexchange.com/questions/3171/what-is-debian-chroot-in-bashrc
  #  https://en.wikipedia.org/wiki/Chroot

  # MAYBE/2018-12-23: Move these definitions to color_util.sh or similar?
  # - NOTE: Bash 4.2 added Unicode support, i.e.,
  #           echo -e "\uHHHH"
  #           printf "\uHHHH"
  # - NOTE: For 5 to 8 digiti Unicode character, use \U, e.g.,
  #           echo -e "\UHHHHHHHH"
  #           printf "\UHHHHHHHH"
  # - NOTE: Pad the \U to 8 digits, or built-in printf may complain.
  #           @mint19.3 $ printf "\U1F4A9"
  #           💩
  #           @mint19.3 $ /usr/bin/printf "\U1F4A9"
  #           /usr/bin/printf: missing hexadecimal number in escape
  #           @mint19.3 $ /usr/bin/printf "\U0001F4A9"
  #           💩
  #         (though latest Bash `echo` and `printf` do not care).
  # - NOTE: If set in PS1 directly, need to $'interpolate', e.g.,
  #           PS1="${titlebar}${prompt_stuff}"$' \U1F480 '"\$ "
  #         - SAVVY: Bash's $'...' sees \uXXXX unicode espace
  #           sequences, but not $"..."
  # - NOTE: And now that I've noted all of this, It's actually
  #         easier to just embed the Unicode within this file.
  #         And then raw macOS (with system Bash 3.x, whose `echo`
  #         and `printf` won't recognize the \Unicode syntax)
  #         will work.
  # - NOTE: I was using ⚓ for _hf_session_is_subshell on Linux for
  #         years until I discovered on @macOS it renders at the
  #         lowly VS15 variant, ⚓︎.
  #         - I tried the ring buoy instead but the terminal does
  #           not read its width correctly. This messes up Bash
  #           history, e.g., if you <Up> then <Home>, the cursor
  #           is off by one. Same for a few other glyphs.
  #         - Canoe works, but I'd like a fuller, smoother icon.
  #           And I like the red color pop that leads my eye to
  #           the start of the prompt.
  #         - Works: 🛶 🍁 🎃 🍿 🫑 🍒 🍓 🍉 🍎 / Don't: ⚓ 🛟 🥭
  local u_tomato="🍅" #             # 🍅  $(printf "\U1F345")
  # local u_evergreen_tree="🌲"     # 🌲  $(printf "\U1F332")
  # local u_cactus="🌵"             # 🌵  $(printf "\U1F335")
  local u_mushroom="🍄" #           # 🍄  $(printf "\U1F344")
  local u_skull="💀"    #           # 💀  $(printf "\U1F480")
  local u_horny="😈"    #           # 💀  $(printf "\U1F480")
  # local u_owl="🦉"                # 🦉  $(printf "\U1F989")
  # local u_herb="🌿"               # 🌿  $(printf "\U1F33F")
  # local u_pineapple="🍍"          # 🍍  $(printf "\U1F34D")
  # # (Draws too light to see:)
  # local u_skull_n_xbones="☠"      # ☠  $(printf "\u2620")

  local local_shell_icon="${u_mushroom}"
  local remote_shell_icon="${u_skull}"

  if _hf_session_is_subshell; then
    local_shell_icon="${u_tomato}"
    remote_shell_icon="${u_horny}"
  fi

  if [ ${HOMEFRIES_PS1_GIT_REBASE_STYLE:-0} -eq 1 ]; then
    # 2024-08-19: Styles I demoed: (🍅) >🍅< ⟪🍅⟫ ⟬🍅⟭ ┃🍅┃
    # - I also demoed other icons but none of these render
    #   well in the macOS terminal good: ⏪ ☢️  ⚠️  🏁
    local_shell_icon='$([ -f "$(git root 2> /dev/null)/.git/rebase-merge/git-rebase-todo" ] && echo "('"${local_shell_icon}"')" || echo "'"${local_shell_icon}"'")'
    remote_shell_icon='$([ -f "$(git root 2> /dev/null)/.git/rebase-merge/git-rebase-todo" ] && echo "('"${remote_shell_icon}"')" || echo "'"${remote_shell_icon}"'")'
  fi

  local_shell_icon="${local_shell_icon} "
  remote_shell_icon="${remote_shell_icon} "

  _humb_prompt_customize_shell_prompt_PS1
  _humb_prompt_customize_shell_prompt_PS2
}

# ***

# REFER: You can use PROMPT_COMMAND instead to set PS1.
# - It's called before every prompt.
#   - (Homefries uses it to call `_hist_util_hook_bg`.)
# - E.g., if you disable all the `unset -f` calls herein,
#   you could set:
#     PROMPT_COMMAND=_humb_prompt_customize_shell_prompts_and_window_title
#   and it'll set PS1 before every prompt.
#   - Though note this runs noticeably slower than the normal
#     prompt. Obviously, we could fix the fcns. herein to improve
#     performance (e.g., if you just press enter at an empty
#     prompt, you'll see a slight lag before the next prompt is
#     printed). But I don't see any benefit to using PROMPT_COMMAND,
#     as you can already embed code to run before every prompt
#     into PS1.
# - You can also skip PS1 and echo from the PROMPT_COMMAND
#   callback directly, e.g.:
#     PS1=""
#     PROMPT_COMMAND='echo -ne "\033]0;SOME TITLE HERE\007"'
#   Also:
#     titlebar="\[\e]0;THIS IS A TEST\a\]"
#     PROMPT_COMMAND='printf '%b' "${titlebar}\[\033[01;36m\]\u@\[\033[1;33m\]\h\[\033[00m\]:\[\033[01;37m\]\W\[\033[00m\]${prompt_symbol} "'

_humb_prompt_customize_shell_prompt_PS1() {
  if [ -z "${HOMEFRIES_PS1_ORIG+x}" ]; then
    export HOMEFRIES_PS1_ORIG="$PS1"
  fi

  # If the user sets a custom PS1, e.g., for an `asciinema rec` demo
  # recording, honor it.
  # - (lb): Note that you can `export PS1` but I could not get around Bash
  #   changing it on startup except via `export` and `--noprofile --norc`.
  #   - For instance, if you do not export PS1, then Bash sets its own prompt:
  #     my-crazy-prompt $ export -n PS1
  #     my-crazy-prompt $ bash --noprofile --norc
  #     bash-4.4$
  #   Otherwise, if you export PS1, Bash respects it:
  #     my-crazy-prompt $ export PS1
  #     my-crazy-prompt $ bash --noprofile --norc
  #     my-crazy-prompt $
  # - Because PS1 will be set either way -- whether it's from
  #   parent session, or whether it's from Bashrc -- we cannot
  #   easily tell how it got set.
  #   - We could compare against observed Bashrc defaults, e.g.,
  #       [ "$PS1" != '\s-\v\$ ' ] && return
  #     but that seems fragile, and it doesn't account for other
  #     distros, or what prompt Bashrc makes for the root user.
  #   - We could check if PS1 is marked for export, but that's
  #     pointless, as system bashrc changes it regardless. E.g.,
  #       # If calling process/session called `export PS1`, leave it.
  #       declare -p | grep '^declare -x PS1=' > /dev/null && return
  #   - So instead we use our own special environment variable.
  if [ -n "${HOMEFRIES_TERM_UTIL_PS1}" ]; then
    PS1="${HOMEFRIES_TERM_UTIL_PS1}"

    return
  fi

  local prompt_symbol="\$"
  if [ ${HOMEFRIES_PS1_GIT_REBASE_STYLE:-0} -eq 2 ]; then
    prompt_symbol='$([ -f "$(git root 2> /dev/null)/.git/rebase-merge/git-rebase-todo" ] && echo "(\$)" || echo "\$")'
  fi

  # Highlight final prompt character "$" in red if previous command failed.
  # - THANX: Inspired by Julia Evans blog post re: Fish shell:
  #     https://jvns.ca/blog/2024/09/12/reasons-i--still--love-fish/#5-nice-default-prompt-including-git-integration
  #   See also these Bash-related links:
  #     https://stackoverflow.com/questions/16715103/bash-prompt-with-the-last-exit-code
  #     https://github.com/dimo414/prompt.gem
  if [ ${HOMEFRIES_PS1_PREV_CMD_FAILED_STYLE:-0} -eq 1 ]; then
    prompt_symbol="\$(test \${_humb_exitcode:-0} -ne 0 && echo \"${fg_red}\")${prompt_symbol}\$(test \${_humb_exitcode:-0} -ne 0 && echo \"${attr_reset}\")"
    # ALTLY: Use one test, but then the final PS1 string is longer (because
    # ${prompt_symbol} is duplicated):
    #   prompt_symbol="\$(test \${_humb_exitcode:-0} -ne 0 && echo \"${fg_red}${prompt_symbol}${attr_reset}\" || echo \"${prompt_symbol}\")"
  fi

  if ${HOMEFRIES_PS1_EMOJI_DISABLE:-false}; then
    local_shell_icon=""
    remote_shell_icon=""
  fi

  if [ $EUID -eq 0 ]; then
    # ${HOMEFRIES_TRACE} && echo "PS1: as root"
    PS1="${titlebar}${bg_magenta}${fg_gray}${cur_user}@${fg_yellow}${mach_name}${attr_reset}${unicolon}${fg_cyan}${basename}${attr_reset}${prompt_symbol} "
  elif _humb_prompt_is_user_logged_on_via_ssh; then
    # ${HOMEFRIES_TRACE} && echo "PS1: via SSH"
    # 2018-12-23: Use remote_shell_icon when logged on over SSH.
    PS1="${titlebar}${fg_gray}${cur_user}${attr_italic}${attr_underlined}${fg_lightorange}@${mach_name}${attr_reset}${unicolon}${fg_cyan}${basename}${attr_reset} ${remote_shell_icon}${prompt_symbol} "
  elif _humb_prompt_user_is_trapped_in_chroot; then
    # ${HOMEFRIES_TRACE} && echo "PS1: chroot jail"
    PS1="${titlebar}${fg_red}**${cur_user}@**${fg_cyan}${mach_name}${attr_reset}${unicolon}${fg_yellow}${basename}${attr_reset} "'! '
  else
    # ${HOMEFRIES_TRACE} && echo "PS1: local shell"
    PS1="${titlebar}${fg_gray}${cur_user}@${fg_yellow}${mach_name}${attr_reset}${unicolon}${fg_cyan}${basename}${attr_reset} ${local_shell_icon}${prompt_symbol} "
    # 2015.02.26: Add git branch.
    #             Maybe... not sure I like this...
    #             maybe change delimiter and make branch name colorful?
    #  PS1="${titlebar}\[\033[01;37m\]\u@\[\033[1;33m\]\h\[\033[00m\]:\[\033[01;36m\]\W\[\033[00m\]"'$(__git_ps1 "-%s" )${prompt_symbol} '
  fi

  if [ ${HOMEFRIES_PS1_PREV_CMD_FAILED_STYLE:-0} -eq 1 ]; then
    PS1="\$(_humb_exitcode=\$?; echo \"${PS1}\")"
  fi
}

# ***

_humb_prompt_customize_shell_prompt_PS2() {
  # 2018-05-28: How about a bold PS2 (continuation) prompt?
  #  PS2="$(tput bold)>${attr_reset} "
  #  PS2="$(tput bold)${attr_underlined}${fg_green}>${attr_reset} "
  #  PS2="$(tput bold)${fg_green}_${attr_reset} "
  #  PS2="$(tput bold)${attr_underlined}${fg_green} ${attr_reset} "
  #  PS2="${attr_underlined}${fg_green} ${attr_reset} "
  PS2="${fg_green}>${attr_reset} "
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# For debugging/tracing Bash scripts using
#
#   `set -x` and `set -v`.
#
# See:
#   http://www.rodericksmith.plus.com/outlines/manuals/bashdbOutline.html
#
# Also:
#   http://bashdb.sourceforge.net/
#   http://www.linuxtopia.org/online_books/advanced_bash_scripting_guide/debugging.html
#   http://www.cyberciti.biz/tips/debugging-shell-script.html
home_fries_set_PS4() {
  # Default is: PS4='+'
  PS4='(${BASH_SOURCE[0]}:${LINENO}): ${FUNCNAME[0]} - [${SHLVL},${BASH_SUBSHELL}, $?]
  '
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# COPYD: Duplicated from, and located in Depoxy shell at:
#   _hf_session_is_subshell
#     https://github.com/landonb/home-fries#🍟
#       ~/.kit/sh/home-fries/lib/session_util.sh @ 55 - 101

# NOTED: Not DRY: Copied from ~/.kit/git/git-smart/bin/git-brs.
#   grep-or-ggrep
_hf_grep_or_ggrep() {
  #   $ grep --version
  #   grep (BSD grep, GNU compatible) 2.6.0-FreeBSD
  #   # "GNU compatible" it's not.
  #   $ ggrep --version
  #   ggrep (GNU grep) 3.8
  if grep -q -e "GNU grep" <(grep --version | head -1); then
    echo "grep"
  elif command -v ggrep >/dev/null; then
    echo "ggrep"
  else
    >&2 echo "ERROR: GNU \`grep\` not found"
  fi
}

_HF_GREP="$(_hf_grep_or_ggrep)"

# E.g.,
#   18305 /home/user/.local/bin/bash
_hf_session_util_is_ppid_bash() {
  ps ax -o pid,command | ${_HF_GREP} -P "^ *${PPID} \S+/bash($| )" &>/dev/null
}

# E.g., login shell
#    9483 -bash
# Where the dash-bash means it was started as interactive session.
# And is what happens when you `bash` from within a `tmux` shell.
# - Though on macOS/iTerm2, /opt/homebrew/bin/bash is first shell's
#   parent process; and subshells are just `bash` (no dash).
_hf_session_util_is_ppid_ibash() {
  ps ax -o pid,command | ${_HF_GREP} -P "^ *${PPID} -?bash$" &>/dev/null
}

# E.g.,
#   23799 /home/user/.local/share/pypoetry/venv/bin/python /home/user/.local/bin/poetry shell
_hf_session_util_is_ppid_poetry_shell() {
  ps ax -o pid,command | ${_HF_GREP} -P "^ *${PPID} \S+/python3? \S+/poetry shell$" &>/dev/null
}

_hf_session_is_subshell() {
  false ||
    _hf_session_util_is_ppid_bash ||
    _hf_session_util_is_ppid_ibash ||
    _hf_session_util_is_ppid_poetry_shell
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

_humb_prompt_os_is_linux() {
  [ "$(uname)" = "Linux" ]
}

_humb_prompt_os_is_macos() {
  [ "$(uname)" = 'Darwin' ]
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# NOTE: This function is a one-off, as it wouldn't be necessary to
#       call it more than once. So it cleans itself up rather than
#       hang around the environment.

_humb_prompt_configure() {
  _humb_prompt_customize_shell_prompts_and_window_title

  unset -f _humb_prompt_os_is_linux
  unset -f _humb_prompt_os_is_macos

  unset -f _humb_prompt_is_user_logged_on_via_ssh
  unset -f _humb_prompt_user_is_trapped_in_chroot
  unset -f _humb_prompt_format_titlebar

  unset -f _humb_prompt_customize_shell_prompt_PS1
  unset -f _humb_prompt_customize_shell_prompt_PS2

  unset -f _humb_prompt_customize_shell_prompts_and_window_title

  unset -f _humb_prompt_configure
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
