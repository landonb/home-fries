# File: bashrc.core.sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Last Modified: 2017.12.17
# Project Page: https://github.com/landonb/home-fries
# Summary: One Developer's Bash Profile [Home-🍟]
# License: GPLv3
# vim:tw=0:ts=2:sw=2:et:norl:

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# *** Doobious Sources

source_utils() {
  # Generally, FRIES_DIR=${HOME}/.fries [a/k/a /home/${LOGNAME}/.fries]
  export HOMEFRIES_DIR=$(dirname $(dirname -- "${BASH_SOURCE[0]}"))
  if [[ ${HOMEFRIES_DIR} == '/' ]]; then
    echo 'WARNING: Where is .fries installed? For real?'
  fi

  declare -a lib_files=()

  unset HOMEFRIES_LOADED_BASH_BASE
  lib_files+=("alias_util.sh")
  lib_files+=("apache_util.sh")
  lib_files+=("array_util.sh")
  lib_files+=("bash_base.sh")
  lib_files+=("color_util.sh")
  lib_files+=("cron_util.sh")
  lib_files+=("crypt_util.sh")
  lib_files+=("curly_util.sh")
  #lib_files+=("cygwin_util.sh")
  lib_files+=("date_util.sh")
  lib_files+=("dir_util.sh")
  lib_files+=("distro_util.sh")
  lib_files+=("docker_util.sh")
  lib_files+=("file_util.sh")
  lib_files+=("fries_util.sh")
  lib_files+=("git_util.sh")
  lib_files+=("grep_util.sh")
  lib_files+=("hist_util.sh")
  lib_files+=("input_util.sh")
  lib_files+=("interact_util.sh")
  lib_files+=("keys_util.sh")
  #lib_files+=("logger.sh")
  lib_files+=("no_util.sh")
  lib_files+=("openshift_util.sh")
  lib_files+=("path_util.sh")
  lib_files+=("paths_util.sh")
  lib_files+=("process_util.sh")
  lib_files+=("python_util.sh")
  lib_files+=("ruby_util.sh")
  lib_files+=("session_util.sh")
  lib_files+=("ssh_util.sh")
  lib_files+=("term_util.sh")
  lib_files+=("time_util.sh")
  lib_files+=("trash_util.sh")
  # 2016-11-12: What about logger.sh?

  DEBUG_TRACE=false
  for lib_file in "${lib_files[@]}"; do
    if [[ -f "${HOMEFRIES_DIR}/lib/${lib_file}" ]]; then
      #echo "Loading: ${lib_file}"
      source "${HOMEFRIES_DIR}/lib/${lib_file}"
    #else
    #  echo "Not found: ${lib_file}"
    fi
  done

  if [[ -z ${HOMEFRIES_WARNINGS+x} ]]; then
    # Usage, e.g.:
    #   HOMEFRIES_WARNINGS=true bash
    HOMEFRIES_WARNINGS=false
  fi
}

source_addit() {
  # 2016-11-18: Wow. This has been here for years, commented out,
  # because I haven't use mkvirtualenv in oh so very, very long.
  # Welcome back, friend.
  if [[ -f /usr/local/bin/virtualenvwrapper.sh ]]; then
    source /usr/local/bin/virtualenvwrapper.sh
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

home_fries_up() {

  #########################

  # Determine OS Flavor

  # This script only recognizes Ubuntu and Red Hat distributions. It'll
  # otherwise complain (but it'll still work, it just won't set a few
  # flavor-specific options, like terminal colors and the prompt).
  # See also: `uname -a`, `cat /etc/issue`, `cat /etc/fedora-release`.

  distro_complain_not_ubuntu_or_red_hat
  unset distro_complain_not_ubuntu_or_red_hat

  #########################

  # Update PATH
  home_fries_set_path_environ
  unset home_fries_set_path_environ

  # Set umask to 0002
  home_fries_default_umask
  unset home_fries_default_umask

  #########################

  # Set EDITOR, default for git, cron, etc.
  home_fries_export_editor_vim
  unset home_fries_export_editor_vim

  #########################

  home_fries_append_ld_library_path
  unset home_fries_append_ld_library_path

  home_fries_alias_ld_library_path_cmds
  unset home_fries_alias_ld_library_path_cmds

  #########################

  # Tell psql to use less for large output
  home_fries_wire_export_less
  unset home_fries_wire_export_less

  #########################

  # Shell options
  home_fries_configure_shell_options
  unset home_fries_configure_shell_options

  #########################

  # Completion options

  home_fries_init_completions
  unset home_fries_init_completions

  home_fries_direxpand_completions
  unset home_fries_direxpand_completions

  #########################

  # SSH

  # NOTE: Not doing this for root.
  # 2012.12.22: Don't do this for cron, either, or cron sends
  #   Identity added: /home/.../.ssh/id_rsa (/home/.../.ssh/id_rsa)
  #   Identity added: /home/.../.ssh/identity (/home/.../.ssh/identity)

  # See: ~/.fries/lib/bash_base.sh
  ssh_agent_kick

  #########################

  # Configure Bash session aliases.

  # Set: `ll` => `ls -ls`, etc.
  home_fries_create_aliases_general
  unset home_fries_create_aliases_general

  # Set: `rg` => `rg --smart-case --hidden --colors ...`
  home_fries_create_aliases_greppers
  unset home_fries_create_aliases_greppers

  # Set: `cdd` => pushd wrapper; `cdc` => popd; `cddc` => toggle cd last
  home_fries_create_aliases_chdir
  unset home_fries_create_aliases_chdir

  # Set: 
  home_fries_create_aliases_tab_completion
  unset home_fries_create_aliases_tab_completion

  # Set: `rm` => `rm_safe` [e.g., "remove" to ~/.trash]
  home_fries_create_aliases_trash
  unset home_fries_create_aliases_trash

  #########################

  # Configure the terminal prompt and colors.

  # Set `PS1=` to customize the terminal prompt.
  dubs_set_terminal_prompt
  unset dubs_set_terminal_prompt

  # Set PS4, for `set -x` and `set -v` debugging/tracing.
  dubs_set_PS4
  unset dubs_set_PS4

  # Fix the colors used by `ls -C` to be less annoying.
  dubs_fix_terminal_colors
  unset dubs_fix_terminal_colors

  #########################

  # Setup distro-agnostic Python and Apache wrappers, aliases, and environs.

  whats_python3
  unset whats_python3

  whats_python2
  unset whats_python2

  whats_apache
  unset whats_apache

  #########################

  configure_crontab
  unset configure_crontab

  #########################

  apache_create_control_aliases
  unset apache_create_control_aliases

  #########################

  #enable_vi_style_editing
  unset enable_vi_style_editing

  #########################

  home_fries_load_completions
  unset home_fries_load_completions

  #########################

  home_fries_map_keys_lenovo
  unset home_fries_map_keys_lenovo

  #########################

  home_fries_configure_gpg_tty
  unset home_fries_configure_gpg_tty

  #########################

  home_fries_configure_history
  unset home_fries_configure_history

  #########################

  # MEH: The permissions on /proc/acpi/wakeup get reset every boot,
  #      so we need a new strategy for this to work.
  #      (NOTE/2018-01-29: Only affects Lenovo X201, I believe.)
  #disable_wakeup_on_lid
  unset disable_wakeup_on_lid

  #########################

  daemonize_gpg_agent
  unset daemonize_gpg_agent

  #########################

  home_fries_load_sdkman
  unset home_fries_load_sdkman

  home_fries_load_nvm_and_completion
  unset home_fries_load_nvm_and_completion

  #########################
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main() {
  source_utils
  unset source_utils

  source_addit
  unset source_addit

  home_fries_up
  unset home_fries_up
}

main "$@"

