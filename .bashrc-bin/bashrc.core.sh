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
  local time_0="$(home_fries_nanos_now)"
  ${HOMEFRIES_TRACE} && echo "   . FRIES: ${lib_file}"
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
  local cname="$1"
  local ahint="$2"
  if ! command -v "${cname}" > /dev/null 2>&1; then
    >&2 echo "WARNING: Missing dependency: ‘${cname}’"
    [ -n "${ahint}" ] && >&2 echo "${ahint}"
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

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

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
  # Ensure these are sourced so that the function is executed,
  # and not the script, because running a script (a subprocess)
  # cannot change the current environment's PATH.
  source_it "path_prefix"
  source_it "path_suffix"

  # sh-rm_safe/bin/*
  #  source_it "path_device"
  #  source_it "rm_rotate"
  #  source_it "rm_safe"
  #  source_it "rmrm"  # See later: We do source this.

  # *** Load order matters, to limit number of `.` invocations.

  source_it "process_util.sh"
  source_it "path_util.sh"
  # Setup PATH.
  source_it "paths_util.sh"

  source_it "distro_util.sh"

  # Ensure term_util.sh does not short-circuit return, as it does
  # to skip reloading if already loaded -- expect here, on the first
  # time through, we ensure that the latest term_util is always sourced.
  export _LOADED_HF_TERM_UTIL=false
  source_it "term_util.sh"

  # *** External projects (revisited).

  # So that each `rmrm` command is stored in Bash history as `#rmrm`,
  # source the rmrm script (otherwise `history -s` has no effect).
  source_it "rmrm"

  # *** Load order does not matter (remaining files only depend
  #     on those previously loaded); so alphabetical.

  source_alias_sources

  source_crypt_sources

  source_it "datetime_now_TTT.sh"
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
  source_it "perl_util.sh"
  # Earlier: "process_util.sh"
  source_it "python_util.sh"
  source_it "ruby_util.sh"
  source_it "session_util.sh"
  source_it "ssh_util.sh"
  # Loaded specially: "term-fzf.bash"
  # Earlier: "term_util.sh"
  source_it "time_util.sh"
  source_it "virtualenvwrapperer.sh"
  # Just some example Bash author might reference:
  #  source_it "show-n-tell/array_iterations.sh"
}

# ***

source_alias_sources () {
  source_it "alias/alias_ag.sh"
  source_it "alias/alias_bash.sh"
  source_it "alias/alias_cd_pushd_popd.sh"
  source_it "alias/alias_completion.sh"
  source_it "alias/alias_cp.sh"
  source_it "alias/alias_df.sh"
  source_it "alias/alias_diff.sh"
  source_it "alias/alias_du.sh"
  source_it "alias/alias_fd.sh"
  source_it "alias/alias_find.sh"
  source_it "alias/alias_free.sh"
  source_it "alias/alias_gimp.sh"
  source_it "alias/alias_git.sh"
  source_it "alias/alias_grep_egrep.sh"
  source_it "alias/alias_hash_type_command.sh"
  source_it "alias/alias_history.sh"
  source_it "alias/alias_htop.sh"
  source_it "alias/alias_less.sh"
  source_it "alias/alias_ls.sh"
  source_it "alias/alias_mv.sh"
  source_it "alias/alias_netstat.sh"
  source_it "alias/alias_ohmyrepos.sh"
  source_it "alias/alias_pwd.sh"
  source_it "alias/alias_pwgen.sh"
  source_it "alias/alias_python.sh"
  source_it "alias/alias_rg_tag.sh"
  source_it "alias/alias_ruby.sh"
  source_it "alias/alias_sudo.sh"
  source_it "alias/alias_rm_rmtrash.sh"
  source_it "alias/alias_tmux_reset.sh"
  source_it "alias/alias_vim_gvim.sh"
  source_it "alias/whowherewhatami.sh"
}

# ***

source_crypt_sources () {
  source_it "crypt/add_user_mlocate_db.sh"
  source_it "crypt/daemonize_gpg_agent.sh"
  source_it "crypt/is_mount_type_crypt.sh"
  source_it "crypt/set_environ_gpg_tty.sh"
}

# ***

source_utils () {
  local time_outer_0="$(home_fries_nanos_now)"
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
  local time_0="$(home_fries_nanos_now)"

  # So that the func being sourced can use stdout
  # to have this shell set, e.g., array variables.
  eval $(eval "$@")
  unset -f "$1"

  print_elapsed_time "${time_0}" "Action: $1"
}

run_and_unset () {
  local time_0="$(home_fries_nanos_now)"

  print_loading_dot

  eval "$@"
  unset -f "$1"

  print_elapsed_time "${time_0}" "Action: $1"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

home_fries_up () {
  local time_outer_0="$(home_fries_nanos_now)"

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
  # 2020-03-19: Lazy-load MANPATH when user first runs `man` in a session. #profiling
  # - Takes ~0.14 secs otherwise!
  #  run_and_unset "home_fries_configure_manpath"

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

  # NOTE: No longer calling ssh-agent-kick.
  # - YOU: Call from private dotfiles or crypt-mount script, etc.
  #   - (lb): E.g., I only need to call on one of my machines, after I
  #     logon and run a crypt-mount script that brings ~/.ssh online.
  #  ${HOMEFRIES_BIN}/ssh-agent-kick

  #########################

  # Configure Bash session aliases.

  # - lib/alias/*.sh
  run_and_unset_home_fries_create_aliases

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

  # Silence a macOS-specific logon alert.
  # - lib/term_util.sh
  run_and_unset "dubs_macos_silence_bash_warning"

  # Add a clear (reset) on macOS that clears (scrollback) buffer.
  # - lib/term_util.sh
  run_and_unset "dubs_macos_alias_clear_really_clear"

  #########################

  # Setup distro-agnostic Python and Apache wrappers, aliases, and environs.

  # - lib/python_util.sh
  run_and_unset "whats_python3"

  # - lib/python_util.sh
  run_and_unset "whats_python2"

  #########################

  # - lib/fries_util.sh
  run_and_unset "home_fries_alias_crontab"

  #########################

  # - lib/fries_util.sh
  run_and_unset "home_fries_punch_anacron"

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

  # - lib/crypt/set_environ_gpg_tty.sh
  run_and_unset "home_fries_configure_gpg_tty"

  # - lib/crypt/add_user_mlocate_db.sh
  run_and_unset "home_fries_mlocate_wire_private_db"

  #########################

  # - lib/hist_util.sh
  run_and_unset "home_fries_configure_history"

  #########################

  # MEH: The permissions on /proc/acpi/wakeup get reset every boot,
  #      so we need a new strategy for this to work.
  #      (NOTE/2018-01-29: Only affects Lenovo X201, I believe.)
  # - lib/session_util.sh
  #  run_and_unset "disable_wakeup_on_lid"
  unset -f disable_wakeup_on_lid

  #########################

  # - lib/crypt/daemonize_gpg_agent.sh
  run_and_unset "daemonize_gpg_agent"

  #########################

  # 2018-09-27 13:41: !!!! PROFILING/HOMEFRIES_PROFILING:
  #   Elapsed: 0.34 min. / Action: home_fries_load_sdkman
  # Disabling until I know more! (Could be because no internet!)
  # - lib/fries_util.sh
  #  run_and_unset "home_fries_load_sdkman"
  unset -f home_fries_load_sdkman

  # - lib/fries_util.sh
  # 2020-03-19: Shave ~0.09 secs. from session standup and lazy-load `nvm`
  #             et al when user first runs `nvm` in a session. #profiling
  #  run_and_unset "home_fries_load_nvm_and_completion"

  # - lib/fries_util.sh
  run_and_unset "home_fries_enable_fuzzy_finder_fzf"

  #########################

  # - lib/input_util.sh
  local time_0="$(home_fries_nanos_now)"
  logitech-middle-mouse-click-disable
  unset -f logitech-middle-mouse-click-disable
  print_elapsed_time "${time_0}" "Action: middle-mouse-click-disable"

  #########################

  # 2018-03-28: Trying direnv (to eventually replace/enhance gogo, perhaps).
  if command -v direnv > /dev/null; then
    local time_0="$(home_fries_nanos_now)"
    # Sets, e.g., PROMPT_COMMAND=_direnv_hook;
    eval "$(direnv hook bash)"
    print_elapsed_time "${time_0}" "hooking direnv"
  fi

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

run_and_unset_home_fries_create_aliases () {

  # Set: `ag` => `ag --smart-case --hidden`, etc.
  # - lib/alias/alias_ag.sh
  run_and_unset "home_fries_aliases_wire_ag"

  # - lib/alias/alias_bash.sh
  run_and_unset "home_fries_aliases_wire_bash"

  # Set: `cdd` => pushd wrapper; `cdc` => popd; `cddc` => toggle cd last
  # - lib/alias/alias_cd_pushd_popd.sh
  run_and_unset "home_fries_aliases_wire_cd_pushd_popd"

  # - lib/alias/alias_completion.sh
  run_and_unset "home_fries_aliases_wire_completion"

  # - lib/alias/alias_cp.sh
  run_and_unset "home_fries_aliases_wire_cp"

  # - lib/alias/alias_diff.sh
  run_and_unset "home_fries_aliases_wire_diff"

  # - lib/alias/alias_df.sh
  run_and_unset "home_fries_aliases_wire_df"

  # - lib/alias/alias_du.sh
  run_and_unset "home_fries_aliases_wire_du"

  # - lib/alias/alias_fd.sh
  run_and_unset "home_fries_aliases_wire_fd"

  # - lib/alias/alias_find.sh
  run_and_unset "home_fries_aliases_wire_find"

  # - lib/alias/alias_free.sh
  run_and_unset "home_fries_aliases_wire_free"

  # - lib/alias/alias_gimp.sh
  run_and_unset "home_fries_aliases_wire_gimp"

  # - lib/alias/alias_git.sh
  run_and_unset "home_fries_aliases_wire_git"

  # Set: `grep` => `grep --color`, etc.
  # - lib/alias/alias_grep_egrep.sh
  run_and_unset "home_fries_aliases_wire_grep_egrep"

  # - lib/alias/alias_hash_type_command.sh
  run_and_unset "home_fries_aliases_wire_hash_type_command"

  # - lib/alias/alias_history.sh
  run_and_unset "home_fries_aliases_wire_history"

  # - lib/alias/alias_htop.sh
  run_and_unset "home_fries_aliases_wire_htop"

  # - lib/alias/alias_less.sh
  run_and_unset "home_fries_aliases_wire_less"

  # - lib/alias/alias_ls.sh
  run_and_unset "home_fries_aliases_wire_ls"

  # - lib/alias/alias_mv.sh
  run_and_unset "home_fries_aliases_wire_mv"

  # - lib/alias/alias_netstat.sh
  run_and_unset "home_fries_aliases_wire_netstat"

  # - lib/alias/alias_ohmyrepos.sh
  run_and_unset "home_fries_aliases_wire_ohmyrepos"

  # - lib/alias/alias_pwd.sh
  run_and_unset "home_fries_aliases_wire_pwd"

  # - lib/alias/alias_pwgen.sh
  run_and_unset "home_fries_aliases_wire_pwgen"

  # - lib/alias/alias_python.sh
  run_and_unset "home_fries_aliases_wire_python"

  # Set: `rm` => `rm_safe` [e.g., "remove" to ~/.trash]
  # - lib/alias/alias_rm_rmtrash.sh
  run_and_unset "home_fries_aliases_wire_rm_rmtrash"

  # Setup `rg` wrapper around `tag`, which will wire
  # `e*` commands for each search to view hits in Vim.
  # - lib/alias/alias_rg_tag.sh
  run_and_unset "home_fries_aliases_wire_rg_tag"

  # - lib/alias/alias_ruby.sh
  #  run_and_unset "home_fries_aliases_wire_ruby"

  # - lib/alias/alias_sudo.sh
  run_and_unset "home_fries_aliases_wire_sudo"

  # - lib/alias/alias_tmux_reset.sh
  run_and_unset "home_fries_aliases_wire_tmux_reset"

  # - lib/alias/alias_vim_gvim.sh
  run_and_unset "home_fries_aliases_wire_vim_gvim"

  # - lib/alias/whowherewhatami.sh
  run_and_unset "home_fries_aliases_wire_amis"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main () {
  local time_main_0="$(home_fries_nanos_now)"

  export_homefries_envs
  unset -f export_homefries_envs

  source_utils
  unset -f source_utils_all
  unset -f source_it
  unset -f source_from_user_path_or_homefries_lib
  unset -f source_utils
  unset -v _LOADED_HF_TERM_UTIL

  home_fries_up
  unset -f home_fries_up

  print_elapsed_time "${time_main_0}" "bashrc.core.sh" "+CORESH: "
}

main "$@"

