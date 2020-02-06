#!/bin/bash
# vim:tw=0:ts=2:sw=2:et:norl:
# Project: https://github.com/landonb/home-fries
# License: GPLv3

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

source_deps () {
  local curdir=$(dirname -- "${BASH_SOURCE[0]}")
  source ${curdir}/bash_base.sh
  source ${curdir}/process_util.sh
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# *** Ubuntu-related

distro_complain_not_ubuntu_or_red_hat () {
  if [[ -e /proc/version ]]; then
    if [[ "`cat /proc/version | grep Ubuntu`" ]]; then
      # echo Ubuntu!
      : # no-op
    elif [[ "`cat /proc/version | grep Red\ Hat`" ]]; then
      # echo Red Hat!
      : # noop
    else
      echo "WARNING: Unknown OS flavor ‘$(cat /proc/version)’"
      echo "Please comment out this gripe or update the file ‘$(basename -- "$0")’"
    fi
  else
    # /proc/version does not exist.
    # echo Chroot!
    : # nop
  fi
}

suss_distro () {
  # 2017-05-03: Disabling. Nothing uses any of these vars, AFAICT.
  if false; then
    # In the regex, \1 is the Fedora release, e.g., '14', and \2 is the friendly
    # name, e.g., 'Laughlin'.
    tweak_errexit
    FEDORAVERSABBR=$(cat /etc/issue \
                     | grep Fedora \
                     | /bin/sed 's/^Fedora release ([0-9]+) \((.*)\)$/\1/')
    # /etc/issue is, e.g., 'Ubuntu 12.04 LTS (precise) \n \l'
    UBUNTUVERSABBR=$(cat /etc/issue \
                     | grep Ubuntu \
                     | /bin/sed -E 's/^Ubuntu ([.0-9]+) [^(]*\((.*)\).*$/\1/')
    # /etc/issue is, e.g., 'Linux Mint 16 Petra \n \l'
    MINTVERSABBR=$(cat /etc/issue \
                   | grep "Linux Mint" \
                   | /bin/sed -E 's/^Linux Mint ([.0-9]+) .*$/\1/')
    reset_errexit
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# *** Window Manager Wat.

# NOTE: VirtualBox does not supply a graphics driver for Cinnamon 2.0,
#       which runs DRI2 (Direct Rendering Interface2). But Xfce runs
#       DRI1, which VirtualBox supports.
determine_window_manager () {
  WM_IS_CINNAMON=false
  WM_IS_XFCE=false
  WM_IS_MATE=false # Pronouced, mah-tay!
  WM_IS_UNKNOWN=false
  WM_TERMINAL_APP=''

  tweak_errexit
  WIN_MGR_INFO=`wmctrl -m >/dev/null 2>&1`
  if [[ $? -ne 0 ]]; then
    # E.g., if you're ssh'ed into a server, returns 1 and "Cannot open display."
    WM_IS_UNKNOWN=true
  fi
  reset_errexit

  if ! ${WM_IS_UNKNOWN}; then
    if [[ `wmctrl -m | grep -e "^Name: Mutter (Muffin)$"` ]]; then
      WM_IS_CINNAMON=true
      WM_TERMINAL_APP='gnome-terminal'
    elif [[ `wmctrl -m | grep -e "^Name: Xfwm4$"` ]]; then
      WM_IS_XFCE=true
      WM_TERMINAL_APP='WHO_CARES'
    elif [[ `wmctrl -m | grep -e "^Name: Metacity (Marco)$"` ]]; then
      # Linux Mint 17.1.
      WM_IS_MATE=true
      WM_TERMINAL_APP='mate-terminal'
    elif [[ `wmctrl -m | grep -e "^Name: Marco$"` ]]; then
      # Linux Mint 17.
      WM_IS_MATE=true
      WM_TERMINAL_APP='mate-terminal'
    else
      WM_IS_UNKNOWN=true
      echo
      echo "ERROR: Unknown Window manager."
      exit 1
    fi
  fi
  #echo "WM_IS_CINNAMON: $WM_IS_CINNAMON"
  #echo "WM_IS_XFCE: $WM_IS_XFCE"
  #echo "WM_IS_MATE: $WM_IS_MATE"
  #echo "WM_IS_UNKNOWN: $WM_IS_UNKNOWN"
  #echo "WM_TERMINAL_APP: $WM_TERMINAL_APP"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# *** Screen saver on/off

screensaver_lockoff () {
  determine_window_manager
  if ${WM_IS_MATE}; then
    # Disable screen saver and lock-out.
    #  gsettings doesn't seem to stick 'til now.
    #?: sudo gsettings set org.mate.screensaver lock-enabled false
    # Or did it just require an apt-get update to finally work?
    gsettings set org.mate.screensaver idle-activation-enabled false
    gsettings set org.mate.screensaver lock-enabled false
    # 2018-03-01: Still not quite working... missing sleep-display-ac?
    #   gsettings list-recursively | grep sleep
    #   gsettings list-recursively | grep idle
    gsettings set org.mate.power-manager sleep-display-ac 0
    # 2018-03-02: Bah. Try 10-folding the idle-delay.
    # Huh: 2 hours is the max. So 130 gets floored to 120.
    gsettings set org.mate.session idle-delay 130
  elif ${WM_IS_CINNAMON}; then
    tweak_errexit +eEx
    gsettings set org.cinnamon.desktop.screensaver lock-enabled false \
      &> /dev/null
    reset_errexit
  fi
}

screensaver_lockon () {
  determine_window_manager
  if ${WM_IS_MATE}; then
    gsettings set org.mate.screensaver idle-activation-enabled true
    gsettings set org.mate.screensaver lock-enabled true
    # 2018-03-01: 30 minutes, sleep display.
    gsettings set org.mate.power-manager sleep-display-ac 1800
  elif ${WM_IS_CINNAMON}; then
    tweak_errexit +eEx
    gsettings set org.cinnamon.desktop.screensaver lock-enabled true \
      &> /dev/null
    reset_errexit
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# *** Apache-related

suss_apache () {
  # Determine the name of the apache user.
  if [[ "`cat /proc/version | grep Ubuntu`" ]]; then
    # echo Ubuntu.
    httpd_user=www-data
    httpd_etc_dir=/etc/apache2
  elif [[ "`cat /proc/version | grep Red\ Hat`" ]]; then
    # echo Red Hat.
    httpd_user=apache
    httpd_etc_dir=/etc/httpd
  else
    echo "Error: Unknown OS."
    exit 1
  fi
}

# Reload the Web server.
ccp_apache_reload () {
  ${DUBS_TRACE} && echo "ccp_apache_reload"
  if [[ -z "$1" ]]; then
    COMMAND="reload"
  elif [[ $1 -ne 1 ]]; then
    COMMAND="reload"
  else
    COMMAND="restart"
  fi
  if [[ "`cat /proc/version | grep Ubuntu`" ]]; then
    # echo Ubuntu.
    sudo /etc/init.d/apache2 $COMMAND
  elif [[ "`cat /proc/version | grep Red\ Hat`" ]]; then
    # echo Red Hat.
    sudo service httpd $COMMAND
  else
    echo "Error: Unknown OS."
    exit 1
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# *** Python-related

# Determine the Python version-path.
suss_python () {
  # NOTE: The |& redirects the python output (which goes to stderr) to stdout.

  # FIXME: Delete this and use the parsing version below.
  #
  ## FIXME: Is this flexible enough? Probably...
  ## 2012.08.21: Ubuntu 8.04 does not support the |& redirection syntax?
  #if [[ -n "`cat /etc/issue | grep '^Ubuntu 8.04'`" ]]; then
  #  PYTHONVERS2=python2.5
  #  PYVERSABBR2=py2.5
  #elif [[ -n "`python --version |& grep 'Python 2.7'`" ]]; then
  #  PYTHONVERS2=python2.7
  #  PYVERSABBR2=py2.7
  #elif [[ -n "`python --version |& grep 'Python 2.6'`" ]]; then
  #  PYTHONVERS2=python2.6
  #  PYVERSABBR2=py2.6
  #else
  #  echo
  #  echo "Unexpected Python version."
  #  exit 1
  #fi

  # Here's another way:
  #if [[ "`cat /proc/version | grep Ubuntu`" ]]; then
  #  if [[ -n "`cat /etc/issue | grep '^Ubuntu 11.04'`" ]]; then
  #    PYTHONVERS2=python2.7
  #    PYVERSABBR2=py2.7
  #  elif [[ -n "`cat /etc/issue | grep '^Ubuntu 10.04'`" ]]; then
  #    PYTHONVERS2=python2.6
  #    PYVERSABBR2=py2.6
  #  else
  #    echo "Warning: Unexpected host OS: Cannot set PYTHONPATH."
  #  fi
  #elif [[ "`cat /proc/version | grep Red\ Hat`" ]]; then
  #  PYTHONVERS2=python2.7
  #fi

  # Convert, e.g., 'Python 2.7.6' to '2.7'.
  PYVERS_RAW2=`python2 --version \
    |& /usr/bin/awk '{print $2}' \
    | /bin/sed -E 's/^([0-9]+\.[0-9]+)\.[0-9]+/\1/g'`
  PYVERS2_DOTLESS=`python2 --version \
    |& /usr/bin/awk '{print $2}' \
    | /bin/sed -E 's/^([0-9]+)\.([0-9]+)\.[0-9]+/\1\2/g'`
  if [[ -z $PYVERS_RAW2 ]]; then
    echo
    echo "######################################################################"
    echo
    echo "WARNING: Unexpected: Could not parse Python2 version."
    echo
    echo "######################################################################"
    echo
    exit 1
  fi
  PYVERS_RAW2=python${PYVERS_RAW2}
  PYVERS_RAW2_m=python${PYVERS_RAW2}m
  PYVERS_CYTHON2=${PYVERS2_DOTLESS}m
  #
  PYTHONVERS2=python${PYVERS_RAW2}
  PYVERSABBR2=py${PYVERS_RAW2}
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# *** Postgres-related

suss_postgres () {
  # Set this to, e.g., '8.4' or '9.1'.
  #
  # Note that if you alias sed, e.g., sed='sed -r', then you'll get an error if
  # you source this script from the command line (e.g., it expands to sed -r -r).
  # So use /bin/sed to avoid any alias.
  tweak_errexit
  if [[ `command -v psql` ]]; then
    POSTGRESABBR=$( \
      psql --version \
      | grep psql \
      | /bin/sed -E 's/psql \(PostgreSQL\) ([0-9]+\.[0-9]+)\.[0-9]+/\1/')
    POSTGRES_MAJOR=$( \
      psql --version \
      | grep psql \
      | /bin/sed -E 's/psql \(PostgreSQL\) ([0-9]+)\.[0-9]+\.[0-9]+/\1/')
    POSTGRES_MINOR=$( \
      psql --version \
      | grep psql \
      | /bin/sed -E 's/psql \(PostgreSQL\) [0-9]+\.([0-9]+)\.[0-9]+/\1/')
  fi # else, psql not installed (yet).
  reset_errexit
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

unset_f_distro_util () {
  unset -f source_deps

  unset -f distro_complain_not_ubuntu_or_red_hat
  unset -f suss_distro

  unset -f suss_apache
  unset -f ccp_apache_reload

  unset -f suss_python

  unset -f suss_postgres

  # So meta.
  unset -f unset_f_distro_util
}

main () {
  source_deps
  unset -f source_deps

  suss_distro
  unset -f suss_distro

  # FIXME/2017-10-03: Find-n-Replace: determine_window_manager => suss_window_manager
  determine_window_manager

  suss_apache
  unset -f suss_apache

  #ccp_apache_reload
  unset -f ccp_apache_reload

  suss_python
  unset -f suss_python

  suss_postgres
  unset -f suss_postgres
}

main "$@"
unset -f main

