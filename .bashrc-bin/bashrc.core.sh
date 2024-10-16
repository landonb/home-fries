# vim:tw=0:ts=2:sw=2:et:norl:ft=bash
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

export_homefries_envs () {
  DEBUG_TRACE=${DEBUG_TRACE:-false}
  # Usage, e.g.:
  #   HOMEFRIES_WARNINGS=true bash
  HOMEFRIES_WARNINGS=${HOMEFRIES_WARNINGS:-false}

  # Generally, HOMEFRIES_DIR="${HOME}/.kit/sh/home-fries"
  if [ -z "${HOMEFRIES_DIR}" ]; then
    HOMEFRIES_DIR="$(dirname -- "$(dirname -- "${BASH_SOURCE[0]}")")"
  fi
  if [ "${HOMEFRIES_DIR}" = '/' ] || [ ! -d "${HOMEFRIES_DIR}" ]; then
    >&2 echo 'WARNING: Where is home-fries installed? For real?'

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
  local deps_path="$2"
  local log_name="${3:-HFRIES}"
  # So that sourced files don't see any args.
  shift $#

  local time_0="$(print_nanos_now)"

  source_it_log_trace "${log_name}" "${lib_file}"

  # Report path if found on PATH
  local lib_path="$(type -p "${lib_file}")"

  if [ "${lib_file#/}" != "${lib_file}" ]; then
    # Caller sent explicit (full) path, so no guesswork needed.
    . "${lib_file}"
    let 'SOURCE_CNT += 1'
  elif [ -f "${lib_path}" ]; then
    # Prefer finding the script on PATH.
    . "${lib_path}"
    let 'SOURCE_CNT += 1'
  elif [ -f "${HOMEFRIES_DIR}/lib/${lib_file}" ]; then
    # Explicit check for before paths_util.sh is sourced, which at
    # some point during startup adds ~/.kit/sh/home-fries/lib to PATH (and
    # then the first condition of this if-block will start evaluating
    # truthy instead of this elif condition).
    . "${HOMEFRIES_DIR}/lib/${lib_file}"
    let 'SOURCE_CNT += 1'
  elif [ -f "${HOMEFRIES_DIR}/lib/utils/${lib_file}" ]; then
    # FIXME/2020-12-16: I'm entertaining idea of renaming-moving
    # lib/util_*.sh to lib/utils/homefries_*.sh. Add pre-access.
    . "${HOMEFRIES_DIR}/lib/utils/${lib_file}"
    let 'SOURCE_CNT += 1'
  elif true && \
    [ -n "${deps_path}" ] && \
    [ -f "${HOMEFRIES_DIR}/deps/${deps_path}/${lib_file}" ] \
  ; then
    . "${HOMEFRIES_DIR}/deps/${deps_path}/${lib_file}"
    let 'SOURCE_CNT += 1'
  else
    # No exceptions: Complain if file missing.
    # - Nothing here is optional.
    >&2 printf '\r%s\n' "MISSING: ${lib_file}"
    # Just in case something else calls this function... ???
    eval "${lib_file} () { \
      >&2 printf '\r%s\n' \"TRAPPED: '${lib_file}' '${deps_path}' '${log_name}'\"; \
    }"
  fi

  print_elapsed_time "${time_0}" "Source: ${lib_file}"
}

# E.g., for output like:
#   ──┬ Loading Homefries scripts
#     └┬ . HFRIES: logger.sh
#     ...
#      └ . HFRIES: user_util.sh
source_it_log_trace () {
  local log_name="$1"
  local lib_file="$2"

  ${HOMEFRIES_TRACE:-false} || return

  local piping
  if ! ${_SOURCE_IT_FINIS_OUTER:-false}; then
    if ${_SOURCE_IT_BEGIN:-false}; then
      if ! ${_SOURCE_IT_FINIS:-false}; then
        piping="├┬"
      else
        piping="├─"
      fi
    elif ! ${_SOURCE_IT_FINIS:-false}; then
      piping="│├"
    else
      piping="│└"
    fi
  else
    # The final outer group, so not leftside pipe.
    if ${_SOURCE_IT_BEGIN:-false}; then
      if ! ${_SOURCE_IT_FINIS:-false}; then
        piping="└┬"
      else
        piping="└─"
      fi
    elif ! ${_SOURCE_IT_FINIS:-false}; then
      piping=" ├"
    else
      piping=" └"
    fi
  fi

  echo "  ${piping} . ${log_name}: ${lib_file}"

  print_loading_dot
}

source_it () {
  source_from_user_path_or_homefries_lib "$@"
}

# CXREF: ~/.kit/sh/home-fries/lib/snips/check_dep.sh
export_homefries_check_dep () {
  . "${HOMEFRIES_DIR}/lib/snips/check_dep.sh"

  export -f check_dep
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

ensure_pathed () {
  local lib_file="$1"
  local deps_path="$2"
  local lib_path="$(type -p "${lib_file}")"
  if [ ! -f "${lib_path}" ]; then
    path_suffix "${HOMEFRIES_DIR}/deps/${deps_path}"
  fi
}

ensure_deps () {
  # User is welcome to install the dependencies and ensure
  # they're found on PATH. If not, we'll use copies we keep
  # in this repo.
  # HINT: If you want to make changes to Homefries and the
  # other projects, use hardlinks so you don't have to sync
  # files manually (though you may when Git committing).
  # - The author uses a private script at
  #     ~/.kit/sh/home-fries/.bashrc-bin/bashrx.private.user.sh
  #   to update PATH to includes these projects, which,
  #   is sourced before this script.
  #   - FIXME/2020-09-26: Add link to the DepoXy Ambers project.

  # Ensure sh-colors/bin/colors.sh on PATH.
  # - Project includes: colors.sh
  ensure_pathed 'colors.sh' 'sh-colors/bin'
  check_dep 'colors.sh'

  # Ensure sh-logger/bin/logger.sh on PATH.
  # - Project includes: logger.sh
  ensure_pathed 'logger.sh' 'sh-logger/bin'
  check_dep 'logger.sh'

  # Ensure sh-pather/bin/path* on PATH.
  # - Project includes: pather.sh, path_prefix, path_suffix
  ensure_pathed 'pather.sh' 'sh-pather/bin'
  check_dep 'pather.sh'

  # Ensure sh-rm_safe/bin/* on PATH.
  # - Project includes: path_device, rm_rotate, rm_safe, rmrm
  ensure_pathed 'rm_safe' 'sh-rm_safe/bin'
  check_dep 'rm_safe'
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# *** Doobious Sources

source_homefries_libs_all () {

  # *** Dependencies: Other Bash projects.

  # HINT: You can ensure these are on PATH before sourcing this
  #       file, or you can just not care and Homefries will load
  #       local copies of the dependencies.

  # USYNC: Set _SOURCE_IT_BEGIN for first source_homefries_libs_all source_it.
  _SOURCE_IT_BEGIN=true \
  source_it "logger.sh" "sh-logger/bin"

  # Ensure other dependencies are either on PATH, or update PATH to
  # include our local copies.
  ensure_deps
  unset -f ensure_deps
  unset -f ensure_pathed

  # *** Load these files first, which are local dependencies for
  #     scripts loaded later.

  source_it "process_util.sh"
  source_it "path_util.sh"
  # Setup PATH.
  source_it "paths_util.sh"

  source_it "distro_util.sh"

  source_it "alias/claim_alias_or_warn.sh"

  # *** External projects (revisited).

  # So that each `rmrm` command is stored in Bash history as `#rmrm`,
  # source the rmrm script (otherwise `history -s` has no effect).
  source_it "rmrm" "sh-rm_safe/bin"

  # *** Load order does not matter for the remaining files, which only
  #     depend on files previously loaded. So ordering alphabetically.

  source_alias_sources
  unset -f source_alias_sources

  source_crypt_sources
  unset -f source_crypt_sources

  source_date_sources
  unset -f source_date_sources

  source_device_sources
  unset -f source_device_sources

  source_distro_sources
  unset -f source_distro_sources

  source_funcs_sources
  unset -f source_funcs_sources

  source_term_sources
  unset -f source_term_sources

  source_utils_sources
  unset -f source_utils_sources
}

# ***

source_alias_sources () {
  source_it "alias/alias_ag.sh"
  source_it "alias/alias_bash.sh"
  source_it "alias/alias_cd_pushd_popd.sh"
  source_it "alias/alias_chmod.sh"
  source_it "alias/alias_clip.sh"
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
  source_it "alias/alias_pwd.sh"
  source_it "alias/alias_pwgen.sh"
  source_it "alias/alias_python.sh"
  source_it "alias/alias_rg_tag.sh"
  source_it "alias/alias_ruby.sh"
  source_it "alias/alias_sudo.sh"
  source_it "alias/alias_rm_rmtrash.sh"
  source_it "alias/alias_vim_gvim.sh"
  source_it "alias/whowherewhatami.sh"
}

# ***

source_crypt_sources () {
  source_it "crypt/daemonize_gpg_agent.sh"
  source_it "crypt/is_mount_type_crypt.sh"
  source_it "crypt/set_environ_gpg_tty.sh"
}

# ***

source_date_sources () {
  source_it "date/date-or-gdate.sh"
  # Order does sorta matter for uptime-s (it's used by at least (currently)
  # fcns. in fries_util.sh and session_util.sh), but this sourcing happens
  # before it's called.
  source_it "date/uptime-s.sh"
}

# ***

source_device_sources () {
  source_it "device/lsusb.sh"
}

# ***

source_distro_sources () {
  source_it "distro/default-browser.sh"
}

# ***

# 2020-12-16: My latest M.O.: Prefer adding new features as executables
# on PATH to ~/.kit/sh/home-fries/bin, or maybe to a new standalone repo
# (that installs (a symlink, usually) to ~/.local/bin). But not all
# features can be run from an executable script (i.e., in a subshell), but
# need to be called in the context of the user's environment instead. Which
# is what funcs/ is for. Idea here is one Bash function per file that's
# named the same as the file. Prefer this to tacking disparate features
# to an existing *_util.sh file, at the expense perhaps of slowing down
# Bashrc session startup (where more individual files seems to equate to
# a longer load time), but at the benefit of modularity and SRP, as well
# as self-documentation and transparency (of features without having to
# view file contents).

source_funcs_sources () {
  source_it "funcs/find-duplicates"
  source_it "funcs/please"
}

# ***

source_term_sources () {
  # 2021-02-20: Formerly "term_util.sh", now 7 scripts.
  source_it "term/disable-ctrl_s-stty-flow-controls.sh"
  source_it "term/equip-colorful-and-informative-ls.sh"
  source_it "term/macos-please-no-zsh-advertisement.sh"
  source_it "term/perhaps-always-on-visible-desktop.sh"
  source_it "term/readline-bind-ctrl-b-fname-rubout.sh"
  source_it "term/set-shell-prompt-and-window-title.sh"
  source_it "term/show-command-name-in-window-title.sh"
}

# ***

source_utils_sources () {
  # FIXME/2020-12-16: Relocate and Rename these files, like:
  #   source_it "utils/homefries_*.sh"
  # Or:
  #   source_it "utils/hf_*.sh"
  # Or, split each file apart into subdir., like term/*.sh

  source_it "ask_yes_no_default.sh"
  source_it "datetime_now_TTT.sh"
  source_it "dir_util.sh"
  # Earlier: "distro_util.sh"
  source_it "docker_util.sh"
  source_it "fffind_util.sh"
  source_it "file_util.sh"
  source_it "fries_util.sh"
  source_it "hist_util.sh"
  source_it "input_util.sh"
  source_it "keys_util.sh"
  source_it "manpath_util.sh"
  source_it "openshift_util.sh"
  # Earlier: "path_util.sh"
  # Earlier: "paths_util.sh"
  source_it "perl_util.sh"
  # Earlier: "process_util.sh"
  source_it "python_util.sh"
  source_it "ruby_util.sh"
  source_it "rust_util.sh"
  source_it "session_util.sh"
  # Earlier: "term/*.sh"
  source_it "time_util.sh"
  # USYNC: Set _SOURCE_IT_FINIS for final source_homefries_libs_all source_it.
  _SOURCE_IT_FINIS=true \
  source_it "user_util.sh"
  # Just some example Bash author might reference:
  #  source_it "snips/array_iterations.sh"
}

# ***

source_homefries_libs () {
  local time_outer_0="$(print_nanos_now)"
  SOURCE_CNT=0

  source_homefries_libs_all
  unset -f source_homefries_libs_all

  print_elapsed_time \
    "${time_outer_0}" \
    "Sourced ${SOURCE_CNT} files (source_homefries_libs)." \
    "SOURCES: "
  unset SOURCE_CNT
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

eval_and_unset () {
  local time_0="$(print_nanos_now)"

  # So that the func being sourced can use stdout
  # to have this shell set, e.g., array variables.
  eval $(eval "$@")
  unset -f "$1"

  print_elapsed_time "${time_0}" "Action: $1"
}

run_and_report () {
  local time_0="$(print_nanos_now)"

  print_loading_dot

  eval "$@"

  print_elapsed_time "${time_0}" "Action: $1"
}

run_and_unset () {
  run_and_report "$@"

  unset -f "$1"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

home_fries_up () {
  # TIMED/2024-06-25: This is taking a hot (literal) second to run.

  local time_outer_0="$(print_nanos_now)"

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
  #  run_and_unset "_hf_jit_configure_manpath"

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

  # - lib/session_util.sh
  run_and_unset "home_fries_configure_shell_options"

  # - lib/session_util.sh
  run_and_unset "home_fries_session_util_configure_aliases_bexit"
  run_and_unset "home_fries_session_util_configure_aliases_ps"
  # run_and_unset "home_fries_session_util_configure_aliases_fn"

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
  unset -f run_and_unset_home_fries_create_aliases

  #########################

  # Configure the terminal prompt and colors.

  # Set `PS1=` to customize the terminal prompt.
  # TIMED/2024-06-25: 0.05 secs. (per HOMEFRIES_PROFILING=true)
  # - Uses: lib/term/set-shell-prompt-and-window-title.sh
  # - Deps: lib/session_util.sh
  # - Don't run_and_unset: Let client reuse if they want.
  run_and_report "_hf_set_terminal_prompt"

  # Set PS4, for `set -x` and `set -v` debugging/tracing.
  # - lib/term/set-shell-prompt-and-window-title.sh
  run_and_unset "home_fries_set_PS4"

  # Fix the colors used by `ls -C` to be less annoying.
  # - lib/term/equip-colorful-and-informative-ls.sh
  run_and_unset "home_fries_fix_terminal_colors"

  # Make the current window always-on-visible-desktop, maybe.
  # - lib/perhaps-always-on-visible-desktop.sh
  run_and_unset "home_fries_always_on_visible_desktop"

  # Re-bind Ctrl-B from same-as-left-arrow to delete-path-part.
  # - lib/term/readline-bind-ctrl-b-fname-rubout.sh
  run_and_unset "home_fries_hook_filename_rubout"

  # Silence a macOS-specific logon alert.
  # - lib/term/macos-please-no-zsh-advertisement.sh
  run_and_unset "home_fries_macos_silence_bash_warning"

  #########################

  # Note this must be called after home_fries_set_path_environ,
  # so that pyenv's PATH prefix doesn't itself get prefixed.
  # - lib/python_util.sh

  # TIMED/2024-06-25: 0.10 secs. (per HOMEFRIES_PROFILING=true)
  run_and_unset "home_fries_setup_pyenv"

  run_and_unset "home_fries_setup_poetry"

  #########################

  # - lib/fries_util.sh
  run_and_unset "home_fries_alias_crontab"

  #########################

  # - lib/fries_util.sh
  run_and_unset "home_fries_punch_anacron"

  #########################

  # - lib/term/disable-ctrl_s-stty-flow-controls.sh
  run_and_unset "unhook_stty_ixon_ctrl_s_xon_xoff_flow_control"

  #########################

  # TIMED/2024-06-25: 0.08 secs. (per HOMEFRIES_PROFILING=true)
  # - lib/fries_util.sh
  run_and_unset "home_fries_load_completions"

  #########################

  # - lib/keys_util.sh
  run_and_unset "home_fries_map_keys_lenovo"

  #########################

  # - lib/crypt/set_environ_gpg_tty.sh
  run_and_unset "home_fries_configure_gpg_tty"

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

  #########################

  # - lib/input_util.sh
  local time_0="$(print_nanos_now)"
  logitech-middle-mouse-click-disable
  unset -f logitech-middle-mouse-click-disable
  print_elapsed_time "${time_0}" "Action: middle-mouse-click-disable"

  #########################

  # Update mate-terminal titlebar on each command.
  # (lb): Note that all commands after this will appear/flicker
  # in the window title.
  run_and_unset "_hf_hook_titlebar_update"
  # - lib/term/show-command-name-in-window-title.sh

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

  # - lib/alias/alias_chmod.sh
  run_and_unset "home_fries_aliases_wire_chmod"

  # - lib/alias/alias_clip.sh
  run_and_unset "home_fries_aliases_wire_clip"

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

  # - lib/alias/alias_pwd.sh
  run_and_unset "home_fries_aliases_wire_pwd"

  # - lib/alias/alias_pwgen.sh
  run_and_unset "home_fries_aliases_wire_pwgen"

  # - lib/alias/alias_python.sh
  run_and_unset "home_fries_aliases_wire_python"
  run_and_unset "home_fries_aliases_wire_poetry"

  # Set: `rm` => `rm_safe` [e.g., "remove" to ~/.trash]
  # - lib/alias/alias_rm_rmtrash.sh
  run_and_unset "home_fries_aliases_wire_rm_rmtrash"

  # Setup `rg` wrapper around `tag`, which will wire
  # `e*` commands for each search to view hits in Vim.
  # - lib/alias/alias_rg_tag.sh
  run_and_unset "home_fries_aliases_wire_rg_tag"

  # - lib/alias/alias_ruby.sh
  # Deprecated:
  #  run_and_unset "home_fries_aliases_wire_ruby"
  run_and_unset "home_fries_unset_f_alias_ruby"

  # - lib/alias/alias_sudo.sh
  run_and_unset "home_fries_aliases_wire_sudo"

  # - lib/alias/alias_vim_gvim.sh
  run_and_unset "home_fries_aliases_wire_vim_gvim"

  # - lib/alias/whowherewhatami.sh
  run_and_unset "home_fries_aliases_wire_amis"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

_hf_cleanup_core () {
  unset -f source_it
  unset -f source_from_user_path_or_homefries_lib
  unset -f source_it_log_trace

  unset -f eval_and_unset
  unset -f run_and_report
  unset -f run_and_unset

  # `run_and_report` calls
  unset -f _hf_set_terminal_prompt

  # From: lib/term/show-command-name-in-window-title.sh
  _hf_cleanup_lib_term_window_title_show_command_name
  unset -f _hf_cleanup_lib_term_window_title_show_command_name
}

_hf_bashrc_core () {
  local time_main_0="$(print_nanos_now)"

  source_homefries_libs
  unset -f source_homefries_libs

  home_fries_up
  unset -f home_fries_up

  print_elapsed_time "${time_main_0}" "bashrc.core.sh" "+CORESH: "

  unset -f _hf_bashrc_core
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

_hf_source_pre_preload_libs () {
  export_homefries_envs
  export_homefries_check_dep
  unset -f export_homefries_envs
  unset -f export_homefries_check_dep

  # Note that 'path_prefix' and 'path_suffix' are executable files, but
  # we source them into the environment, because just running a script
  # (in a subprocess) has no impact on the current environment's PATH.
  source_it "path_prefix" "sh-pather/bin"
  source_it "path_suffix" "sh-pather/bin"
}

# So that HOMEFRIES* environs, path_prefix, etc., available on
# HOME_FRIES_PRELOAD=true.
_hf_source_pre_preload_libs
unset -f _hf_source_pre_preload_libs

