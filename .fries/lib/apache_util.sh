#!/bin/bash
# vim:tw=0:ts=2:sw=2:et:norl:

# File: apache_util.sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project Page: https://github.com/landonb/home-fries
# Summary: Generic Bash function library.
# License: GPLv3

# Usage: Source this script. Call its functions. Use its exports.

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

source_deps() {
  :
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

whats_apache () {
  # Determine the apache user.
  # 'TEVS: CAPITALIZE these, like most exports.
  if [[ -e /proc/version ]]; then
    if [[ "`cat /proc/version | grep Ubuntu`" ]]; then
      # echo Ubuntu!
      export httpd_user=www-data
      export httpd_etc_dir=/etc/apache2
    elif [[ "`cat /proc/version | grep Red\ Hat`" ]]; then
      # echo Red Hat!
      export httpd_user=apache
      export httpd_etc_dir=/etc/httpd
    else
      echo
      echo "ERROR: whats_apache: Unexpected OS; cannot set httpd_user/_etc_dir."
      echo
    fi
  else
    # If no /proc/version, then this is an unwired chroot jail.
    : # Meh.
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# Control and Kill Apache Processes.
apache_create_control_aliases() {
  # Restart Apache aliases.
  if [[ -e /proc/version ]]; then
    if [[ "`cat /proc/version | grep Ubuntu`" ]]; then
      alias re='\
        ${DUBS_TRACE} && echo "re" ; \
        sudo /etc/init.d/apache2 reload'
      alias res='\
        ${DUBS_TRACE} && echo "res" ; \
        sudo /etc/init.d/apache2 restart'
    elif [[ "`cat /proc/version | grep Red\ Hat`" ]]; then
      alias re='\
        ${DUBS_TRACE} && echo "re" ; \
        sudo service httpd reload'
      alias res='\
        ${DUBS_TRACE} && echo "res" ; \
        sudo service httpd restart'
    fi
  # else, in unrigged chroot.
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main() {
  : #source_deps
}

main "$@"
