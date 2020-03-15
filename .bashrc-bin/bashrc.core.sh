# File: bashrc.core.sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries
# Summary: One Developer's Bash Profile [Home-🍟]
# License: MIT
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

export_homefries_envs () {
  DEBUG_TRACE=${DEBUG_TRACE:-false}
  # Usage, e.g.:
  #   HOMEFRIES_WARNINGS=true bash
  HOMEFRIES_WARNINGS=${HOMEFRIES_WARNINGS:-false}

  # Generally, FRIES_DIR=${HOME}/.homefries [a/k/a /home/${LOGNAME}/.homefries]
  if [ -z "${HOMEFRIES_DIR}" ]; then
    HOMEFRIES_DIR="$(dirname $(dirname -- "${BASH_SOURCE[0]}"))"
  fi
  if [ "${HOMEFRIES_DIR}" = '/' ] || [ ! -d "${HOMEFRIES_DIR}" ]; then
    >&2 echo 'WARNING: Where is .homefries installed? For real?'
    return 0
  fi
  export HOMEFRIES_DIR
  export HOMEFRIES_BIN="${HOMEFRIES_BIN:-${HOMEFRIES_DIR}/bin}"
  export HOMEFRIES_LIB="${HOMEFRIES_LIB:-${HOMEFRIES_DIR}/lib}"
  export HOMEFRIES_VAR="${HOMEFRIES_VAR:-${HOMEFRIES_DIR}/var}"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

source_from_user_path_or_homefries_lib () {
  local lib_file="$1"
  local time_0=$(date +%s.%N)
  ${DUBS_TRACE} && echo ". FRIES: ${lib_file}"
  if command -v "${lib_file}" > /dev/null; then
    # Prefer finding the script on PATH.
    . "${lib_file}"
    let 'SOURCE_CNT += 1'
  elif [ -f "${HOMEFRIES_DIR}/lib/${lib_file}" ]; then
    # Rather than put ~/.homefries/lib on PATH, this.
    . "${HOMEFRIES_DIR}/lib/${lib_file}"
    let 'SOURCE_CNT += 1'
  else
    # No exceptions: Complain if file missing.
    # - Nothing here is optional.
    >&2 echo "MISSING: ${lib_file}"
  fi
  print_elapsed_time "${time_0}" "Source: ${lib_file}"
}

source_it () {
  source_from_user_path_or_homefries_lib "$@"
}

# For sourced files to ensure things setup as expected, too.
check_dep () {
  ! command -v $1 &> /dev/null &&
    >&2 echo "WARNING: Missing dependency: ‘$1’"
}

check_deps () {
  # Onus is on user to figure out how to wire these!
  # - The author uses a ~/.homefries/.bashrc-bin/bashrx.private.user.sh script
  #   to put these on PATH.
  # Verify sh-colorlib/bin/colorlib.sh loaded.
  check_dep '_hofr_no_color'
  # Verify sh-logger/bin/logger.sh loaded.
  check_dep '_sh_logger_log_msg'
  # Verify sh-pathlib/bin/path* loaded.
  check_dep 'path_prefix'
  check_dep 'path_suffix'
}

# *** Doobious Sources

source_utils_all () {
  check_deps

  # *** External projects (you've loaded via private Bash).

  # sh-colorlib/bin/colorlib.sh
  # source_it "colorlib.sh"
  # source_it "test_colorlib"

  # sh-logger/bin/logger.sh
  # source_it "logger.sh"

  # sh-pathlib/bin/*
  # source_it "pathlib.sh"
  # source_it "path_prefix"
  # source_it "path_suffix"

  # sh-rm_safe/bin/*
  # source_it "path_device"
  # source_it "rm_rotate"
  # source_it "rm_safe"
  # source_it "rmrm"

  # *** Load order matters, to limit number of `.` invocations.

  source_it "process_util.sh"
  source_it "path_util.sh"

  source_it "distro_util.sh"

  source_it "term_util.sh"

  # *** Load order does not matter (remaining files only depend
  #     on those previously loaded); so alphabetical.

  source_it "alias_util.sh"
  source_it "apache_util.sh"
  source_it "array_util.sh"
  source_it "color_term.sh"
  source_it "crypt_util.sh"
  source_it "date_util.sh"
  source_it "dir_util.sh"
  # Earlier: "distro_util.sh"
  source_it "docker_util.sh"
  source_it "fffind_util.sh"
  source_it "file_util.sh"
  source_it "fries_util.sh"
  source_it "git_util.sh"
  source_it "hist_util.sh"
  source_it "input_util.sh"
  source_it "interact_util.sh"
  source_it "keys_util.sh"
  source_it "manpath_util.sh"
  source_it "openshift_util.sh"
  # Earlier: "path_util.sh"
  source_it "paths_util.sh"
  # Earlier: "process_util.sh"
  source_it "python_util.sh"
  source_it "ruby_util.sh"
  source_it "session_util.sh"
  source_it "ssh_util.sh"
  # Loaded specially: "term-fzf.bash"
  # Earlier: "term_util.sh"
  source_it "time_util.sh"
  source_it "trash_util.sh"
}

# ***

source_utils () {
  local time_outer_0=$(date +%s.%N)
  SOURCE_CNT=0

  source_utils_all

  print_elapsed_time \
    "${time_outer_0}" \
    "Sourced ${SOURCE_CNT} files (source_utils)." \
    "SOURCES: "
  unset SOURCE_CNT
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

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
  PATH="$(echo "${PATH//:/$'\n'}" | grep -v -e "^${HOME}/.virtualenvs/" | tr '\n' ':')"
  export PATH

  if [ -f "${HOME}/.local/bin/virtualenvwrapper.sh" ]; then
    . "${HOME}/.local/bin/virtualenvwrapper.sh"
  elif [ -f /usr/local/bin/virtualenvwrapper.sh ]; then
    . /usr/local/bin/virtualenvwrapper.sh
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

  # - lib/ssh_util.sh
  ssh_agent_kick

  #########################

  # Configure Bash session aliases.

  # Set: `ll` => `ls -ls`, etc.
  # - lib/alias_util.sh
  run_and_unset "home_fries_create_aliases_general"

  # - lib/alias_util.sh
  run_and_unset "home_fries_create_aliases_ohmyrepos"

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

  # Configure the terminal prompt and colors.

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
  # - lib/term_util.sh
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

  export_homefries_envs
  unset -f export_homefries_envs

  source_utils
  unset -f source_utils_all
  unset -f source_it
  unset -f source_from_user_path_or_homefries_lib
  unset -f source_utils

  source_virtualenvwrapper
  unset -f source_virtualenvwrapper

  home_fries_up
  unset -f home_fries_up

  print_elapsed_time "${time_main_0}" "bashrc.core.sh" "+CORESH: "
}

main "$@"

