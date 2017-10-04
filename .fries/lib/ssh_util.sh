#!/bin/bash
# Last Modified: 2017.10.03
# vim:tw=0:ts=2:sw=2:et:norl:

# File: ssh_util.sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project Page: https://github.com/landonb/home-fries
# Summary: Generic Bash function library.
# License: GPLv3

# Usage: Source this script. Call its functions. Use its exports.

# ============================================================================
# *** Kick that ssh-agent.

ssh_agent_kick () {
  if [[ $EUID -ne 0 \
     && "dumb" != "${TERM}" \
     && -e "$HOME/.ssh" ]]; then
    # See http://help.github.com/working-with-key-passphrases/
    SSH_ENV="$HOME/.ssh/environment"
    function start_agent() {
      #echo -n "Initializing new SSH agent... "
      /usr/bin/ssh-agent | sed 's/^echo/#echo/' > "${SSH_ENV}"
      #echo "ok."
      chmod 600 "${SSH_ENV}"
      . "${SSH_ENV}" > /dev/null
      # The default ssh-add behavior is to just load id_dsa and id_rsa.
      # But we don't want to use id_dsa, since RSA is better than DSA.
      # And we might have multiple keys we want to load. So load whatever
      # ends in _rsa.
      #  /usr/bin/ssh-add
      #  find $HOME/.ssh -name "*_[rd]sa" -maxdepth 1 ...
      # Weird. With Stdin, ssh-add opens a GUI window, rather than
      # asking for your passphrase on the command line.
      #  find $HOME/.ssh -name "*_rsa" -maxdepth 1 | xargs /usr/bin/ssh-add
      rsa_keys=`ls $HOME/.ssh/*_rsa 2> /dev/null`
      if [[ -n $rsa_keys ]]; then
        for pvt_key in $(/bin/ls $HOME/.ssh/*_rsa $HOME/.ssh/*_dsa 2> /dev/null); do
          sent_passphrase=false
          secret_name=$(basename -- "${pvt_key}")
          if [[    -n "$SSH_SECRETS" \
                && -d "$SSH_SECRETS" \
                && -e "$SSH_SECRETS/$secret_name" ]]; then
            if [[ $(command -v expect > /dev/null && echo true) ]]; then
              # CUTE! If your $pphrase has a bracket in it, e.g., "1234[", expect complains:
              #        "missing close-bracket while executing send "1234["
              pphrase=$(cat ${SSH_SECRETS}/${secret_name})
              /usr/bin/expect -c " \
              spawn /usr/bin/ssh-add ${pvt_key}; \
              expect \"Enter passphrase for /home/${USER}/.ssh/${secret_name}:\"; \
              send \"${pphrase}\n\"; \
              interact ; \
              "
              unset pphrase
              sent_passphrase=true
            else
              echo "NOTICE: no expect: ignoring: ${SSH_SECRETS}/${pvt_key}"
            fi
          elif [[ ! -d "$SSH_SECRETS" ]]; then
            if [[ -z $SSH_SECRETS ]]; then
              echo "NOTICE: No SSH_SECRETS directory defined."
            else
              echo "NOTICE: No directory at: $SSH_SECRETS"
            fi
            echo "        Set this up yourself."
            echo "        To test again: ssh-agent -k"
            echo "          and then open a new terminal."
          fi
          if ! ${sent_passphrase}; then
            /usr/bin/ssh-add $pvt_key
          fi
        done
      fi
      # Test: ssh-agent -k # then, open a terminal.
    }
    # Source SSH settings, if applicable
    if [[ -f "${SSH_ENV}" ]]; then
      . "${SSH_ENV}" > /dev/null
      #ps ${SSH_AGENT_PID} doesn't work under Cygwin.
      ps -ef | grep ${SSH_AGENT_PID} | grep ssh-agent$ > /dev/null || {
        start_agent;
      }
    else
      start_agent;
    fi
  fi
} # end: ssh_agent_kick

main() {
  :
}

main "$@"

