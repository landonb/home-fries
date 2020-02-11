# File: bashrc.core.sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Last Modified: 2017.12.17
# Project Page: https://github.com/landonb/home-fries
# Summary: One Developer's Bash Profile [Home-🍟]
# License: GPLv3
# vim:tw=0:ts=2:sw=2:et:norl:

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# *** Doobious Sources

source_utils () {
  local time_outer_0=$(date +%s.%N)

  # Generally, FRIES_DIR=${HOME}/.fries [a/k/a /home/${LOGNAME}/.fries]
  export HOMEFRIES_DIR=$(dirname $(dirname -- "${BASH_SOURCE[0]}"))
  if [[ ${HOMEFRIES_DIR} == '/' ]]; then
    echo 'WARNING: Where is .fries installed? For real?'
  fi

  declare -a lib_files=()

  unset -v HOMEFRIES_LOADED_BASH_BASE
  lib_files+=("alias_util.sh")
  lib_files+=("apache_util.sh")
  lib_files+=("array_util.sh")
  lib_files+=("bash_base.sh")
  lib_files+=("color_envs.sh")
  lib_files+=("color_funcs.sh")
  # SKIPPING:("cron_util.sh")
  lib_files+=("crypt_util.sh")
  lib_files+=("curly_util.sh")
  # SKIPPING:("cygwin_util.sh")
  lib_files+=("date_util.sh")
  lib_files+=("dir_util.sh")
  # SKIPPING:("direnv_util.sh")
  lib_files+=("distro_util.sh")
  lib_files+=("docker_util.sh")
  lib_files+=("fffind_util.sh")
  lib_files+=("file_util.sh")
  # SKIPPING:("find_util.sh")
  lib_files+=("fries_util.sh")
  lib_files+=("git_util.sh")
  lib_files+=("hist_util.sh")
  lib_files+=("input_util.sh")
  lib_files+=("interact_util.sh")
  lib_files+=("keys_util.sh")
  # SKIPPING:("logger.sh")
  lib_files+=("no_util.sh")
  lib_files+=("openshift_util.sh")
  lib_files+=("path_util.sh")
  lib_files+=("paths_util.sh")
  lib_files+=("process_util.sh")
  lib_files+=("python_util.sh")
  # SKIPPING:("ruby_chutil.sh")
  lib_files+=("ruby_util.sh")
  lib_files+=("session_util.sh")
  lib_files+=("ssh_util.sh")
  lib_files+=("term_util.sh")
  lib_files+=("time_util.sh")
  lib_files+=("trash_util.sh")

  DEBUG_TRACE=false
  for lib_file in "${lib_files[@]}"; do
    if [[ -f "${HOMEFRIES_DIR}/lib/${lib_file}" ]]; then
      local time_0=$(date +%s.%N)
      source "${HOMEFRIES_DIR}/lib/${lib_file}"
      print_elapsed_time "${time_0}" "Source: ${lib_file}"
    else
      # Was:
      #  ${DUBS_PROFILING} && echo "MISSING: ${lib_file}"
      >&2 echo "MISSING: ${lib_file}"
    fi
  done

  if [[ -z ${HOMEFRIES_WARNINGS+x} ]]; then
    # Usage, e.g.:
    #   HOMEFRIES_WARNINGS=true bash
    HOMEFRIES_WARNINGS=false
  fi

  print_elapsed_time \
    "${time_outer_0}" \
    "Sourced ${#lib_files[@]} files (source_utils)." \
    "SOURCES: "
}

source_virtualenvwrapper () {
  local time_outer_0=$(date +%s.%N)

  # Before sourcing the virturalenv wrapper, remove remnants from PATH.
  # That is, if you `workon <venv>` and than run `bash` or `tmux`, the
  # venv binaries will still be on PATH. Then, when sourcing the wrapper
  # on bash (home-fries) startup, you'd see:
  #
  #   /home/<user>/.virtualenvs/<venv>/bin/python:
  #     Error while finding module specification for 'virtualenvwrapper.hook_loader'
  #       (ModuleNotFoundError: No module named 'virtualenvwrapper')
  #   virtualenvwrapper.sh: There was a problem running the initialization hooks.
  #
  #   If Python could not import the module virtualenvwrapper.hook_loader,
  #     check that virtualenvwrapper has been installed for
  #       VIRTUALENVWRAPPER_PYTHON=/home/landonb/.virtualenvs/dob37/bin/python
  #         and that PATH is set properly.
  #
  # Note the wrapper checks $WORKON_HOME, which defaults to ".virtualenvs"
  # if blank, to form the path, e.g., workon_home_dir="$HOME/$WORKON_HOME".
  # - Here we convert PATH separators to newlines;
  # - ignore any line starting with WORKON; and
  # - reform the path, converting newlines back to colons.
  # Note, too, the inner-$, in <$'\n'>, is ANSI-C Quoting.
  # https://www.gnu.org/software/bash/manual/html_node/ANSI_002dC-Quoting.html
  PATH=$(echo "${PATH//:/$'\n'}" | grep -v -e "^${HOME}/.virtualenvs/" | tr '\n' ':')
  export PATH

  if [[ -f ${HOME}/.local/bin/virtualenvwrapper.sh ]]; then
    source ${HOME}/.local/bin/virtualenvwrapper.sh
  elif [[ -f /usr/local/bin/virtualenvwrapper.sh ]]; then
    source /usr/local/bin/virtualenvwrapper.sh
  fi

  print_elapsed_time \
    "${time_outer_0}" \
    "Sourced virtualenvwrapper.sh." \
    "Sourced: "
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

eval_and_unset () {
  local time_0=$(date +%s.%N)

  # So that the func being sourced can use stdout
  # to have this shell set, e.g., array variables.
  eval $(eval "$@")
  unset -f "$1"

  print_elapsed_time "${time_0}" "Action: $1"
}

run_and_unset () {
  local time_0=$(date +%s.%N)

  eval "$@"
  unset -f "$1"

  print_elapsed_time "${time_0}" "Action: $1"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

home_fries_up () {
  local time_outer_0=$(date +%s.%N)

  #########################

  # Determine OS Flavor

  # This script only recognizes Ubuntu and Red Hat distributions. It'll
  # otherwise complain (but it'll still work, it just won't set a few
  # flavor-specific options, like terminal colors and the prompt).
  # See also: `uname -a`, `cat /etc/issue`, `cat /etc/fedora-release`.
  # - lib/distro_util.sh
  run_and_unset "distro_complain_not_ubuntu_or_red_hat"

  #########################

  # Update PATH
  # - lib/paths_util.sh
  run_and_unset "home_fries_set_path_environ"

  # (lb): Set MANPATH. (Specifically, cull paths to anything on a CryFS mount,
  # which makes `man <topic>` takes so many seconds to load; sheesh, annoying!)
  # - lib/paths_util.sh
  run_and_unset "home_fries_configure_manpath"

  # Set umask to 0002
  # - lib/file_util.sh
  run_and_unset "home_fries_default_umask"

  #########################

  # Set EDITOR, used by git, cron, dob, etc.
  # - lib/fries_util.sh
  run_and_unset "home_fries_export_editor_vim"

  #########################

  # - lib/fries_util.sh
  run_and_unset "home_fries_append_ld_library_path"

  # - lib/fries_util.sh
  run_and_unset "home_fries_alias_ld_library_path_cmds"

  #########################

  # Tell psql to use less for large output
  # - lib/file_util.sh
  run_and_unset "home_fries_wire_export_less"

  #########################

  # Shell options
  # - lib/session_util.sh
  run_and_unset "home_fries_configure_shell_options"

  #########################

  # Completion options

  # - lib/fries_util.sh
  eval_and_unset "home_fries_init_completions"

  # - lib/fries_util.sh
  run_and_unset "home_fries_direxpand_completions"

  #########################

  # SSH

  # NOTE: Not doing this for root.
  # 2012.12.22: Don't do this for cron, either, or cron sends
  #   Identity added: /home/.../.ssh/id_rsa (/home/.../.ssh/id_rsa)
  #   Identity added: /home/.../.ssh/identity (/home/.../.ssh/identity)

  # See: ~/.fries/lib/bash_base.sh
  # - lib/ssh_util.sh
  ssh_agent_kick

  #########################

  # Configure Bash session aliases.

  # Set: `ll` => `ls -ls`, etc.
  # - lib/alias_util.sh
  run_and_unset "home_fries_create_aliases_general"

  # Set: `rg` => `rg --smart-case --hidden --colors ...`
  # - lib/alias_util.sh
  run_and_unset "home_fries_create_aliases_greppers"

  # Set: `cdd` => pushd wrapper; `cdc` => popd; `cddc` => toggle cd last
  # - lib/alias_util.sh
  run_and_unset "home_fries_create_aliases_chdir"

  # - lib/alias_util.sh
  run_and_unset "home_fries_create_aliases_tab_completion"

  # Set: `rm` => `rm_safe` [e.g., "remove" to ~/.trash]
  # - lib/trash_util.sh
  run_and_unset "home_fries_create_aliases_trash"

  #########################

  # Configure the terminal prompt and colors. (From term_util.sh)

  # Set `PS1=` to customize the terminal prompt.
  # - lib/term_util.sh
  run_and_unset "dubs_set_terminal_prompt"

  # Set PS4, for `set -x` and `set -v` debugging/tracing.
  # - lib/term_util.sh
  run_and_unset "dubs_set_PS4"

  # Fix the colors used by `ls -C` to be less annoying.
  # - lib/term_util.sh
  run_and_unset "dubs_fix_terminal_colors"

  # Make the current window always-on-visible-desktop, maybe.
  # - lib/term_util.sh
  run_and_unset "dubs_always_on_visible_desktop"

  # Re-bind Ctrl-B from same-as-left-arrow to delete-path-part.
  run_and_unset "dubs_hook_filename_rubout"

  #########################

  # Setup distro-agnostic Python and Apache wrappers, aliases, and environs.

  # - lib/python_util.sh
  run_and_unset "whats_python3"

  # - lib/python_util.sh
  run_and_unset "whats_python2"

  # - lib/apache_util.sh
  run_and_unset "whats_apache"

  #########################

  # - lib/fries_util.sh
  run_and_unset "home_fries_alias_crontab"

  #########################

  # - lib/fries_util.sh
  run_and_unset "home_fries_punch_anacron"

  #########################

  # - lib/apache_util.sh
  run_and_unset "apache_create_control_aliases"

  #########################

  # - lib/term_util.sh
  #run_and_unset "enable_vi_style_editing"
  unset -f enable_vi_style_editing

  #########################

  # - lib/fries_util.sh
  run_and_unset "home_fries_load_completions"

  #########################

  # - lib/keys_util.sh
  run_and_unset "home_fries_map_keys_lenovo"

  #########################

  # - lib/crypt_util.sh
  run_and_unset "home_fries_configure_gpg_tty"

  # - lib/crypt_util.sh
  run_and_unset "home_fries_mlocate_wire_private_db"

  #########################

  # - lib/hist_util.sh
  run_and_unset "home_fries_configure_history"

  #########################

  # MEH: The permissions on /proc/acpi/wakeup get reset every boot,
  #      so we need a new strategy for this to work.
  #      (NOTE/2018-01-29: Only affects Lenovo X201, I believe.)
  # - lib/session_util.sh
  #run_and_unset "disable_wakeup_on_lid"
  unset -f disable_wakeup_on_lid

  #########################

  # - lib/crypt_util.sh
  run_and_unset "daemonize_gpg_agent"

  #########################

  # 2018-09-27 13:41: !!!! PROFILING/DUBS_PROFILING:
  #   Elapsed: 0.34 min. / Action: home_fries_load_sdkman
  # Disabling until I know more! (Could be because no internet!)
  # - lib/fries_util.sh
  # run_and_unset "home_fries_load_sdkman"
  unset -f home_fries_load_sdkman

  # - lib/fries_util.sh
  run_and_unset "home_fries_load_nvm_and_completion"

  # - lib/fries_util.sh
  run_and_unset "home_fries_enable_fuzzy_finder_fzf"

  #########################

  # - lib/input_util.sh
  local time_0=$(date +%s.%N)
  logitech-middle-mouse-click-disable
  unset -f logitech-middle-mouse-click-disable
  print_elapsed_time "${time_0}" "disable middle mouse click"

  #########################

  # 2018-03-28: Trying direnv (to eventually replace/enhance gogo, perhaps).
  local time_0=$(date +%s.%N)
  # Sets, e.g., PROMPT_COMMAND=_direnv_hook;
  eval "$(direnv hook bash)"
  print_elapsed_time "${time_0}" "hooking direnv"

  #########################

  # Update mate-terminal titlebar on each command.
  # (lb): Note that all commands after this will appear/flicker
  # in the window title.
  run_and_unset "fries_hook_titlebar_update"
  # - lib/term_util.sh

  #########################

  print_elapsed_time \
    "${time_outer_0}" \
    "Setup actions (home_fries_up)." \
    "ACTIONS: "
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main () {
  local time_main_0=$(date +%s.%N)

  source_utils
  unset -f source_utils

  source_virtualenvwrapper
  unset -f source_virtualenvwrapper

  home_fries_up
  unset -f home_fries_up

  print_elapsed_time "${time_main_0}" "bashrc.core.sh" "+CORESH: "
}

main "$@"

