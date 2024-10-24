#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=bash
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# FIXME/2020-02-06: This file is the dumping ground for rando!
# - Move these functions to more appropriately-named lib/<files>.sh
#   - E.g., group completions fcns. and move to their own file;
#           probably retire SDKMAK;
#           check if LD_LIBRARY_PATH still needed, and maybe move to LD-specific file;
#           move crontab and anacron to its own file;
#           not sure where EDITOR setting goes...;
#           move pdf180rot to, what, a PDF-named Bashrc?

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

  # 2016-06-28: An article suggested sourcing /etc/bash_completion
  #   https://stackoverflow.com/questions/68372/what-is-your-single-most-favorite-command-line-trick-using-bash
  # 2019-10-13: There was a comment about not being sure I should
  # enable completion, but I never followed up. I love completion!
  # But recently I noticed that tab-completing some scripts fails,
  # but I hadn't noticed this error before, oddly!
  if [ -f /etc/bash_completion ]; then
    # 2019-10-13: Took me long enough to notice!: _xspecs set here, but not
    # outside function! Thus, default tab-completion can fail, because an
    # associative array variable is not set. E.g., $associate_array[$filename]
    # fails because Bash expects the index value to be a number unless the
    # array was explicitly declared -A, and the array that was declared was
    # lost outside of the scope of the function. So the caller should run this
    # function using eval, sending this output to its shell, thereby capturing
    # the lost variable.
    # 2019-10-21: This is what I tried on 2019-10-13:
    #             I changed bashrc.core.sh's
    #               run_and_unset "home_fries_direxpand_completions"
    #             to
    #               eval_and_unset "home_fries_init_completions"
    #             and then tried sourcing it here and exporting the missing array:
    #               . /etc/bash_completion
    #               # If eval_and_unset is called, you need to echo the _xspecs array:
    #               echo $(declare -p _xspecs)
    # 2019-10-21: But then I had issues with completion on `pass ...<TAB>`.
    #  So now let's try sourcing everything, but using eval to do it in the
    #  context of the caller. Or at least that what I think happens. At least
    #  it fixes completion on \`pass\`. But I need to pay better attention to the
    #  issue, because I may have affected completion on other apps. I can at least
    #  list apps that I expect tab completion to work against: starting with pass.
    #  And then someday I can test them all and verify if everything WADs or not.
    echo ". /etc/bash_completion"
  fi
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

  # 2022-10-28: My new M1 MacBook (Apple Silicon) exhibits slightly
  # opposite behavior: It performs Bash variable expansion on <TAB>
  # when `direxpand` is enabled, but it doesn't exhibit (thankfully)
  # $-escaping when disabled.
  os_is_macos && return

  shopt -s direxpand &> /dev/null
}

# --- Generic completions

# Bash command completion for some apps (docker, git, Jira, tig, tmux, Travis CI).
#
# Previously, this function sourced any completion file it'd find, e.g.,
#   while IFS= read -r -d '' file; do ... done
# But the completion files rarely change. So, for readability, and to
# avoid a security hole (indiscriminately sourcing any file therein),
# we'll just explicitly list them here.
#
# - Note that most of the completion files are setup and symlinked by
#   OMR (Oh! My Repos) `mr infuse` commands. The author currently has
#   these completion files installed:
#
#     docker-compose, and jira-completion (from this project, home-fries)
#     git-completion.bash (from https://github.com/landonb/git-smart)
#     git-extras-bash_completion.sh (from https://github.com/tj/git-extras)
#     poetry-completion.bash (from https://github.com/python-poetry/poetry)
#     pyenv.bash (from https://github.com/pyenv/pyenv)
#     tig-completion.bash (from https://github.com/jonas/tig)
#     tmux (from https://github.com/imomaliev/tmux-bash-completion)
#
# - You can still opt-into the load-all-completion-files behavior by
#   setting the HOMEFRIES_LOAD_COMPLETIONS_ANY environment.
# - Or you can declare your own HOMEFRIES_LOAD_COMPLETIONS array to
#   set your own completion file list.

home_fries_load_completions () {
  # Load all Homebrew completion files, both from bash-completion formula,
  # also from individual formulas and casks.
  #
  # - See:
  #
  #     brew install bash-completion@2
  #
  #     command ls -1 /opt/homebrew/etc/bash_completion.d
  # 
  # Verify loaded: [ "${BASH_COMPLETION_VERSINFO}" = "2" ] && echo LOADED
  if command -v brew > /dev/null; then
    if [ -r "$(brew --prefix)/etc/profile.d/bash_completion.sh" ]; then
      # CXREF: /opt/homebrew/etc/profile.d/bash_completion.sh
      . "$(brew --prefix)/etc/profile.d/bash_completion.sh"
    fi
  fi

  local completions_dir="${HOMEFRIES_BIN:-${HOME}/.kit/sh/home-fries/bin}/completions"
  [ -d "${completions_dir}" ] || return

  if ${HOMEFRIES_LOAD_COMPLETIONS_ANY:-false}; then
    # BEWARE: This could be a security risk, if you're worried that an
    # attacker could dump arbitrary files in your completions directory.
    while IFS= read -r -d '' completion_file; do
      # Check that the file exists (it could be a broken symlink
      # (such as a symlink to an unmounted encfs on fresh boot)).
      if [ -e "${completion_file}" ]; then
        . ${completion_file}
      fi
    done < <(find ${completions_dir}/* -maxdepth 1 ! -path . -print0)
  else
    # Selectively load completions (safer than if-branch).
    if ! declare -p HOMEFRIES_LOAD_COMPLETIONS >/dev/null 2>&1; then
      local -a HOMEFRIES_LOAD_COMPLETIONS

      # When sourced on Bash v3, docker-compose STDERRs but still exits 0:
      #   "WARNING: Skipping: /home/user/.homefries/bin/completions/docker-compose (Bash version 3.x)"
      HOMEFRIES_LOAD_COMPLETIONS+=("docker-compose")
      HOMEFRIES_LOAD_COMPLETIONS+=("git-completion.bash")
      HOMEFRIES_LOAD_COMPLETIONS+=("git-extras-bash_completion.sh")
      HOMEFRIES_LOAD_COMPLETIONS+=("jira-completion")
      HOMEFRIES_LOAD_COMPLETIONS+=("poetry-completion.bash")
      # Two notes re: pyenv.bash -- you won't see this file unless pyenv
      # installed from sources using DepoXy OMR 'install' task (if installed
      # via Homebrew, no such file); secondly, this is redundant, because HF
      # also calls `eval "$(pyenv init -)"` on startup.
      HOMEFRIES_LOAD_COMPLETIONS+=("pyenv.bash")
      HOMEFRIES_LOAD_COMPLETIONS+=("tig-completion.bash")
      HOMEFRIES_LOAD_COMPLETIONS+=("tmux")
    fi

    local source_out
    source_out="$(mktemp)"

    for completion_file in ${HOMEFRIES_LOAD_COMPLETIONS[@]}; do
      local completion_path="${completions_dir}/${completion_file}"
      if [ -e "${completion_path}" ]; then
        # echo "completion_file: ${completion_path}"
        . "${completion_path}" > "${source_out}" 2>&1
        # All because docker-compose...
        if [ -s "${source_out}" ]; then
          if [ "${completion_file}" = "docker-compose" ] && \
            cat "${source_out}" | grep -q -e "(Bash version 3.x)$" \
          ; then
            if ${HOMEFRIES_ALERT_BASH3_OR_LESSER:-false}; then
              echo "ALERT: Docker completion not supported in Bash v3"
            fi
          else
            # (lb): My Vim shell highlighter does }\` wrong and does not
            # see the escaped backtick when it trails a right brace, so
            # use less-sightly ''""'' syntax.
            echo 'ALERT: Unexpected `. '"${completion_path}"'` output:'
            echo
            cat "${source_out}"
          fi
        fi
        command rm -f -- "${source_out}"
      fi
    done
  fi
}

# --- SDKMAN

home_fries_load_sdkman () {
  # 2017-02-25: Such Yellers! The SDKMAN! installer appended this to .bashrc:
  #   #THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
  if [ -d "${HOME}/.sdkman" ]; then
    export SDKMAN_DIR="${HOME}/.sdkman"
    [ -s "${HOME}/.sdkman/bin/sdkman-init.sh" ] &&
      . "/home/landonb/.sdkman/bin/sdkman-init.sh"
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
  if [ -d /usr/lib/expect5.45 ]; then
    if [[ ":${LD_LIBRARY_PATH}:" != *":/usr/lib/expect5.45:"* ]]; then
      export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:/usr/lib/expect5.45"
    fi
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
  claim_alias_or_warn "ct" 'crontab -e -u ${LOGNAME}'

  local vim_editor=""
  if [ -e "/usr/bin/vim.basic" ]; then
    vim_editor=/usr/bin/vim.basic
  elif [ -e "/usr/bin/vim.tiny" ]; then
    vim_editor=/usr/bin/vim.tiny
  fi
  # 2015.01.25: FIXME: Not sure what best to use...
  vim_editor=/usr/bin/vim
  if [ -n "${vim_editor}" ]; then
    claim_alias_or_warn "ct-www" '\
      ${HOMEFRIES_TRACE} && echo "ct-www" ; \
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
# shell is opened, and if it hasn't been done since the latest
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
  if [ ! -e "${HOME}/.anacron/anacrontab" ]; then
    return
  fi
  if [ ! -d "${HOME}/.anacron/spool" ]; then
    return
  fi

  # Create the system boot touchfile.
  # NOTE: Need --tmpdir when specifying TEMPLATE-XXX so file goes to /tmp, not $(pwd).
  local boottouch=$(mktemp --tmpdir "BOOT-XXXXXXXXXX")
  # Not a typo: Use Homefries' `uptime-s`, not Linux-only `uptime -s`.
  # ALTLY:
  #   touch -t "$(uptime-s +"%C%y%m%d%H%M.%S")" -- "${boottouch}"
  touch -d "$(uptime-s)" -- "${boottouch}"

  # Name the user anacron touchfile.
  local punchfile="${HOME}/.anacron/punched"

  # Run anacron if never punched, or if booted more recently than punched.
  if [ ! -e "${punchfile}" ] || [ "${boottouch}" -nt "${punchfile}" ]; then
    touch -- "${punchfile}"
    # -s | Serialize jobs execution.
    /usr/sbin/anacron \
      -s \
      -t ${HOME}/.anacron/anacrontab \
      -S ${HOME}/.anacron/spool
  fi

  # Cleanup.
  command rm -- "${boottouch}"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# Default Editor for git, cron, etc.

home_fries_export_editor_vim () {
  # Shim to a Vim wrapper that (1) starts insert mode, and (2) homes the cursor.
  # Under home-fries:bin/, which is wired to $PATH.
  export EDITOR="editor-vim-0-0-insert"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# FIXME/2022-11-04 15:30: Cleanup this comment:

# 2020-01-03: More random crap!
# - I had thought about making a poutine-level command, like fries-findup,
#   but all that overhead for just a few lines of code?
# - I also thought about make a .homefries/lib/pdf_util.sh, but I thought
#   again, all that overhead for just a few lines of code?
# So here it is. Simply enough.

pdf180rot () {
  if ! command -v qpdf > /dev/null; then
    >&2 echo "MISSING: Cannot locate executable: \`qpdf\`"
    return 1
  fi

  if [ -z "$1" ]; then
    >&2 echo "USAGE: pdf180rot <path/to/pdf>"
    return 1
  fi

  if [ ! -f "$1" ]; then
    >&2 echo "ERROR: No such file: ‘$1’"
    return 1
  fi

  command cp -- "$1" "${1}-TBD"
  qpdf "${1}-TBD" "$1" --rotate=+180:1-z
  command rm -- "${1}-TBD"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main () {
  :
}

main "$@"
unset -f main

