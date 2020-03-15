#!/bin/bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

check_deps () {
  # Verify logger.sh loaded.
  check_dep '_sh_logger_log_msg'
}

# ============================================================================
# *** Kick that ssh-agent.

ssh_agent_kick () {
  local old_level=${LOG_LEVEL}
  export LOG_LEVEL=${LOG_LEVEL_NOTICE}
  if [[ ${EUID} -ne 0 \
     && "dumb" != "${TERM}" \
     && -e "${HOME}/.ssh" ]]; then
    # See http://help.github.com/working-with-key-passphrases/
    SSH_ENV="${HOME}/.ssh/environment"
    function start_agent () {
      # echo -n "Initializing new SSH agent... "
      /usr/bin/ssh-agent | /bin/sed 's/^echo/#echo/' > "${SSH_ENV}"
      # echo "ok."
      chmod 600 "${SSH_ENV}"
      # Source the environ the new process spit out.
      . "${SSH_ENV}" > /dev/null
      # Look for keys to load. Use cheat PWDs as appropriate.
      local rsa_keys=$(/bin/ls ${HOME}/.ssh/*_ed25519 ${HOME}/.ssh/*_rsa 2> /dev/null)
      for pvt_key in ${rsa_keys}; do
        local sent_passphrase=false
        local secret_name=$(basename -- "${pvt_key}")
        if [[ -n "${SSH_SECRETS}" \
           && -d "${SSH_SECRETS}" \
           && -e "${SSH_SECRETS}/${secret_name}" ]]; then
          if [[ $(command -v expect > /dev/null && echo true) ]]; then
            # CUTE! If $pphrase has a bracket in it, e.g., "1234[", expect complains:
            #        "missing close-bracket while executing send "1234["
            local pphrase=$(cat ${SSH_SECRETS}/${secret_name})
            /usr/bin/expect -c " \
              spawn /usr/bin/ssh-add ${pvt_key}; \
              expect \"Enter passphrase for /home/${LOGNAME}/.ssh/${secret_name}:\"; \
              send \"${pphrase}\n\"; \
              interact ; \
            "
            unset -v pphrase
            sent_passphrase=true
          else
            notice "no expect: ignoring: ${SSH_SECRETS}/${pvt_key}"
          fi
        elif [[ ! -d "${SSH_SECRETS}" ]]; then
          if [[ -z ${SSH_SECRETS} ]]; then
            notice 'No SSH_SECRETS directory defined.'
          else
            notice "No directory at: ${SSH_SECRETS}"
          fi
          notice '        Set this up yourself.'
          notice '        To test again: ssh-agent -k'
          notice '          and then open a new terminal.'
        fi
        if ! ${sent_passphrase}; then
          /usr/bin/ssh-add "${pvt_key}"
        fi
      done
      # Test: ssh-agent -k # then, open a terminal (or call ssh_agent_kick).
    }

    # Source SSH settings, if applicable
    if [[ -f "${SSH_ENV}" ]]; then
      # Source SSH setings.
      . "${SSH_ENV}" > /dev/null
      # Look for existing ssh-agent.
      ps -ef | grep ${SSH_AGENT_PID} | grep ssh-agent$ > /dev/null || {
        start_agent
        # Set global variable telling caller if we called ssh-add.
        export SSH_ENV_FRESH=true
        # It's up to whatever code that cares to `unset SSH_ENV_FRESH`.
      }
    else
      start_agent
    fi
  fi
  export LOG_LEVEL=${old_level}
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main () {
  check_deps
  unset -f check_deps
}

main "$@"
unset -f main

