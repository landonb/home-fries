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
  local deps_path="$2"
  local time_0="$(home_fries_nanos_now)"
  ${HOMEFRIES_TRACE} && echo "   . FRIES: ${lib_file}"
  print_loading_dot

  local lib_path="$(type -p "${lib_file}")"
  if [ -f "${lib_path}" ]; then
    # Prefer finding the script on PATH.
    . "${lib_path}"
    let 'SOURCE_CNT += 1'
  elif [ -f "${HOMEFRIES_DIR}/lib/${lib_file}" ]; then
    # Explicit check for before paths_util.sh is sourced, which at
    # some point during startup adds ~/.homefries/lib to PATH (and
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
    eval "${lib_file} () { >&2 printf '\r%s\n' \"TRAPPED: ${@}\"; }"
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
    >&2 printf '\r%s\n' "WARNING: Missing dependency: ‘${cname}’"
    [ -n "${ahint}" ] && >&2 echo "${ahint}"
    false
  else
    true
  fi
}
export -f check_dep

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
  #     ~/.homefries/.bashrc-bin/bashrx.private.user.sh
  #   to update PATH to includes these projects, which,
  #   is sourced before this script.
  #   - FIXME/2020-09-26: Add link to the Waffle Batter project.

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

  # Note that 'path_prefix' and 'path_suffix' are executable files, but
  # we source them into the environment, because just running a script
  # (in a subprocess) has no impact on the current environment's PATH.
  source_it "path_prefix" "sh-pather/bin"
  source_it "path_suffix" "sh-pather/bin"

  # Ensure other dependencies are either on PATH, or update PATH to
  # include our local copies.
  ensure_deps
  unset -f ensure_deps
  unset -f ensure_pathed

  # *** Load order matters, to limit number of `.` invocations.

  source_it "process_util.sh"
  source_it "path_util.sh"
  # Setup PATH.
  source_it "paths_util.sh"

  source_it "distro_util.sh"

  # *** External projects (revisited).

  # So that each `rmrm` command is stored in Bash history as `#rmrm`,
  # source the rmrm script (otherwise `history -s` has no effect).
  source_it "rmrm" "sh-rm_safe/bin"

  # *** Load order does not matter (remaining files only depend
  #     on those previously loaded); so alphabetical.

  source_alias_sources
  unset -f source_alias_sources

  source_crypt_sources
  unset -f source_crypt_sources

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

# 2020-12-16: My latest M.O.: Prefer adding new features as executables
# on PATH to ~/.homefries/bin, or maybe to a new standalone repo (that
# installs (a symlink, usually) to ~/.local/bin). But not all features
# can be run from an executable script (i.e., in a subshell), but need
# to be called in the context of the user's environment instead. Which
# is what funcs/ is for. Idea here is one Bash function per file that's
# named the same as the file. Prefer this to tacking disparate features
# to an existing *_util.sh file, at the expense perhaps of slowing down
# Bashrc session startup (where more individual files seems to equate to
# a longer load time), but at the benefit of modularity and SRP, as well
# as self-documentation and transparency (of features without having to
# view file contents).

source_funcs_sources () {
  source_it "funcs/aci"
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
  #
  #   source_it "utils/homefries_*.sh"

  source_it "datetime_now_TTT.sh"
  source_it "dir_util.sh"
  # Earlier: "distro_util.sh"
  source_it "docker_util.sh"
  source_it "fffind_util.sh"
  source_it "file_util.sh"
  source_it "fries_util.sh"
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
  source_it "ruby_util.sh"
  source_it "rust_util.sh"
  source_it "session_util.sh"
  source_it "ssh_util.sh"
  # Loaded specially: "term-fzf.bash"
  # Earlier: "term/*.sh"
  source_it "time_util.sh"
  source_it "virtualenvwrapperer.sh"
  # Just some example Bash author might reference:
  #  source_it "snips/array_iterations.sh"
}

# ***

source_homefries_libs () {
  local time_outer_0="$(home_fries_nanos_now)"
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
  unset -f run_and_unset_home_fries_create_aliases

  #########################

  # Configure the terminal prompt and colors.

  # Set `PS1=` to customize the terminal prompt.
  # - lib/term/set-shell-prompt-and-window-title.sh
  run_and_unset "dubs_set_terminal_prompt"

  # Set PS4, for `set -x` and `set -v` debugging/tracing.
  # - lib/term/set-shell-prompt-and-window-title.sh
  run_and_unset "dubs_set_PS4"

  # Fix the colors used by `ls -C` to be less annoying.
  # - lib/term/equip-colorful-and-informative-ls.sh
  run_and_unset "dubs_fix_terminal_colors"

  # Make the current window always-on-visible-desktop, maybe.
  # - lib/perhaps-always-on-visible-desktop.sh
  run_and_unset "dubs_always_on_visible_desktop"

  # Re-bind Ctrl-B from same-as-left-arrow to delete-path-part.
  # - lib/term/readline-bind-ctrl-b-fname-rubout.sh
  run_and_unset "dubs_hook_filename_rubout"

  # Silence a macOS-specific logon alert.
  # - lib/term/macos-please-no-zsh-advertisement.sh
  run_and_unset "dubs_macos_silence_bash_warning"

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
  run_and_unset "home_fries_enable_fuzzy_finder_fzf"

  #########################

  # - lib/input_util.sh
  local time_0="$(home_fries_nanos_now)"
  logitech-middle-mouse-click-disable
  unset -f logitech-middle-mouse-click-disable
  print_elapsed_time "${time_0}" "Action: middle-mouse-click-disable"

  #########################

  # 2018-03-28: Trying direnv (to eventually replace/enhance gogo, perhaps).
  # 2021-08-04: I can't remember the last time I used direnv.
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

  source_homefries_libs
  unset -f source_it
  unset -f source_from_user_path_or_homefries_lib
  unset -f source_homefries_libs

  home_fries_up
  unset -f home_fries_up
  unset -f eval_and_unset
  unset -f run_and_unset

  print_elapsed_time "${time_main_0}" "bashrc.core.sh" "+CORESH: "
}

main "$@"
unset -f main

