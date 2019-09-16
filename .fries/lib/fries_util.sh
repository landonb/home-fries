#!/bin/bash
# Last Modified: 2017.10.03
# vim:tw=0:ts=2:sw=2:et:norl:

# File: fries_util.sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project Page: https://github.com/landonb/home-fries
# Summary: Generic Bash function library.
# License: GPLv3

# Usage: Source this script. Call its functions. Use its exports.
# NOTE/2017-10-03: This particular script has no useful fcns, just environs.

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

source_deps () {
  local curdir=$(dirname -- "${BASH_SOURCE[0]}")
  source ${curdir}/process_util.sh
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# --- Completion options

home_fries_init_completions () {
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
  # Anyway, we'll enable it for now and see what happens................................
}

# --- Re-enable better Bash tab auto-completion.

home_fries_direxpand_completions () {
  # With thanks to:
  #   http://askubuntu.com/questions/70750/
  #     how-to-get-bash-to-stop-escaping-during-tab-completion
  # 2014.01.22: In older Bash, e.g., in Fedora 14, if you typed
  #  $ ll /home/${LOGNAME}/<TAB>
  # your home dir would be listed and the shell prompt would change to, e.g.,
  #  $ ll /home/yourname/
  # but in newer Bash, a <TAB> completion attempt results in
  #  $ ll /home/\${LOGNAME}/
  # which is completely useless. So revert to the old behavior.
  # And using &> since this option isn't available on older OSes
  # (which already default to the (subjectively) "better" behavior).
  shopt -s direxpand &> /dev/null
}

# --- Generic completions

home_fries_load_completions () {
  # Bash command completion (for dub's apps).
  if [[ -d ${HOMEFRIES_DIR}/bin/completions ]]; then
    # 2016-06-28: Currently just ./termdub_completion.
    # 2016-10-30: Now with `exo` command completion.
    # 2016-11-16: sourcing a glob doesn't work for symlinks.
    #   source ${HOMEFRIES_DIR}/bin/completions/*
    # I though a find -exec would work, but nope.
    #   find ${HOMEFRIES_DIR}/bin/completions/ ! -type d -exec bash -c "source {}" \;
    # So then just iterate, I suppose.
    while IFS= read -r -d '' file; do
      #echo "file = $file"
      # Check that the file exists (could be broken symlink
      # (e.g., symlink to unmounted encfs on fresh boot)).
      if [[ -e ${file} ]]; then
        source ${file}
      fi
    done < <(find ${HOMEFRIES_DIR}/bin/completions/* -maxdepth 1 ! -path . -print0)
  fi
}

# --- SDKMAN

home_fries_load_sdkman () {
  # 2017-02-25: Such Yellers! The SDKMAN! installer appended this to .bashrc:
  #   #THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
  if [[ -d "${HOME}/.sdkman" ]]; then
    export SDKMAN_DIR="${HOME}/.sdkman"
    [[ -s "${HOME}/.sdkman/bin/sdkman-init.sh" ]] && source "/home/landonb/.sdkman/bin/sdkman-init.sh"
  fi
}

# --- NVM

home_fries_load_nvm_and_completion () {
  # 2017-07-20: What nvm writes to the end of ~/.bashrc.
  #  curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.2/install.sh | bash
  if [[ -d $HOME/.nvm ]]; then
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# LD_LIBRARY_PATH

home_fries_append_ld_library_path () {
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
  if [[ ":${LD_LIBRARY_PATH}:" != *":/usr/lib/expect5.45:"* ]]; then
    export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/usr/lib/expect5.45
  fi
}

# SQLITE3 / LD_LIBRARY_PATH / SELECT load_extension()/.load

home_fries_alias_ld_library_path_cmds () {
  # 2016-05-03: sqlite3 looks for extensions in the local dir and at
  #             LD_LIBRARY_PATH, but the latter isn't really set up,
  #             e.g., on one machine, it's "/usr/lib/expect5.45:" and
  #             doesn't include the standard system library directory,
  #             /usr/local/lib.
  #
  # We could set LD_LIBRARY_PATH:
  #
  #   export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/usr/local/lib
  #
  # but some blogs I saw don't think you should eff with the ell-d path.
  #
  #   ftp://linuxmafia.com/kb/Admin/ld-lib-path.html
  #
  # We can alias sqlite3 instead, which is probably the solution with
  # the least impact:
  #
  alias sqlite3='LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib sqlite3'
  #
  # however, scripts that call sqlite3 (like hamster-briefs) still have the
  # issue. I guess we'll just let them deal...
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# Crontab shortcuts.

home_fries_alias_crontab () {
  alias ct='crontab -e -u ${LOGNAME}'

  local vim_editor=""
  if [[ -e "/usr/bin/vim.basic" ]]; then
    vim_editor=/usr/bin/vim.basic
  elif [[ -e "/usr/bin/vim.tiny" ]]; then
    vim_editor=/usr/bin/vim.tiny
  fi
  # 2015.01.25: FIXME: Not sure what best to use...
  vim_editor=/usr/bin/vim
  if [[ -n ${vim_editor} ]]; then
    alias ct-www='\
      ${DUBS_TRACE} && echo "ct-www" ; \
      sudo -u ${httpd_user} \
        SELECTED_EDITOR=${vim_editor} \
        crontab -e -u $httpd_user'
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# Anacron check.

# Much like the system's anacron service runs on boot to see if
# any anacron tasks were scheduled to have run while the machine
# was off, we can also see if it's time to call anacron to do
# something.
#
# Note that there's an easier way around this, if you set your
# user's crontab to call anacron every minute, e.g.,
#
#   echo "* * * * * /usr/sbin/anacron -t ${HOME}/.anacron/anacrontab -S ${HOME}/.anacron/spool" | crontab
#
# except then the daily anacron tasks *alway* runs at midnight,
# as opposed to running in the morning like the system daily is
# scheduled (/etc/crontab runs cron.daily at 6:25 if anacron is
# not installed; but when anacron is installed, its crontab, at
# /etc/cron.d/anacron, runs at 7:30 AM.
#
# To mimic this behavior for a user, set their crontab to call
# anacron in the morning, and then run this function anytime a
# shell is opened, and if it hasn't been down since the latest
# boot, call anacron. (This means that, if the machine is up
# most of the time, the normal cron job will run the dailies
# in the morning; but if the machine is booted any time after
# midnight but before the scheduled cron time, anacron will see
# the spool date is the day before, and will run the dailies.
# So better behavior, but not perfect -- and really I just do
# not want my daily backup task running at midnight every night,
# when I'm often awake and at my machine.)
#
# With thanks to super nice code to create a touchfile from the
# last boot time.
#
#   https://unix.stackexchange.com/questions/243976/
#     how-do-i-find-files-that-are-created-modified-accessed-before-reboot

home_fries_punch_anacron () {
  if [[ ! -e ${HOME}/.anacron/anacrontab ]]; then
    return
  fi
  if [[ ! -d ${HOME}/.anacron/spool ]]; then
    return
  fi

  # Create the system boot touchfile.
  # NOTE: Need --tmpdir when specifying TEMPLATE-XXX so file goes to /tmp, not $(pwd).
  local boottouch=$(mktemp --tmpdir "BOOT-XXXXXXXXXX")
  touch -d "$(uptime -s)" "${boottouch}"

  # Name the user anacron touchfile.
  local punchfile="${HOME}/.anacron/punched"

  # Run anacron if never punched, or if booted more recently than punched.
  if [[ ! -e ${punchfile} || ${boottouch} -nt ${punchfile} ]]; then
    touch ${punchfile}
    # -s | Serialize jobs execution.
    /usr/sbin/anacron \
      -s \
      -t ${HOME}/.anacron/anacrontab \
      -S ${HOME}/.anacron/spool
  fi

  # Cleanup.
  /bin/rm "${boottouch}"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# Default Editor for git, cron, etc.

home_fries_export_editor_vim () {
  # Many apps recognize the EDITOR variable, including git, crontab, and dob.
  # Some apps use the variable directly, while others, like crontab, call
  # /usr/bin/sensible-editor. You can also set the editor interactively using
  # /usr/bin/select-editor (but the UI won't find your local builds).
  if [[ -e "${HOME}/.local/bin/vim" ]]; then
    export EDITOR="${HOME}/.local/bin/vim"
  elif [[ -e '/srv/opt/bin/bin/vim' ]]; then
    export EDITOR='/srv/opt/bin/bin/vim'
  elif [[ -e '/usr/bin/vim.basic' ]]; then
    export EDITOR='/usr/bin/vim.basic'
  elif [[ -e '/usr/bin/vim' ]]; then
    export EDITOR='/usr/bin/vim'
  else
    echo "WARNING: bashrc.core.sh: did not set EDITOR: No vim found"
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main () {
  source_deps
  unset -f source_deps

  must_sourced "${BASH_SOURCE[0]}"
}

main "$@"

