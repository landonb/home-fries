# File: bashrc.core.sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Last Modified: 2016.10.13
# Project Page: https://github.com/landonb/home_fries
# Summary: One Developer's Bash Profile
# License: GPLv3

# FIXME Notes
#############

# MAYBE: Cray-cray: None of @ $ ? are mapped in Bash
#        and are free to be aliased or made into commands.
#        Can you think of any magical mapping?

#
#####################

if [[ -f ${HOME}/.fries/lib/bash_base.sh ]]; then
  # 2016.05.05: Cinqo de Mayo. This is cool, right?
  DEBUG_TRACE=false source ${HOME}/.fries/lib/bash_base.sh
fi

if [[ -f ${HOME}/.fries/lib/util.sh ]]; then
  source ${HOME}/.fries/lib/util.sh
fi

# 2016-10-11: Might as well plop git fcns in the sess', eh?
if [[ -f ${HOME}/.fries/lib/git_util.sh ]]; then
  source ${HOME}/.fries/lib/git_util.sh
fi

# Vendor paths (see: setup_mint17.sh)
#####################################

OPT_DLOADS=/srv/opt/.downloads
OPT_BIN=/srv/opt/bin
OPT_SRC=/srv/opt/src
OPT_DOCS=/srv/opt/docs
# 2016-10-10: Google's NoTo zip is nearly 500 MB, so moving .fonts off home.
OPT_FONTS=/srv/opt/.fonts

# Determine OS Flavor
#####################

# This script only recognizes Ubuntu and Red Hat distributions. It'll
# otherwise complain (but it'll still work, it just won't set a few
# flavor-specific options, like terminal colors and the prompt).
# See also: `uname -a`, `cat /etc/issue`, `cat /etc/fedora-release`.

if [[ -e /proc/version ]]; then
  if [[ "`cat /proc/version | grep Ubuntu`" ]]; then
    # echo Ubuntu!
    : # no-op
  elif [[ "`cat /proc/version | grep Red\ Hat`" ]]; then
    # echo Red Hat!
    : # noop
  else
    echo "WARNING: Unknown OS flavor: $(cat /proc/version)"
    echo "Please update this file ($(basename $0)) or comment out this gripe."
  fi
else
  # /proc/version does not exist.
  # echo Chroot!
  : # nop
fi

# Update PATH
#############

# Home-fries scripts are in ~/.fries/bin. Third-party applications installed
# by custom_mint17.extras.sh et al are installed to /srv/opt/bin.

# Binary fries.
PATH="/home/${LOGNAME}/.fries/bin:${PATH}"

# /srv/opt/bin
PATH="${OPT_BIN}:${PATH}"

# ~/.local/bin is where, e.g., `pip install --user blah` installs.
PATH="${PATH}:${HOME}/.local/bin"

# Android Studio.
JAVA_HOME=${OPT_BIN}/jdk
JRE_HOME=$JAVA_HOME/jre
if [[ -d ${JAVA_HOME} ]]; then
  PATH="${JAVA_HOME}/bin:${JRE_HOME}/bin:${PATH}"
fi
if [[ -d ${OPT_BIN}/android-studio/bin ]]; then
  PATH="${PATH}:${OPT_BIN}/android-studio/bin"
fi
if [[ -d ${OPT_BIN}/android-sdk/platform-tools ]]; then
  PATH="${PATH}:${OPT_BIN}/android-sdk/platform-tools"
fi

# No whep. 2016.04.28 and this is the first time I've seen this.
#   $ ifconfig
#   Command 'ifconfig' is available in '/sbin/ifconfig'
#   The command could not be located because '/sbin' is not included in the PATH environment variable.
#   This is most likely caused by the lack of administrative privileges associated with your user account.
#   ifconfig: command not found
PATH="${PATH}:/sbin"

# 2016-07-11: Google Go, for Google Drive `drive`.
#
# The latest go binary.
if [[ -d /usr/local/go/bin ]]; then
  PATH=/usr/local/go/bin:${PATH}
fi
if [[ ! -d ${HOME}/.gopath ]]; then
  # 2016-10-03: Why not?
  mkdir ${HOME}/.gopath
fi
if [[ -d ${HOME}/.gopath ]]; then
  # Local go projects you install.
  export GOPATH=${HOME}/.gopath
  # Check with: `go env`

  #PATH=${GOPATH}:${GOPATH}/bin:${PATH}
  PATH=${GOPATH}:${GOPATH}/bin:${PATH}
fi

# OpenShift Origin server.
if [[ -d ${OPT_BIN}/openshift-origin-server ]]; then
  PATH="${PATH}:${OPT_BIN}/openshift-origin-server"
fi

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
#umask 0007
# 2015.05.14: On second thought... After 'git pull' I have to fix permissions
#             on the Excensus web application files, so might as well make life
#             easier.
umask 0002

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

# SQLITE3 / LD_LIBRARY_PATH / SELECT load_extension()/.load

# 2016-05-03: sqlite3 looks for extensions in the local dir and at
#             LD_LIBRARY_PATH, but the latter isn't really set up,
#             e.g., on tribolium, it's "/usr/lib/expect5.45:" and
#             doesn't include the standard system library directory,
#             /usr/local/lib.
#
# We could set LD_LIBRARY_PATH:
#
#   export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/usr/local/lib
#
# but some blogs I saw don't think you should eff with the ell-d path.
#
# We can alias sqlite3 instead, which is probably the solution with
# the least impact:
#
alias sqlite3='LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib sqlite3'
#
# however, scripts that call sqlite3 (like hamster_briefs) still have the
# issue. I guess we'll just let them deal...

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
shopt -s nocaseglob

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

# 2016-06-28: An article suggested sourcing /etc/bash_completion
# https://stackoverflow.com/questions/68372/what-is-your-single-most-favorite-command-line-trick-using-bash
if [ -f /etc/bash_completion ]; then
  . /etc/bash_completion
fi
# Not sure I need it, though. I read the file (/usr/share/bash-completion/bash_completion)
# and it seems more useful for sysadmins doing typical adminy stuff and less anything I'm
# missing out on.
# Anyway, we'll enable it for now and see what happens....................................

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
  function start_agent() {
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
      for pvt_key in $(/bin/ls $HOME/.ssh/*_rsa $HOME/.ssh/*_dsa 2> /dev/null); do
        sent_passphrase=false
        secret_name=$(basename $pvt_key)
        if [[    -n "$SSH_SECRETS" \
              && -d "$SSH_SECRETS" \
              && -e "$SSH_SECRETS/$secret_name" ]]; then
          if [[ $(command -v expect > /dev/null && echo true) ]]; then
            # CUTE! If your $pphrase has a bracket in it, e.g., "1234[", expect complains:
            #        "missing close-bracket while executing send "1234["
            pphrase=$(cat ${SSH_SECRETS}/${secret_name})
            /usr/bin/expect -c " \
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
        elif [[ ! -d "$SSH_SECRETS" ]]; then
          if [[ -z $SSH_SECRETS ]]; then
            echo "NOTICE: No SSH_SECRETS directory defined."
          else
            echo "NOTICE: No directory at: $SSH_SECRETS"
          fi
          echo "        Set this up yourself."
          echo "        To test again: ssh-agent -k"
          echo "          and then open a new terminal."
        fi
        if ! ${sent_passphrase}; then
          /usr/bin/ssh-add $pvt_key
        fi
      done
    fi
    # Test: ssh-agent -k # then, open a terminal.
  }
  # Source SSH settings, if applicable
  if [[ -f "${SSH_ENV}" ]]; then
    . "${SSH_ENV}" > /dev/null
    #ps ${SSH_AGENT_PID} doesn't work under Cygwin.
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
# 2015.04.04: Tray Cray.
# FIXME: completions... limit to just directories, eh.
function cdd_() {
  if [[ -n $2 ]]; then
    echo 'You wish!' $*
    return 1
  fi
  if [[ -n $1 ]]; then
    pushd "$1" &> /dev/null
    # Same as:
    #  pushd -n "$1" &> /dev/null
    #  cd "$1"
    if [[ $? -ne 0 ]]; then
      # Maybe the stupid user provided a path to a file.
      pushd "$(dirname $1)" &> /dev/null
      if [[ $? -ne 0 ]]; then
        echo "You're dumb."
      else
        # alias errcho='>&2 echo'
        # echo blah >&2
        >&2 echo "FYI: We popped you to a file's homedir, home skillet."
      fi
    fi
  else
    pushd ${HOME} &> /dev/null
  fi
}
# FIXME: 2015.04.04: Still testing what makes the most sense:
#        2016-10-07: I just use `cdd`. What's the problem?
alias cdd='cdd_'
#alias ccd='cdd_'
#alias cdc='cdd_'
# MAYBE GOES FULL ON:
##alias cd='cdd_'
# FIXME: Choose one of:
#alias ppd='popd > /dev/null'
#alias pod='popd > /dev/null'
alias cdc='popd > /dev/null'

# 2015.08.06: Project directory aliases.
# WAS: alias cdfe='pushd ~/.fries/.erectus &> /dev/null'
alias cdfe='pushd ~/.waffle &> /dev/null'
alias cdwf='pushd ~/.waffle &> /dev/null'

# Misc. directory aliases.
alias h='history'         # Nothing special, just convenient.
alias n='netstat -tulpn'  # --tcp --udp --listening --program (name) --numeric
# See alias t="todo.sh" below. Anyway, htop's better.
#alias t='top -c'          # Show full command.
alias ht='htop'           #
alias cmd='command -v $1' # Show executable path or alias definition.
alias grep='grep --color' # Show differences in colour.
#alias less='less -r'      # Raw control characters.
alias less='less -R'      # Better Raw control characters (aka color).
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
alias lS='/bin/ls --color=auto -lhFaS' # Sort by size, from largest (show empties last).

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
#
# NOTE: You have to escape wildcards so that are not expanded too soon, e.g.,
#
#         mv. '*' some/place
#
mv_dotglob () {
  if [[ -z "$1" && -z "$2" ]]; then
    echo "missing args weirdo"
  fi
  shopt -s dotglob
  # or,
  #  set -f
  if [[ $1 == '-f' ]]; then
    /bin/mv $*
  else
    mv $*
  fi
  shopt -u dotglob
  # or,
  #  set +f
}

alias mv.='mv_dotglob'

# Show resource usage, and default to human readable figures.
alias df='df -h -T'
alias du='du -h'
#alias duhome='du -ah /home | sort -n'
# Use same units, else sort mingles different sizes.
# cd ~ && du -BG -d 1 . | sort -n
alias free="free -m"

# [lb] uses p frequently, just like h and ll.
alias p='pwd'

# Alias python from py, but only if there's not already symlink.
if [[ ! -e /usr/bin/py ]]; then
  alias py='/usr/bin/env python'
fi
if [[ ! -e /usr/bin/py2 ]]; then
  alias py2='/usr/bin/env python2'
fi
if [[ ! -e /usr/bin/py3 ]]; then
  alias py3='/usr/bin/env python3'
fi

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
# When you use the -m/--max-count option, you'll see a bunch of
#   ERR: Too many matches in somefile. Skipping the rest of this file.
# which come on stderr from each process thread and ends up interleaving
# with the results, making the output messy and unpredicatable.
# So that Vim can predictably parse the output, we use this shim of a fcn.
function ag_peek () {
  ag -A 0 -B 0 --hidden --follow --max-count 1 $* 2> /dev/null
}

# Does this help?
alias findi='find . -iname'

# 2016-06-28: Stay in same dir when launching bash.
# FIXME: Should I make sure just to do this if a gnome/mate terminal?
alias bash='DUBS_STARTIN=$(dir_resolve $(pwd -P)) /bin/bash'

# Do it to it git it st'ok it
alias git-st='git-st.sh'
alias git-diff='GIT_ST_DIFF=true git-st.sh'
alias git-add='GIT_ST_ADDP=true git-st.sh'

# 2016-09-24: Why didn't I think of this 'til now?
# [Note also that pass can just do it, too.]
alias pwgen16="pwgen -n 16 -s -N 1 -y"

# 2016-10-12: This is temporary? We'll see.
if [[ -f ~/.fries/bin/packme ]]; then
  alias pckme="packme"
fi

# Fix rm to be a crude trashcan
###############################

alias rm='rm_safe'
# DANGER: Will Robinson. Be careful when you repeat yourself, it'll be gone.
alias rmrm='/bin/rm -rf'

# Remove aliases (where "Remove" is a noun, not a verb! =)
$DUBS_TRACE && echo "Setting trashhome"
if [[ -z "$DUB_TRASHHOME" ]]; then
  # Path is ~/.trash
  trashdir=$HOME
else
  trashdir=$DUB_TRASHHOME
fi
#
# 2016-04-26: I added empty_trashes because, while trashes were being
# created on different devices from rm_safe, rmtrash was only emptying
# the trash in the user's home.
#   Also: I find myself feeling more comfortable moving .trash to .trash-TBD
#   for a while and then deleting the .trash-TBD, just in case I don't, say,
#   in a week realize I deleted something. So here's a two-step trash:
#   if you call rmtrash once, it'll temporarily backup the .trash dirs;
#   when you call rmtrash again, it'll remove the last temporary backups.
#   In this manner, you can call rmtrash periodically, like once a month
#   or whatever, and you won't have to worry about accidentally deleting
#   things.
#   MAYBE: You could do an anacron check on the timestamp of the .trash-TBD
#          and call empty_trashes after a certain amount of time has elapsed.
empty_trashes () {
  # locate .trash | grep "\/\.trash$"
  for device_path in `mount \
    | grep \
      -e " type fuse.encfs (" \
      -e " type ext4 (" \
    | awk '{print $3}'`; \
  do
    if [[ "${device_path}" == "/" ]]; then
      trash_path="$trashdir/.trash"
    else
      trash_path="$device_path/.trash"
    fi
    YES_OR_NO="N"
    if [[ -d $trash_path ]]; then
      # FIXME/MAYBE/LATER: Disable asking if you find this code solid enough.
      echo -n "Empty trash at: \"$trash_path\"? [y/n] "
      read -e YES_OR_NO
      if [[ ${YES_OR_NO^^} == "Y" ]]; then
        if [[ -d $trash_path-TBD ]]; then
          /bin/rm -rf $trash_path-TBD
        fi
        /bin/mv $trash_path $trash_path-TBD
        touch $trash_path-TBD
        mkdir $trash_path
      else
        echo "Skipping: User said not to: $trash_path"
      fi
    else
      echo "Skipping: No trash at: $trash_path"
    fi
  done
}
# 2016-04-26: Beef up your trash takeout with Beefy Brand Disposal.
#   Too weak: alias rmtrash='/bin/rm -rf $trashdir/.trash ; mkdir $trashdir/.trash'
alias rmtrash='empty_trashes'

function device_on_which_file_resides() {
  if [[ -d "$1" || -f "$1" ]]; then
    owning_device=$(df "$1" | awk 'NR == 2 {print $1}')
  elif [[ -h "$1" ]]; then
    # A symbolic link, so don't use the linked-to file's location, and don't
    # die if the link is dangling (df says "No such file or directory").
    owning_device=$(df $(dirname "$1") | awk 'NR == 2 {print $1}')
  else
    owning_device=''
    echo "ERROR: Not a directory, regular file, or symbolic link: $1."
    return 1
  fi
  echo $owning_device
}

function device_filepath_for_file() {
  usage_report=$(df "$1")
  if [[ $? -eq 0 ]]; then
    device_path=$(echo "$usage_report" | awk 'NR == 2 {for(i=7;i<=NF;++i) print $i}')
  else
    if [[ ! -L "$1" ]]; then
      # df didn't find file, and file not a symlink.
      echo "WARNING: Using relative path because not a file: $1"
    # else, df didn't find symlink because it points at non existant file.
    fi
    device_path=$(df $(dirname "$1") | awk 'NR == 2 {for(i=7;i<=NF;++i) print $i}')
  fi
  echo $device_path
}

function ensure_trashdir() {
  device_trashdir="$1"
  trash_device="$2"
  if [[ -f ${device_trashdir}/.trash ]]; then
    ensured=0
    # MAYBE: Suppress this message, or at least don't show multiple times
    #        for same ${trash_device}.
    echo "Trash is disabled on device ${trash_device}."
  else
    if [[ ! -e ${device_trashdir}/.trash ]]; then
      echo "Trash directory not found on ${trash_device}"
      sudo_prefix=""
      if [[ ${device_trashdir} == "/" ]]; then
        # The file being deleted lives on the root device but the default
        # trash directory is not on the same device. This could mean the
        # user has an encrypted home directory. Rather than moving files
        # to the encryted space, use an unencrypted trash location, but
        # make the user do it.
        echo
        echo "There's no /.trash directory for the root device."
        echo
        echo "This probably means you have an encrypted home directory."
        echo
        sudo_prefix="sudo"
      fi
      echo "Create a new trash at ${device_trashdir}/.trash ?"
      echo -n "Please answer [y/n]: "
      read the_choice
      if [[ ${the_choice} != "y" && ${the_choice} != "Y" ]]; then
        ensured=0
        echo "To suppress this message, run: touch ${device_trashdir}/.trash"
      else
        ${sudo_prefix} /bin/mkdir -p ${device_trashdir}/.trash
        if [[ -n ${sudo_prefix} ]]; then
          sudo chgrp staff /.trash
          sudo chmod 2775 /.trash
        fi
      fi
    fi
    if [[ -d ${device_trashdir}/.trash ]]; then
      ensured=1
    fi
  fi
  return ${ensured}
}

function rm_safe() {
  # The trash can way!
  # You can disable the trash by running
  #   /bin/rm -rf ~/.trash && touch ~/.trash
  # You can make the trash with rmtrash or mkdir ~/.trash,
  #   or run the command and you'll be prompted.
  OLD_IFS=$IFS
  IFS=$'\n'
  for fpath in $*; do
    local bname=$(basename "${fpath}")
    # A little trick to make sure to use the trash can on
    # the right device, to avoid copying files.
    trash_device=$(device_on_which_file_resides "${trashdir}")
    if [[ $? -ne 0 ]]; then
      echo "ERROR: No device for trashdir: ${trashdir}"
      return 1
    fi
    fpath_device=$(device_on_which_file_resides "${fpath}")
    if [[ $? -ne 0 ]]; then
      echo "ERROR: No device for fpath: ${fpath}"
      return 1
    fi
    if [[ ${trash_device} = ${fpath_device} ]]; then
      # MAYBE: Update this fcn. to support specific trash
      # directories on each device. For now you can specify
      # one specific dir for one drive (generally /home/$USER/.trash)
      # and then all other drives it's assumed to be at, e.g.,
      # /media/XXX/.trash.
      device_trashdir="${trashdir}"
    else
      device_trashdir=$(device_filepath_for_file "${fpath}")
      trash_device=${fpath_device}
    fi
    ensure_trashdir "${device_trashdir}" "${trash_device}"
    if [[ $? -eq 1 ]]; then
      local fname=${bname}
      if [[ -e "${device_trashdir}/.trash/${fname}" || -h "${device_trashdir}/.trash/${fname}" ]]; then
        fname="${bname}.$(date +%Y_%m_%d_%Hh%Mm%Ss_%N)"
      fi
      # If fpath is a symlink and includes a trailing slash, doing a raw mv:
      #  /bin/mv "${fpath}" "${device_trashdir}/.trash/${fname}"
      # causes the response:
      #  /bin/mv: cannot move ‘symlink/’ to ‘/path/to/.trash/symlink.2015_12_03_14h26m51s_179228194’: Not a directory
      /bin/mv "$(dirname "${fpath}")/${bname}" "${device_trashdir}/.trash/${fname}"
    else
      # Ye olde original rm alias, now the unpreferred method.
      /bin/rm -i "${fpath}"
    fi
  done
  IFS=$OLD_IFS
}

function rm_safe_deprecated() {
  /bin/mv --target-directory ${trashdir}/.trash "$*"
}

# Terminal Prompt
#################

function dubs_set_terminal_prompt() {

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
    elif [[ $(stat -c %i /) -eq 2 ]]; then
      # Not in chroot jail.
      #TITLEBAR='\[\e]0;\u@\h:\w\a\]'
      #TITLEBAR='\[\e]0;\w:(\u@\h)\a\]'
      #TITLEBAR='\[\e]0;\w\a\]'
      TITLEBAR='\[\e]0;\W\a\]'
    else
      TITLEBAR='\[\e]0;|-\W-|\a\]'
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
  if [[ -e /proc/version ]]; then
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
      # 2015.03.04: I need to know when I'm in chroot hell.
      # NOTE: There's a better way using sudo to check if in chroot jail
      #       (which is compatible with Mac, BSD, etc.) but we don't want
      #       to use sudo, and we know we're on Linux. And on Linux,
      #       the inode of the (outermost) root directory is always 2.
      # CAVEAT: This check works on Linux but probably not on Mac, BSD, Cygwin, etc.
      if [[ $(stat -c %i /) -eq 2 ]]; then
        #PS1="${TITLEBAR}\[\033[01;37m\]\u@\[\033[1;33m\]\h\[\033[00m\]:\[\033[01;36m\]\W\[\033[00m\]\$ "
        # 2015.03.04: The chroot is Ubuntu 12.04, and it's Bash v4.2 does not
        #             support Unicode \uXXXX escapes, so use the escape in the
        #             outer. (Follow the directory path with an anchor symbol
        #             so I know I'm *not* in the chroot.)
        PS1="${TITLEBAR}\[\033[01;37m\]\u@\[\033[1;33m\]\h\[\033[00m\]:\[\033[01;36m\]\W\[\033[00m\]"$' \u2693 '"\$ "
        # 2015.02.26: Add git branch.
        #             Maybe... not sure I like this...
        #             maybe change delimiter and make branch name colorful?
        #PS1="${TITLEBAR}\[\033[01;37m\]\u@\[\033[1;33m\]\h\[\033[00m\]:\[\033[01;36m\]\W\[\033[00m\]"'$(__git_ps1 "-%s" )\$ '
      else
        # NOTE: Bash's $'...' sees \uXXXX unicode espace sequences, but not $"..."
        # See the Unicode character table: http://unicode-table.com/en/
        # Bash doesn't support all Unicode characters, so see also this list:
        #   https://mkaz.com/2014/04/17/the-bash-prompt/
        #PS1="${TITLEBAR}\[\033[01;31m\]"$'\u2605'"\u@"$'\u2605'"\[\033[1;36m\]\h\[\033[00m\]:\[\033[01;33m\]\W\[\033[00m\]"$' \u2693 '
        # 2015.03.04: As mentioned above, the chroot may be running an old Bash,
        #             so use the Unicode \uXXXX escape in the outer only.
        PS1="${TITLEBAR}\[\033[01;31m\]**\u@**\[\033[1;36m\]\h\[\033[00m\]:\[\033[01;33m\]\W\[\033[00m\] "'! '
      fi
    elif [[ "`cat /proc/version | grep Red\ Hat`" ]]; then
      $DUBS_TRACE && echo "Red Hat"
      PS1="${TITLEBAR}\[\033[01;36m\]\u@\[\033[1;33m\]\h\[\033[00m\]:\[\033[01;37m\]\W\[\033[00m\]\$ "
    else
        echo "WARNING: Not enough info. to set PS1."
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
#PYTHON_VER=$(python --version 2>&1)
# Convert, e.g., 'Python 3.4.0' to '3.4'.
# Note the |&, which is like 2>&1, i.e., send stderr to stdout.
# 2016-07-18: Ubuntu 16.04: Adds a plus sign!: Python 3.5.1+
PYVERS_RAW3=`python3 --version \
  |& /usr/bin/awk '{print $2}' \
  | /bin/sed -r 's/^([0-9]+\.[0-9]+)\.[0-9]+\+?/\1/g'`
if [[ -n $PYVERS_RAW3 ]]; then
  export PYTHONVERS3=python${PYVERS_RAW3}
  export PYVERSABBR3=py${PYVERS_RAW3}
else
  echo
  echo "######################################################################"
  echo
  echo "WARNING: Unexpected: Could not parse Python3 version."
  echo "python3 --version: `python3 --version`"
  python3 --version
  python3 --version |& /usr/bin/awk '{print $2}'
  python3 --version |& /usr/bin/awk '{print $2}' | /bin/sed -r 's/^([0-9]+\.[0-9]+)\.[0-9]+\+?/\1/g'
  echo
  echo "######################################################################"
  echo
  # If we exit, you cannot log on the terminal! Because /bin/bash exits...
  #exit 1
fi

# Convert, e.g., 'Python 2.7.6' to '2.7'.
# 2016-07-18: NOTE: Default on Mint 17: Python 2.7.6
#              Default on Ubuntu 16.04: Python 2.7.12
PYVERS_RAW2=`python2 --version \
  |& /usr/bin/awk '{print $2}' \
  | /bin/sed -r 's/^([0-9]+\.[0-9]+)\.[0-9]+/\1/g'`
PYVERS_DOTLESS2=`python2 --version \
  |& /usr/bin/awk '{print $2}' \
  | /bin/sed -r 's/^([0-9]+)\.([0-9]+)\.[0-9]+/\1\2/g'`
if [[ -z $PYVERS_RAW2 ]]; then
  echo
  echo "######################################################################"
  echo
  echo "WARNING: Unexpected: Could not parse Python2 version."
  echo
  echo "######################################################################"
  echo
  # If we exit, you cannot log on the terminal! Because /bin/bash exits...
  #exit 1
fi
PYVERS_RAW2=${PYVERS_RAW2}
PYVERS_RAW2_m=${PYVERS_RAW2}m
PYTHONVERS2_m=python${PYVERS_RAW2_m}
PYVERS_CYTHON2=${PYVERS_DOTLESS2}m
#
PYTHONVERS2=python${PYVERS_RAW2}
PYVERSABBR2=py${PYVERS_RAW2}

# Determine the apache user.
# 'TEVS: CAPITALIZE these, like most exports.
if [[ -e /proc/version ]]; then
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
else
  # If no /proc/version, then this is an unwired chroot jail.
  : # Meh.
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
  alias ct-www='\
    ${DUBS_TRACE} && echo "ct-www" ; \
    sudo -u $httpd_user \
      SELECTED_EDITOR=${VIM_EDITOR} \
      crontab -e -u $httpd_user'
fi

#########################

# Control and Kill Processes.

# Restart Apache.
if [[ -e /proc/version ]]; then
  if [[ "`cat /proc/version | grep Ubuntu`" ]]; then
    alias re='\
      ${DUBS_TRACE} && echo "re" ; \
      sudo /etc/init.d/apache2 reload'
    alias res='\
      ${DUBS_TRACE} && echo "res" ; \
      sudo /etc/init.d/apache2 restart'
  elif [[ "`cat /proc/version | grep Red\ Hat`" ]]; then
    alias re='\
      ${DUBS_TRACE} && echo "re" ; \
      sudo service httpd reload'
    alias res='\
      ${DUBS_TRACE} && echo "res" ; \
      sudo service httpd restart'
  fi
# else, in unrigged chroot.
fi

#########################

# SYNC_ME: See also fcn. of same name in bash_base.sh/bashrc_core.sh.
# EXPLAIN/FIXME: Why doesn't bash_core.sh just use what's in bash_base.sh
#                and share like a normal script?
killsomething () {
  something=$1
  # The $2 is the awk way of saying, second column. I.e., ps aux shows
  #   apache 27635 0.0 0.1 238736 3168 ? S 12:51 0:00 /usr/sbin/httpd
  # and awk splits it on whitespace and sets $1..$11 to what was split.
  # You can even {print $99999} but it's just a newline for each match.
  somethings=`ps aux | grep "${something}" | grep -v "\<grep\>" | awk '{print $2}'`
  # NOTE: awk {'print $2'} is also acceptable.
  if [[ "$somethings" != "" ]]; then
    echo $(ps aux | grep "${something}" | grep -v "\<grep\>")
    echo "Killing: $somethings"
    echo $somethings | xargs sudo kill -s 9 >/dev/null 2>&1
  fi
  return 0
}

#########################

# C.f. ${HOME}/.fries/lib/bash_base.sh.
dir_resolve () {
  # Squash error messages but return error status, maybe.
  pushd "$1" &> /dev/null || return $?
  # -P returns the full, link-resolved path.
  dir_resolved="`pwd -P`"
  popd &> /dev/null
  echo "$dir_resolved"
}

# symlink_dirname gets the dirname of
# a filepath after following symlinks;
# can be used in lieu of dir_resolve.
symlink_dirname () {
  echo $(dirname $(readlink -f $1))
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
  THIS_WINDOW_ID=$(xdotool getactivewindow)
  WINDOW_IDS=$(xdotool search --class "$WM_TERMINAL_APP")
  for winid in $WINDOW_IDS; do
    # Don't send the command to this window, at least not yet, since it'll
    # end up on stdin of this fcn. and won't be honored as a bash command.
    if [[ $THIS_WINDOW_ID -ne $winid ]]; then
      # See if this is a legit window or not.
      DESKTOP_NUM=$(xdotool get_desktop_for_window $winid 2> /dev/null)
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
        xdotool type --window $winid $*
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
  THIS_WINDOW_ID=$(xdotool getactivewindow)
  WINDOW_IDS=$(xdotool search --class "$WM_TERMINAL_APP")
  for winid in $WINDOW_IDS; do
    if [[ $THIS_WINDOW_ID -ne $winid ]]; then
      DESKTOP_NUM=$(xdotool get_desktop_for_window $winid 2> /dev/null)
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
    THIS_WINDOW_ID=$(xdotool getactivewindow)
    WINDOW_IDS=$(xdotool search --class "$WM_TERMINAL_APP")
    for winid in $WINDOW_IDS; do
        if [[ $THIS_WINDOW_ID -ne $winid ]]; then
            DESKTOP_NUM=$(xdotool get_desktop_for_window $winid 2> /dev/null)
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

termdo-bash-reset () {
  termdo-all /bin/bash
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

#########################

echoerr () { echo "$@" 1>&2; }

#########################

# Helpers for fixing permissions (mostly for web-accessible files).

# Recursively web-ify a directory hierarchy.

webperms () {
  if [[ -z $1 || ! -d $1 ]]; then
    echo "ERROR: Not a directory: $1"
    return 1
  fi
  # Recurse through the web directory.
  # The naive `find` approach.
  #   find $1 -type d -exec chmod 2775 {} +
  #   find $1 -type f -exec chmod u+rw,g+rw,o+r {} +
  # A smarter approach: use chmod's 'X' flag to only add the
  # execute bit to directories or to files that already have
  # execute permission for some user.
  ##chmod -R o+rX $1
  #chmod -R u+rwX,g+rwX,o+rX $1
  ${DUBS_TRACE} && echo "Web dir.: $1"
  #chmod -R o+rX $1 &> /dev/null || sudo chmod -R o+rX $1
  chmod -R u+rwX,g+rwX,o+rX $1 &> /dev/null || sudo chmod -R u+rwX,g+rwX,o+rX $1
  # Also fix the ancestor permissions.
  local CUR_DIR=$1
  while [[ -n ${CUR_DIR} && $(dirname ${CUR_DIR}) != '/' ]]; do
    ${DUBS_TRACE} && echo "Ancestor: ${CUR_DIR}"
    # NOTE: Not giving read access, just execute.
      chmod -R o+X ${CUR_DIR} &> /dev/null || sudo chmod -R o+X ${CUR_DIR}
    local CUR_DIR=$(dirname ${CUR_DIR})
  done
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
  # Python has a great timeit fcn. you could use on a command, or
  # you could just do it in Bash. Except msg is not as friendly here.
  if [[ -z ${simpletimeit_0+x} ]]; then
    if [[ -z $1 ]]; then
      echo "Nothing took no time."
      return
    else
      time_0=$(date +%s.%N)
      $*
    fi
  else
    time_0=${simpletimeit_0}
  fi
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

#alias tt="todo.sh traskr"
#alias tt="traskr.py"

# FIXME: We can do better!
#PATH="${PATH}:/kit/traskr-time-tracker"

#eval "$(register-python-argcomplete ${HOME}/.todo.actions.d/traskr)"
#eval "$(register-python-argcomplete /kit/traskr-time-tracker/traskr.py)"
#eval "$(register-python-argcomplete traskr.py)"
if [[ -e /usr/local/bin/register-python-argcomplete ]]; then
  eval "$(register-python-argcomplete tt)"
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
  for subdir in $(find . -name ".git" -type d); do
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
  DEVICE_NUM=$(xinput --list --id-only "SynPS/2 Synaptics TouchPad" 2> /dev/null)
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

mount_guard () {
  if [[ -n $(/bin/ls -A ~/.waffle/.guard) ]]; then
    encfs ~/.waffle/.guard ~/.waffle/guard
  fi
}

umount_guard () {
  fusermount -u ~/.waffle/guard
}

#mount_sepulcher () {
#  if [[ -z $(/bin/ls -A ~/.fries/sepulcher) ]]; then
#    encfs ~/.fries/.sepulcher ~/.fries/sepulcher
#  fi
#}

#umount_sepulcher () {
#  fusermount -u ~/.fries/sepulcher
#}

# To manage the encfs (change pwd, etc.), see: encfsctl

#########################

# Bash command completion (for dub's apps).

if [[ -d ${HOME}/.fries/bin/completions ]]; then
  # 2016-06-28: Currently just ./termdub_completion.
  source ${HOME}/.fries/bin/completions/*
fi

#########################

# Secure ``locate`` with ``ecryptfs``

# https://askubuntu.com/questions/20821/using-locate-on-an-encrypted-partition

updatedb_ecryptfs () {
  /bin/mkdir -p ~/.mlocate
  export LOCATE_PATH="$HOME/.mlocate/mlocate.db"
  updatedb -l 0 -o $HOME/.mlocate/mlocate.db -U $HOME
}

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
    command -v xmodmap &> /dev/null
    if [[ $? -eq 0 ]]; then
      xmodmap -e "keycode 166 = Delete" # brobackward
    fi
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

# For pinentry (for vim-gunpg):
export GPG_TTY=`tty`

#########################

# Show timestamps in bash history.

export HISTTIMEFORMAT="%d/%m/%y %T "

#########################

# "Want colored man pages?"
# http://boredzo.org/blog/archives/2016-08-15/colorized-man-pages-understood-and-customized
# https://superuser.com/questions/452034/bash-colorized-man-page

man() {
  env \
    LESS_TERMCAP_mb=$(printf "\e[1;31m") \
    LESS_TERMCAP_md=$(printf "\e[1;31m") \
    LESS_TERMCAP_me=$(printf "\e[0m") \
    LESS_TERMCAP_se=$(printf "\e[0m") \
    LESS_TERMCAP_so=$(printf "\e[1;44;33m") \
    LESS_TERMCAP_ue=$(printf "\e[0m") \
    LESS_TERMCAP_us=$(printf "\e[1;32m") \
    man "$@"
}

#########################

# 2015.08.30: Well, this is new: [lb] seeing Ctrl-D'ing to get outta
#             Python propagating to Bash, which didn't usedta happen.
#             So now force user to type `exit` to close Bash terminal.
# 2016-09-23: Title better: Prevent Ctrl-D from exiting shell.
export IGNOREEOF=9999999

# 2016-09-24: Seriously? This is what's been hounding me forever?
#             So that, e.g., `echo "!X"` works.
#             And I _rarely_ use !n to repeat a history command.
#             Usually, I just up-arrow.
#             Recently, I've been Ctrl-R'ing.
#             But I'm always annoyed when a bang in a paragraph
#             *confuses* the shell.
set +o histexpand

#########################

# 2016-09-26: This is just a reminder of a good way to iterate over directories.
# I used to just change IFS, but this trick handles newlines and asterisks in paths,
# in addition to spaces in file/directory/path names.
#   http://unix.stackexchange.com/questions/9496/looping-through-files-with-spaces-in-the-names
printdirsincur () {
  find . -maxdepth 1 -type d ! -path . -print0 | while IFS= read -r -d '' file; do
    echo "file = $file"
  done
}

printdirsincur_better () {
  # HA. HA. HA!
  # http://unix.stackexchange.com/questions/272698/why-is-the-array-empty-after-the-while-loop
  #
  # This one avoids an issue with the '|' pipe causing a subsheel to run.
  #
  # Which means an environment variable you set outside the while loop, such as
  # an array, will not be affected by whatever happens inside the while loop.
  # So use <() instead, which causes no subshell.
  while IFS= read -r -d '' file; do
    echo "file = $file"
  done < <(find . -maxdepth 1 -type d ! -path . -print0)
}

# Also remember: In Bash, to handle spaces when iterating over an array, iterate the indices.
array_iterate_example () {
  AN_ARR=$1
  for ((i = 0; i < ${#AN_ARR[@]}; i++)); do
    AN_ELEM="${AN_ARR[$i]}"
    echo "AN_ELEM: ${AN_ELEM}"
  done
}

#########################

# 2016-10-05: [lb] not seeing the disable-wake-on-lid action working, from:
#
#     ~/.fries/once/recipe/usr/lib/pm-utils/sleep.d/33disablewakeups
#
#             so let's try this here in bashrc.

disable_wakeup_on_lid () {
  cat /proc/acpi/wakeup | grep "^LID" &> /dev/null
  if [[ $? -eq 0 ]]; then
    cat /proc/acpi/wakeup | grep "^LID" | grep disabled &> /dev/null
    if [[ $? -ne 0 ]]; then
      #echo " LID" | sudo tee /proc/acpi/wakeup
      echo " LID" | tee /proc/acpi/wakeup
    fi
  fi
} # end: disable_wakeup_on_lid

# FIXME: The permissions on /proc/acpi/wakeup get reset every boot, so we need a new strategy.
#disable_wakeup_on_lid

#########################

#function uuid_8 () {
#  local UUID=`uuidgen`
#  # Returns, e.g., 3748b331-be9b-4446-ba00-4f7937eec047
#  echo ${UUID:0:8}
#}

#########################

# 2016-10-10: Starting in September sometime,
# on both 14.04/rebecca/trusty and 16.04/sarah/xenial,
# both my laptop and my desktop had stopped asking for
# a password on resume from suspend.
#
# This is a hacky work-around -- using the screen saver.
# I don't know that the screensaver's lock is as secure as the window manager's lock.
# FIXME/EXPLAIN: How does a screensaver lock and an encrypted home work?
#                You can just physically connect to the machine somehow
#                and read home directory files, can you?
# In any case, this is the best I can do so far.

# FIXME: This isn't the right URL but 'natchurally I didn't come up with any
#   of the gnome-screensaver-command, dbus-send, or systemctl command.
#   I just found them. 'natchurally.
#     https://bugs.launchpad.net/linuxmint/+bug/1185681
#   Hopeless links:
#     http://askubuntu.com/questions/22735/disable-locking-the-screen-after-resuming-from-suspend
#       gsettings get org.gnome.desktop.lockdown disable-lock-screen
#         is false already!
lock_screensaver_and_power_suspend () {
  source /etc/lsb-release
  if [[ ${DISTRIB_CODENAME} = 'xenial' || ${DISTRIB_CODENAME} = 'sarah' ]]; then
    gnome-screensaver-command --lock && \
      systemctl suspend -i
  elif [[ ${DISTRIB_CODENAME} = 'trusty' || ${DISTRIB_CODENAME} = 'rebecca' ]]; then
    gnome-screensaver-command --lock && \
      dbus-send --system --print-reply --dest=org.freedesktop.UPower \
        /org/freedesktop/UPower org.freedesktop.UPower.Suspend
  else
    echo "ERROR: Unknown distro to us. Refuse to Lock Screensaver and Power Suspend."
    return 1
  fi
} # end: lock_screensaver_and_power_suspend

# 2016-10-10: Seriously? `qq` isn't a command? Sweet!
alias qq="lock_screensaver_and_power_suspend"

#########################

############################################################################
# DONE                              DONE                              DONE #
############################################################################

