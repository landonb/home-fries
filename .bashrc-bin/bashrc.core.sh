# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

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
  ${HOMEFRIES_TRACE} && echo ". FRIES: ${lib_file}"
  print_loading_dot
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
  if ! command -v $1 > /dev/null 2>&1; then
    >&2 echo "WARNING: Missing dependency: ‘$1’"
    false
  else
    true
  fi
}
export -f check_dep

check_deps () {
  # Onus is on user to figure out how to wire these!
  # - The author uses a ~/.homefries/.bashrc-bin/bashrx.private.user.sh script
  #   to put these on PATH.
  # - Note that we're not checking that these have been sourced, just on PATH,
  #   so check for their filename, not for functions they export.
  # Verify sh-colors/bin/colors.sh loaded.
  #   check_dep '_hofr_no_color'
  check_dep 'colors.sh'
  # Verify sh-logger/bin/logger.sh loaded.
  #   check_dep '_sh_logger_log_msg'
  check_dep 'logger.sh'
  # Verify sh-pather/bin/path* loaded.
  #   check_dep '_sh_pather_path_part_remove'
  check_dep 'pather.sh'
  # Verify sh-rm_safe/bin/* loaded.
  #   check_dep '_sh_rm_safe_device_on_which_file_resides'
  check_dep 'rm_safe'
}

# *** Doobious Sources

source_utils_all () {
  check_deps

  # *** External projects (you've loaded via private Bash).

  # sh-colors/bin/colors.sh
  #  source_it "colors.sh"
  #  source_it "test_colors"

  # sh-logger/bin/logger.sh
  #  source_it "logger.sh"

  # sh-pather/bin/*
  #  source_it "pather.sh"
  #  source_it "path_prefix"
  #  source_it "path_suffix"

  # sh-rm_safe/bin/*
  #  source_it "path_device"
  #  source_it "rm_rotate"
  #  source_it "rm_safe"
  #  source_it "rmrm"

  # *** Load order matters, to limit number of `.` invocations.

  source_it "process_util.sh"
  source_it "path_util.sh"
  # Setup PATH.
  source_it "paths_util.sh"

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
  # Earlier: "paths_util.sh"
  # Earlier: "process_util.sh"
  source_it "python_util.sh"
  source_it "ruby_util.sh"
  source_it "session_util.sh"
  # Loaded specially: "term-fzf.bash"
  # Earlier: "term_util.sh"
  source_it "time_util.sh"
  source_it "trash_util.sh"
  source_it "venvwrap_wrap.sh"
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

  print_loading_dot

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

  # 2020-03-18: Is this really still necessary?
  # - Let's try... without.
  #   - Perhaps rely on private dotfiles to kick.
  #   - Another reason not to call on shell startup: The kick really only
  #     needs to happen on desktop logon, i.e., once after booting machine;
  #     and is not necessary for every shell.
  #  ${HOMEFRIES_BIN}/ssh-agent-kick

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

  # 2018-09-27 13:41: !!!! PROFILING/HOMEFRIES_PROFILING:
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
  print_elapsed_time "${time_0}" "Action: middle-mouse-click-disable"

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

  home_fries_up
  unset -f home_fries_up

  print_elapsed_time "${time_main_0}" "bashrc.core.sh" "+CORESH: "
}

main "$@"

