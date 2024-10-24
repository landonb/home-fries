#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=bash
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

_hf_check_deps_set_shell_prompt () {
  # Verify distro_util.sh loaded.
  check_dep 'os_is_macos' || return $?
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# USAGE: Optional terminal window title user prefix
DUBS_STICKY_PREFIX="${DUBS_STICKY_PREFIX}"

# USAGE: Configure git-rebase indicator style
# - 0: Off
# - 1: Put parentheses around the host icon, e.g., (🍅)
# - 2: Put parentheses around the prompt terminus, e.g., ($)
HOMEFRIES_PS1_GIT_REBASE_STYLE=${HOMEFRIES_PS1_GIT_REBASE_STYLE:-2}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

_hf_prompt_is_user_logged_on_via_ssh () {
  # https://unix.stackexchange.com/questions/9605/how-can-i-detect-if-the-shell-is-controlled-from-ssh
  # "If one of the variables SSH_CLIENT or SSH_TTY is defined, it's an ssh session.
  #  If the login shell's parent process name is sshd, it's an ssh session."
  if [ -n "${SSH_CLIENT}" ] || [ -n "${SSH_TTY}" ]; then

    return 0
  else
    case $(ps -o comm= -p ${PPID}) in
      sshd|*/sshd)

        return 0
        ;;
      # mate-terminal) ...
      *)

        return 1
        ;;
    esac
  fi

  return 1
}

_hf_prompt_user_is_not_trapped_in_chroot () {
  ( os_is_linux && [ $(stat -c %i /) -eq 2 ] ) ||
  ( os_is_macos && [ $(stat -f %i /) -eq 2 ] )
}

_hf_prompt_format_titlebar () {
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
  # - CXREF: See _hf_print_terminal_window_number for deets.
  # Sets ITERM2_WINDOW_NUMBER
  _hf_set_iterm2_window_number_environ

  local winnum="${ITERM2_WINDOW_NUMBER}"

  # - CXREF: ~/.kit/sh/home-fries/lib/term/show-command-name-in-window-title.sh
  local lib_term_dir
  lib_term_dir="$(dirname -- "${BASH_SOURCE[0]}")"
  #
  local basename
  # HSTRY/2024-06-25: Previously just showed working directory basename:
  #   basename="\W"
  # - But we can use a function callback to get crafty with the path text.
  # CXREF: ~/.kit/sh/home-fries/lib/term/window-title--fancy-cwd-path
  basename='$('"${lib_term_dir}"'/window-title--fancy-cwd-path)'

  local endof_osc='\a'

  local sticky_alert=''

  if ${DUBS_ALWAYS_ON_VISIBLE:-false}; then
    sticky_alert="${DUBS_STICKY_PREFIX}"
  fi

  # Name this terminal window specially if special.
  # NOTE: This information comes from Gnome, where we've set the Gnome shortcut
  #       to pass this environment variable to us.
  # NOTE: To test gnome-terminal, run it from your home directory, otherwise it
  #       won't find your bash scripts.
  local titlebar

  if ! _hf_prompt_is_user_logged_on_via_ssh; then
    # echo "User not logged on via SSH"
    if [ "${HOMEFRIES_TITLE}" != '' ]; then

      titlebar="\[\e]0;${winnum}${sticky_alert}${HOMEFRIES_TITLE}\a\]"
    elif _hf_prompt_user_is_not_trapped_in_chroot; then
      # Not in chroot jail.
      #  titlebar="\[\e]0;\u@\h:\w\a\]"
      #  titlebar="\[\e]0;\w:(\u@\h)\a\]"
      #  titlebar="\[\e]0;\w\a\]"

      titlebar="\[\e]0;${winnum}${sticky_alert}${basename}\a\]"
    else
      # In chroot jail.
      titlebar="\[\e]0;${winnum}|-${sticky_alert}${basename}-|\a\]"
    fi
  else
    # echo "User *is* logged on via SSH!"
    local -a choices

  # choices+=("\[\e]0;${winnum}${sticky_alert}$(hostname) → ${basename}${endof_osc}\]")
    choices+=("\[\e]0;${winnum}${sticky_alert}$(hostname) 🦉 ${basename}${endof_osc}\]")
    choices+=("\[\e]0;${winnum}${sticky_alert}$(hostname) 👗 ${basename}${endof_osc}\]")
    choices+=("\[\e]0;${winnum}${sticky_alert}$(hostname) 🌊 ${basename}${endof_osc}\]")
    choices+=("\[\e]0;${winnum}${sticky_alert}$(hostname) 🌿 ${basename}${endof_osc}\]")
    choices+=("\[\e]0;${winnum}${sticky_alert}$(hostname) 🍍 ${basename}${endof_osc}\]")

    # Using RANDOM builtin.
    titlebar="${choices[$RANDOM % 5]}"
  fi

  printf "${titlebar}"
}

_hf_prompt_customize_shell_prompts_and_window_title () {
  # (lb): Note that colors.sh defines similar colors, but without
  # the ``01;`` part. I cannot remember what that component means....
  local fg_red='\[\033[01;31m\]'
  local fg_green='\[\033[01;32m\]'
  local fg_yellow='\[\033[01;33m\]'
  local fg_cyan='\[\033[01;36m\]'
  local fg_gray='\[\033[01;37m\]'
  local bg_magenta='\[\033[01;45m\]'
  local cur_user='\u'
  local attr_reset='\[\033[00m\]'
  local attr_underlined="\033[4m"
  # local attr_bold="\[\033[1m\]"  # See also: $(tput bold).
  #
  local mach_name='\h'
  # (lb): 2020-08-24: At least on Mac I use, hostname is 16-character MAC.
  os_is_macos && mach_name="$(scutil --get LocalHostName | sed -E 's/(.{8}).*/\1/')"
  mach_name="${HOMEFRIES_TERM_UTIL_PS1_HOST:-${mach_name}}"
  #
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
  # # From debian .bashrc:
  # PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

  local titlebar="$(_hf_prompt_format_titlebar)"

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
  local u_tomato="🍅"             # 🍅  $(printf "\U1F345")
 #local u_evergreen_tree="🌲"     # 🌲  $(printf "\U1F332")
 #local u_cactus="🌵"             # 🌵  $(printf "\U1F335")
  local u_mushroom="🍄"           # 🍄  $(printf "\U1F344")
  local u_skull="💀"              # 💀  $(printf "\U1F480")
  local u_horny="😈"              # 💀  $(printf "\U1F480")
 #local u_owl="🦉"                # 🦉  $(printf "\U1F989")
 #local u_herb="🌿"               # 🌿  $(printf "\U1F33F")
 #local u_pineapple="🍍"          # 🍍  $(printf "\U1F34D")
  # (Draws too light to see:)
  #  local u_skull_n_xbones="☠"   # ☠  $(printf "\u2620")

  local local_shell_icon="${u_mushroom}"
  local remote_shell_icon="${u_skull}"

  # CXREF: _hf_session_is_subshell: ~/.homefries/lib/session_util.sh:96
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

  _hf_prompt_customize_shell_prompt_PS1
  _hf_prompt_customize_shell_prompt_PS2
}

# ***

_hf_prompt_customize_shell_prompt_PS1 () {
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

  # NOTE: Using "" below instead of '' so that ${titlebar} is resolved by the
  #       shell first.
  # ${HOMEFRIES_TRACE} && echo "PS1: Preparing prompt"
  if [ -e /proc/version ] || os_is_macos ; then
    if [ $EUID -eq 0 ]; then
      local fg_path=""
      # ${HOMEFRIES_TRACE} && echo "PS1: Running as root!"
      if os_is_macos || [ "$(cat /proc/version | grep Ubuntu)" ]; then
        # ${HOMEFRIES_TRACE} && echo "PS1: On Ubuntu"
        fg_path="${fg_cyan}"
      elif [ "$(cat /proc/version | grep Red\ Hat)" ]; then
        # ${HOMEFRIES_TRACE} && echo "PS1: On Red Hat"
        # - DUNNO/2024-05-01: I don't recall history of this path (and
        #   it's been eons since I last used Fedora).
        fg_path="${fg_gray}"
      else
        echo "WARNING: Not enough info. to set PS1."

        return
      fi
      PS1="${titlebar}${bg_magenta}${fg_gray}${cur_user}@${fg_yellow}${mach_name}${attr_reset}:${fg_path}${basename}${attr_reset}${prompt_symbol} "
    elif os_is_macos || [ "$(cat /proc/version | grep Ubuntu)" ]; then
      # ${HOMEFRIES_TRACE} && echo "PS1: On Ubuntu"
      # 2015.03.04: I need to know when I'm in chroot hell.
      # NOTE: There's a better way using sudo to check if in chroot jail
      #       (which is compatible with Mac, BSD, etc.) but we don't want
      #       to use sudo, and we know we're on Linux. And on Linux,
      #       the inode of the (outermost) root directory is always 2.
      # CAVEAT: This check works on Linux but probably not on Mac, BSD, Cygwin, etc.
      if _hf_prompt_is_user_logged_on_via_ssh; then
        # 2018-12-23: Killer.

        PS1="${titlebar}${fg_gray}${cur_user}$(attr_italic)$(attr_underline)$(fg_lightorange)@${mach_name}${attr_reset}:${fg_cyan}${basename}${attr_reset} ${remote_shell_icon} ${prompt_symbol} "
      elif _hf_prompt_user_is_not_trapped_in_chroot; then
        #PS1="${titlebar}\[\033[01;37m\]\u@\[\033[1;33m\]\h\[\033[00m\]:\[\033[01;36m\]\W\[\033[00m\]${prompt_symbol} "
        # 2015.03.04: The chroot is Ubuntu 12.04, and it's Bash v4.2 does not
        #             support Unicode \uXXXX escapes, so use the escape in the
        #             outer. (Follow the directory path with an anchor symbol
        #             so I know I'm *not* in the chroot.)
        # With a colon between hostname and working directory:
        #   PS1="${titlebar}${fg_gray}${cur_user}@${fg_yellow}${mach_name}${attr_reset}:${fg_cyan}${basename}${attr_reset} ${local_shell_icon} ${prompt_symbol} "
        # With a space between hostname and working directory, so double-click works.
        #   PS1="${titlebar}${fg_gray}${cur_user}@${fg_yellow}${mach_name}${attr_reset} ${fg_cyan}${basename}${attr_reset} ${local_shell_icon} ${prompt_symbol} "
        # With a Unicode colon between hostname and working directory, so double-click works.

        PS1="${titlebar}${fg_gray}${cur_user}@${fg_yellow}${mach_name}${attr_reset}∶${fg_cyan}${basename}${attr_reset} ${local_shell_icon} ${prompt_symbol} "
        # 2015.02.26: Add git branch.
        #             Maybe... not sure I like this...
        #             maybe change delimiter and make branch name colorful?
        #PS1="${titlebar}\[\033[01;37m\]\u@\[\033[1;33m\]\h\[\033[00m\]:\[\033[01;36m\]\W\[\033[00m\]"'$(__git_ps1 "-%s" )${prompt_symbol} '
      else
        # NOTE: Bash's $'...' sees \uXXXX unicode espace sequences, but not $"..."
        # See the Unicode character table: http://unicode-table.com/en/
        # Bash doesn't support all Unicode characters, so see also this list:
        #   https://mkaz.com/2014/04/17/the-bash-prompt/
        #PS1="${titlebar}\[\033[01;31m\]"$'\u2605'"\u@"$'\u2605'"\[\033[1;36m\]\h\[\033[00m\]:\[\033[01;33m\]\W\[\033[00m\]"$' \u2693 '
        # 2015.03.04: As mentioned above, the chroot may be running an old Bash,
        #             so use the Unicode \uXXXX escape in the outer only.

        PS1="${titlebar}${fg_red}**${cur_user}@**${fg_cyan}${mach_name}${attr_reset}:${fg_yellow}${basename}${attr_reset} "'! '
      fi
    elif [ "$(cat /proc/version | grep Red\ Hat)" ]; then
      # ${HOMEFRIES_TRACE} && echo "PS1: On Red Hat"

      PS1="${titlebar}${fg_cyan}${cur_user}@${fg_yellow}${mach_name}${attr_reset}:${fg_gray}${basename}${attr_reset}${prompt_symbol} "
    else
      echo "WARNING: _hf_prompt_customize_shell_prompts_and_window_title: Not enough info. to set PS1."
    fi
  else
    # This is a chroot jail without a mounted /proc.
    : # Just use default prompt.
  fi

  # NOTE: There's an alternative to PS1, PROMPT_COMMAND,
  #       which works if PS1 is empty.
  #         PS1=""
  #         PROMPT_COMMAND='echo -ne "\033]0;SOME TITLE HERE\007"'
  #       But the escapes don't work the same. E.g., this looks really funny:
  #         titlebar="\[\e]0;THIS IS A TEST\a\]"
  #         PROMPT_COMMAND='printf '%b' "${titlebar}\[\033[01;36m\]\u@\[\033[1;33m\]\h\[\033[00m\]:\[\033[01;37m\]\W\[\033[00m\]${prompt_symbol} "'
}

# ***

_hf_prompt_customize_shell_prompt_PS2 () {
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
home_fries_set_PS4 () {
  # Default is: PS4='+'
  PS4='(${BASH_SOURCE[0]}:${LINENO}): ${FUNCNAME[0]} - [${SHLVL},${BASH_SUBSHELL}, $?]
  '
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# NOTE: This function is a one-off, as it wouldn't be necessary to
#       call it more than once. So it cleans itself up rather than
#       hang around the environment.

_hf_set_terminal_prompt () {
  _hf_check_deps_set_shell_prompt || return $?
  unset -f _hf_check_deps_set_shell_prompt

  _hf_prompt_customize_shell_prompts_and_window_title

  unset -f _hf_prompt_is_user_logged_on_via_ssh
  unset -f _hf_prompt_user_is_not_trapped_in_chroot
  unset -f _hf_prompt_format_titlebar

  unset -f _hf_prompt_customize_shell_prompts_and_window_title
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

