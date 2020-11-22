#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# YOU: Uncomment to re-source this file.
#  unset -v _LOADED_HF_TERM_UTIL
${_LOADED_HF_TERM_UTIL:-false} && return || _LOADED_HF_TERM_UTIL=true

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# FIXME/2020-03-19 02:20: Add already-loaded flag to Home Fries, like Vim,
# e.g., this file being sourced twice on startup.

check_deps () {
  # Verify sh-colors/bin/colors.sh loaded.
  check_dep '_hofr_no_color'
  # Verify sh-logger/bin/logger.sh loaded.
  check_dep '_sh_logger_log_msg'
  # Verify distro_util.sh loaded.
  # - Including 'os_is_macos'.
  check_dep 'suss_window_manager'
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

DUBS_STICKY_PREFIX='(Dubs) '
DUBS_STICKY_PREFIX_RE='\(Dubs\) '

dubs_logged_on_via_ssh () {
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

user_not_trapped_chroot () {
  ( os_is_linux && [ $(stat -c %i /) -eq 2 ] ) ||
  ( os_is_macos && [ $(stat -f %i /) -eq 2 ] )
}

fries_format_titlebar () {
  # 2012.10.17: Also change the titlebar name for special terminal windows,
  #             like the log-tracing windows.
  # See: http://unix.stackexchange.com/questions/14113/
  # is-it-possible-to-set-gnome-terminals-title-to-userhost-for-whatever-host-i
  # Search: PROMPTING in `man bash`.
  #          \u is the username
  #          \h is the hostname up to the first '.'
  #          \W is the basename of the current working directory,
  #             with $HOME abbreviated with a tilde
  #          \[ and \] delimit a non-printing sequence w/ control chars;
  #             can be used to embed terminal control sequences into the prompt
  #          \e is an ASCII escape character (0nn)
  #          \e]0; is like ESC]0; and resets formatting (including color)
  #             since this string is for the window titlebar
  #          \a is the ASCII bell char (07)
  #             EXPLAIN: What does \a do?
  #                      Chime when you hit <BS> on an empty prompt?
  #                      But this is the window titlebar title... hmmm.
  # By default, the title bar is user@host:working-directory.
  # "The escape sequence to use is ESC]2;new titleBEL":
  #   https://wiki.archlinux.org/index.php/Bash/Prompt_customization#Customizing_the_terminal_window_title
  # Note also using wmctrl, e.g.,: `wmctrl -r :ACTIVE: -T "On ${1}"`
  #titlebar='\[\e]0;\u@\h:\W\a\]'
  # This does the same thing but uses octal ASCII escape chars instead of
  # bash's escape chars:
  #  titlebar='\[\033]2;\u@\h\007\]'
  # Gnome-terminal's default (though it doesn't specify it, it just is):
  #  titlebar='\[\e]0;\u@\h:\w\a\]'
  local basename='\W'
  local hellsbells='\a'

  local sticky_alert=''
  if ${DUBS_ALWAYS_ON_VISIBLE:-false}; then
    # MEH/2018-05-28: (lb): Make this settable... if anyone else ever uses Home Fries...
    sticky_alert="${DUBS_STICKY_PREFIX}"
  fi

  # Name this terminal window specially if special.
  # NOTE: This information comes from Gnome, where we've set the Gnome shortcut
  #       to pass this environment variable to us.
  # NOTE: To test gnome-terminal, run it from your home directory, otherwise it
  #       won't find your bash scripts.
  local titlebar
  if ! $(dubs_logged_on_via_ssh); then
    # echo "User not logged on via SSH"
    if [ "${HOMEFRIES_TITLE}" != '' ]; then
      titlebar="\[\e]0;${sticky_alert}${HOMEFRIES_TITLE}\a\]"
    elif user_not_trapped_chroot; then
      # Not in chroot jail.
      #  titlebar="\[\e]0;\u@\h:\w\a\]"
      #  titlebar="\[\e]0;\w:(\u@\h)\a\]"
      #  titlebar="\[\e]0;\w\a\]"
      titlebar="\[\e]0;${sticky_alert}${basename}\a\]"
    else
      # In chroot jail.
      titlebar="\[\e]0;|-${sticky_alert}${basename}-|\a\]"
    fi
  else
    # echo "User *is* logged on via SSH!"
    local -a choices
    #  choices+=("\[\e]0;${sticky_alert}$(hostname) → ${basename}${hellsbells}\]")
    choices+=("\[\e]0;${sticky_alert}$(hostname) 🦉 ${basename}${hellsbells}\]")
    choices+=("\[\e]0;${sticky_alert}$(hostname) 👗 ${basename}${hellsbells}\]")
    choices+=("\[\e]0;${sticky_alert}$(hostname) 🌊 ${basename}${hellsbells}\]")
    choices+=("\[\e]0;${sticky_alert}$(hostname) 🌿 ${basename}${hellsbells}\]")
    choices+=("\[\e]0;${sticky_alert}$(hostname) 🍍 ${basename}${hellsbells}\]")
    # Using RANDOM builtin.
    titlebar="${choices[$RANDOM % 5]}"
  fi

  printf "${titlebar}"
}

dubs_set_terminal_prompt () {
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

  local titlebar="$(fries_format_titlebar)"

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
  local u_anchor="⚓"             # ⚓  $(printf "\u2693")
  local u_evergreen_tree="🌲"     # 🌲  $(printf "\U1F332")
  local u_cactus="🌵"             # 🌵  $(printf "\U1F335")
  local u_mushroom="🍄"           # 🍄  $(printf "\U1F344")
  local u_skull="💀"              # 💀  $(printf "\U1F480")
  local u_owl="🦉"                # 🦉  $(printf "\U1F989")
  local u_herb="🌿"               # 🌿  $(printf "\U1F33F")
  local u_pineapple="🍍"          # 🍍  $(printf "\U1F34D")
  # (Draws too light to see:)
  #  local u_skull_n_xbones="☠"   # ☠  $(printf "\u2620")

  # NOTE: Using "" below instead of '' so that ${titlebar} is resolved by the
  #       shell first.
  # ${HOMEFRIES_TRACE} && echo "PS1: Preparing prompt"
  if [ -e /proc/version ] || os_is_macos ; then
    if [ $EUID -eq 0 ]; then
      # ${HOMEFRIES_TRACE} && echo "PS1: Running as root!"
      if os_is_macos || [ "$(cat /proc/version | grep Ubuntu)" ]; then
        # ${HOMEFRIES_TRACE} && echo "PS1: On Ubuntu"
        PS1="${titlebar}${bg_magenta}${fg_gray}${cur_user}@${fg_yellow}${mach_name}${attr_reset}:${fg_cyan}${basename}${attr_reset}\$ "
      elif [ "$(cat /proc/version | grep Red\ Hat)" ]; then
        # ${HOMEFRIES_TRACE} && echo "PS1: On Red Hat"
        PS1="${titlebar}${bg_magenta}${fg_gray}${cur_user}@${fg_yellow}${mach_name}${attr_reset}:${fg_gray}${basename}${attr_reset}\$ "
      else
        echo "WARNING: Not enough info. to set PS1."
      fi
    elif os_is_macos || [ "$(cat /proc/version | grep Ubuntu)" ]; then
      # ${HOMEFRIES_TRACE} && echo "PS1: On Ubuntu"
      # 2015.03.04: I need to know when I'm in chroot hell.
      # NOTE: There's a better way using sudo to check if in chroot jail
      #       (which is compatible with Mac, BSD, etc.) but we don't want
      #       to use sudo, and we know we're on Linux. And on Linux,
      #       the inode of the (outermost) root directory is always 2.
      # CAVEAT: This check works on Linux but probably not on Mac, BSD, Cygwin, etc.
      if $(dubs_logged_on_via_ssh); then
        # 2018-12-23: Killer.
        PS1="${titlebar}${fg_gray}${cur_user}$(attr_italic)$(attr_underline)$(fg_lightorange)@${mach_name}${attr_reset}:${fg_cyan}${basename}${attr_reset} ${u_skull} \$ "
      elif user_not_trapped_chroot; then
        #PS1="${titlebar}\[\033[01;37m\]\u@\[\033[1;33m\]\h\[\033[00m\]:\[\033[01;36m\]\W\[\033[00m\]\$ "
        # 2015.03.04: The chroot is Ubuntu 12.04, and it's Bash v4.2 does not
        #             support Unicode \uXXXX escapes, so use the escape in the
        #             outer. (Follow the directory path with an anchor symbol
        #             so I know I'm *not* in the chroot.)
        PS1="${titlebar}${fg_gray}${cur_user}@${fg_yellow}${mach_name}${attr_reset}:${fg_cyan}${basename}${attr_reset} ${u_mushroom} \$ "
        # 2015.02.26: Add git branch.
        #             Maybe... not sure I like this...
        #             maybe change delimiter and make branch name colorful?
        #PS1="${titlebar}\[\033[01;37m\]\u@\[\033[1;33m\]\h\[\033[00m\]:\[\033[01;36m\]\W\[\033[00m\]"'$(__git_ps1 "-%s" )\$ '
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
      PS1="${titlebar}${fg_cyan}${cur_user}@${fg_yellow}${mach_name}${attr_reset}:${fg_gray}${basename}${attr_reset}\$ "
    else
        echo "WARNING: dubs_set_terminal_prompt: Not enough info. to set PS1."
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
  #         PROMPT_COMMAND='printf '%b' "${titlebar}\[\033[01;36m\]\u@\[\033[1;33m\]\h\[\033[00m\]:\[\033[01;37m\]\W\[\033[00m\]\$ "'

  # 2018-05-28: How about a bold PS2 (continuation) prompt?
  #  PS2="$(tput bold)>${attr_reset} "
  #  PS2="$(tput bold)${attr_underlined}${fg_green}>${attr_reset} "
  #  PS2="$(tput bold)${fg_green}_${attr_reset} "
  #  PS2="$(tput bold)${attr_underlined}${fg_green} ${attr_reset} "
  #  PS2="${attr_underlined}${fg_green} ${attr_reset} "
  PS2="${fg_green}>${attr_reset} "
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# Auto-update mate-terminal window title.

# 2020-01-02: (lb): My first attempt using PROMPT_COMMAND failed,
# but then I learned that trapping DEBUG is the proper way. In any
# case, for posterity:
#
#   _fries_term_hook () {
#     # Works: Shows up before PS4 prompt, e.g.,
#     #       123user@host:/ $
#     #echo -n "123"
#     # Fails: Shows before PS4, e.g.,
#     #      ]0;echo -en ""user@host:/ $
#     #echo -en "\033]0;${BASH_COMMAND}\007"
#     # Fails: Prints line before every prompt, e.g.,
#     #     echo "${BASH_COMMAND}" 1>&2
#     #     user@host:/ $
#     #>&2 echo "${BASH_COMMAND}"
#     :
#   }
#
#   fries_hook_titlebar_update () {
#     if [[ ! ${PROMPT_COMMAND} =~ "_fries_term_hook" ]]; then
#       PROMPT_COMMAND="_fries_term_hook;${PROMPT_COMMAND}"
#     fi
#   }

fries_hook_titlebar_update () {
  # Show the command in the window titlebar.

  # MEH: (lb): I'd rather the title not flicker for fast commands,
  # but it's nice to have for long-running commands, like `man foo`
  # and `dob edit`, etc.

  # This overrides the title set in PS4 (which is, e.g., \W\a, which prints
  # the basename of the current directory; but fortunately it only overrides
  # it while the command is running: after the command completes, the \W\a
  # title is restored. This makes for a nice titlebar title that shows the
  # basename of the directory when the prompt is active, but shows the name
  # of the actively running command if there is one, e.g., `man bash`.
  trap 'printf "\033]0;%s\007" "${BASH_COMMAND}"' DEBUG
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
dubs_set_PS4 () {
  # Default is: PS4='+'
  PS4='(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]} - [${SHLVL},${BASH_SUBSHELL}, $?]
  '
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# Fix ls -C
###########

dubs_fix_terminal_colors () {
  # On directories with world-write (0002) privileges,
  # the directory name is blue on green, which is hard to read.
  # 42 is the green background, which we turn to white, 47.
  # Use the following commands to generate the export variable on your machine:
  #   dircolors --print-database
  #   dircolors --sh
  if [ -e /proc/version ]; then
    if [ "$(cat /proc/version | grep Ubuntu)" ]; then
      # echo Ubuntu!
      # EXPLAIN/2020-08-31 19:19: Why not just call `eval $(dircolors)` here?
      LS_COLORS='no=00:fi=00:di=01;34:ln=01;36:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:su=37;41:sg=30;43:tw=30;47:ow=34;47:st=37;44:ex=01;32:*.tar=01;31:*.tgz=01;31:*.svgz=01;31:*.arj=01;31:*.taz=01;31:*.lzh=01;31:*.lzma=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.dz=01;31:*.gz=01;31:*.bz2=01;31:*.bz=01;31:*.tbz2=01;31:*.tz=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.rar=01;31:*.ace=01;31:*.zoo=01;31:*.cpio=01;31:*.7z=01;31:*.rz=01;31:*.jpg=01;35:*.jpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.svg=01;35:*.mng=01;35:*.pcx=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.m2v=01;35:*.mkv=01;35:*.ogm=01;35:*.mp4=01;35:*.m4v=01;35:*.mp4v=01;35:*.vob=01;35:*.qt=01;35:*.nuv=01;35:*.wmv=01;35:*.asf=01;35:*.rm=01;35:*.rmvb=01;35:*.flc=01;35:*.avi=01;35:*.fli=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.yuv=01;35:*.aac=00;36:*.au=00;36:*.flac=00;36:*.mid=00;36:*.midi=00;36:*.mka=00;36:*.mp3=00;36:*.mpc=00;36:*.ogg=00;36:*.ra=00;36:*.wav=00;36:'
    elif [ "$(cat /proc/version | grep Red\ Hat)" ]; then
      # echo Red Hat!
      LS_COLORS='rs=0:di=01;34:ln=01;36:mh=00:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:su=37;41:sg=30;43:ca=30;41:tw=30;47:ow=34;47:st=37;44:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arj=01;31:*.taz=01;31:*.lzh=01;31:*.lzma=01;31:*.tlz=01;31:*.txz=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.dz=01;31:*.gz=01;31:*.xz=01;31:*.bz2=01;31:*.bz=01;31:*.tbz=01;31:*.tbz2=01;31:*.tz=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.rar=01;31:*.ace=01;31:*.zoo=01;31:*.cpio=01;31:*.7z=01;31:*.rz=01;31:*.lz=01;31:*.jpg=01;35:*.jpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.svg=01;35:*.svgz=01;35:*.mng=01;35:*.pcx=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.m2v=01;35:*.mkv=01;35:*.ogm=01;35:*.mp4=01;35:*.m4v=01;35:*.mp4v=01;35:*.vob=01;35:*.qt=01;35:*.nuv=01;35:*.wmv=01;35:*.asf=01;35:*.rm=01;35:*.rmvb=01;35:*.flc=01;35:*.avi=01;35:*.fli=01;35:*.flv=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.yuv=01;35:*.axv=01;35:*.anx=01;35:*.ogv=01;35:*.ogx=01;35:*.aac=00;36:*.au=00;36:*.flac=00;36:*.mid=00;36:*.midi=00;36:*.mka=00;36:*.mp3=00;36:*.mpc=00;36:*.ogg=00;36:*.ra=00;36:*.wav=00;36:*.axa=00;36:*.oga=00;36:*.spx=00;36:*.xspf=00;36:';
    fi
    if [ -n "${LS_COLORS}" ]; then
      export LS_COLORS
    fi
  elif command -v gdircolors > /dev/null; then
    # 2020-08-31: macOS support.
    # Note that `gdircolors` (and `dircolors`) prints two lines, the first,
    # `LS_COLORS='...'`, and then `export LS_COLORS`, so just eval its output.
    eval $(gdircolors)
  else
    # In an unrigged chroot, so no /proc/version.
    : # Nada.
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# FIXME/2020-03-12 02:41: Unused: Can probably delete this function.

invoked_from_terminal () {
  # E.g., Consider the fcn. and script,
  #
  #   echo 'test_f () { echo $0; }; test_f' > test.sh
  #
  # and the outputs,
  #
  #   $ ./test.sh
  #   ./test.sh
  #
  #   $ source test.sh
  #   /bin/bash
  #
  # Note: Sometimes the second command returns just 'bash', depending
  #       on how the terminal was invoked.
  #
  # There might be a better way to do this, but it seems checking the
  # name of file is sufficient to determine if calling `exit` will
  # just kill a script or if it will exit the user's terminal.

  local bashed=0
  if [ $(printf "$0" | grep "bash$" -) ]; then
    bashed=1
  fi

  return ${bashed}
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# NOTE: In addition to [ -t 1 ], there are other ways to test if there is a tty
#       attached or not. But the other methods I tried didn't work.
#
# - Consider how the -t test works:
#
#   $ if [ -t 1 ]; then >&2 echo TERMinal; else >&2 echo NOTERM; fi
#   TERMinal
#   $ /bin/bash -c 'if [ -t 1 ]; then >&2 echo TERMinal; else >&2 echo NOTERM; fi'
#   TERMinal
#   $ echo -e '#!/bin/bash\nif [ -t 1 ]; then >&2 echo TERMinal; else >&2 echo NOTERM; fi' \
#     > /tmp/test.sh && chmod 775 /tmp/test.sh && /tmp/test.sh
#   TERMinal
#
# - Compare that to another interactive terminal test, the $- 'i' flag, e.g.,:
#
#   [[ "$-" =~ .*i.* ]] && return 1 || return 0
#
#   And consider how it behaves differently in a subshell:
#
#   $ [[ "$-" =~ .*i.* ]] && echo YES || echo NO
#   YES
#   $ /bin/bash -c '[[ "$-" =~ .*i.* ]] && echo YES || echo NO'
#   NO
#   $ echo -e "#!/bin/bash\n[[ \"\$-\" =~ .*i.* ]] && echo YES || echo NO\n" \
#       > /tmp/test.sh && chmod 775 /tmp/test.sh && /tmp/test.sh
#   NO
#
# - See also testing `$PS1`, oddly enough, e.g.,
#
#   [ -z "$PS1" ] && return 0 || return 1
#
#   And:
#
#   $ echo $PS1
#   \[\e...
#   $ /bin/bash -c 'echo $PS1'
#   # EMPTY
#   $ echo -e '#!/bin/bash\necho $PS1' > /tmp/test.sh && /tmp/test.sh
#   # EMPTY
#
# So for this to all work, use [ -t 1 ].
#
# Ref: man test (and man bash):
#
#     -t FD  file descriptor FD is opened on a terminal
#
# Ref: man bash:
#
#     PS1 is set and $- includes i if bash is interactive, allowing
#     a shell script or a startup file to test this state.

stdout_isatty () {
  [ -t 1 ]
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

get_terminal_window_ids () {
  # 2018-02-14: `xdotool search` is returning 1 more than the number of
  # mate-terminals. I thought it was if I ran bash within bash within a
  # terminal, but that wasn't the case. Not sure what it is. But there's
  # another way we can get exactly what we want, with `wmctrl` instead.
  #   xdotool search --class "${WM_TERMINAL_APP}"
  wmctrl -l -x | grep "${WM_TERMINAL_APP}" | awk '{print $1}'
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# Send commands to all the terminal windows.

# But first,
#  some xdotool notes...
#
# If you don't specify what to search, xdotool adds to stderr,
#   "Defaulting to search window name, class, and classname"
# We can search for the app name using --class or --classname.
#   xdotool search --class "mate-terminal"
# Translate the window IDs to their terminal titles:
#   xdotool search --class "mate-terminal" | xargs -d '\n' -n 1 xdotool getwindowname
# 2016-05-04: Note that the first window in the list is named "Terminal",
#   but it doesn't correspond to an actual terminal, it doesn't seem.
#     $ RESPONSE=$(xdotool windowactivate 77594625 2>&1)
#     $ echo $RESPONSE
#     XGetWindowProperty[_NET_WM_DESKTOP] failed (code=1)
#     $ echo $?
#     0
#   What's worse is that that window hangs on activate.
#     $ xdotool search --class mate-terminal -- windowactivate --sync %@ type "echo 'Hello buddy'\n"
#     XGetWindowProperty[_NET_WM_DESKTOP] failed (code=1)
#     [hangs...]
#   Fortunately, like all problems, this one can be solved with bash, by
#   checking the desktop of the terminal window before sending it keystrokes.

termdo-all () {
  suss_window_manager
  local THIS_WINDOW_ID=$(xdotool getactivewindow)
  local WINDOW_IDS=$(get_terminal_window_ids)
  local winid
  for winid in ${WINDOW_IDS}; do
    # Don't send the command to this window, at least not yet, since it'll
    # end up on stdin of this fcn. and won't be honored as a bash command.
    if [ ${THIS_WINDOW_ID} -ne ${winid} ]; then
      # See if this is a legit window or not.
      local DESKTOP_NUM=$(xdotool get_desktop_for_window ${winid} 2> /dev/null)
      # For real terminal, the number is 0 or greater;
      # for the fakey, it's 0, and also xdotool returns 1.
      if [ $? -eq 0 ]; then
        # This was my first attempt, before realizing the obvious.
        #   if false; then
        #     xdotool windowactivate --sync $winid
        #     sleep .1
        #     xdotool type "echo 'Hello buddy'
        ##"
        #     # Hold on a millisec, otherwise I've seen, e.g., the trailing
        #     # character end up in another terminal.
        #     sleep .2
        #   fi
        # And then this is the obvious:

        # Oh, wait, the type and key commands take a window argument...
        # NOTE: Without the quotes, e.g., xdotool type --window $winid $*,
        #       you'll have issues, e.g., xdotool sudo -K
        #       shows up in terminals as, sudo-K: command not found
        # NOTE: If you've bash'ed within a session, you'll find all 'em.
        #       And you'll xdotool them all. But not a big deal?
        xdotool windowactivate --sync ${winid} type "$*"
        # Note that 'type' isn't always good with newlines, so use 'key'.
        # 2018-02-14 16:42: Revisit that comment. Docs make it seem like newlines ok.
        xdotool windowactivate --sync ${winid} key Return
      fi
    fi
  done
  # Bring original window back to focus.
  xdotool windowactivate --sync ${THIS_WINDOW_ID}
  # Now we can do what we did to the rest to ourselves.
  eval $*
}

# Test:
if false; then
  termdo-all "echo Wake up get outta bed
"
fi

termdo-reset () {
  suss_window_manager
  local THIS_WINDOW_ID=$(xdotool getactivewindow)
  local WINDOW_IDS=$(get_terminal_window_ids)
  local winid
  for winid in $WINDOW_IDS; do
    if [ $THIS_WINDOW_ID -ne $winid ]; then
      local DESKTOP_NUM=$(xdotool get_desktop_for_window $winid 2> /dev/null)
      if [ $? -eq 0 ]; then
        # Note that the terminal from whence this command is being run
        # will get the keystrokes -- but since the command is running,
        # the keystrokes sit on stdin and are ignored. Then along comes
        # the ctrl-c, killing this fcn., but not until after all the other
        # terminals also got their fill.

        xdotool windowactivate --sync ${winid} key ctrl+c
        xdotool windowactivate --sync ${winid} type "cd $1"
        # Hrmm. 'Ctrl+c' and 'ctrl+c' are acceptable, but 'return' is not.
        xdotool windowactivate --sync ${winid} key Return
      fi
    fi
  done
  # Bring original window back to focus.
  xdotool windowactivate --sync ${THIS_WINDOW_ID}
  # Now we can act locally after having acted globally.
  cd $1
}

termdo-cmd () {
  suss_window_manager
  local THIS_WINDOW_ID=$(xdotool getactivewindow)
  local WINDOW_IDS=$(get_terminal_window_ids)
  local winid
  for winid in $WINDOW_IDS; do
    if [ $THIS_WINDOW_ID -ne ${winid} ]; then
      local DESKTOP_NUM=$(xdotool get_desktop_for_window ${winid} 2> /dev/null)
      if [ $? -eq 0 ]; then

        xdotool windowactivate --sync ${winid} key ctrl+c
        xdotool windowactivate --sync ${winid} key ctrl+d
        xdotool windowactivate --sync ${winid} type "$1"
        # Hrmm. 'Ctrl+c' and 'ctrl+c' are acceptable, but 'return' is not.
        xdotool windowactivate --sync ${winid} key Return
      fi
    fi
  done
  # Bring original window back to focus.
  xdotool windowactivate --sync ${THIS_WINDOW_ID}
  # Now we can act locally after having acted globally.
  eval $1
}

termdo-sudo-reset () {
  # sudo security
  # -------------
  # Make all-terminal fcn. to revoke sudo on all terms,
  # to make up for security hole of leaving terminals sudo-ready.
  # Then again, real reason against is doing something dumb,
  # so really you should always be sudo-promted.
  # But maybe the answer is really a confirm prompt,
  # not a password prompt (like in Windows, ewwwww!). -summer2016
  termdo-all "echo termdo-sudo-reset says"
  termdo-all sudo -K
}

# FIXME/MAYBE: Add a close-all fcn:
#               1. Send ctrl-c
#               2. Send exit one or more times (to exit nested shells)

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

enable_vi_style_editing () {
  # Vi-style editing.

  # MAYBE:
  #  set -o vi

  # Use ``bind -P`` to see the current bindings.

  # See: http://www.catonmat.net/download/bash-vi-editing-mode-cheat-sheet.txt
  # (from http://www.catonmat.net/blog/bash-vi-editing-mode-cheat-sheet/)
  # (also http://www.catonmat.net/download/bash-vi-editing-mode-cheat-sheet.pdf)

  # See: http://vim.wikia.com/wiki/Use_vi_shortcuts_in_terminal
  :
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# 2020-08-25: Replace ${VAR^^} with POSIX-compliant pipe chain (because macOS's
# deprecated Bash is 3.x and does not support ${VAR^^} capitalization operator,
# and the now-default zsh shell does not support ${VAR^^} capitalization).
first_char_capped () {
  printf "$1" | cut -c1-1 | tr '[:lower:]' '[:upper:]'
}

# 2017-06-06: Still refining Bash input experience.
default_yes_question () {
  printf %s "Tell me yes or no. [Y/n] "
  read -e YES_OR_NO
  if [ -z "${YES_OR_NO}" ] || [ "$(first_char_capped ${YES_OR_NO})" = 'Y' ]; then
    echo "YESSSSSSSSSSSSS"
  else
    echo "Apparently not"
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

echoerr () (
  IFS=" "
  printf '%s\n' "$*" 1>&2
)

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# 2018-05-28: Bounce around workspaces. (lb): Metacity is griefing when
# I Alt-Tab between windows: It switches desktops to the window's owning
# desktop. You don't notice if the window is pinned to the current
# desktop, but if the the window is set to "Always on Visible Workspace",
# you might switch desktops! One option is to right-click on the window
# in the window list, send it to the desktop within which you want to
# work, switch to that desktop, and then enables always-on-visible. Or,
# you could just run this command and bring your windows to the desired
# desktop.
# 2019-01-05: And... now it seems the issue for which space() was writ
# to address is not longer an issue in 18.04. When I switch desktops
# by clicking in the applet widget and then alt-tab between windows,
# the desktop is not unexpectedly changing to another one. Thank you,
# whomeever fixed this bug! (I think between 14.04 and 18.04; not sure
# if it inflicted 16.04). / That said, space() is still useful to run
# at least once to make certain browser tabs and other application
# windows sticky.

space () {
  local re_num='^[1-4]+$'
  if ! [[ $1 =~ ${re_num} ]]; then
    echo 'USAGE: space [1-4]' 1>&2
    return 1
  fi
  local wspace=$(($1 - 1))
  local active_window=$(xdotool getactivewindow)
  echo "Reassigning sticky windows' parents..."
  # Early solution: Move known windows according to business logic.
  #  xdotool search --name '(Dubs)|SAMPI' | xargs -I % echo wmctrl -t ${wspace} -b add,sticky -i -r %
  #  xdotool search --name '(Dubs)|SAMPI' | xargs -I % wmctrl -t ${wspace} -b add,sticky -i -r %
  # Better solution: Move all windows known to be always-on-visible.
  # wmctrl:
  #   -t: desktop no.
  #   -i: -r is an integer
  #   -r: window str or id
  #   -b: modify property
  # NOTE: (lb): Apologies for the Business Logic, but the Gnome 2 Launcher
  #       Panels should not be touched. These are identified by:
  #
  #           | /bin/grep -v 'Bottom Expanded Edge Panel$' \
  #
  #       I mean, they can be touched, and all will seem well, but sometime in
  #       the future, when you double-click a window titlebar to maximize it,
  #       you'll see it's bottom edge goes beneath the bottom panels. (And I'm
  #       sure it should really just be 'Edge Panel$', to include cases where
  #       the panel is elsewhere (Left, Top, or Right), or where the panel is
  #       not expanded fully. But none of those cases apply to me, so ignoring.)
  winids=($(wmctrl -l \
    | /bin/grep -E '^0x[a-f0-9]{8} +-1 ' \
    | /bin/grep -v 'Bottom Expanded Edge Panel$' \
    | awk '{print $1}'))
  #printf "%s\n" "${winids[@]}" | xargs -I % echo wmctrl -t ${wspace} -b add,sticky -i -r %
  for winid in ${winids[@]}; do
    # Just for enduser enjoyment.
    echo_wmctrl_sticky_cmd_winid "${winid}"
  done
  # NOTE: Combining the 2 commands seems to work, but it doesn't:
  #  | xargs -I % wmctrl -t ${wspace} -b add,sticky -i -r %
  # So do the 2 operations separately.
  printf "%s\n" "${winids[@]}" | xargs -I % wmctrl -t ${wspace} -i -r %
  # Change active desktop. Can come before or after adding sticky.
  echo "Switching to Desktop “${wspace}” aka Workspace “$1”."
  wmctrl -s ${wspace}
  printf "%s\n" "${winids[@]}" | xargs -I % wmctrl -b add,sticky -i -r %
  # Restore previously active window.
  wmctrl -i -a ${active_window}
}

echo_wmctrl_sticky_cmd_winid () {
  local winid=$1
  printf '%s%b\n' \
    " wmctrl -b add,sticky -i -r ${winid}" \
    " $(fg_mintgreen)$(wmctrl -l | grep "^${winid}" | cut -d ' ' -f 4-)$(attr_reset)"
}

echo_wmctrl_sticky_cmd_winname () {
  local winname=$1
  local winid=$(wmctrl -l | grep "${winname}$" | cut -d ' ' -f 1)
  if [ -n "${winid}" ]; then
    winid="$(fg_mintgreen)${winid}"
  else
    #winid='~NOTFOUND~'
    #winid="$(fg_lightorange)${winid}"
    # On second thought, don't pollute.
    return
  fi
  printf '%b\n' " wmctrl -b add,sticky -i -r ${winid}$(attr_reset) ${winname}"
}

# TIPS: You can add your own, personal windows to the sticky list,
#       so that running `space` will make all your favorite windows
#       sticky. E.g.,
if false; then
  # —————— ✂ ——— ✁ —————— [ copy-paste ] —————— ✁ ——— ✂ ——————

  private_space () {
    declare -a winnames=()
    # Dubs Vim, e.g., if you send files to the same GVim with:
    #  gvim --servername SAMPI --remote-silent path/to/file
    winnames+=("SAMPI")
    # E.g., Gmail, etc.
    winnames+=("[mM]ail - Chromium")
    winnames+=("[mM]ail - Google Chrome")
    # Music apps 'n tabs:
    winnames+=("Live Stream | The Current from Minnesota Public Radio - Chromium")
    winnames+=("Live Stream | The Current from Minnesota Public Radio - Google Chrome")
    winnames+=("Spotify")
    for (( i = 0; i < ${#winnames[@]}; i++ )); do
      echo_wmctrl_sticky_cmd_winname "${winnames[$i]}"
      # We could just use -r, e.g.,
      #   wmctrl -b add,sticky -r "${winnames[$i]}"
      # But Grep let's us be a little more precise (i.e., use $ for EOL).
      local winid=$(wmctrl -l | grep "${winnames[$i]}$" | cut -d ' ' -f 1)
      if [ -n "${winid}" ]; then
        wmctrl -b add,sticky -i -r ${winid}
      fi
    done
  }

  monkey_patch_space () {
    # Remove the first two lines and last line, e.g.,:
    #   function()
    #   {
    #     ...
    #   }
    old_space=$(declare -f space | tail -n +3 | head -n -1)

    space () {
      # Meh. Don't validate the desktop number before making windows sticky.
      # (We need to do this before running old_space, to ensure that our
      #  favorite windows are sticky first, before reassigning sticky parents.
      #  Also, if we do this after old_space, there's a little screen flicker
      #  that makes that sequence look unnatural, ick.)

      echo "Making ${LOGNAME}'s windows sticky..."
      private_space

      eval "${old_space}"
    }
  }

  # —————— ✂ ——— ✁ —————— [ copy-paste ] —————— ✁ ——— ✂ ——————
fi

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

sleep_then_ensure_always_on_visible_desktop () {
  if ${DUBS_ALWAYS_ON_VISIBLE:-false}; then
    sleep 3  #  MAGIC_NUMBER: It takes a few seconds for Home Fries to load.
    local winids
    winids=($(wmctrl -l -p \
      | /bin/grep -E "^0x[a-f0-9]{8} +-?[0-3] +[0-9]+ +$(hostname) +${DUBS_STICKY_PREFIX_RE}" \
      | cut -d ' ' -f 1))
    printf "%s\n" "${winids[@]}" | xargs -I % wmctrl -b add,sticky -i -r %
  fi
}

dubs_always_on_visible_desktop () {
  if ${DUBS_ALWAYS_ON_VISIBLE:-false}; then
    # (lb): Gah. If you open lots of windows at once (or just change
    # focus to another window as the terminal is loading [as Home Fries
    # loads], the script's terminal window may no longer be the active
    # window! Like, duh! So this is no good:
    #
    #   wmctrl -r :ACTIVE: -b add,sticky
    #
    # Because I am unable to figure out how to find the owning window ID...
    # (I tried `xdotool search --pid $PPID`, but it appears all shells have
    # the same parent process, the one and only `mate-terminal`. And the
    # windows are not attached to the child, i.e., ``xdotool search --pid $$`
    # shows nothing (and `wmctrl -l -p` confirms that all terminal windows
    # share the same process ID (of the mate-terminal parent)), it looks like
    # our best bet is to use that special title prefix we set just prior to
    # this code being called (in dubs_set_terminal_prompt).
    #
    # Ug again. I thought the title would be set already, but it's not...
    #
    #  winids=($(wmctrl -l -p \
    #    | /bin/grep -E "^0x[a-f0-9]{8} +-?[0-3] +[0-9]+ +$(hostname) +${DUBS_STICKY_PREFIX_RE}" \
    #    | cut -d ' ' -f 1))
    #
    # So rely on special default title in use before ours applies... "Terminal".
    # ... Ug triple! Other windows also have that name while loading, duh!
    #
    #   winids=($(wmctrl -l -p \
    #     | /bin/grep -E "^0x[a-f0-9]{8} +-?[0-3] +[0-9]+ +$(hostname) +Terminal$" \
    #     | cut -d ' ' -f 1))
    #
    # So, like, really? A total kludge is in order?! Deal with this "later!"
    #
    # NOTE: Use (subshell) to suppress output (e.g., job number and 'Done').
    (sleep_then_ensure_always_on_visible_desktop &)
    # Lest we apply same always-on to any new window opened as child of this one.
    export DUBS_ALWAYS_ON_VISIBLE=
  fi

  unset -f sleep_then_ensure_always_on_visible_desktop
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# MAYBE/2020-09-09 15:58: Consider moving to .inputrc, e.g.,:
#   #bind \\C-b:unix-filename-rubout
#   bind "\C-b": unix-filename-rubout
# https://superuser.com/questions/606212/bash-readline-deleting-till-the-previous-slash

# DOCS/2020-09-09 16:00: Use Ctrl-b in shell to delete backward to space or slash.

#  $ bind -P | grep -e unix-filename-rubout -e C-b
#  backward-char can be found on "\C-b", "\eOD", "\e[D".
#  unix-filename-rubout is not bound to any keys
#
#  # Essentially, default <C-b> moves cursor back one, same as left arrow.
#
#  $ bind \\C-b:unix-filename-rubout
#  $ bind -P | grep unix-filename-rubout
#  unix-filename-rubout can be found on "\C-b".
dubs_hook_filename_rubout () {
  local expect_txt
  expect_txt='unix-filename-rubout is not bound to any keys'
  if [[ $expect_txt != $(bind -P | grep -e unix-filename-rubout) ]]; then
    return
  fi
  expect_txt='backward-char can be found on '
  if [[ "$(bind -P | grep C-b)" != "${expect_txt}"* ]]; then
    return
  fi

  bind \\C-b:unix-filename-rubout
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# 2020-03-20: I really need to split this file into dozens of little plugs!
# - For now, adding just another function to this really long file.
# - I don't normally care about Ctrl-s too much, but I find that the more
# I run Vim in a terminal (because I'm wicked into tmux panes recently),
# the more I inadvertently type Ctrl-s, thinking that I'm saving, then
# freaking out for a split second thinking my machine or Vim froze, to
# getting frustrated that I typed Ctrl-s and need to Ctrl-q, then :w. Ug.
# - tl;dr Make Ctrl-s work in terminal vim.
# - AFAIK, XON/XOFF flow control is only used for serial connections
#   (RS-232), so nothing lost by disabling this.
# - Ref: Some interesting background information on these settings:
#     https://unix.stackexchange.com/questions/12107/
#       how-to-unfreeze-after-accidentally-pressing-ctrl-s-in-a-terminal#12146
unhook_stty_ixon_ctrl_s_xon_xoff_flow_control () {
  # Disable XON/XOFF flow control, and sending of start/stop characters,
  # i.e., reclaim Ctrl-s and Ctrl-q.
  # - (lb): For whatever reason, -ixoff is already default for me, even on
  #           bash --noprofile --norc
  stty -ixon -ixoff
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

dubs_macos_silence_bash_warning () {
  os_is_macos || return
  # 2020-08-25: Disable "The default interactive shell is now zsh" alert.
  export BASH_SILENCE_DEPRECATION_WARNING=1
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

dubs_macos_alias_clear_really_clear () {
  # Clear the screen, and then clear the scrollback buffer.
  #
  # - "Terminal supports an extension of the ED (Erase in Display)
  #    escape sequence to erase the scroll-back."
  #
  #     https://apple.stackexchange.com/questions/31872/
  #       how-do-i-reset-the-scrollback-in-the-terminal-via-a-shell-command
  #
  #     ESC [ Ps J
  #
  #       Parameter   Parameter Meaning
  #
  #       0           Erase from the active position to the end of the screen
  #       1           Erase from start of the screen to the active position
  #       2           Erase all of the display
  #
  #    https://www.vt100.net/docs/vt100-ug/chapter3.html#ED

  # See also Edit > Clear Buffer (Cmd-K) in iTerm2.

  # 1st answer to SE.com Q, 63 (up)votes [2020-09-18], is
  # calling `clear` and sending ED command (see above).
  #
  #   alias clear='clear && printf "\\e[3J"'

  # 2nd answer to SE.com Q, 31 (up)votes, suggests Cmd-K
  # (View > Clear scrollback), and even automating with
  # osascript, but a few issues:
  # - This is OS and terminal application dependent; it'd
  #   be better to use a portable, generic shell solution.
  # - The author suggests using an osascript so you can at
  #   least create a shell alias, but the command is still
  #   OS- and application-dependent. E.g.,
  #     osascript -e \
  #       'tell application "System Events" to keystroke "k" using command down'
  # - I've found that osascript is slow.

  # 3rd answer to SE.com Q, 12 (up)votes:
  # - The author suggests chaining CSI commands:
  #   - CSI 2 J (E2): Clear visible.
  #   - CSI 3 J (The "E3 extension"): Clear scrollback.
  #   - CSI 1 ; 1 H (Cursor Position (CUP) command): Cursor to top-left.
  # - I like this version -- it's explicit and seems the most universal.
  # - Also, `clear` on Linux Mint 19.3 seems to clear scrollback back
  #   not visible, but it also scrolls the view so it looks like the
  #   screen is blank, but if you page up, you'll see one screenful
  #   of scrollback. Fail!
  # - Ref:
  #   - See *HISTORY* in `man clear`
  #   - See *XTerm Control Sequences*,
  #     e.g., https://www.x.org/docs/xterm/ctlseqs.pdf
  #   - See *Erase in Display (ED)*
  #     https://en.wikipedia.org/wiki/ANSI_escape_code#CSI_sequences
  #     https://en.wikipedia.org/wiki/ANSI_escape_code#Terminal_output_sequences
  #     https://www.vt100.net/docs/vt100-ug/chapter3.html#ED
  # - Meh:
  #   - The CUP default is 1,1, so '\033[1;1H' → '\033[;H' → '\033[H';
  #     also '\033' → '\e', so this could be shortened
  #            printf "\\e[2J\\e[3J\\e[;H"'
  #     but for some reason (compatibility?) I generally prefer \033 over \e.
  alias clear='printf "\\033[2J\\033[3J\\033[1;1H"'
  # Why not also do the same for `reset`, which you can type with one hand.
  alias reset='printf "\\033[2J\\033[3J\\033[1;1H"'
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main () {
  check_deps
  unset -f check_deps

  unhook_stty_ixon_ctrl_s_xon_xoff_flow_control
}

main "$@"
unset -f main

