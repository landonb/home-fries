# File: bashrc.core.sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Last Modified: 2015.03.01
# Project Page: https://github.com/landonb/home_fries
# Summary: One Developer's Bash Profile
# License: GPLv3

# FIXME Notes
#############

# MAYBE: Cray-cray: None of @ $ ? are mapped in Bash
#        and are free to be aliased or made into commands.
#        Can you think of any magical mapping?

# Vendor paths (see: setup_mint17.sh)
#####################################

OPT_BIN=/srv/opt/bin
OPT_DLOADS=/srv/opt/.downloads

# Determine OS Flavor
#####################

# This script only recognizes Ubuntu and Red Hat distributions. It'll
# otherwise complain (but it'll still work, it just won't set a few
# flavor-specific options, like terminal colors and the prompt).
# See also: `uname -a`, `cat /etc/issue`, `cat /etc/fedora-release`.

if [[ "`cat /proc/version | grep Ubuntu`" ]]; then
  # echo Ubuntu!
  : # no-op
elif [[ "`cat /proc/version | grep Red\ Hat`" ]]; then
  # echo Red Hat!
  : # noop
else
  echo "WARNING: Unknown OS flavor."
  echo "Please update this file ($(basename $0)) or comment out this gripe."
fi

# Update PATH
#############

# [lb]'s scripts are in ~/.fries/bin.
# Third-party applications are installed to /srv/opt/bin.

#PATH="/home/${LOGNAME}/.fries/bin/vendor:${PATH}"
PATH="/home/${LOGNAME}/.fries/bin:${PATH}"
PATH="${OPT_BIN}:${PATH}"
export PATH

# Umask
#######

# Set umask to ensure group r-w-x permissions for new files and directories
# (for collaborative development, e.g., so a co-worker can ssh to your machine
# and poke around your files).
#
# This is more useful in a collaborative environment than on one's own machine.
#
#   As one example, if a naive user calls pg_restore from a remote
#   machine but references a database dump on your machine, Psql will
#   create intermediate files on your machine. If that user's umask is,
#   e.g., 0077, then only that user will have read-write access to the
#   files and you'll need to ask that user or use sudo to wipe the files.
#
# Remember: umask bits are removed from bits applied to the new file or dir.
#   A 0000 umask won't mask anything
#     and new files will be user-group-world read-writeable;
#     new directories will be user-group-world read-writeable-executable
#       and will have the sticky bit set.
#   For 0006, files will be -rw-rw---- and dirs will be drwxrws--x.
#
# Circa 2009, Debian defaults to 0022 -- give group and world execute + read.
# Ubuntu defaults to 0006, or r+w+x for owner and group, and just
#                             execute for everyone else.
# 2015.02.26: Linux Mint 17.1 defaults to 0022.

#umask 0006
# 2015.02.26: [lb] doesn't have anyone ssh'ing into my box anymore (or
#             at least rarely ever) and since I'm developing web apps,
#             I should probably default to no access for other, and
#             then to deliberately use a fix-perms/web-perms macro to
#             make htdocs/ directories accessible to the web user.
umask 0007

# SVN/gVim
##########

export SVN_EDITOR=gvim

# Default Editor for git, cron, etc.
####################################

# When you run crontab, it calls /usr/bin/sensible-editor to run an editor.
# You can set the editor using /usr/bin/select-editor.
# For machines without the latter installed, set the EDITOR variable.
# The EDITOR variable also works with git.
if [[ -e '/usr/bin/vim.basic' ]]; then
   export EDITOR='/usr/bin/vim.basic'
elif [[ -e '/usr/bin/vim' ]]; then
   export EDITOR='/usr/bin/vim'
else
   echo "WARNING: Did not set EDITOR: no vim found."
fi

# Vi vs. Vim
############

# When logged in as root, vi is a dumbed-down vim. Root rarely needs it --
# only when the home directories aren't mounted -- so just alias vi to vim.
if [[ $EUID -eq 0 ]]; then
  alias vi="vim"
fi

# LD_LIBRARY_PATH
#################

# 2015.01.20: This seems really weird, having to set LD_LIBRARY_PATH.
#             In Cyclopath, we set this for gdal and geos when
#             we startup pyserver, but we don't set this for
#             any user programs... is there something we could
#             do via `./configure` or `make` or `make install`
#             so we don't have to specify this?
# Set the library path, lest:
#   expect: error while loading shared libraries: libexpect5.45.so:
#     cannot open shared object file: No such file or directory
# Do this before the SSH function, which expects expect.
export LD_LIBRARY_PATH=/usr/lib/expect5.45:${LD_LIBRARY_PATH}

# Tell psql to use less for large output
########################################

# In Fedora (at least not in Ubuntu at work), if this isn't on, psql
# paginates large output, but you can only hit space to go through it
# (there's no going backwards) and the output is left in the command
# window. Using less, you can use the keys you normally use with less,
# and when you're done, the output isn't left as crud in the window.
# 2014.11.20: Add -R so ANSI "color" escape sequences work, otherwise
# commands like `git log` will show escape characters as, e.g., ESC[33mc.
#export PAGER=less
export PAGER=less\ -R
# -i or --ignore-case
# -M or --LONG-PROMPT
# -xn,... or --tabs=n,...
# NOTE -F or --quit-if-one-screen
#      This is cool in that, for short files, it just dumps the file
#      and quits. But for multiple pages, the output remains in the
#      terminal, which is annoying; I don't like crud!
export LESS="-iMx2"

# Shell Options
###############

# See man bash for more options.

# Don't wait for job termination notification.
# Report status of terminated bg jobs immediately (same as set -b).
set -o notify

# Don't use ^D to exit.
# set -o ignoreeof

# Use case-insensitive filename globbing.
# shopt -s nocaseglob

# Make bash append rather than overwrite the history on disk.
# shopt -s histappend

# When changing directory small typos can be ignored by bash
# for example, cd /vr/lgo/apaache would find /var/log/apache.
# shopt -s cdspell

# Completion options
####################

# These completion tuning parameters change the behavior of bash_completion.

# Access remotely checked-out files over passwordless ssh for CVS.
# COMP_CVS_REMOTE=1

# Avoid stripping description in --option=description of './configure --help'.
# COMP_CONFIGURE_HINTS=1

# Define to avoid flattening internal contents of tar files.
# COMP_TAR_INTERNAL_PATHS=1

# If this shell is interactive, turn on programmable completion enhancements.
# Any completions you add in ~/.bash_completion are sourced last.
# case $- in
#   *i*) [[ -f /etc/bash_completion ]] && . /etc/bash_completion ;;
# esac

# History Options
#################

# Don't put duplicate lines in the history.
# HISTCONTROL opts.: ignoredups ignorespace ignoreboth / erasedups
export HISTCONTROL="ignoredups"

# Ignore some controlling instructions.
# export HISTIGNORE="[   ]*:&:bg:fg:exit"

# Whenever displaying the prompt, write the previous line to disk.
# export PROMPT_COMMAND="history -a"

# SSH
#####

# NOTE: Not doing this for root.
# 2012.12.22: Don't do this for cron, either, or cron sends
#   Identity added: /home/.../.ssh/id_rsa (/home/.../.ssh/id_rsa)
#   Identity added: /home/.../.ssh/identity (/home/.../.ssh/identity)

if [[ $EUID -ne 0 \
   && "dumb" != "${TERM}" \
   && -e "$HOME/.ssh" ]]; then
  # See http://help.github.com/working-with-key-passphrases/
  SSH_ENV="$HOME/.ssh/environment"
  function start_agent {
    #echo -n "Initializing new SSH agent... "
    /usr/bin/ssh-agent | sed 's/^echo/#echo/' > "${SSH_ENV}"
    #echo "ok."
    chmod 600 "${SSH_ENV}"
    . "${SSH_ENV}" > /dev/null
    # The default ssh-add behavior is to just load id_dsa and id_rsa.
    # But we don't want to use id_dsa, since RSA is better than DSA.
    # And we might have multiple keys we want to load. So load whatever
    # ends in _rsa.
    #  /usr/bin/ssh-add
    #  find $HOME/.ssh -name "*_[rd]sa" -maxdepth 1 ...
    # Weird. With Stdin, ssh-add opens a GUI window, rather than
    # asking for your passphrase on the command line.
    #  find $HOME/.ssh -name "*_rsa" -maxdepth 1 | xargs /usr/bin/ssh-add
    rsa_keys=`ls $HOME/.ssh/*_rsa 2> /dev/null`
    if [[ -n $rsa_keys ]]; then
      for pvt_key in $(/bin/ls $HOME/.ssh/*_rsa); do
        # Skip symlinks (I've got ~/.ssh/id_rsa linked to ~/.ssh/id_foo_rsa).
        if [[ ! -h ${pvt_key} ]]; then
          sent_passphrase=false
          secret_name=$(basename $pvt_key)
          if [[    -n "$SSH_SECRETS" \
                && -d "$SSH_SECRETS" \
                && -e "$SSH_SECRETS/$secret_name" ]]; then
            if [[ $(command -v expect > /dev/null && echo true) ]]; then
              pphrase=$(cat ${SSH_SECRETS}/${secret_name})
              /usr/bin/expect -c "
              spawn /usr/bin/ssh-add ${pvt_key}; \
              expect \"Enter passphrase for /home/${USER}/.ssh/${secret_name}:\"; \
              send \"${pphrase}\n\"; \
              interact ; \
              "
              unset pphrase
              sent_passphrase=true
            else
              echo "NOTICE: no expect: ignoring: ${SSH_SECRETS}/${pvt_key}"
            fi
          fi
          if ! ${sent_passphrase}; then
            /usr/bin/ssh-add $pvt_key
          fi
        fi
      done
    fi
    # Test: ssh-agent -k # then, open a terminal.
  }
  # Source SSH settings, if applicable
  if [[ -f "${SSH_ENV}" ]]; then
    . "${SSH_ENV}" > /dev/null
    #ps ${SSH_AGENT_PID} doesn't work under cywgin
    ps -ef | grep ${SSH_AGENT_PID} | grep ssh-agent$ > /dev/null || {
      start_agent;
    }
  else
    start_agent;
  fi
fi

# Aliases
#########

# Hint: To run the native command and not the alias, use a \ prefix, e.g.,
#       \rm will call the real /bin/rm not the alias.

# NOTE: Sometimes the -i doesn't get overriden by -f so it's best to call
#       `/bin/cp` or `\cp` and not `cp -f` if you want to overwrite files.
alias cp='cp -i'
alias mv='mv -i'

# Misc.
alias h='history'         # Nothing special, just convenient.
alias n='netstat -tulpn'  # --tcp --udp --listening --program (name) --numeric
alias t='top -c'          # Show full command.
alias cmd='command -v $1' # Show executable path or alias definition.
alias grep='grep --color' # Show differences in colour.
alias less='less -r'      # Raw control characters.
alias sed='sed -r'        # Use extended regex.
alias whence='type -a'    # `where`, of a sort.

# gVim.
alias ff='gvim --servername DIGAMMA --remote-silent' # For those special occassions
alias fd='gvim --servername   DELTA --remote-silent' # when you want to get away
alias fs='gvim --servername   SAMPI --remote-silent' # because relaxation is key
alias fa='gvim --servername   ALPHA --remote-silent' # follow your spirit.

# Directory listings.
# 2015.01.20: Used to use --color=tty (which still works), but man says =auto.
alias ls='/bin/ls -hFA --color=auto'  # Human readable, classify files, shows
                                      #   almost all (excludes ./ and ../),
                                      #   and uses colour.
alias l='/bin/ls -ChFA --color=auto --group-directories-first'
                                      # Compact listing (same as -hFA, really),
                                      #   but list directories first which
                                      #   seems to make the output cleaner.
alias ll='/bin/ls -lhFa --color=auto' # Long listing; includes ./ and ../
                                      #   (so you can check permissions)
alias lo='ll -rt'                     # Reverse sort by time.

# Move a glob of files and include .dotted (hidden) files.
alias mv_all='mv_dotglob'
# Problem illustration:
#   $ ls project
#   .agignore
#   $ mv project/* .
#   mv: cannot stat ‘project/*’: No such file or directory
# This fcn. uses shopt to include dot files.
# Note: We've aliased `mv` to `/bin/mv -i`, so you'll be asked to
#       confirm any overwrites, unless you call `mv_all -f` instead.
mv_dotglob () {
  shopt -s dotglob
  if [[ $1 == '-f' ]]; then
    /bin/mv $*
  else
    mv $*
  fi
  shopt -u dotglob
}

# Show resource usage, and default to human readable figures.
alias df='df -h -T'
alias du='du -h'
#alias duhome='du -ah /home | sort -n'
alias free="free -m"

# [lb] uses p frequently, just like h and ll.
alias p='pwd'

# Alias python from py.
alias py='/usr/bin/env python'
alias py2='/usr/bin/env python2'
alias py3='/usr/bin/env python3'

# The `whoami` is just `id -un` in disguise.
# Here are its lesser known sibling commands.
# alias whereami=is an actual package you can install.
alias whereami="echo 'How should I know?' ; \
              /usr/bin/python /usr/lib/command-not-found whereami"
alias howami="echo 'Doing well. Thanks for asking.' ; \
              /usr/bin/python /usr/lib/command-not-found howami"
alias whatami="echo 'Neither plant nor animal.' ; \
              /usr/bin/python /usr/lib/command-not-found whatami"
alias whenami="echo 'You are in the here and now.' ; \
              /usr/bin/python /usr/lib/command-not-found whenami"
alias whyami="echo 'Because you gotta be somebody.' ; \
              /usr/bin/python /usr/lib/command-not-found whyami"

alias cls='clear' # If you're like me and poisoned by DOS memories.

# Preferred grep switches and excludes.
#   -n, --line-number
#   -R, --dereference-recursive
#   -i, --ignore-case
if [[ -e $HOME/.grepignore ]]; then
  alias eg='egrep -n -R -i --color --exclude-from="$HOME/.grepignore"'
  alias egi='egrep -n -R --color --exclude-from="$HOME/.grepignore"'
fi

# The Silver Search.
# Always allow lowercase, and, more broadly, all smartcase.
alias ag='ag --smart-case --hidden'

# Fix rm to be a crude trashcan
###############################

# Remove aliases (where "Remove" is a noun, not a verb! =)
$DUBS_TRACE && echo "Setting trashhome"
if [[ -z "$DUB_TRASHHOME" ]]; then
  # Path is ~/.trash
  trashdir=$HOME
else
  trashdir=$DUB_TRASHHOME
fi;

alias rm='rm_safe'
alias rmtrash='/bin/rm -rf $trashdir/.trash ; mkdir $trashdir/.trash'
# DANGER: Will Robinson. Be careful when you repeat yourself, it'll be gone.
alias rmrm='/bin/rm -rf'

function rm_safe {
  if [[ ! -e $trashdir/.trash ]]; then
    /bin/mkdir $trashdir/.trash
  fi
  if [[ -d $trashdir/.trash ]]; then
    /bin/mv --target-directory $trashdir/.trash $*
  else
    /bin/rm -i $*
  fi
}

# Terminal Prompt
#################

function dubs_set_terminal_prompt () {

  ssh_host=$1

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
  TITLEBAR='\[\e]0;\u@\h:\W\a\]'
  # This does the same thing but uses octal ASCII escape chars instead of
  # bash's escape chars:
  #  TITLEBAR='\[\033]2;\u@\h\007\]'
  # Gnome-terminal's default (though it doesn't specify it, it just is):
  #  TITLEBAR='\[\e]0;\u@\h:\w\a\]'

  # Name this terminal window specially if special.
  # NOTE: This information comes from Gnome, where we've set the Gnome shortcut
  #       to pass this environment variable to us.
  # NOTE: To test gnome-terminal, run it from your home directory, otherwise it
  #       won't find your bash scripts.
  if [[ "$ssh_host" == "" ]]; then
    if [[ "$DUBS_TERMNAME" != "" ]]; then
      TITLEBAR="\[\e]0;${DUBS_TERMNAME}\a\]"
    else
      #TITLEBAR='\[\e]0;\u@\h:\w\a\]'
      #TITLEBAR='\[\e]0;\w:(\u@\h)\a\]'
      #TITLEBAR='\[\e]0;\w\a\]'
      TITLEBAR='\[\e]0;\W\a\]'
    fi
  else
    TITLEBAR="\[\e]0;On ${ssh_host}\a\]"
  fi

  # 2012.10.17: The default bash includes ${debian_chroot:+($debian_chroot)} in
  # the PS1 string, but it really shouldn't be set on any of our systems (it's
  # pretty much obsolete, or at least pertains to a linux usage we're not).
  # "Chroot is a unix feature that lets you restrict a process to a subtree of
  # the filesystem." See:
  #  http://unix.stackexchange.com/questions/3171/what-is-debian-chroot-in-bashrc
  #  https://en.wikipedia.org/wiki/Chroot

  # NOTE: Using "" below instead of '' so that ${TITLEBAR} is resolved by the
  #       shell first.
  $DUBS_TRACE && echo "Setting prompt"
  if [[ $EUID -eq 0 ]]; then
    $DUBS_TRACE && echo "Running as root!"
    if [[ "`cat /proc/version | grep Ubuntu`" ]]; then
      $DUBS_TRACE && echo "Ubuntu"
      PS1="${TITLEBAR}\[\033[01;45m\]\[\033[01;37m\]\u@\[\033[1;33m\]\h\[\033[00m\]:\[\033[01;36m\]\W\[\033[00m\]\$ "
    elif [[ "`cat /proc/version | grep Red\ Hat`" ]]; then
      $DUBS_TRACE && echo "Red Hat"
      PS1="${TITLEBAR}\[\033[01;45m\]\[\033[01;37m\]\u@\[\033[1;33m\]\h\[\033[00m\]:\[\033[01;37m\]\W\[\033[00m\]\$ "
    else
      echo "WARNING: Not enough info. to set PS1."
    fi
  elif [[ "`cat /proc/version | grep Ubuntu`" ]]; then
    $DUBS_TRACE && echo "Ubuntu"
    PS1="${TITLEBAR}\[\033[01;37m\]\u@\[\033[1;33m\]\h\[\033[00m\]:\[\033[01;36m\]\W\[\033[00m\]\$ "
    # 2015.02.26: Add git branch.
    #             Maybe... not sure I like this...
    #             maybe change delimiter and make branch name colorful?
    #PS1="${TITLEBAR}\[\033[01;37m\]\u@\[\033[1;33m\]\h\[\033[00m\]:\[\033[01;36m\]\W\[\033[00m\]"'$(__git_ps1 "-%s" )\$ '
  elif [[ "`cat /proc/version | grep Red\ Hat`" ]]; then
    $DUBS_TRACE && echo "Red Hat"
    PS1="${TITLEBAR}\[\033[01;36m\]\u@\[\033[1;33m\]\h\[\033[00m\]:\[\033[01;37m\]\W\[\033[00m\]\$ "
  else
      echo "WARNING: Not enough info. to set PS1."
  fi

  # NOTE: There's an alternative to PS1, PROMPT_COMMAND,
  #       which works if PS1 is empty.
  #         PS1=""
  #         PROMPT_COMMAND='echo -ne "\033]0;SOME TITLE HERE\007"'
  #       But the escapes don't work the same. E.g., this looks really funny:
  #         TITLEBAR="\[\e]0;THIS IS A TEST\a\]"
  #         PROMPT_COMMAND='echo -ne "${TITLEBAR}\[\033[01;36m\]\u@\[\033[1;33m\]\h\[\033[00m\]:\[\033[01;37m\]\W\[\033[00m\]\$ "'

}

dubs_set_terminal_prompt

# Fix ls -C
###########

# On directories with world-write (0002) privileges,
# the directory name is blue on green, which is hard to read.
# 42 is the green background, which we turn to white, 47.
# Use the following commands to generate the export variable on your machine:
# dircolors --print-database
# dircolors --sh
if [[ "`cat /proc/version | grep Ubuntu`" ]]; then
  # echo Ubuntu!
  LS_COLORS='no=00:fi=00:di=01;34:ln=01;36:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:su=37;41:sg=30;43:tw=30;47:ow=34;47:st=37;44:ex=01;32:*.tar=01;31:*.tgz=01;31:*.svgz=01;31:*.arj=01;31:*.taz=01;31:*.lzh=01;31:*.lzma=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.dz=01;31:*.gz=01;31:*.bz2=01;31:*.bz=01;31:*.tbz2=01;31:*.tz=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.rar=01;31:*.ace=01;31:*.zoo=01;31:*.cpio=01;31:*.7z=01;31:*.rz=01;31:*.jpg=01;35:*.jpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.svg=01;35:*.mng=01;35:*.pcx=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.m2v=01;35:*.mkv=01;35:*.ogm=01;35:*.mp4=01;35:*.m4v=01;35:*.mp4v=01;35:*.vob=01;35:*.qt=01;35:*.nuv=01;35:*.wmv=01;35:*.asf=01;35:*.rm=01;35:*.rmvb=01;35:*.flc=01;35:*.avi=01;35:*.fli=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.yuv=01;35:*.aac=00;36:*.au=00;36:*.flac=00;36:*.mid=00;36:*.midi=00;36:*.mka=00;36:*.mp3=00;36:*.mpc=00;36:*.ogg=00;36:*.ra=00;36:*.wav=00;36:'
elif [[ "`cat /proc/version | grep Red\ Hat`" ]]; then
  # echo Red Hat!
  LS_COLORS='rs=0:di=01;34:ln=01;36:mh=00:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:su=37;41:sg=30;43:ca=30;41:tw=30;47:ow=34;47:st=37;44:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arj=01;31:*.taz=01;31:*.lzh=01;31:*.lzma=01;31:*.tlz=01;31:*.txz=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.dz=01;31:*.gz=01;31:*.xz=01;31:*.bz2=01;31:*.bz=01;31:*.tbz=01;31:*.tbz2=01;31:*.tz=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.rar=01;31:*.ace=01;31:*.zoo=01;31:*.cpio=01;31:*.7z=01;31:*.rz=01;31:*.lz=01;31:*.jpg=01;35:*.jpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.svg=01;35:*.svgz=01;35:*.mng=01;35:*.pcx=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.m2v=01;35:*.mkv=01;35:*.ogm=01;35:*.mp4=01;35:*.m4v=01;35:*.mp4v=01;35:*.vob=01;35:*.qt=01;35:*.nuv=01;35:*.wmv=01;35:*.asf=01;35:*.rm=01;35:*.rmvb=01;35:*.flc=01;35:*.avi=01;35:*.fli=01;35:*.flv=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.yuv=01;35:*.axv=01;35:*.anx=01;35:*.ogv=01;35:*.ogx=01;35:*.aac=00;36:*.au=00;36:*.flac=00;36:*.mid=00;36:*.midi=00;36:*.mka=00;36:*.mp3=00;36:*.mpc=00;36:*.ogg=00;36:*.ra=00;36:*.wav=00;36:*.axa=00;36:*.oga=00;36:*.spx=00;36:*.xspf=00;36:';
fi;
export LS_COLORS

# Cygwin section
################

#alias c:='cd /cygdrive/c'
#alias d:='cd /cygdrive/d'
#alias e:='cd /cygdrive/e'
#alias f:='cd /cygdrive/f'
#alias g:='cd /cygdrive/g'
#alias h:='cd /cygdrive/h'
#alias i:='cd /cygdrive/i'

# LINUX OS FLAVOR SPECIFICS
###########################

# OS-Specific HTTPd User Shortcut and Default Python Version.

# SYNC_ME: See $cp/scripts/setupcp/runic/auto_install/check_parms.sh

# Determine the Python version-path.
#PYS_VER=$(python --version 2>&1)
# Convert, e.g., 'Python 3.4.0' to '3.4'.
# Note the |&, which is like 2>&1, i.e., send stderr to stdout.
PYVERS_RAW=`python3 --version \
  |& /usr/bin/awk '{print $2}' \
  | /bin/sed -r 's/^([0-9]+\.[0-9]+)\.[0-9]+/\1/g'`
if [[ -n $PYVERS_RAW ]]; then
  export PYTHONVERS=python${PYVERS_RAW}
  export PYVERSABBR=py${PYVERS_RAW}
else
  echo "Unexpected: Could not parse Python version."
  exit 1
fi

# Determine the apache user.
# 'TEVS: CAPITALIZE these, like most exports.
if [[ "`cat /proc/version | grep Ubuntu`" ]]; then
  # echo Ubuntu!
  export httpd_user=www-data
  export httpd_etc_dir=/etc/apache2
elif [[ "`cat /proc/version | grep Red\ Hat`" ]]; then
  # echo Red Hat!
  export httpd_user=apache
  export httpd_etc_dir=/etc/httpd
else
  echo
  echo "Error: Unexpected OS; cannot set httpd_user/_etc_dir."
  echo
fi

# Remove SVN directories.
#########################

alias svnrm='find . -name ".svn" -type d -exec /bin/rm -rf {} \\;'

# Re-enable better Bash tab auto-completion.
#########################

# With thanks to:
#   http://askubuntu.com/questions/70750/
#     how-to-get-bash-to-stop-escaping-during-tab-completion
# 2014.01.22: In older Bash, e.g., in Fedora 14, if you typed
#  $ ll /home/$USER/<TAB>
# your home dir would be listed and the shell prompt would change to, e.g.,
#  $ ll /home/yourname/
# but in newer Bash, a <TAB> completion attempt results in
#  $ ll /home/\$USER/
# which is completely useless. So revert to the old behavior.
# And using &> since this option isn't available on older OSes
# (which already default to the (subjectively) "better" behavior).
shopt -s direxpand &> /dev/null

#########################

# Crontab shortcuts.

alias ct='crontab -e -u $USER'
if [[ -e "/usr/bin/vim.basic" ]]; then
  VIM_EDITOR=/usr/bin/vim.basic
elif [[ -e "/usr/bin/vim.tiny" ]]; then
  VIM_EDITOR=/usr/bin/vim.tiny
fi
# 2015.01.25: FIXME: Not sure what best to use...
VIM_EDITOR=/usr/bin/vim
if [[ -n $VIM_EDITOR ]]; then
  alias ct-www='sudo -u $httpd_user \
                  SELECTED_EDITOR=${VIM_EDITOR} \
                  crontab -e -u $httpd_user'
fi

#########################

# Control and Kill Processes.

# Restart Apache.
if [[ "`cat /proc/version | grep Ubuntu`" ]]; then
  alias re='sudo /etc/init.d/apache2 reload'
  alias res='sudo /etc/init.d/apache2 restart'
elif [[ "`cat /proc/version | grep Red\ Hat`" ]]; then
  alias re='sudo service httpd reload'
  alias res='sudo service httpd restart'
fi

#########################

killsomething () {
  something=$1
  # The $2 is the awk way of saying, second column. I.e., ps aux shows
  #   apache 27635 0.0 0.1 238736 3168 ? S 12:51 0:00 /usr/sbin/httpd
  # and awk splits it on whitespace and sets $1..$11 to what was split.
  # You can even {print $99999} but it's just a newline for each match.
  somethings=`ps aux | grep "${something}" | awk '{print $2}'`
  # NOTE: awk {'print $2'} is also acceptable.
  if [[ "$somethings" != "" ]]; then
    echo $somethings | xargs sudo kill -s 9 >/dev/null 2>&1
  fi
  return 0
}

#########################

# C.f. ~/.fries/bin/ccp_base.sh.
dir_resolve () {
  # Change to desired directory. Squash errors. Return error status, maybe.
  cd "$1" 2>/dev/null || return $?
  # Use pwd's -P to return the full, link-resolved path.
  echo "`pwd -P`"
}

#########################

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

  if [[ `echo "$0" | grep "bash$" -` ]]; then
    bashed=1
  else
    bashed=0
  fi

  return $bashed
}

#########################

echoerr () { echo "$@" 1>&2; }

#########################

# Helpers for fixing permissions (mostly for web-accessible files).

# Recursively web-ify a directory hierarchy.






# FIXME: Copy the webify fcn here.......
webperms () {
  if [[ -z $1 || ! -d $1 ]]; then
    echo "ERROR: Not a directory: $1"
    return 1
  else
    # The naive `find` approach.
    #   find $1 -type d -exec chmod 2775 {} +
    #   find $1 -type f -exec chmod u+rw,g+rw,o+r {} +
    # A smarter chmod usage: The 'X' flag only adds the execute
    # bit to directories or to files that already have execute
    # permission for some user.
    #chmod -R o+rX $1
    chmod -R u+rwX,g+rwX,o+rX $1
  fi
}






# Web-ify a single directory (does not recurse).
dirperms () {
  # find . -maxdepth 1 -type d -exec chmod 2775 {} +
  # find . -maxdepth 1 -type f -exec chmod u+rw,g+rw,o+r {} +
  if [[ -z $1 ]]; then
    one_dir=".* *"
  else
    one_dir=$1
  fi
  chmod --silent u+rwX,g+rwX,o+rX $one_dir
}

# Reset file permissions on directory hierarchy.
# Caveat: Removes executable bits from executable files.
reperms () {
  # This doesn't work: it makes the current directory inaccesible:
  #   chmod --silent -R 664 $one_dir
  #   chmod --silent -R u+X,g+X,o+X $one_dir
  # Nor does this work: it doesn't un-executable-ify my files (weird):
  #   if [[ -z $1 ]]; then
  #     one_dir="."
  #   else
  #     one_dir=$1
  #   fi
  #   chmod --silent -R u-x,u+rwX,g-x,g+rwX,o-wx,o+rX $one_dir
  # Guess we'll stick with find:
  find $1 -type d -exec chmod 2775 {} +
  find $1 -type f -exec chmod 664 {} +
  echo "Done!"
  echo "But you'll want to chmod 775 executable files as appropriate."
  echo "To see a list of distinct file extensions, try:"
  echo " find . -type f | perl -ne 'print $1 if m/\.([^.\/]+)$/' | sort -u"
}

#########################

simpletimeit () {
  # Python has a great timeit fcn. you could use on a command,
  # or you could just do it in Bash.
  time_0=$(date +%s.%N)
  $*
  time_1=$(date +%s.%N)
  TM_USED=`printf "%.2F" $(echo "($time_1 - $time_0) / 60.0" | bc -l)`
  echo
  echo "Your task took ${TM_USED} mins."
}

#########################

# https://github.com/downloads/ginatrapani/todo.txt-cli/

# In lieu of system-wide installation, i.e.,
#   sudo cp path/to/todo_completion /etc/bash_completion.d/todo
# we can just source the file for ourselves.
if [[ -e ${OPT_DLOADS}/todo.txt_cli/todo_completion ]]; then
  source ${OPT_DLOADS}/todo.txt_cli/todo_completion
  # NOTE: If you alias todo.sh, e.g.,
  #         alias t="todo.sh"
  #       you'll also need to update the completion.
  #         complete -F _todo t
  alias t="todo.sh"
  complete -F _todo t
fi

#########################

# https://code.google.com/p/punch-time-tracking/

# alias p= might be nice, as in p[unch] i[n] and p[unch] o[ut],
# but my brain is wired to hit 'p' for `pwd`. Ug... but 'c' works,
# as in clock in clock out.

alias c="${OPT_DLOADS}/punch-time-tracking/Punch.py"

#########################

# git subdirectory statusr

# I maintain a bunch of Vim plugins,
# published at https://github.com/landonb/dubs_*,
# that are loaded as submodules in an uber-project
# that makes it easy to share my plugins and makes
# it simple to deploy them to a new machine, found
# at https://github.com/landonb/dubsacks_vim.
#
# However, git status doesn't work like, say, svn status:
# you can't postpend a directory path and have it search
# that. For example, from the parent directory of the plugins,
# e.g., from ~/.vim/bundle_/, using git status doesn't
# work, e.g., running `git status git_ignores_this` no matter
# what the third token is always reports on the git status of
# the working directory, which in my case is ~/.vim.

git_status_all () {
  for subdir in `find . -name ".git"`; do  
    gitst=$(git --git-dir=$subdir --work-tree=$subdir/.. status --short)
    if [[ -n $gitst ]]; then
      echo
      echo "====================================================="
      echo "Dirty project: $subdir"
      echo
      # We could just echo, but the we've lost any coloring.
      # Ok: echo $gitst
      # Better: run git again.
      #git --git-dir=$subdir --work-tree=$subdir/.. status
      git --git-dir=$subdir --work-tree=$subdir/.. status --short
      echo
    fi
  done
}

alias git_st_all='git_status_all'
# Hrmm... gitstall? I'm not sold on any alias yet...
alias gitstall='git_status_all'

#########################

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

# Default is: PS4='+'

PS4='(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]} - [${SHLVL},${BASH_SUBSHELL}, $?]
'

#########################

# MAYBE:
#source /usr/local/bin/virtualenvwrapper.sh

#########################

# git-flow-completion
# https://github.com/bobthecow/git-flow-completion

#source /srv/opt/.downloads/git-flow-completion/git-flow-completion.bash

#########################

# 2015.02.20: Fancy find: A linux find command that honors .*ignore,
#                         like .gitignore and .agignore.

# FIXME: For this to be really effective, you'd have to descend
#        into directories looking for the ignore files... so,
#        like, really tedious...
#        You could either descend into each directory to look
#        for the ignore file before `find`ing, or you could
#        `find` first and then cull the results (by going into
#        directories of each result and walking up the tree
#        looking for ignore files, which seems extremely teeds).
#        Ug. For now, I guess a find that honors ignores is still
#        a pipe dream... though maybe an easy solution is to descend
#        into all directories looking for ignore files, and then
#        making a big array of fuller paths of ignore rules, i.e.,
#        if starting in some/dir then *.pyc in some/dir/this/that/.gitignore
#        becomes some/dir/this/that/**/*.pyc... oy.
fffind () {

  HERE_WE_ARE=$(dir_resolve $(pwd -P))

  BIG_IGNORE_LIST=()

  # Go up the hierarchy...
  while [[ ${HERE_WE_ARE} != '/' ]]; do
    for ignore_f in ".agignore" ".gitignore" ".findignore"; do
      if [[ -e "${HERE_WE_ARE}/${ignore_f}" ]]; then
        # Read line by line from the file.
        while read fline; do
          # Bash regular expressions, eh.
          if [[ ! "${fline}" =~ ^[[:space:]]*# ]]; then
            # Not a comment line.
            BIG_IGNORE_LIST+=("-path '${fline}' -prune -o")
          fi
        done < "${HERE_WE_ARE}/${ignore_f}"
      fi
    done
    # Keep looping:
    HERE_WE_ARE=$(dir_resolve ${HERE_WE_ARE}/..)
  done

  # Go down the hierarchies...
  # Find all .agignore, .gitignore, and .anythingignore.
  for ignore_f in `find . -type f -name ".*ignore"`; do
    ignore_p=$(dirname ${ignore_f})
    while read fline; do
      # Bash regular expressions, eh.
      if [[ ! "${fline}" =~ ^[[:space:]]*# ]]; then
        # Not a comment line.
        BIG_IGNORE_LIST+=("-path '${ignore_p}/${fline}' -prune -o")
      fi
    done < "${ignore_f}"
  done

  # So, calling find on its own does not work, probably
  # because of the globbing. So eval the commmand.
  # Nope: find . ${BIG_IGNORE_LIST[@]} -name $*
  # eval "find . ${BIG_IGNORE_LIST[@]} -name $*"
    eval "find . ${BIG_IGNORE_LIST[@]} -name $* | grep -E $*"

} # fffind

#########################

# Disable the touchpad while typing.
# 2015.02.20: The T440p is a great laptop but my thumbs keep
#             *lightly* brushing the touchpad, sending my cursor
#             (and screen or cursor focus) elsewhere.

# syndaemon is one option... but I always use a mouse, so why not
#  just disable the touchpad completely?
#    -i specifies how many seconds after last key press before
#       enabling the touchpad (default is 2 seconds)
#    -K allows modifiers such as Shift and Alt
#    -R uses XRecord for detecting keyboard activity instead of polling
#    -t only disables tapping and scrolling but allows mouse movement
#    -d will start syndaemon as a daemon
#  E.g.,
#    syndaemon -i 5 -K -R -t -d

if [[ $(command -v xinput > /dev/null) || $? -eq 0 ]]; then
  DEVICE_NUM=$(xinput --list --id-only "SynPS/2 Synaptics TouchPad" &> /dev/null)
  if [[ -n ${DEVICE_NUM} ]]; then
    xinput set-prop ${DEVICE_NUM} "Device Enabled" 0
  fi
fi

#########################

# For those (silly) projects that use tabs (I know!) in Bash scripts,
# you'll want to disable tab autocompletion if you want to copy-and-paste
# from the script to the terminal, otherwise the autocomplete responses
# are intertwined with the paste.

#alias tabsoff="bind 'set disable-completion on'"
#alias tabson="bind 'set disable-completion off'"

alias toff="bind 'set disable-completion on'"
alias ton="bind 'set disable-completion off'"

#########################

# Vi-style editing.

# MAYBE:
#  set -o vi

# Use ``bind -P`` to see the current bindings.

# See: http://www.catonmat.net/download/bash-vi-editing-mode-cheat-sheet.txt
# (from http://www.catonmat.net/blog/bash-vi-editing-mode-cheat-sheet/)
# (also http://www.catonmat.net/download/bash-vi-editing-mode-cheat-sheet.pdf)

# See: http://vim.wikia.com/wiki/Use_vi_shortcuts_in_terminal

#########################

# Encrypted Filesystem.

mount_sepulcher () {
  if [[ -z $(/bin/ls -A ~/.fries/sepulcher) ]]; then
    encfs ~/.fries/.sepulcher ~/.fries/sepulcher
  fi
}

umount_sepulcher () {
  fusermount -u ~/.fries/sepulcher
}

# To manage the encfs (change pwd, etc.), see: encfsctl

#########################

# Bash command completion.

if [[ -d /home/landon/.fries/bin/completions ]]; then
  source /home/landon/.fries/bin/completions/*
fi

#########################

# Special key mapping for ThinkPad X201 laptops.

# HINTS: To reset your keyboard, run:
#           setxkbmap
#        To see current settings, run:
#           xmodmap -pke
#           xmodmap -pm
#        To find out your keyboard's key codes, run:
#           xev

# CAVEAT: This doesn't care if you're using another keyboard.

# OTHER: Super_L is the "Windows" key.

# A sudo way:
#   sudo dmidecode | \
#     grep "Version: ThinkPad X201" > /dev/null \
#     && echo true || echo false

# A non-sudo way.
# Note: xprop -root just checks that X is running (and we're not sshing in).
if xprop -root &> /dev/null; then
  if [[ -e /sys/class/dmi/id/product_version && \
        $(cat /sys/class/dmi/id/product_version) == "ThinkPad X201" ]] ; then
    # On Lenovo ThinkPad: Map Browser-back to Delete
    #   |-------------------------------|
    #   | Brw Bck | Up Arrow | Brow Fwd |
    #   |-------------------------------|
    #   | L Arrow | Down Arr | R Arrow  |
    #   |-------------------------------|
    # Here's the view of the bottom row:
    #  L-Ctrl|Fn|Win|Alt|--Space--|Alt|Menu|Ctrl|Browse-back|Up-arrow|Broforward
    #                                             Left-Arrow|Down-arw|Right-Arrow
    xmodmap -e "keycode 166 = Delete" # brobackward
    # 2015.02.28: At some point, browser-back stopped working, and I used
    #             right-ctrl instead, but now browser back is remapping again.
    #               xmodmap -e "keycode 105 = Delete" # right-ctrl
  fi
fi

if false; then

  # Not all keyboards arrange their six page keys the same way. Some use 
  # two rows and three columns, and some use three rows and two columns.
  # And even when the rows and columns match, not all keyboards use the 
  # same key combinations within.

  # The 2x3 keyboard layout that I like:
  #
  # ||============================||
  # || Insert || Print  || Pause  ||
  # ||        || Screen || Break  ||
  # ||============================||
  #
  # ||==================||
  # || Home   || End    ||
  # ||        ||        ||
  # ||==================||
  # || Insert || Page   ||
  # ||        || Up     ||
  # ||        ||========||
  # ||        || Page   ||
  # ||        || Down   ||
  # ||==================||

  # The 2x3 keyboard layout I do not like:
  # 
  # ||============================||
  # || Print  || Scroll || Pause  ||
  # || Screen || Lock   || Break  ||
  # ||============================||
  #
  # ||==================||
  # || Home   || Page   ||
  # ||        || Up     ||
  # ||==================||
  # || End    || Page   ||
  # ||        || Down   ||
  # ||==================||
  # || Delete || Insert ||
  # ||        ||        ||
  # ||==================||

  # NOTE: To make changes to this list, clear your settings first: $ setxkbmap
  keysym Home = Home
  keysym Page_Up = End
  keysym End = Delete
  keysym Page_Down = Page_Up
  keysym Delete = Delete
  keysym Insert = Page_Down

  # These work (xmodmap takes 'em), but these don't work:
  #   keysym Print = Insert
  #   keysym Scroll_Lock = Print
  #   keysym Sys_Req = Insert
  # These also do not work:
  #   $ xmodmap -pke | grep Print
  #     keycode 107 = Print Sys_Req Print Sys_Req
  #     keycode 218 = Print NoSymbol Print
  #   $ xmodmap -pke | grep Print
  #     keycode  78 = Scroll_Lock NoSymbol Scroll_Lock
  #   keycode 107 = Insert
  #   keycode 218 = Insert
  #   keycode  78 = Print
  # Instead, go to GNOME > System > Preferences > Keyboard Shortcuts
  #   under Desktop, change "Take a screenshot" and "Take a screenshot 
  #   of a window" to Scroll Lock and Alr+Scroll Lock, respectively.
  #   Now, you can override the Print Screen key.
  keysym Print = Insert

fi

#########################

# FIXME: Should move this to a personal-file-mgmt-specific bashrc.

function mv_receipts () {
  /bin/mv -i *.receipt.txt /kit/landonb/finances/receipts/
}

############################################################################
# DONE                              DONE                              DONE #
############################################################################

