#!/bin/bash
# vim:tw=0:ts=2:sw=2:et:norl:

# File: term_util.sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project Page: https://github.com/landonb/home-fries
# Summary: Generic Bash function library.
# License: GPLv3

# Usage: Source this script. Call its functions. Use its exports.

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

source_deps() {
  local curdir=$(dirname -- "${BASH_SOURCE[0]}")
  # determine_window_manager
  source ${curdir}/distro_util.sh
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

function dubs_set_terminal_prompt() {
  local ssh_host=$1

  # Configure a colorful prompt of the following format:
  #  user@host:dir
  # See <http://www.termsys.demon.co.uk/vtansi.htm>
  #  for more about colours.
  #  There's a nifty chart at <http://www.frexx.de/xterm-256-notes/>
  #export PS1='\u@\[\033[0;35m\]\h\[\033[0;33m\][\W\[\033[00m\]]: '
  #export PS1='\u@\[\033[0;32m\]\h\[\033[0;36m\][\W\[\033[00m\]]: '
  # A;XYm ==>
  #   A=1 means bright
  #   XY=30 is Black  31 Red      32 Green  33 Yellow
  #      34    Blue   35 Magenta  36 Cyan   37 White
  #   X=3 is Foreground, =4 is Background colors, i.e., 47 is White BG
  #export PS1='\[\033[1;37m\]\u@\[\033[1;33m\]\h\[\033[1;36m\][\W\[\033[00m\]]: '
  #from debian .bashrc
  #PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

  # 2012.10.17: Also change the titlebar name for special terminal windows,
  #             like the log-tracing windows.
  # See: http://unix.stackexchange.com/questions/14113/
  # is-it-possible-to-set-gnome-terminals-title-to-userhost-for-whatever-host-i
  # Search: PROMPTING in `man bash`.
  #          \u is the username
  #          \h is the hostname up to the first '.'
  #          \W is the basename of the current working directory,
  #             with $HOME abbreviated with a tilde
  #          \[ and \] delimit a non-printing sequence w/ control chars; can
  #          b  e used to embed terminal control sequences into the prompt
  #          \e is an ASCII escape character (0nn)
  #          \e]0; is like ESC]0; and resets formatting (including color)
  #             since this string is for the window titlebar
  #          \a is the ASCII bell char (07)
  #             EXPLAIN: What does \a do?
  #                      Chime when you hit <BS> on an empty prompt?
  #                      But this is the window titlebar title... hmmm.
  # By default, the title bar is user@host:working-directory.
  local titlebar='\[\e]0;\u@\h:\W\a\]'
  # This does the same thing but uses octal ASCII escape chars instead of
  # bash's escape chars:
  #  titlebar='\[\033]2;\u@\h\007\]'
  # Gnome-terminal's default (though it doesn't specify it, it just is):
  #  titlebar='\[\e]0;\u@\h:\w\a\]'

  # Name this terminal window specially if special.
  # NOTE: This information comes from Gnome, where we've set the Gnome shortcut
  #       to pass this environment variable to us.
  # NOTE: To test gnome-terminal, run it from your home directory, otherwise it
  #       won't find your bash scripts.
  if [[ "$ssh_host" == "" ]]; then
    if [[ "$DUBS_TERMNAME" != "" ]]; then
      titlebar="\[\e]0;${DUBS_TERMNAME}\a\]"
    elif [[ $(stat -c %i /) -eq 2 ]]; then
      # Not in chroot jail.
      #titlebar='\[\e]0;\u@\h:\w\a\]'
      #titlebar='\[\e]0;\w:(\u@\h)\a\]'
      #titlebar='\[\e]0;\w\a\]'
      titlebar='\[\e]0;\W\a\]'
    else
      titlebar='\[\e]0;|-\W-|\a\]'
    fi
  else
    titlebar="\[\e]0;On ${ssh_host}\a\]"
  fi

  # 2012.10.17: The default bash includes ${debian_chroot:+($debian_chroot)} in
  # the PS1 string, but it really shouldn't be set on any of our systems (it's
  # pretty much obsolete, or at least pertains to a linux usage we're not).
  # "Chroot is a unix feature that lets you restrict a process to a subtree of
  # the filesystem." See:
  #  http://unix.stackexchange.com/questions/3171/what-is-debian-chroot-in-bashrc
  #  https://en.wikipedia.org/wiki/Chroot

  # NOTE: Using "" below instead of '' so that ${titlebar} is resolved by the
  #       shell first.
  $DUBS_TRACE && echo "Setting prompt"
  if [[ -e /proc/version ]]; then
    if [[ $EUID -eq 0 ]]; then
      $DUBS_TRACE && echo "Running as root!"
      if [[ "`cat /proc/version | grep Ubuntu`" ]]; then
        $DUBS_TRACE && echo "Ubuntu"
        PS1="${titlebar}\[\033[01;45m\]\[\033[01;37m\]\u@\[\033[1;33m\]\h\[\033[00m\]:\[\033[01;36m\]\W\[\033[00m\]\$ "
      elif [[ "`cat /proc/version | grep Red\ Hat`" ]]; then
        $DUBS_TRACE && echo "Red Hat"
        PS1="${titlebar}\[\033[01;45m\]\[\033[01;37m\]\u@\[\033[1;33m\]\h\[\033[00m\]:\[\033[01;37m\]\W\[\033[00m\]\$ "
      else
        echo "WARNING: Not enough info. to set PS1."
      fi
    elif [[ "`cat /proc/version | grep Ubuntu`" ]]; then
      $DUBS_TRACE && echo "Ubuntu"
      # 2015.03.04: I need to know when I'm in chroot hell.
      # NOTE: There's a better way using sudo to check if in chroot jail
      #       (which is compatible with Mac, BSD, etc.) but we don't want
      #       to use sudo, and we know we're on Linux. And on Linux,
      #       the inode of the (outermost) root directory is always 2.
      # CAVEAT: This check works on Linux but probably not on Mac, BSD, Cygwin, etc.
      if [[ $(stat -c %i /) -eq 2 ]]; then
        #PS1="${titlebar}\[\033[01;37m\]\u@\[\033[1;33m\]\h\[\033[00m\]:\[\033[01;36m\]\W\[\033[00m\]\$ "
        # 2015.03.04: The chroot is Ubuntu 12.04, and it's Bash v4.2 does not
        #             support Unicode \uXXXX escapes, so use the escape in the
        #             outer. (Follow the directory path with an anchor symbol
        #             so I know I'm *not* in the chroot.)
        PS1="${titlebar}\[\033[01;37m\]\u@\[\033[1;33m\]\h\[\033[00m\]:\[\033[01;36m\]\W\[\033[00m\]"$' \u2693 '"\$ "
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
        PS1="${titlebar}\[\033[01;31m\]**\u@**\[\033[1;36m\]\h\[\033[00m\]:\[\033[01;33m\]\W\[\033[00m\] "'! '
      fi
    elif [[ "`cat /proc/version | grep Red\ Hat`" ]]; then
      $DUBS_TRACE && echo "Red Hat"
      PS1="${titlebar}\[\033[01;36m\]\u@\[\033[1;33m\]\h\[\033[00m\]:\[\033[01;37m\]\W\[\033[00m\]\$ "
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
  #         PROMPT_COMMAND='echo -ne "${titlebar}\[\033[01;36m\]\u@\[\033[1;33m\]\h\[\033[00m\]:\[\033[01;37m\]\W\[\033[00m\]\$ "'
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
dubs_set_PS4() {
  # Default is: PS4='+'
  PS4='(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]} - [${SHLVL},${BASH_SUBSHELL}, $?]
  '
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# Fix ls -C
###########

dubs_fix_terminal_colors() {
  # On directories with world-write (0002) privileges,
  # the directory name is blue on green, which is hard to read.
  # 42 is the green background, which we turn to white, 47.
  # Use the following commands to generate the export variable on your machine:
  # dircolors --print-database
  # dircolors --sh
  if [[ -e /proc/version ]]; then
    if [[ "`cat /proc/version | grep Ubuntu`" ]]; then
      # echo Ubuntu!
      LS_COLORS='no=00:fi=00:di=01;34:ln=01;36:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:su=37;41:sg=30;43:tw=30;47:ow=34;47:st=37;44:ex=01;32:*.tar=01;31:*.tgz=01;31:*.svgz=01;31:*.arj=01;31:*.taz=01;31:*.lzh=01;31:*.lzma=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.dz=01;31:*.gz=01;31:*.bz2=01;31:*.bz=01;31:*.tbz2=01;31:*.tz=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.rar=01;31:*.ace=01;31:*.zoo=01;31:*.cpio=01;31:*.7z=01;31:*.rz=01;31:*.jpg=01;35:*.jpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.svg=01;35:*.mng=01;35:*.pcx=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.m2v=01;35:*.mkv=01;35:*.ogm=01;35:*.mp4=01;35:*.m4v=01;35:*.mp4v=01;35:*.vob=01;35:*.qt=01;35:*.nuv=01;35:*.wmv=01;35:*.asf=01;35:*.rm=01;35:*.rmvb=01;35:*.flc=01;35:*.avi=01;35:*.fli=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.yuv=01;35:*.aac=00;36:*.au=00;36:*.flac=00;36:*.mid=00;36:*.midi=00;36:*.mka=00;36:*.mp3=00;36:*.mpc=00;36:*.ogg=00;36:*.ra=00;36:*.wav=00;36:'
    elif [[ "`cat /proc/version | grep Red\ Hat`" ]]; then
      # echo Red Hat!
      LS_COLORS='rs=0:di=01;34:ln=01;36:mh=00:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:su=37;41:sg=30;43:ca=30;41:tw=30;47:ow=34;47:st=37;44:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arj=01;31:*.taz=01;31:*.lzh=01;31:*.lzma=01;31:*.tlz=01;31:*.txz=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.dz=01;31:*.gz=01;31:*.xz=01;31:*.bz2=01;31:*.bz=01;31:*.tbz=01;31:*.tbz2=01;31:*.tz=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.rar=01;31:*.ace=01;31:*.zoo=01;31:*.cpio=01;31:*.7z=01;31:*.rz=01;31:*.lz=01;31:*.jpg=01;35:*.jpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.svg=01;35:*.svgz=01;35:*.mng=01;35:*.pcx=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.m2v=01;35:*.mkv=01;35:*.ogm=01;35:*.mp4=01;35:*.m4v=01;35:*.mp4v=01;35:*.vob=01;35:*.qt=01;35:*.nuv=01;35:*.wmv=01;35:*.asf=01;35:*.rm=01;35:*.rmvb=01;35:*.flc=01;35:*.avi=01;35:*.fli=01;35:*.flv=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.yuv=01;35:*.axv=01;35:*.anx=01;35:*.ogv=01;35:*.ogx=01;35:*.aac=00;36:*.au=00;36:*.flac=00;36:*.mid=00;36:*.midi=00;36:*.mka=00;36:*.mp3=00;36:*.mpc=00;36:*.ogg=00;36:*.ra=00;36:*.wav=00;36:*.axa=00;36:*.oga=00;36:*.spx=00;36:*.xspf=00;36:';
    fi
    if [[ -n ${LS_COLORS} ]]; then
      export LS_COLORS
    fi
  else
    # In an unrigged chroot, so no /proc/version.
    : # Nada.
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

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
  if [[ `echo "$0" | grep "bash$" -` ]]; then
    bashed=1
  fi

  return $bashed
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
  determine_window_manager
  local THIS_WINDOW_ID=$(xdotool getactivewindow)
  local WINDOW_IDS=$(xdotool search --class "$WM_TERMINAL_APP")
  local winid
  for winid in $WINDOW_IDS; do
    # Don't send the command to this window, at least not yet, since it'll
    # end up on stdin of this fcn. and won't be honored as a bash command.
    if [[ $THIS_WINDOW_ID -ne $winid ]]; then
      # See if this is a legit window or not.
      local DESKTOP_NUM=$(xdotool get_desktop_for_window $winid 2> /dev/null)
      # For real terminal, the number is 0 or greater;
      # for the fakey, it's 0, and also xdotool returns 1.
      if [[ $? -eq 0 ]]; then
        # This was my first attempt, before realizing the obvious.
        if false; then
          xdotool windowactivate --sync $winid
          sleep .1
          xdotool type "echo 'Hello buddy'
#"
          # Hold on a millisec, otherwise I've seen, e.g., the trailing
          # character end up in another terminal.
          sleep .2
        fi
        # And then this is the obvious:

        # Oh, wait, the type and key commands take a window argument...
        # NOTE: Without the quotes, e.g., xdotool type --window $winid $*,
        #       you'll have issues, e.g., xdotool sudo -K
        #       shows up in terminals as, sudo-K: command not found
        xdotool type --window $winid "$*"
        # Note that 'type' isn't always good with newlines, so use 'key'.
        xdotool key --window $winid Return
      fi
    fi
  done
  # Now we can do what we did to the rest to ourselves.
  eval $*
}

# Test:
if false; then
  termdo-all "echo Wake up get outta bed
"
fi

termdo-reset () {
  determine_window_manager
  local THIS_WINDOW_ID=$(xdotool getactivewindow)
  local WINDOW_IDS=$(xdotool search --class "$WM_TERMINAL_APP")
  local winid
  for winid in $WINDOW_IDS; do
    if [[ $THIS_WINDOW_ID -ne $winid ]]; then
      local DESKTOP_NUM=$(xdotool get_desktop_for_window $winid 2> /dev/null)
      if [[ $? -eq 0 ]]; then
        # Note that the terminal from whence this command is being run
        # will get the keystrokes -- but since the command is running,
        # the keystrokes sit on stdin and are ignored. Then along comes
        # the ctrl-c, killing this fcn., but not until after all the other
        # terminals also got their fill.

        xdotool key --window $winid ctrl+c

        xdotool type --window $winid "cd $1"
        # Hrmm. 'Ctrl+c' and 'ctrl+c' are acceptable, but 'return' is not.
        xdotool key --window $winid Return
      fi
    fi
  done
  # Now we can act locally after having acted globally.
  cd $1
}

termdo-cmd () {
  determine_window_manager
  local THIS_WINDOW_ID=$(xdotool getactivewindow)
  local WINDOW_IDS=$(xdotool search --class "$WM_TERMINAL_APP")
  local winid
  for winid in $WINDOW_IDS; do
    if [[ $THIS_WINDOW_ID -ne $winid ]]; then
      local DESKTOP_NUM=$(xdotool get_desktop_for_window $winid 2> /dev/null)
      if [[ $? -eq 0 ]]; then
        xdotool key --window $winid ctrl+c
        xdotool key --window $winid ctrl+d
        xdotool type --window $winid "$1"
        # Hrmm. 'Ctrl+c' and 'ctrl+c' are acceptable, but 'return' is not.
        xdotool key --window $winid Return
      fi
    fi
  done
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
  termdo-all sudo -K
}

# FIXME/MAYBE: Add a close-all fcn:
#               1. Send ctrl-c
#               2. Send exit one or more times (to exit nested shells)

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

enable_vi_style_editing() {
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

# 2017-06-06: Still refining Bash input experience.
default_yes_question() {
  echo -n "Tell me yes or no. [Y/n] "
  read -e YES_OR_NO
  if [[ ${YES_OR_NO^^} =~ ^Y.* || -z ${YES_OR_NO} ]]; then
    echo "YESSSSSSSSSSSSS"
  else
    echo "Apparently not"
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# NOTE: You can also precede the echo:
#         >&2 echo "blah"
echoerr () { echo "$@" 1>&2; }

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main() {
  source_deps
}

main "$@"

