#!/bin/bash
#  vim:tw=0:ts=2:sw=2:et:norl:

# File: custom_setup.extras.sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Last Modified: 2017.10.03
# Project Page: https://github.com/landonb/home_fries
# Summary: Third-party tools downloads compiles installs.
# License: GPLv3

if [[ "$0" == "$BASH_SOURCE" ]]; then
  # 2016-11-12: Calling script. Die on error, so we can fix it.
  # set -e
  set -o errexit
  USING_ERREXIT=true
else
  # Sourcing script.
  set +o errexit
fi
function errexit_cleanup () {
  echo
  echo "ERROR: The script failed!!"
  # No exit necessary, unless we want to specify status.
  exit 1
}
trap errexit_cleanup EXIT

# set -v
#   Print shell input lines as they are read.
#set -o verbose
# set -x
#   After expanding each simple command, for command, case command, select
#   command, or arithmetic for command, display the expanded value of PS4,
#   followed by the command and its expanded arguments or associated word list.
#set -o xtrace

# DEVs: For you:
SKIP_APT_GET_UPDATE=false
#SKIP_APT_GET_UPDATE=true

# DEVs: Easy one-offs.
SKIP_EVERYTHING=false
#SKIP_EVERYTHING=true

PAUSE_BETWEEN_INSTALLS=false
# 2016-11-14: Leaving this enabled for now, since I don't run this script
# very often and the errexit setting is new; so best to nurse it, I guess.
PAUSE_BETWEEN_INSTALLS=true

# Whether or not to re-install already installed applications.
FORCE_REINSTALL=false
REINSTALL_OR_SKIP=$(${FORCE_REINSTALL} && echo "REINSTALLING" || echo "SKIPPING")

# DEVs: If you're copying and pasting manually, source this:
#
#   source ${HOME}/.fries/once/linux_setup_base.sh

if [[ ! -e ./linux_setup_base.sh ]]; then
  echo "Error: Expected to find ./linux_setup_base.sh."
  exit 1
fi
#DEBUG_TRACE=false
DEBUG_TRACE=true
source ./linux_setup_base.sh

source ./installers/_announcement.sh

# *** Don't Repeat Yourself.

if sudo -n true 2>/dev/null; then
  # Has sudo already.
  :
else
  #echo
  echo "LET'S GET THE PARTY STARTED"
  sudo -v
fi

# *** Ensure expected directories exist.

# FIXME/MEH: Instead of OPT_BIN, install to ~/.local/bin?
#            Or maybe not; then I might not be able to tell
#            what was pip installed vs. dubs installed.

stage_4_setup_ensure_dirs () {
  for dir_path in \
    ${OPT_DLOADS} \
    ${OPT_BIN} \
    ${OPT_SRC} \
    ${OPT_DOCS} \
    ${OPT_FONTS} \
    ${OPT_LARGE} \
  ; do
    #echo "dir_path: ${dir_path}"
    if [[ -z ${dir_path} ]]; then
      echo "ERROR: Missing OPT_* paths."
      exit 1
    fi
    /bin/mkdir -p ${dir_path}
  done
}
stage_4_setup_ensure_dirs

# *** Let the installations begin!

stage_4_dropbox_install () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_dropbox_install"

  pushd ${OPT_BIN} &> /dev/null

  if [[ -e ${OPT_BIN}/dropbox.py ]]; then
    set +e
    grep "^# This file is part of nautilus-dropbox 2015.10.28.$" ${OPT_BIN}/dropbox.py &> /dev/null
    exit_code=$?
    reset_errexit
    if [[ ${exit_code} -eq 0 ]]; then
      echo
      echo "${REINSTALL_OR_SKIP}: Already installed: dropbox.py"
      echo
      if ! ${FORCE_REINSTALL}; then
        return
      fi
    else
      DROPBOX_OLDER="${OPT_BIN}/dropbox.py-`date +%Y.%m.%d-%T`"
      /bin/mv ${OPT_BIN}/dropbox.py ${DROPBOX_OLDER}
      chmod -x ${DROPBOX_OLDER}
    fi
  fi

  wget -O ${OPT_BIN}/dropbox.py \
    "https://www.dropbox.com/download?dl=packages/dropbox.py"

  # Set the permissions so you can execute the CLI interface:
  chmod +x ${OPT_BIN}/dropbox.py

  # Avoid the warning: "Note: python-gpgme is not installed, we will not
  # be able to verify binary signatures."
  sudo apt-get install -y python-gpgme

  # Changing the shebang is unnecessary unless you remap /usr/bin/python.
  #
  #  sudo /bin/sed -i.bak \
  #    "s/^#!\/usr\/bin\/python$/#!\/usr\/bin\/python2/" \
  #    ${OPT_BIN}/dropbox.py

  # FIXME: Is this step missing?
  #        Install the daemon: dropbox.py start -i
  #        except you're prompted to agree to install proprietary daemon
  echo
  echo "NOTICE: To finish installing dropbox, run:"
  echo "          dropbox.py start -i"
# FIXME: Do we need a startup script to ensure dropbox runs on boot?
  echo "          dropbox.py autostart y"
  echo

  mkdir -p $HOME/.config/autostart

  echo "[Desktop Entry]
Type=Application
Exec=${OPT_BIN}/dropbox.py start
Hidden=false
X-MATE-Autostart-enabled=true
Name[en_US]=Dropbox
Name=Dropbox
Comment[en_US]=
Comment=
" > $HOME/.config/autostart/dropbox.desktop

  popd &> /dev/null

} # end: stage_4_dropbox_install

stage_4_meld_configure () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "Skipping: stage_4_meld_configure"

  # Take a look at custom_setup.landon.sh for manual steps to setup meld.
  # (This script could edit ~/.gconf/apps/meld/%gconf.xml but the file
  # filters are a little dependent on the user, so make the user do it.)
  :

} # end: stage_4_meld_configure

stage_4_psql_configure () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_psql_configure"

  # Postgres config. Where POSTGRESABBR is, e.g., "9.1".

  if [[ ! -d /etc/postgresql ]]; then
    echo
    echo "ERRO: Postgres is not installed."
    exit 1
  fi

  if [[ -z ${POSTGRESABBR} ]]; then
    echo
    echo "ERROR: POSTGRESABBR is not set."
    exit 1
  fi

  # Add the postgres group(s).
  # 2016-03-24: Currently an empty () array.
  if [[ -n ${USE_PROJECT_PSQLGROUPS} ]]; then
    for psql_group in ${USE_PROJECT_PSQLGROUPS[@]}; do
      sudo -u postgres createuser \
        --no-superuser --createdb --no-createrole \
        $psql_group
    done
  fi

  # Backup existing files. With a GUID. Just to be Grazy.
  if false; then
    sudo mv /etc/postgresql/${POSTGRESABBR}/main/pg_hba.conf \
            /etc/postgresql/${POSTGRESABBR}/main/pg_hba.conf.`uuidgen`
    sudo mv /etc/postgresql/${POSTGRESABBR}/main/pg_ident.conf \
            /etc/postgresql/${POSTGRESABBR}/main/pg_ident.conf.`uuidgen`
    sudo mv /etc/postgresql/${POSTGRESABBR}/main/postgresql.conf \
            /etc/postgresql/${POSTGRESABBR}/main/postgresql.conf.`uuidgen`
  fi

  # MEH: If you implement this, be sure to backup pg_hba.conf.
  if false; then
    # We usually configure psql on a per-project basis.
    if [[ -e ${SCRIPT_DIR}/recipe/etc/postgresql/${POSTGRESABBR}/main/pg_hba.conf ]]; then
      sudo /bin/cp -a \
        ${SCRIPT_DIR}/recipe/etc/postgresql/${POSTGRESABBR}/main/pg_hba.conf \
        /etc/postgresql/${POSTGRESABBR}/main/pg_hba.conf
    fi
  fi

  # MEH: If you implement this, be sure to backup pg_ident.conf.
  if false; then
    if [[ -e ${SCRIPT_DIR}/common/etc/postgresql/${POSTGRESABBR}/main/pg_ident.conf ]]; then
      m4 \
        --define=HTTPD_USER=${httpd_user} \
        --define=TARGETUSER=$USER \
          ${SCRIPT_DIR}/common/etc/postgresql/${POSTGRESABBR}/main/pg_ident.conf \
        | sudo tee /etc/postgresql/${POSTGRESABBR}/main/pg_ident.conf \
        &> /dev/null
    fi
  fi

  # NOTE: Deferring installing postgresql.conf until /ccp/var/log
  #       is created (otherwise the server won't start) and until we
  #       configure/install other things so that the server won't not
  #       not start because of some shared memory limit issue.

  # Set group associations, i.e., for the 'staff' group.
  if [[ -n ${USE_STAFF_GROUP_ASSOCIATION} ]]; then
    sudo chown postgres:${USE_STAFF_GROUP_ASSOCIATION} \
      /etc/postgresql/${POSTGRESABBR}/main/*
    # Is this okay?
    sudo chmod 640 /etc/postgresql/${POSTGRESABBR}/main/*
  fi

  #sudo /etc/init.d/postgresql reload
  sudo /etc/init.d/postgresql restart

} # end: stage_4_psql_configure

stage_4_apache_configure () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_apache_configure"

  echo
  echo "FIXME: 2016-11-13: stage_4_apache_configure not called in a long time"
  return

  if [[ ! -d /etc/apache2 ]]; then
    echo
    echo "ERROR: Apache2 is not installed."
    exit 1
  fi

  # Make the Apache configs group-writeable.
  # Set group associations, i.e., for the 'staff' group.
  if [[ -n ${USE_STAFF_GROUP_ASSOCIATION} ]]; then
    sudo /bin/chgrp -R ${USE_STAFF_GROUP_ASSOCIATION} /etc/apache2/
    sudo /bin/chmod 664  /etc/apache2/apache2.conf
    sudo /bin/chmod 664  /etc/apache2/ports.conf
    sudo /bin/chmod 2775 /etc/apache2/sites-available
    sudo /bin/chmod 2775 /etc/apache2/sites-enabled
    sudo /bin/chmod 664  /etc/apache2/sites-available/*.conf
  fi

  # MEH: If you implement this, be sure to backup apache2.conf.
  if false; then
    # Avoid an apache gripe and set ServerName.
    if [[ -e ${SCRIPT_DIR}/recipe/etc/apache2/apache2.conf ]]; then
      m4 \
        --define=HOSTNAME=${HOSTNAME} \
        --define=MACH_DOMAIN=${USE_DOMAIN} \
          ${SCRIPT_DIR}/recipe/etc/apache2/apache2.conf \
          > /etc/apache2/apache2.conf
    fi
  fi

  # Enable the virtual hosts module, for VirtualHost.
  sudo a2enmod vhost_alias
  # Enable the headers module, for <IfModule...>Header set...</IfModule>
  sudo a2enmod headers

  # Same as: service apache2 restart
  sudo /etc/init.d/apache2 restart

  # Remove the default conf.
  /bin/rm -f /etc/apache2/sites-enabled/000-default.conf

  # MAYBE: [lb] thinks Apache will start on boot, but it might be that
  #        I ran the following commands and forgot to include them herein:
  #
  #           sudo update-rc.d apache2 enable
  #           sudo /etc/init.d/apache2 restart
  #

} # end: stage_4_apache_configure

stage_4_quicktile_install () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_quicktile_install"

  # QuickTile by ssokolow (similar to WinSplit Revolution)
  # is an edge tiling window feature.
  #
  # It lets you quickly resize and move windows to pre-defined tiles.
  #
  # This is similar to a behavior in Windows 7, GNOME 3, and Cinnamon,
  # when you drag a window to the top, bottom, left or right of the
  # screen and it assumes a window size half of the screen, except in
  # MATE when you drag a window to one of the four sides, you cannot
  # resize it afterwards.
  #
  # See: http://ssokolow.com/quicktile/
  #
  # Usage: With the target window active, hold Ctrl + Alt and hit numpad
  # 1 through 9 to tile the window. 1 through 9 map to the relative screen
  # positions, e.g., 1 is lower-left, 6 is right-half, etc.

  if $WM_IS_MATE; then
    if [[ ! -d ${OPT_DLOADS}/quicktile ]]; then
      pushd ${OPT_DLOADS} &> /dev/null
      # http://github.com/ssokolow/quicktile/tarball/master
      git clone git://github.com/ssokolow/quicktile
    else
      pushd ${OPT_DLOADS}/quicktile &> /dev/null
      git pull origin
    fi
    popd &> /dev/null
    pushd ${OPT_DLOADS}/quicktile &> /dev/null
    # ./quicktile.py # Writes: ~/.config/quicktile.cfg
    # It also spits out the help and returns an error code.
    set +e
    ./quicktile.py
    reset_errexit
    # ./setup.py build
    sudo ./setup.py install
    # Test:
    #  quicktile.py --daemonize
    # Well, that's odd:
    sudo chmod 644 /etc/xdg/autostart/quicktile.desktop
    sudo chmod 755 /usr/local/bin/quicktile.py
    dest_dir=/usr/local/lib/python2.7/dist-packages/QuickTile-0.2.2-py2.7.egg
    sudo find $dest_dir -type d -exec chmod 2775 {} +
    sudo find $dest_dir -type f -exec chmod u+rw,g+rw,o+r {} +
    # Hrm. I reinstalled but then had to make my own startup file, since
    # /etc/xdg/autostart/quicktile.desktop no longer seemed to work (it
    # doesn't appear to be registered; probably a dconf problem). SO
    # just make your own startup file and have it execute:
    #   /usr/local/bin/quicktile.py --daemonize &
    #
    # See: $HOME/.config/autostart/quicktile.py.desktop
    popd &> /dev/null
  fi

} # end: stage_4_quicktile_install

stage_4_pidgin_setup_autostart () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_pidgin_setup_autostart"

  echo
  echo "WARNING: Deprecated: stage_4_pidgin_setup_autostart"
  echo
  return

  # Configure Pidgin to start on login.

  # You can setup Pidgin to load on login manually via Mint's Startup
  # Applications, but it's funner to automate every last setup task.

  # MAYBE: Should we just copy this from a setup file?
  #        Maybe check for a file to copy first, then do this on backup.

  mkdir -p $HOME/.config/autostart

  echo "[Desktop Entry]
Type=Application
Exec=/usr/bin/pidgin
Hidden=false
X-MATE-Autostart-enabled=true
Name[en_US]=Pidgin
Name=Pidgin
Comment[en_US]=
Comment=
" > $HOME/.config/autostart/pidgin.desktop

} # end: stage_4_pidgin_setup_autostart

stage_4_hamster_time_tracker_setup () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_hamster_time_tracker_setup"

  # The application at `sudo apt-get install hamster-applet` is from 2010.
  # But it still seems better than the one on github. Just be sure to
  # also install hamster-indicator, in addition to hamster-applet.
  #
  # https://github.com/projecthamster/hamster
  if false; then
    sudo add-apt-repository -y ppa:dylanmccall/hamster-time-tracker-git-daily
    # NOTE: To remove the repository:
    #  sudo /bin/rm /etc/apt/sources.list.d/dylanmccall-hamster-time-tracker-git-daily-trusty.list
    #if ! ${SKIP_APT_GET_UPDATE}; then
      sudo apt-get update
    #fi
    sudo apt-get install -y hamster-time-tracker
    # Dependencies.
    sudo apt-get install -y gettext intltool python-gconf python-xdg gir1.2-gconf-2.0
    # Note that the binary is simply /usr/bin/hamster.
  fi
  # There's also the package which is the same as from the untrusted repo.
  if false; then
    pushd ${OPT_DLOADS} &> /dev/null
    wget -N https://github.com/projecthamster/hamster/releases/download/v2.0-rc1/hamster_2.0-rc1-2_all.deb
    sudo dpkg -i hamster_2.0-rc1-2_all.deb
    sudo dpkg --remove
    popd &> /dev/null
  fi

  sudo apt-get install -y hamster-applet hamster-indicator

  # Update hamster to special fork.

  pushd ${OPT_DLOADS} &> /dev/null

  # Skip if already installed.
  if type -P module &>/dev/null; then
    if [[ ! -e ${OPT_DLOADS}/hamster-applet ]]; then
      git clone https://github.com/landonb/hamster-applet
    else
      # NOTE: Given the `type -P`, this path probably not gonna happen.
      #       Which if fine, since I `pip install -e` it.
      pushd ${OPT_DLOADS}/hamster-applet &> /dev/null
      git pull
      popd &> /dev/null
    fi
  else
    echo "Skipping: Already installed: hamster-applet"
  fi

  if [[ -f /usr/share/pyshared/hamster/overview.py ]]; then
    HAMSTER_PKGS=/usr/share/pyshared/hamster
  elif [[ -f /usr/lib/python2.7/dist-packages/hamster/overview.py ]]; then
    HAMSTER_PKGS=/usr/lib/python2.7/dist-packages/hamster
  else
    echo
    echo "ERROR: Where's hamster? Try:"
    echo "    locate overview_totals.py"
    exit 1
  fi

  set +e
  pkill -f hamster-service
  pkill -f hamster-windows-service
  reset_errexit

  if [[    -e ${HAMSTER_PKGS}/overview.py.ORIG \
        || -e ${HAMSTER_PKGS}/overview_totals.py.ORIG ]]; then
    echo
    echo "${REINSTALL_OR_SKIP}: Already installed: Hamster"
    echo
    if ! ${FORCE_REINSTALL}; then
      return
    fi
  else
    sudo /bin/cp -a \
        ${HAMSTER_PKGS}/overview.py \
        ${HAMSTER_PKGS}/overview.py.ORIG
    sudo /bin/cp -a \
        ${HAMSTER_PKGS}/overview_totals.py \
        ${HAMSTER_PKGS}/overview_totals.py.ORIG
  fi

  sudo /bin/cp -af \
      hamster-applet/src/hamster/overview.py \
      ${HAMSTER_PKGS}/overview.py
  sudo /bin/cp -af \
      hamster-applet/src/hamster/overview_totals.py \
      ${HAMSTER_PKGS}/overview_totals.py

  popd &> /dev/null

  # Auto-start hamster on boot.

  mkdir -p ${HOME}/.config/autostart

  if false; then
    echo "[Desktop Entry]
Type=Application
Exec=/usr/bin/hamster-time-tracker
Hidden=false
X-MATE-Autostart-enabled=true
Name[en_US]=Hamster
Name=Hamster
Comment[en_US]=
Comment=
" > ${HOME}/.config/autostart/hamster-time-tracker.desktop
  fi

  echo "[Desktop Entry]
Type=Application
Exec=/usr/bin/hamster-indicator
Hidden=false
X-MATE-Autostart-enabled=true
Name[en_US]=Hamster
Name=Hamster
Comment[en_US]=
Comment=
" > ${HOME}/.config/autostart/hamster-indicator.desktop

  # 2016-11-17: Configure hamster.
  #  - Don't "Stop tracking when computer becomes idle."
  #  - "Remind of current activity every:" 66 minutes, not 27.
  #  - Add "Also remind when no activity is set".
  #  - New days starts at: 05:30. Is this okay?
  # See: ~/.gconf/apps/hamster-applet/%gconf.xml

  gconftool-2 \
    --set /apps/hamster-applet/notify_on_idle \
    --type bool "true"

  gconftool-2 \
    --set /apps/hamster-applet/notify_interval \
    --type int "66"

  gconftool-2 \
    --set /apps/hamster-applet/enable_timeout \
    --type bool "true"

  # NOTE: When I fiddled with the preferences to see what changed in
  #       %gconf.xml, I never saw this one pop up. However, I do see
  #       it's schema listed via `gconftool-2 -R /`. And it works
  #       when I tickle it.

  # This is off by default, but whatever.
  gconftool-2 \
    --set /apps/hamster-applet/stop_on_shutdown \
    --type bool "false"

  gconftool-2 \
    --set /apps/hamster-applet/enable_timeout \
    --type bool "false"

  # Start hamster.

  hamster-indicator &

} # end: stage_4_hamster_time_tracker_setup

stage_4_hamster_briefs_setup () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

# FIXME/2016-11-21: With travel unpack, you'll set this up under /kit...
# and then who should call `pip install --user -v -e .` ?
echo
echo "WARNING: Skipping hamster-briefs install."
echo "FIXME: Determine who should pip install this from /kit, right?"
echo "FIXME: Also, pip install pyoiler-* projects first."
echo
return

  stage_announcement "stage_4_hamster_briefs_setup"

  pushd ${OPT_DLOADS} &> /dev/null

  if [[ ! -e ${OPT_DLOADS}/hamster-briefs ]]; then
    git clone https://github.com/landonb/hamster-briefs
  else
    pushd ${OPT_DLOADS}/hamster-briefs &> /dev/null
    git pull
    popd &> /dev/null
  fi

  # 2016-11-21: The old way, before I pipped the project.
  #/bin/ln -sf ${OPT_DLOADS}/hamster-briefs/hamster-briefs.py ${OPT_BIN}
  #/bin/ln -sf ${OPT_DLOADS}/hamster-briefs/hamster-love.sh ${OPT_BIN}
  #/bin/ln -sf ${OPT_DLOADS}/hamster-briefs/transform-brief.py ${OPT_BIN}

  pushd ${OPT_DLOADS}/hamster-briefs &> /dev/null
  pip install --user -v -e .
  popd &> /dev/null

  popd &> /dev/null

} # end: stage_4_hamster_briefs_setup

stage_4_gmail_notifier_setup () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_gmail_notifier_setup"

  # Linux Mint MATE 17.x
  if [[ -e /usr/bin/gnome-gmail-notifier ]]; then
    echo "[Desktop Entry]
Type=Application
Exec=/usr/bin/gnome-gmail-notifier
Hidden=false
X-MATE-Autostart-enabled=true
Name[en_US]=Gmail Notifier
Name=Gmail Notifier
Comment[en_US]=
Comment=
" > $HOME/.config/autostart/gnome-gmail-notifier.desktop
  fi

  # Ubuntu MATE 15.10
  if [[ -e /usr/bin/gm-notify ]]; then
    echo "[Desktop Entry]
Type=Application
Exec=/usr/bin/gm-notify
Hidden=false
X-MATE-Autostart-enabled=true
Name[en_US]=Gmail Notifier
Name=Gmail Notifier
Comment[en_US]=
Comment=
" > $HOME/.config/autostart/gm-notify.desktop
  fi

} # end: stage_4_gmail_notifier_setup

stage_4_firefox_configure () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "Nada: stage_4_firefox_configure"

  # Configure Firefox.

  # FIXME: MAYBE: Do this... cp or maybe use m4.
  #cp ~/.mozilla/firefox/*.default/prefs.js ...
  ## Diff the old Firefox's file and the new Firefox's file?
  #cp ... ~/.mozilla/firefox/*.default/prefs.js

  : # http://stackoverflow.com/questions/12404661/what-is-the-use-case-of-noop-in-bash
    # http://unix.stackexchange.com/questions/31673/what-purpose-does-the-colon-builtin-serve

} # end: stage_4_firefox_configure

stage_4_chrome_install () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_chrome_install"

  # Install Chrome.
  #
  # NOTE: We should be okay to distribute Chrome. Per:
  #   https://www.google.com/intl/en/chrome/browser/privacy/eula_text.html
  #
  # "21.2 Subject to the Terms, and in addition to the license grant
  #  in Section 9, Google grants you a non-exclusive, non-transferable
  #  license to reproduce, distribute, install, and use Google Chrome
  #  solely on machines intended for use by your employees, officers,
  #  representatives, and agents in connection with your business
  #  entity, and provided that their use of Google Chrome will be
  #  subject to the Terms. ...August 12, 2010"
  #
  pushd ${OPT_DLOADS} &> /dev/null

  wget -N \
    https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb

  sudo dpkg -i google-chrome-stable_current_amd64.deb

  # Firefox Google Search Add-On
  # Hrm, [lb] thinks the user has to do this themselves...
  #mkdir -p ${OPT_DLOADS}/firefox-google-search-add_on
  #cd ${OPT_DLOADS}/firefox-google-search-add_on
  #wget -N \
  #  https://addons.mozilla.org/firefox/downloads/file/157593/google_default-20120704.xml?src=search

  popd &> /dev/null

} # end: stage_4_chrome_install

stage_4_https_everywhere_install () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "Skipping: stage_4_https_everywhere_install"

  # HTTPS Everywhere.
  #
  # See: https://www.eff.org/https-everywhere

  # NOTE: It looks like you have to install xpi via the
  #       browser. The CLI command is deprecated, it seems.
  # See: Post_Setup_Script_Manual_Steps.rst for a reminder to the
  #      user and instructions on setting up https everywhere and
  #      mouse gestures in both Firefox and Chrome.
  if false; then
    mkdir -p ${OPT_DLOADS}/https-everywhere
    pushd ${OPT_DLOADS}/https-everywhere &> /dev/null
    # 2014.01.28: The Firefox version is labeled "stable".
    wget -N https://www.eff.org/files/https-everywhere-latest.xpi
    # Hmmm... can't get cli install to work.
    #   sudo /bin/cp https-everywhere-latest.xpi /usr/lib/firefox/extensions/
    #   sudo chmod 664 /usr/lib/firefox/extensions/https-everywhere-latest.xpi
    #   #
    #   sudo /bin/cp https-everywhere-latest.xpi /usr/lib/firefox-addons/extensions/
    #   sudo chmod 664 /usr/lib/firefox-addons/extensions/https-everywhere-latest.xpi
    #   #
    #   sudo /bin/cp https-everywhere-latest.xpi /opt/firefox/extensions/
    #   sudo chmod 664 /opt/firefox/extensions/https-everywhere-latest.xpi
    #   #
    #   sudo unzip https-everywhere-latest.xpi -d \
    #  /usr/lib/firefox-addons/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384
    #  dest_dir=/usr/lib/firefox-addons/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384
    #  sudo find $dest_dir -type d -exec chmod 2775 {} +
    #  sudo find $dest_dir -type f -exec chmod u+rw,g+rw,o+r {} +
    popd &> /dev/null
  fi

} # end: stage_4_https_everywhere_install

stage_4_virtualbox_install () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_virtualbox_install"

  # I first tried apt-get install virtualbox, but that was not a happy camper:
  #     * Starting VirtualBox kernel modules
  #     * No suitable module for running kernel found
  #                                                    [fail]
  #
  # Note also there used to be a pre-4.0 virtualbox-nonfree, but now
  # it is all rolled into one package. There is also virtualbox-4.3,
  # but let us not be specific.
  #
  # Note also if you frakup, you can always backup:
  #   sudo apt-get install virtualbox
  #   sudo apt-get purge virtualbox

  # Headers are needed for VirtualBox but should already be current:
  sudo apt-get install -y linux-headers-`uname -r`

# FIXME: Install VBox 5.0
#        https://www.virtualbox.org/wiki/Linux_Downloads
#
#echo "deb http://download.virtualbox.org/virtualbox/debian vivid contrib" \
#  >> /etc/apt/sources.list
##wget https://www.virtualbox.org/download/oracle_vbox.asc
##sudo apt-key add oracle_vbox.asc
###or more simply:
#wget -q https://www.virtualbox.org/download/oracle_vbox.asc -O- | sudo apt-key add -
##key fingerprint
#7B0F AB3A 13B9 0743 5925  D9C9 5442 2A4B 98AB 5139
#Oracle Corporation (VirtualBox archive signing key) <info@virtualbox.org>
#if ! ${SKIP_APT_GET_UPDATE}; then
#  sudo apt-get update
#fi
#sudo apt-get install virtualbox-5.0

  # Get the latest Debian package. At least if this script is uptodate.
  #
  #   https://www.virtualbox.org/wiki/Downloads


  # 2016-05-02: Here's the old, tedious version-specific install procedure.
  if false; then
    # Major: 4
    #LATEST_VBOX_VERS_MINOR="26"
    #LATEST_VBOX_VERS_BUILD="98988"
    #LATEST_VBOX_VERS_MINOR="28"
    #LATEST_VBOX_VERS_BUILD="100309"
    #LATEST_VBOX_VERS_MAJOR="4.3"
    #LATEST_VBOX_VERS_MINOR="30"
    #LATEST_VBOX_VERS_BUILD="101610"
    # Major: 5
    #LATEST_VBOX_VERS_MINOR="10"
    #LATEST_VBOX_VERS_BUILD="104061"
    #LATEST_VBOX_VERS_MINOR="12"
    #LATEST_VBOX_VERS_BUILD="104815"
    #LATEST_VBOX_VERS_MINOR="14"
    #LATEST_VBOX_VERS_BUILD="105127"
    #LATEST_VBOX_VERS_MINOR="16"
    #LATEST_VBOX_VERS_BUILD="105871"
    LATEST_VBOX_VERS_MAJOR="5.0"
    LATEST_VBOX_VERS_MINOR="20"
    LATEST_VBOX_VERS_BUILD="106931"

    LATEST_VBOX_VERSION_BASE="${LATEST_VBOX_VERS_MAJOR}.${LATEST_VBOX_VERS_MINOR}"
    LATEST_VBOX_VERSION_FULL="${LATEST_VBOX_VERSION_BASE}-${LATEST_VBOX_VERS_BUILD}"

    source /etc/lsb-release
    if [[ $DISTRIB_CODENAME == 'sarah' ]]; then
      # Mint 18.X is sarah is xenial.
      UBUNTU_CODENAME=xenial
    elif [[ $DISTRIB_CODENAME == 'rebecca' ]]; then
      # Mint 17.X is rebecca is trusty.
      UBUNTU_CODENAME=trusty
    else
      UBUNTU_CODENAME=$DISTRIB_CODENAME
    fi
    LATEST_VBOX_DEB_PKG="\
virtualbox-${LATEST_VBOX_VERS_MAJOR}_${LATEST_VBOX_VERSION_FULL}~Ubuntu~${UBUNTU_CODENAME}_amd64.deb"

    # We don't worry about the extension pack because the app'll download'll it.
    #LATEST_VBOX_EXTPACK="\
    #Oracle_VM_VirtualBox_Extension_Pack-${LATEST_VBOX_VERS_MAJOR}.${LATEST_VBOX_VERSION_FULL}.vbox-extpack"
    # https://www.virtualbox.org/download/testcase/VBoxGuestAdditions_5.0.17-106140.iso

    pushd ${OPT_DLOADS} &> /dev/null

    if [[ -e ${OPT_DLOADS}/${LATEST_VBOX_DEB_PKG} ]]; then
      echo
      echo "${REINSTALL_OR_SKIP}: Already installed: VirtualBox"
      echo
      if ! ${FORCE_REINSTALL}; then
        return
      else
        /bin/rm ${OPT_DLOADS}/${LATEST_VBOX_DEB_PKG}
      fi
    fi

    wget -N \
      http://download.virtualbox.org/virtualbox/${LATEST_VBOX_VERSION_BASE}/${LATEST_VBOX_DEB_PKG}

    #sudo apt-get remove virtualbox-4.3
    sudo dpkg -i ${LATEST_VBOX_DEB_PKG}
    #/bin/rm ${LATEST_VBOX_DEB_PKG}

    if false; then
      # This Guy, for USB 2.
      wget -N \
        http://download.virtualbox.org/virtualbox/${LATEST_VBOX_VERSION_BASE}/${LATEST_VBOX_EXTPACK}
    fi

    # The next time you run VirtualBox, it should download the latest extensionl pack.
    # But if it doesn't you can do it manually:
    #   File > Preferences...,
    #     [click] Extensions
    #     [click icon for] Add Package
    #     [select, e.g.,] /srv/opt/.downloads/Oracle_VM_VirtualBox_Extension_Pack-4.3.30-101610.vbox-extpack

    popd &> /dev/null

  fi # end: if False

  set +e
  command -v virtualbox_update.sh
  exit_code=$?
  reset_errexit
  if [[ ${exit_code} -eq 0 ]]; then
    echo
    echo "Running virtualbox_update.sh"
    echo
    virtualbox_update.sh

    sudo usermod -a -G vboxsf ${USER}
    sudo usermod -a -G vboxusers ${USER}
  else
    echo
    echo "WARNING: Not found: virtualbox_update.sh"
    echo "         You'll want to call this on your own later."
    echo
  fi

  # MEH: One doc [lb] read says add youruser to 'lp' and 'users' groups,
  # in addition to obvious 'vboxsf' and 'vboxusers' group. See: /etc/group.

  # MAYBE: Need this here or in the guest?
  #        2016-05-02: I don't remember what I added this for...
  # [apt-get install] virtualbox-guest-additions-iso
  # Add to vboxusers? and lp and users?
  # #sudo usermod -a -G lp ${USER}
  # #sudo usermod -a -G users ${USER}

} # end: stage_4_virtualbox_install

stage_4_reader_install () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_reader_install"

  if [[ -e /opt/Adobe/Reader9/Reader/intellinux/bin/acroread ]]; then
    echo
    echo "${REINSTALL_OR_SKIP}: Already installed: acroread"
    echo
    if ! ${FORCE_REINSTALL}; then
      return
    fi
  fi

  # 2014.11.10: On Windows and Mac it's Adobe 11 but on Linux it's still 9.5.5,
  # because Adobe discountinued their Linux work.

  # See also other PDF applications, like
  # evince (Ubuntu), atril (Mint fork of evince) and okular.

  if [[ -z ${INCLUDE_ADOBE_READER+x} ]]; then
    INCLUDE_ADOBE_READER=true
  fi

  # NOTE: We cannot distribute Reader...
  #   cd /opt/Adobe/Reader9/bin
  #   sudo ./UNINSTALL
  if ${INCLUDE_ADOBE_READER}; then
    pushd ${OPT_DLOADS} &> /dev/null
    wget -N \
      http://ardownload.adobe.com/pub/adobe/reader/unix/9.x/9.5.5/enu/AdbeRdr9.5.5-1_i486linux_enu.bin
    chmod a+x ./Adbe*.bin
    # Specify the install path otherwise the installer will ask us.
    sudo ./Adbe*.bin --install_path=/opt
    # Remove the Desktop icon that it creates.
    /bin/rm -f /home/$USER/Desktop/AdobeReader.desktop
    # Note that we could remove the binary, but Reader is discontinued on
    # Linux, so might as well hold onto it, in case Adobe ever purges.
    #  /bin/rm ${OPT_DLOADS}/AdbeRdr9.5.5-1_i486linux_enu.bin
    popd &> /dev/null
  fi

  # Here's how to uninstall it:
  #  pushd /opt/Adobe/Reader9/bin && sudo ./UNINSTALL

} # end: stage_4_reader_install

stage_4_modern_ie_install () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "Modern is the new ancient: stage_4_modern_ie_install"

# See: http://dev.modern.ie/
  if false; then

    # Notes:
    # - VMs expire after 90 days.
    # - On first install, set snapshot.

    # IE11 on Win7
    wget https://az412801.vo.msecnd.net/vhd/VMBuild_20141027/VirtualBox/IE11/Linux/IE11.Win7.For.Linux.VirtualBox.zip

    # IE11 on Win8.1
    wget https://az412801.vo.msecnd.net/vhd/VMBuild_20141027/VirtualBox/IE11/Linux/IE11.Win8.1.For.Linux.VirtualBox.zip

    # IE10 on Win8
    wget https://az412801.vo.msecnd.net/vhd/VMBuild_20141027/VirtualBox/IE10/Linux/IE10.Win8.For.Linux.VirtualBox.zip

    # IE10 on Win7
    wget https://az412801.vo.msecnd.net/vhd/VMBuild_20141027/VirtualBox/IE10/Linux/IE10.Win7.For.Linux.VirtualBox.zip

    # IE9 on Win7
    wget https://az412801.vo.msecnd.net/vhd/VMBuild_20141027/VirtualBox/IE9/Linux/IE9.Win7.For.Linux.VirtualBox.zip

    # IE8 on Win7
    wget https://az412801.vo.msecnd.net/vhd/VMBuild_20141027/VirtualBox/IE8/Linux/IE8.Win7.For.Linux.VirtualBox.zip

    # There's also IE8 on XP and IE7 on Vista

  fi

} # end: stage_4_modern_ie_install

stage_4_dev_testing_expect_install () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "Don't expect: stage_4_dev_testing_expect_install"

  # Unleash this code if you don't want to just `apt-get install -y expect`.

  if false; then

    pushd ${OPT_DLOADS} &> /dev/null

    # FIXME: Move all the apt-get installs from the big list above
    #        to the setup function that needs them?
    sudo apt-get install -y tcl tcl-dev

    wget -N http://downloads.sourceforge.net/project/expect/Expect/5.45/expect5.45.tar.gz
    tar xvzf expect5.45.tar.gz
    cd expect5.45
    ./configure
    make

    # 2015.01.20: This seems to install without any perms issues.
    # FIXME: Use `sudo su --login -c ''` to replace chmod cleanups.
    sudo su --login -c "cd ${OPT_DLOADS}/expect5.45 && make install"

    # NOTE: You'll have to manually setup your LD_LIBRARY_PATH. E.g.,
    #
    #   LD_LIBRARY_PATH=/usr/lib/expect5.45
    #   export LD_LIBRARY_PATH

    popd &> /dev/null

  fi

} # end: stage_4_dev_testing_expect_install

stage_4_restview_install () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_restview_install"

  # Weird. This installs restview with ownership as my ${USER}.
  #sudo su -c "pip install restview"
  sudo pip2 install restview
  sudo pip3 install restview

} # end: stage_4_restview_install

# FIXME: Is there a way to automatically get the latest
#        packages from SourceForge without hardcoding here?

stage_4_rssowl_install () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "Skipping: stage_4_rssowl_install"

  # RSSOwl RSS Client
  # FIXME: Test RSSOwl and decide if this should be excluded.
  if false; then
    pushd ${OPT_DLOADS} &> /dev/null
    wget "http://downloads.sourceforge.net/project/rssowl/rssowl%202/2.2.1/rssowl-2.2.1.linux.x86_64.zip"
    unzip rssowl-2.2.1.linux.x86_64.zip -d rssowl-2.2.1
    cd rssowl-2.2.1/rssowl/
# FIXME: Move the installation folder somewhere...
#        or add to PATH...
# ${OPT_DLOADS}/rssowl-2.2.1/rssowl/RSSOwl
    popd &> /dev/null
  fi

} # end: stage_4_rssowl_install

stage_4_cloc_install () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_cloc_install"

  # 2016-11-06: This is the old way:
  if false; then
    pushd ${OPT_BIN} &> /dev/null
    wget -N \
      http://downloads.sourceforge.net/project/cloc/cloc/v1.62/cloc-1.62.pl
    # Set the permissions so you can execute the CLI interface:
    chmod +x ${OPT_BIN}/cloc-1.62.pl
    popd &> /dev/null
  fi

  # And here's the new way:
  pushd ${OPT_DLOADS} &> /dev/null

  if [[ ! -e ${OPT_DLOADS}/cloc ]]; then
    git clone https://github.com/AlDanial/cloc
  else
    pushd cloc &> /dev/null
    git pull
    popd &> /dev/null
  fi

  cd ${OPT_BIN} &> /dev/null
  /bin/ln -sf ${OPT_DLOADS}/cloc/cloc
  # /bin/rm cloc-1.62.pl

  popd &> /dev/null

} # end: stage_4_cloc_install

stage_4_parT_install () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_parT_install"

  if [[ -f /usr/bin/parT ]]; then
    echo
    echo "${REINSTALL_OR_SKIP}: Already installed: parT"
    echo
    if ! ${FORCE_REINSTALL}; then
      return
    fi
  fi

  pushd ${OPT_DLOADS} &> /dev/null

  if [[ ! -e ${OPT_DLOADS}/parT ]]; then
    git clone https://github.com/landonb/parT
  else
    pushd parT &> /dev/null
    git pull
    popd &> /dev/null
  fi

  cd parT &> /dev/null

  ./build.sh
  sudo /bin/cp -af parT /usr/bin
  sudo chown root:root /usr/bin/parT

  popd &> /dev/null

  # Stupid message for debugging ./setup_ubuntu.sh
  stage_curtains "stage_4_parT_install"

} # end: stage_4_parT_install

stage_4_cookiecutter_install () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_cookiecutter_install"

  # 2015.02.06: Cookiecutter in the distro is 0.6.4,
  #             but >= 0.7.0 is where it's at.

  sudo pip install cookiecutter

  # WTW?                            -rwxrwx--x
  # 2015.02.19: On fresh Mint 17.1: -rwxr-x--x
  # Anyway, 'other' is missing the read bit.
  sudo chmod 755 /usr/local/bin/cookiecutter

} # end: stage_4_cookiecutter_install

stage_4_pencil_install () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "Erased: stage_4_pencil_install"

  # 2016.03.23: Disabling this until I find myself needing to use it.

  if false; then

    pushd ${OPT_DLOADS} &> /dev/null

    wget -N http://evoluspencil.googlecode.com/files/evoluspencil_2.0.5_all.deb
    sudo dpkg -i evoluspencil_2.0.5_all.deb
    #/bin/rm ${OPT_DLOADS}/evoluspencil_2.0.5_all.deb

    popd &> /dev/null

  fi

} # end: stage_4_pencil_install

stage_4_jsctags_install () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "Skipping: stage_4_jsctags_install"

  # https://github.com/ramitos/jsctags

  # audit this first.
  if false; then
    sudo npm install -g git://github.com/ramitos/jsctags.git
  fi

  # If you want to add it to package.json instead:
  #
  #   "jsctags": "git://github.com/ramitos/jsctags.git"

  # Usage: jsctags [--dir=/path/to] /path/to/file.js [-f]
  # use -f to make tags file, else it's a json file.

} # end: stage_4_jsctags_install

stage_4_disable_services () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "Pretend: stage_4_disable_services"

  # 2015.02.22: From /var/log/auth.log, lines like
  #   Feb 22 14:55:05 philae smbd[30165]: pam_unix(samba:session):
  #     session closed for user nobody
  # but no "session started" or "session opened" lines. Whatever.
  # I don't Samba. https://en.wikipedia.org/wiki/Samba_%28software%29

  # 2016.03.23: Samba's not installed by default;
  #             this is all a no-op, right?

  set +e
  # Stop it now.
  sudo service smbd stop
  # Have it not start in the future.
  sudo update-rc.d -f smbd remove
  # Restore with:
  #   sudo update-rc.d -f smbd defaults
  reset_errexit

} # end: stage_4_disable_services

stage_4_spotify_install () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_spotify_install"

  pushd ${OPT_DLOADS} &> /dev/null

  # From:
  #  https://www.spotify.com/us/download/previews/

  set +e
  grep "repository.spotify.com" /etc/apt/sources.list &> /dev/null
  exit_code=$?
  reset_errexit
  if [[ ${exit_code} -ne 0 ]]; then
    # FIXME: Is there a way to use Aptitude instead? Like,
    #           sudo add-apt-repository -y ppa:dylanmccall/hamster-time-tracker-git-daily
    echo "deb http://repository.spotify.com stable non-free" \
      | sudo tee -a /etc/apt/sources.list &> /dev/null
  fi

  # 2015.05.31: Is adding the key still necessary?
  #             This step not listed on the spotify page.
  sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 94558F59

  #if ! ${SKIP_APT_GET_UPDATE}; then
    sudo apt-get update
  #fi

  # 2015.05.31: Is this step now necessary?
  sudo apt-get install spotify-client

  # FIXME: More post-install reminders:
  #         Disable the annoying notification popup when a new track starts.
  #         (Though I do kinda like it to know when ads are finished playing.)
  if false; then
    echo "ui.track_notifications_enabled=false" \
      >> ~/.config/spotify/Users/*/prefs
  fi

  popd &> /dev/null

  # Run it: spotify

} # end: stage_4_spotify_install

stage_4_relocate_spotify_cache () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_relocate_spotify_cache"

  # 2016-11-12: News reports of Spotify writing lots to user's local space,
  # and my local space is an SSD, so stop that! spotify.
  #
  #  $ du -m -d 1 ~/.cache | sort -nr
  #  5328   ~/.cache
  #  4275   ~/.cache/spotify
  #   631   ~/.cache/google-chrome
  #   176   ~/.cache/chromium
  #   146   ~/.cache/thumbnails
  #    66   ~/.cache/apt-file
  #    17   ~/.cache/Atlassian
  #    12   ~/.cache/mozilla

  if [[ -e ${HOME}/.cache/spotify ]]; then
    if [[ ! -h ${HOME}/.cache/spotify ]]; then
      /bin/cp -ar ${HOME}/.cache/spotify ${OPT_LARGE}
      /bin/rm -rf ${HOME}/.cache/spotify
      /bin/ln -s ${OPT_LARGE}/spotify ${HOME}/.cache/spotify
    fi
  fi

} # end: stage_4_relocate_spotify_cache

stage_4_openjump_install () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_openjump_install"

  if [[ -f ${OPT_DLOADS}/OpenJUMP-1.8.0-r4164-CORE/bin/oj_linux.sh ]]; then
    echo
    echo "${REINSTALL_OR_SKIP}: Already installed: OpenJUMP"
    echo
    if ! ${FORCE_REINSTALL}; then
      return
    fi
  fi

  pushd ${OPT_DLOADS} &> /dev/null

  #wget -N \
  #  http://downloads.sourceforge.net/project/jump-pilot/OpenJUMP/1.8.0/OpenJUMP-Installer-1.8.0-r4164-PLUS.jar
  #wget -N \
  #  http://downloads.sourceforge.net/project/jump-pilot/OpenJUMP/1.8.0/OpenJUMP-Installer-1.8.0-r4164-CORE.jar
  #java -jar OpenJUMP-Installer-1.8.0-r4164-CORE.jar
  ##java -jar OpenJUMP-Installer-1.8.0-r4164-PLUS.jar
  wget -N \
    http://downloads.sourceforge.net/project/jump-pilot/OpenJUMP/1.8.0/OpenJUMP-Portable-1.8.0-r4164-CORE.zip
  wget -N \
    http://downloads.sourceforge.net/project/jump-pilot/OpenJUMP/1.8.0/OpenJUMP-Portable-1.8.0-r4164-PLUS.zip

  unzip OpenJUMP-Portable-1.8.0-r4164-CORE.zip -d OpenJUMP-1.8.0-r4164-CORE-unzip/
  mv OpenJUMP-1.8.0-r4164-CORE-unzip/OpenJUMP-1.8.0-r4164-CORE .
  rmdir OpenJUMP-1.8.0-r4164-CORE-unzip

  /bin/ln -sf ${OPT_DLOADS}/OpenJUMP-1.8.0-r4164-CORE/bin/oj_linux.sh ${OPT_BIN}/oj_linux.sh

  popd ${OPT_DLOADS} &> /dev/null

} # end: stage_4_openjump_install

stage_4_liclipse_install () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_liclipse_install"

  echo
  echo "WARNING: Deprecated: stage_4_liclipse_install"
  echo
  return

  pushd ${OPT_DLOADS} &> /dev/null

  wget -N "https://googledrive.com/host/0BwwQN8QrgsRpLVlDeHRNemw3S1E/LiClipse%202.0.0/liclipse_2.0.0_linux.gtk.x86_64.tar.gz"
# FIXME:
#       https://googledrive.com/host/0BwwQN8QrgsRpLVlDeHRNemw3S1E/LiClipse%202.4.0/liclipse_2.4.0_linux.gtk.x86_64.tar.gz
  tar -xzf liclipse_2.0.0_linux.gtk.x86_64.tar.gz
  /bin/ln -s /srv/opt/.downloads/liclipse/LiClipse /srv/opt/bin/LiClipse

  popd &> /dev/null

# and also:

# FIXME: mkdir gk12_2.......
  pushd /srv/excensus/gk12_2 &> /dev/null
  /bin/cp /srv/opt/.downloads/liclipse_2.0.0_linux.gtk.x86_64.tar.gz /srv/excensus/gk12_2
  tar -xzf liclipse_2.0.0_linux.gtk.x86_64.tar.gz
  /bin/rm liclipse_2.0.0_linux.gtk.x86_64.tar.gz
  #/bin/ln -s /srv/excensus/gk12_2/liclipse/LiClipse /srv/excensus/gk12_2/bin
  popd &> /dev/null

# or maybe just:

  pushd /srv/opt/.downloads &> /dev/null
  wget -N "https://googledrive.com/host/0BwwQN8QrgsRpLVlDeHRNemw3S1E/LiClipse%202.0.0/liclipse_2.0.0_linux.gtk.x86_64.tar.gz"
  tar -xzf liclipse_2.0.0_linux.gtk.x86_64.tar.gz
  mv liclipse /srv/excensus/gk12_2
  /bin/ln -s /srv/excensus/gk12_2/liclipse/LiClipse /srv/opt/bin/LiClipse
  popd &> /dev/null

} # end: stage_4_liclipse_install

stage_4_all_the_young_pips () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_all_the_young_pips"

  pushd ${OPT_DLOADS} &> /dev/null

  was_umask=$(umask)
  umask 0002

  wget -N https://bootstrap.pypa.io/get-pip.py
  sudo python2 get-pip.py
  sudo python3 get-pip.py

  # 2016-11-12: Meh. I got my own uncommitted script now.
  if false; then
    # My ~/.vim/bundle_/ contains a dozenish sub-gits. Uncommitted helps.
    sudo pip2 install uncommitted
    sudo chmod 755 /usr/local/bin/uncommitted
    # Be sure to specify -l to use locate.
    # E.g., `uncommitted -l ~/.vim`, or `uncommitted -l -v ~/.vim`.
  fi

  # https://argcomplete.readthedocs.org/en/latest/#activating-global-completion%20argcomplete
# FIXME:
# The directory 'll ~/.cache/pip' or its parent directory is not owned by the current user and caching wheels has been disabled. check the permissions and owner of that directory. If executing pip with sudo, you may want sudo's -H flag.
  sudo pip2 install argcomplete
  sudo pip3 install argcomplete
  sudo activate-global-python-argcomplete
  # To upgrade:
  sudo pip2 install --upgrade argcomplete
  sudo pip3 install --upgrade argcomplete

  # 2016-11-19 PyPi
  # https://packaging.python.org/distributing/
  pip install -U pip setuptools
  # MAYBE: Use virtualenv instead of pipping here.
  sudo pip2 install twine
  sudo pip3 install twine

  # 2016-11-22 PyYAML
  sudo pip2 install PyYAML
  sudo pip3 install PyYAML

  # 2016-12-07: Pyonep.
  # MAYBE: Use virtualenv instead of pipping here.
  # https://github.com/exosite-labs/pyonep
  sudo pip2 install pyonep
  sudo pip3 install pyonep

  # 2017-04-19: sha512_crypt wrapper [mkpasshash.py]
  sudo pip2 install passlib
  sudo pip3 install passlib

  umask ${was_umask}

  popd &> /dev/null

} # end: stage_4_all_the_young_pips

stage_4_install_ruby_install () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_install_ruby_install"

  pushd ${OPT_DLOADS} &> /dev/null

  wget -O ruby-install-0.6.0.tar.gz https://github.com/postmodern/ruby-install/archive/v0.6.0.tar.gz
  tar -xzvf ruby-install-0.6.0.tar.gz
  pushd ruby-install-0.6.0 &> /dev/null
  sudo make install
  popd &> /dev/null
  # Verify
  if [[ "$(ruby-install -V)" != "ruby-install: 0.6.0" ]]; then
    echo "ERROR: Something went wrong with install ruby-install."
    exit 1
  fi
  # Install the latest Ruby.
  # PATIENCE: `ruby-install` runs for a few minutes 'cause it builds Ruby.
  #   And it always build fresh, even if that version of ruby is already there.
  # 2016-12-08: Did "ruby 2.3" just install 2.3.0? I have 2.3.0 and 2.3.3 and gem
  #   problems with the latter.
  #ruby-install --latest ruby 2.3
  ruby-install --latest ruby 2.3.3
  # Install other versions if you want, too, but this project uses 2.3.
  ruby-install --latest ruby 2.2
  # 2017-07-05: Hrmmm... `ruby 2` installs the lastest Ruby, currently 2.4.1.
  ruby-install --latest ruby 2
  # 2017-07-05: I need this for backward compatibility...
  ruby-install --latest ruby 2.0.0-p648
  # 2017-08-15: Whoopie!
  ruby-install --latest ruby 2.4.0

  wget -O chruby-0.3.9.tar.gz https://github.com/postmodern/chruby/archive/v0.3.9.tar.gz
  tar -xzvf chruby-0.3.9.tar.gz
  pushd chruby-0.3.9 &> /dev/null
  sudo make install
  popd &> /dev/null

  popd &> /dev/null

} # end: stage_4_install_ruby_install

ruby_install_gems () {
  echo chruby $1
  chruby $1
  gem install \
    --user-install \
    bundler \
    pry \
    byebug \
    commander \
    rubocop \
    terminal-table \
    httparty
}

stage_4_shiny_precious_gems () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_shiny_precious_gems"

  pushd ${OPT_DLOADS} &> /dev/null

  # 2016-12-06: Ug. Ubuntu 14.04, why do I still use thee?
  #   $ ruby -v
  #   ruby 1.9.3p484 (2013-11-22 revision 43786) [x86_64-linux]
  #   $ ruby2.0 -v
  #   ruby 2.0.0p384 (2014-01-12) [x86_64-linux-gnu]

  if false; then
    rb22_sha256="de8e192791cb157d610c48a9a9ff6e7f19d67ce86052feae62b82e3682cc675f"
    rb22_version=2.2.6
    rb22_archive="ruby-${rb22_version}.tar.gz"
    rb22_https="https://cache.ruby-lang.org/pub/ruby/2.2/${rb22_archive}"
    #
    wget -N ${rb22_https}
    # https://help.ubuntu.com/community/HowToSHA256SUM
    if [[ $(sha256sum ${rb22_archive} | awk '{print $1}') != ${rb22_sha256} ]]; then
      echo "FATAL: SHA256 mismatch: $(sha256sum ${rb22_archive}) / expected: ${rb22_sha256}"
      exit 1
    fi
    tar xvzf ${rb22_archive}
    cd "ruby-${rb22_version}"
    ./configure
    make
    sudo make install
    #
    #cd ...
    #/bin/ln -s ...
  fi

  if false; then
    rb23_sha256="241408c8c555b258846368830a06146e4849a1d58dcaf6b14a3b6a73058115b7"
    rb23_version=2.3.3
    rb23_archive="ruby-${rb23_version}.tar.gz"
    rb23_https="https://cache.ruby-lang.org/pub/ruby/2.3/${rb23_archive}"
    #
    wget -N ${rb23_https}
    # https://help.ubuntu.com/community/HowToSHA256SUM
    if [[ $(sha256sum ${rb23_archive} | awk '{print $1}') != ${rb23_sha256} ]]; then
      echo "FATAL: SHA256 mismatch: $(sha256sum ${rb23_archive}) / expected: ${rb23_sha256}"
      exit 1
    fi
    tar xvzf ${rb23_archive}
    cd "ruby-${rb23_version}"
    ./configure
    make
    sudo make install
  fi

  # 2016-12-07: Added, then disabled. See ruby-install and chruby instead.
  if false; then
    sudo apt-add-repository ppa:brightbox/ruby-ng
    sudo apt-get update
    sudo apt-get install -y ruby2.2 ruby2.2-dev ruby2.2-doc
    sudo apt-get install -y ruby2.3 ruby2.3-dev ruby2.3-doc
  fi

  # MAYBE: Is there such a thing as a ~/.gemspec or something
  #   that installs non-project specific dev gems?

  # REVIEW: Does gem need to be called for each chruby version?

  # gem installer
  sudo gem install bundler

  # ruby-debug is good through ruby 1.9, not 2.x (2016-12-06: Currently 2.3).
  #sudo gem install ruby-debug
  # pry is an irb alternative that can kind of debug (but without step capability).
  sudo gem install pry
  # byebug seems to be the Rubyist's debugger.
  sudo gem install byebug

  # CLI framework.
  sudo gem install commander

  # Style guide checker.
  sudo gem install rubocop

  # ASCII tables.
  sudo gem install terminal-table

  sudo gem install httparty

  #ruby_install_gems ruby-1.9
  #ruby_install_gems ruby-2.2
  #ruby_install_gems ruby-2.3
  #ruby_install_gems ruby-2.3.0
  ruby_install_gems ruby-2.3.3
  ruby_install_gems ruby-2.4.0

  popd &> /dev/null

} # end: stage_4_shiny_precious_gems

stage_4_indirect_user_fonts () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_indirect_user_fonts"

  pushd ${OPT_FONTS} &> /dev/null

  if [[ ! -h ${HOME}/.fonts ]]; then
    # 2016-11-14: This seems pointless. Wasn't the point of this fcn. to do the moving?
    echo
    echo "NOTICE: ~/.fonts exists but is not symlink (to ${OPT_FONTS})"
    echo
    #echo "MAYBE: Relocate the ~/.fonts dir if you want (e.g., off SSD)"
    #echo"        or fix this fcn. to do it automatically...."
    #echo
    num_files=$(ls -1 ${OPT_FONTS} | wc -l)
    if [[ ${num_files} -eq 0 ]]; then
      rmdir ${OPT_FONTS}
      /bin/mv ${HOME}/.fonts ${OPT_FONTS}
    else
      echo
      echo "ALERT: You'll have to setup ${OPT_FONTS} yourself, if you care."
      echo -n " got it? [press any key to continue]"
      read -n 1 ignored
    fi
  fi

  if [[ ! -e ${HOME}/.fonts ]]; then
    if [[ -h ${HOME}/.fonts ]]; then
      echo "Removing and replacing dead link at: ${HOME}/.fonts"
      /bin/rm ${HOME}/.fonts
    fi
    /bin/ln -s ${OPT_FONTS} ${HOME}/.fonts
  fi

  sudo fc-cache -fv

  popd &> /dev/null

} # end: stage_4_indirect_user_fonts

stage_4_font_mania () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_font_mania"

  stage_4_indirect_user_fonts

  do_update_cache=false

  mkdir -p ${HOME}/.fonts

  pushd ${HOME}/.fonts &> /dev/null

  if [[ ! -d santos-dumont ]]; then
    wget -N http://dl.1001fonts.com/santos-dumont.zip
    # Unpack SANTO___.TTF et al
    unzip -o -d santos-dumont santos-dumont.zip
    /bin/mv santos-dumont/SANTO___.TTF .
    do_update_cache=true
  fi

  if [[ ! -d pinewood ]]; then
    wget -N http://dl.1001fonts.com/pinewood.zip
    unzip -o -d pinewood pinewood.zip
    /bin/mv pinewood/Pinewood.ttf .
    do_update_cache=true
  fi

  # Google Open Sans by Steve Matteson
  if [[ ! -d open-sans ]]; then
    wget -N http://dl.1001fonts.com/open-sans.zip
    unzip -o -d open-sans open-sans.zip
    do_update_cache=true
  fi

  popd &> /dev/null

  # Build font information cache files.
  if ${do_update_cache}; then
    sudo fc-cache -fv
  fi

} # end: stage_4_font_mania

stage_4_font_typeface_hack () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_font_typeface_hack"

  stage_4_indirect_user_fonts

  if [[ ! -e ~/.fonts/Hack-v2_010-ttf/Hack-Regular.ttf ]]; then

    pushd ${OPT_DLOADS} &> /dev/null

    wget -N https://github.com/chrissimpkins/Hack/releases/download/v2.010/Hack-v2_010-ttf.zip
    mkdir -p ~/.fonts
    # Use -f to "freshen" only those file that are newer in the archive.
    # Hrmm, -f doesn't do anything if the files don't already exist...
    if [[ ! -e ~/.fonts/Hack-v2_010-ttf ]]; then
      unzip -d ~/.fonts/Hack-v2_010-ttf Hack-v2_010-ttf.zip
    else
      unzip -f -d ~/.fonts/Hack-v2_010-ttf Hack-v2_010-ttf.zip
    fi

    popd &> /dev/null

    # Build font information cache files.
    sudo fc-cache -fv

  fi

} # end: stage_4_font_typeface_hack

stage_4_font_google_noto () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_font_google_noto"

  stage_4_indirect_user_fonts

  pushd ${OPT_DLOADS} &> /dev/null

  wget_resp=$(wget -N https://noto-website.storage.googleapis.com/pkgs/Noto-hinted.zip 2>&1)

  set +e
  echo $wget_resp | grep "no newer than.*not retrieving" > /dev/null
  exit_code=$?
  reset_errexit
  if [[ ${exit_code} -ne 0 ]]; then
    # NOTICE: ~/.fonts should be a symlink to /srv/opt/.fonts
    mkdir -p ~/.fonts
    if [[ ! -e ~/.fonts/Noto-fonts ]]; then
      # -d only works in the directory does not already exist.
      unzip -d ~/.fonts/Noto-fonts Noto-hinted.zip
    else
      # -f freshens an existing expanded archive.
      unzip -f -d ~/.fonts/Noto-fonts Noto-hinted.zip
    fi

    sudo fc-cache -fv
  fi

  popd &> /dev/null

} # end: stage_4_font_google_noto

stage_4_sqlite3 () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_sqlite3"

  pushd ${OPT_DLOADS} &> /dev/null

  # See: https://www.sqlite.org/download.html
  #SQLITE_YEAR=2015
  #SQLITE_BASE=sqlite-shell-linux-x86-3081101
  #SQLITE_BASE=sqlite-shell-linux-x86-3090200
  SQLITE_YEAR=2016
  #SQLITE_BASE=sqlite-shell-linux-x86-3100100
  SQLITE_BASE=sqlite-tools-linux-x86-3110100

  wget -N https://www.sqlite.org/${SQLITE_YEAR}/${SQLITE_BASE}.zip
  unzip -o -d ${SQLITE_BASE} ${SQLITE_BASE}.zip

  if [[ -e /usr/bin/sqlite3 ]]; then
    set +e
    diff ${SQLITE_BASE}/${SQLITE_BASE}/sqlite3 /usr/bin/sqlite3 &> /dev/null
    exit_code=$?
    reset_errexit
    if [[ ${exit_code} -ne 0 ]]; then
      sudo /bin/mv /usr/bin/sqlite3 /usr/bin/sqlite3-$(date +%Y.%m.%d-%T)
    fi
  fi

  sudo /bin/cp -ar ${SQLITE_BASE}/${SQLITE_BASE}/sqlite3 /usr/bin/sqlite3
  sudo chmod 755 /usr/bin/sqlite3
  sudo chown root:root /usr/bin/sqlite3

  # What about developer headers? Is what's in apt still okay?
  #  sudo apt-get install -y libsqlite0-dev
  # Otherwise we might want to get the source.
  # https://www.sqlite.org/2015/sqlite-amalgamation-3081101.zip

  # Here's maybe if you wanted to build from scratch rather than binary-cheat.
  if false; then
    #sudo apt-get install -y libgeos-dev
    pushd ${OPT_DLOADS} &> /dev/null
    #RELEASE_YEAR="2015"
    #SQLITE3_VER="sqlite-autoconf-3080803"
    RELEASE_YEAR="2016"
    SQLITE3_VER="sqlite-autoconf-3120200"
    wget -N https://sqlite.org/${RELEASE_YEAR}/${SQLITE3_VER}.tar.gz
    tar xzf ${SQLITE3_VER}.tar.gz
    cd ${SQLITE3_VER}
    #source ENV_PATH
    umask 002
    #./configure --enable-dynamic-extensions --prefix=...
    ./configure --enable-dynamic-extensions
    make
    #make install
    sudo make install
    popd &> /dev/null
  fi

  popd &> /dev/null

} # end: stage_4_sqlite3

state_4_mod_spatialite () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "state_4_mod_spatialite"

  if [[ -f /usr/local/lib/libspatialite.so.7.1.0 ]]; then
    echo
    echo "${REINSTALL_OR_SKIP}: Already installed: libspatialite"
    echo
    if ! ${FORCE_REINSTALL}; then
      return
    fi
  fi

  pushd ${OPT_DLOADS} &> /dev/null

  # NOTE: Skipping `apt-get install -y python-pyspatialite` (not
  #       available from the Ubuntu 12.04 repository), and skipping
  #       `pip3 install pyspatialite` (fails on missing libproj-dev, and
  #       `apt-get install libproj-dev` installs a version too old), but
  #       that doesn't matter: spatialite is best run as a SQLite extension
  #       that we can build ourselves, rather than using a shim layer.
  #
  # 2016-05-03: Does this no longer work? This used to work. Maybe
  #             it was on some other Ubuntu flavor and not Linux Mint....
  #             Anyway, this used to work:
  #         $ sudo apt-get install -y sqlite3 libsqlite3-dev spatialite-bin libspatialite5
  #         $ sqlite3
  #         sqlite> SELECT load_extension("libspatialite.so.5");
  #             But now I get
  #         Error: libspatialite.so.5.so: cannot open shared object file: No such file or directory

  # Avoid ./configure complaint: "checking for geos-config... no"
  sudo apt-get install -y libgeos-dev

  # FIXME/WHATEVER/2016-11-13: Adding this to ~/.sqliterc
  #     SELECT load_extension("/usr/local/lib/libspatialite");
  # causes
  #     Error: near line 1: /usr/local/lib/libspatialite.so: wrong ELF class: ELFCLASS64
  # So not quite sure what's up.

  # See:
  #   https://www.gaia-gis.it/fossil/libspatialite/index
  # 2015-09-07: v4.3.0a
  #LIBSPATIALITE_VERS=libspatialite-4.3.0
  LIBSPATIALITE_VER=libspatialite-4.3.0a
  LIBSPATIALITE_PKG=${LIBSPATIALITE_VER}.tar.gz
  wget -N http://www.gaia-gis.it/gaia-sins/libspatialite-sources/${LIBSPATIALITE_PKG}
  tar xvf ${LIBSPATIALITE_PKG}
  cd ${LIBSPATIALITE_VER}
  # source ENV_PATH...
  umask 002
  #./configure --enable-freexl=no --prefix=...
  #./configure --enable-freexl=no
  CFLAGS="-m64" ./configure --enable-freexl=no
  make
  sudo make install

  # 2016-11-13: Rebuilt with the -m64 flag and the library is half the size:
  #   $ ll ./src/.libs/libspatialite.so.7.1.0
  #   -rwxrwxr-x 1  me  me  7.5M Nov 13 22:12 ./src/.libs/libspatialite.so.7.1.0*
  #   $ ll /usr/local/lib/libspatialite.so.7.1.0
  #   -rwxr-xr-x 1 root root 15M Nov 12 19:16 /usr/local/lib/libspatialite.so.7.1.0*
  # But still get same ELFCLASS64 problem.
  # And this doesn't work:
  #   CFLAGS="-m32" ./configure --enable-freexl=no

  popd &> /dev/null

} # end: state_4_mod_spatialite


stage_4_opencl () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_opencl"

  echo
  echo "WARNING: Deprecated: stage_4_opencl"
  echo
  return

  pushd ${OPT_DLOADS} &> /dev/null

  #https://software.intel.com/en-us/intel-opencl

  # https://software.intel.com/en-us/articles/opencl-drivers#ubuntu64
  # https://software.intel.com/en-us/articles/intel-code-builder-for-opencl-api
  # To install both the Code Builder and the OpenCL runtime packages for Linux*, use the following public key: Intel-E901-172E-EF96-900F-B8E1-4184-D7BE-0E73-F789-186F.pub

  wget -N \
    http://registrationcenter.intel.com/irc_nas/5193/intel_code_builder_for_opencl_2015_ubuntu_5.0.0.43_x64.tgz

  # sudo apt-get install -y opencl-headers
  sudo apt-get install -y rpm alien libnuma1

  tar -xvf intel_code_builder_for_opencl_2015_ubuntu_5.0.0.43_x64.tgz
  cd intel_sdk_for_ocl_applications_2014_ubuntu_5.0.0.43_x64/

  #sudo rpm --import Intel-E901-172E-EF96-900F-B8E1-4184-D7BE-0E73-F789-186F.pub
  sudo rpm --import PUBLIC_KEY.PUB

  cd rpm

  fakeroot alien --to-deb opencl-1.2-base-5.0.0.43-1.x86_64.rpm
  fakeroot alien --to-deb opencl-1.2-intel-cpu-5.0.0.43-1.x86_64.rpm

  sudo dpkg -i opencl-1.2-base_5.0.0.43-2_amd64.deb
  sudo dpkg -i opencl-1.2-intel-cpu_5.0.0.43-2_amd64.deb

  # The above installs the library files and installable client driver
  # registration in /opt/intel/opencl-1.2-5.0.0.43.
  # Two more steps were needed to run an OpenCL program.

  # Add library to search path.
  if [[ -e /etc/ld.so.conf.d/intelOpenCL.conf ]]; then
    echo "ERROR: Unexpected: /etc/ld.so.conf.d/intelOpenCL.conf exists."
    exit 1
  fi
  # sudo nano /etc/ld.so.conf.d/intelOpenCL.conf
  # # Add the line:
  # /opt/intel/opencl-1.2-5.0.0.43/lib64
  echo "/opt/intel/opencl-1.2-5.0.0.43/lib64" | sudo tee -a /etc/ld.so.conf.d/intelOpenCL.conf

  # Link to the intel icd file in the expected location:
  sudo mkdir -p /etc/OpenCL/vendors/
  sudo ln /opt/intel/opencl-1.2-5.0.0.43/etc/intel64.icd /etc/OpenCL/vendors/intel64.icd
  sudo ldconfig

  # Now you can run an existing application. Or, if doing developmnent,
  # install the developer headers and tools.
  #  fakeroot alien --to-deb opencl-1.2-devel-3.0.67279-1.x86_64.rpm
  #  fakeroot alien --to-deb opencl-1.2-intel-devel-3.0.67279-1.x86_64.rpm
  #  sudo dpkg -i opencl-1.2-devel_3.0.67279-2_amd64.deb
  #  sudo dpkg -i opencl-1.2-intel-devel_3.0.67279-2_amd64.deb

  # Verify.
  sudo apt-get install -y clinfo
  sudo clinfo

} # end: stage_4_opencl

stage_4_darktable () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_darktable"

  # NOTE: pmjdebruijn's builds are generally the latest-greatest.
  if true; then
    #deb http://ppa.launchpad.net/pmjdebruijn/darktable-release/ubuntu trusty main
    #deb-src http://ppa.launchpad.net/pmjdebruijn/darktable-release/ubuntu trusty main
    sudo add-apt-repository -y ppa:pmjdebruijn/darktable-release
    # NOTE: To remove the repository:
    #  sudo /bin/rm /etc/apt/sources.list.d/pmjdebruijn-darktable-release-trusty.list
    #if ! ${SKIP_APT_GET_UPDATE}; then
      sudo apt-get update
    #fi
    sudo apt-get install -y darktable
  else

    # From scratch!

    if [[ -f /usr/bin/darktable ]]; then
      echo
      echo "${REINSTALL_OR_SKIP}: Already installed: darktable"
      echo
      if ! ${FORCE_REINSTALL}; then
        return
      fi
    fi

    pushd ${OPT_DLOADS} &> /dev/null

    # Download libgphoto2-2.5.8.tar.bz2 (6.9 MB).
    # http://sourceforge.net/projects/gphoto/files/latest/download?source=files
    sudo apt-get install -y gphoto2 libgphoto2-dev libgphoto2-2-dev libgphoto2-6

    sudo apt-get install -y libgtk2.0-dev libcurl4-gnutls-dev
    # libcurlpp-dev

    # wget -N https://github.com/darktable-org/darktable/archive/release-1.6.9.tar.gz
    # https://github.com/darktable-org/darktable/releases/download/release-1.6.9/darktable-1.6.9.tar.xz
    if [[ ! -d darktable ]]; then
      git clone -b release-1.6.9 git@github.com:darktable-org/darktable.git
      cd darktable
    else
      cd darktable
      git pull
    fi
    # Release build.
    ./build.sh --prefix /opt/darktable --buildtype Release
    # Debug build.
    #  ./build.sh --prefix /opt/darktable --buildtype Debug
    cd build
    sudo make install
    # Installs to: /opt/darktable/bin/darktable

    popd &> /dev/null

  fi

} # end: stage_4_darktable

stage_4_digikam_from_scratch () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_digikam_from_scratch"

  echo
  echo "WARNING: Broken install (at least in 14.04): stage_4_digikam_from_scratch"
  echo
  echo "NOTICE: 2016-02-04: Building digikam 4.14.0 does not work."
  echo "        Don't waste your time."
  echo "        Call stage_4_digikam_from_distro"
  echo "        and stage_4_digikam5_from_distro instead."
  echo
  return

  pushd ${OPT_DLOADS} &> /dev/null

  # The exiv2 on Linux Mint 17.1 is exiv2 0.23 001700 (C) 2004-2012,
  # but digikam wants 0.24+, so gotta build exiv2 from scratch, eh.
  #  sudo apt-get install -y exiv2
  #  #sudo apt-get install -y libexiv2-dev
  #  sudo apt-get install -y libkexiv2-dev
  #  sudo apt-get install -y libexiv2-12
  #  #sudo apt-get remove libexiv2-12
  # http://www.exiv2.org/download.html
  EXIV2_LATEST="exiv2-0.25"
  EXIV2_ARCHIVE="${EXIV2_LATEST}.tar.gz"
  wget -N http://www.exiv2.org/${EXIV2_ARCHIVE}
  tar -xvf ${EXIV2_ARCHIVE}
  cd ${EXIV2_LATEST}
  ./configure
  make
  sudo make install

  # Meh. There's probably a better way to disable/hide the old library.
  sudo /bin/mv /usr/lib/libexiv2.so.12 /usr/lib/libexiv2.so.12.ORIG
  sudo /bin/mv /usr/lib/libexiv2.so.12.0.0 /usr/lib/libexiv2.so.12.0.0.ORIG

  LIBRAW_LATEST="LibRaw-0.17.0"
  LIBRAW_ARCHIVE="${LIBRAW_LATEST}.tar.gz"
  wget -N http://www.libraw.org/data/${LIBRAW_ARCHIVE}
  tar -xvf ${LIBRAW_ARCHIVE}
  cd ${LIBRAW_LATEST}
  ./configure
  make
  sudo make install

  # gpsd is complicated. see build.txt
  if false; then
    sudo apt-get install -y scons
    GPSD_LATEST="gpsd-3.15"
    GPSD_ARCHIVE="${GPSD_LATEST}.tar.gz"
    wget -N http://download-mirror.savannah.gnu.org/releases/gpsd/${GPSD_ARCHIVE}
    tar -xvf ${GPSD_ARCHIVE}
    cd ${GPSD_LATEST}
    ./configure
    make
    sudo make install
  fi

  # 2015.10.22: FIXME/MEH: Cannot get marble to build at work...
  # dpkg --get-selections | grep -v deinstall
  # dpkg -l
  if true; then
    sudo apt-get install -y \
      libxslt1-dev \
      libxslt1.1 \
      libqtwebkit-dev \
      libqt5webkit5-dev \
      libqextserialport-dev \
      libquazip0-dev \
      qtmobility-dev \
      libwlocate-dev \
      libqt5svg5 \
      libqt5svg5-dev \
      qtscript5-dev \
      cmake
      #qt-sdk
      #qt5-default
    # Optional marble features.
    sudo apt-get install -y \
      libphonon-dev \
      libphonon4qt5-dev \
      phonon \
      phonon4qt5 \
      libqt5designer5 \
      libqt5designercomponents5 \
      libqt5location5 \
      libgps-dev \
      libshp-dev \
      libquazip0-dev \
      libquazip0 \
      libqextserialport-dev \
      libqextserialport1 \
      automoc
    # Whatever. Trying to build a KDE app on Mint not going so well..
    #
    # -- Could NOT find Phonon (missing:  PHONON_LIBRARY)
    # -- Could NOT find QextSerialPort (missing:  QEXTSERIALPORT_LIBRARIES)
    # -- Could NOT find quazip (missing:  QUAZIP_LIBRARIES)
    # -- checking for module 'liblocation>=0.102'
    # --   package 'liblocation>=0.102' not found
    #  * QextSerialPort , access to serial ports , <http://code.google.com/p/qextserialport/>
    #    Reading from serial port in APRS plugin
    #  * quazip , reading and writing of ZIP archives , <http://quazip.sourceforge.net/>
    #    reading and displaying .kmz files
    #  * liblocation , position information on Maemo 5 devices , <http://maemo.org/>
    #    position information via GPS/WLAN for the Nokia N900 smartphone
    #
    # cmake not finding libshp, even after this:
    #  sudo apt-get install -y libshp1 libshp-dev
    # cmake not finding libgps, even after this:
    #  sudo apt-get install -y libgps20
    #  sudo apt-get install -y libgps-dev
    #  sudo apt-get install -y libqgpsmm20
    #  sudo apt-get install -y libqgpsmm-dev
    #  sudo apt-get install -y gpsd
    # cmake not finding liblocation, even after this:
    #  sudo apt-get install -y qtlocation5-dev
    #  sudo apt-get install -y libwlocate-dev
    #  sudo apt-get install -y libqt5location5
    #  But who cares: position information via GPS/WLAN for the Nokia N900 smartphone

    # https://marble.kde.org/sources.php
    # https://github.com/KDE/marble/releases
    #git clone -b Applications/15.04 git://anongit.kde.org/marble ./marble/sources
    git clone -b Applications/15.08 git://anongit.kde.org/marble ./marble/sources
    mkdir -p ./marble/build
    cd ./marble/build
    cmake -DCMAKE_BUILD_TYPE=Debug -DQTONLY=FALSE -DCMAKE_INSTALL_PREFIX=/usr/local ../sources
    make
    sudo make install
    #LD_LIBRARY_PATH=/usr/local/lib /usr/local/bin/marble

    # make fails:
    #
    # $ make
    # ...
    # [ 50%] Building CXX object src/lib/marble/CMakeFiles/marblewidget-qt5.dir/marblewidget-qt5_automoc.cpp.o
    # Linking CXX shared library libmarblewidget-qt5.so
    # [ 50%] Built target marblewidget-qt5
    # [ 50%] Automoc for target MarbleWidgetPlugin
    # Generating moc_MarbleWidgetPlugin.cpp
    # /srv/opt/.downloads/marble/sources/src/plugins/designer/marblewidget/MarbleWidgetPlugin.h:29:
    #  Error: Undefined interface
    # AUTOMOC: error: process for
    #  /srv/opt/.downloads/marble/build/src/plugins/designer/marblewidget/moc_MarbleWidgetPlugin.cpp
    #  failed:
    # /srv/opt/.downloads/marble/sources/src/plugins/designer/marblewidget/MarbleWidgetPlugin.h:29:
    #  Error: Undefined interface
    #
    # moc failed...
    # make[2]: *** [src/plugins/designer/marblewidget/CMakeFiles/MarbleWidgetPlugin_automoc] Error 1
    # make[1]: *** [src/plugins/designer/marblewidget/CMakeFiles/MarbleWidgetPlugin_automoc.dir/all] Error 2
    # make: *** [all] Error 2
  else
    # For work laptop...
    sudo apt-get install -y libmarble-dev
    # Hrmm. Screw building marble if we can just repo it.
    sudo apt-get install -y marble
    sudo apt-get install -y marble-qt
    sudo apt-get install -y libmarble-dev
    fi

  sudo apt-get install -y \
    kde-full \
    cmake \
    qt4-qmake \
    qt5-qmake \
    kde-workspace-dev \
    kdevplatform-dev

  sudo apt-get install -y libraw-dev
  #sudo apt-get install -y libraw9

  # Too old
  #  sudo apt-get install -y libopencv-dev

  #sudo apt-get remove -y libcv-dev
  sudo apt-get install -y \
    libsane-dev \
    libqjson-dev

  sudo apt-get install -y \
    libmysql++-dev \
    libmysqld-dev \
    libboost-graph-dev \
    libpgf-dev \
    kdepimlibs5-dev \
    liblensfun-dev \
    libeigen3-dev \
    gphoto2 libgphoto2-dev libgphoto2-2-dev libgphoto2-6 \
    baloo baloo-dev baloo4 libbaloowidgets-dev \
    libsqlite0-dev \
    doxygen
  #sudo apt-get install -y libmysqlclient-dev

  sudo apt-get install -y libmysql++3 mysql-common mysql-client mysql-server

  # Open Source Computer Vision (and machine learning software library).
  # http://opencv.org/
  # https://github.com/Itseez/opencv/releases
  #OPENCV_LATEST="3.0.0"
  OPENCV_LATEST="2.4.11"
  OPENCV_BUILD="opencv-${OPENCV_LATEST}"
  OPENCV_ARCHIVE="${OPENCV_BUILD}.zip"
  wget -O ${OPENCV_ARCHIVE} https://github.com/Itseez/opencv/archive/${OPENCV_LATEST}.zip
  unzip -d ${OPENCV_BUILD} ${OPENCV_ARCHIVE}
  mkdir ${OPENCV_BUILD}/${OPENCV_BUILD}/release
  cd ${OPENCV_BUILD}/${OPENCV_BUILD}/release
  cmake -D CMAKE_BUILD_TYPE=RELEASE -D CMAKE_INSTALL_PREFIX=/usr/local ..
  make
  sudo make install

  #sudo apt-get install -y \
  #  qt4-default qt4-dev-tools qt4-qmake qt4-qtconfig \
  #  libqt4-opengl \
  #  libqt4-dev-bin \
  #  libqt4-dev

  sudo apt-get install -y \
    libqca2-dev \
    libqtgstreamer-dev \
    libgpod-dev \
    libkdcraw-dev
    # Not the packages I thought would work, but these are
    # for optional digikam features so whatever.
    # libgphoto2-dev
    # libgphoto2-2-dev
    # baloo-dev
    # libhupnp-dev
    # libbaloowidgets-dev
    # libqtsolutions-soap-2.7-1

echo
echo "FIXME: On work laptop: Add include path to ./bootstrap.linux"
echo
# Add to ./bootstrap.linux:
#  -DQT_QT_INCLUDE_DIR=/usr/include/qt4 \

  # cdd ${OPT_DLOADS}
  # http://download.kde.org/stable/digikam
  #DIGIKAM_LATEST="digikam-4.12.0"
  #DIGIKAM_LATEST="digikam-4.13.0"
  # 2016.02.04: Tried compiling 4.14.0 but ./bootstrap.linxux dies.
  #  Apparently, libkdcraw, libkexiv2, libkipi, etc. are no longer
  #  packed in the source but should be grabbed from KDE directly.
  #  I tried, e.g., 'sudo apt-get install libkdcraw-dev', but the
  #  bootstrap.linux still failed. I tried other tricks, too, until
  #  I finally got getting 4.14 from the philip5 ppa working.
  DIGIKAM_LATEST="digikam-4.14.0"
echo
echo "FIXME: Unable to successfully build digikam-4.14.0 on Linux Mint 17.1 Rebecca Ubuntu trusty 14.04."
echo

  DIGIKAM_ARCHIVE="${DIGIKAM_LATEST}.tar.bz2"
  wget -N http://download.kde.org/stable/digikam/${DIGIKAM_ARCHIVE}
  tar -xvjf ${DIGIKAM_ARCHIVE}
  cd ${DIGIKAM_LATEST}
#kde4-config --prefix
## /usr
  ./bootstrap.linux
  cd build
  #cmake -DCMAKE_BUILD_TYPE=debugfull -DCMAKE_INSTALL_PREFIX=`kde4-config --prefix` ..
  make
  sudo make install

  popd &> /dev/null

} # end: stage_4_digikam_from_scratch

stage_4_digikam_from_distro () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_digikam_from_distro"

  echo
  echo "WARNING: Deprecated: stage_4_digikam_from_distro"
  echo
  return

  # 2016.03.24: 4.12.0 is on 15.10.
  #             So the backport code is just for Mint 17.x.
  #
  # Load the release codename, e.g., raring, trusty, wily, etc.
  source /etc/lsb-release
  if [[ ${DISTRIB_CODENAME} = 'trusty' || ${DISTRIB_CODENAME} = 'rebecca' ]]; then

    # 2016.02.06: Now I cannot get the new 4.14.0 to build at home, so ppa'ing.
    # 2015.10.22: Argh. I got digikam to build at home, but at work, 'snot working.
    # Install digikam 4.0.0:
    #  sudo apt-get install digikam

    # Linux Mint 17.1 "rebecca" is Ubuntu 14.04 "trusty".

    sudo add-apt-repository -y ppa:philip5/extra
    # [lb] not sure why we need kubuntu-backports but without it apt-install
    # fails and not with a really good explanation.
    sudo add-apt-repository ppa:philip5/kubuntu-backports
    #sudo add-apt-repository ppa:kubuntu-ppa/backports
    # NOTE: To remove the repositories:
    #  sudo /bin/rm /etc/apt/sources.list.d/philip5-extra-trusty.list
    #  sudo /bin/rm /etc/apt/sources.list.d/philip5-kubuntu-backports-trusty.list
    #  #sudo /bin/rm /etc/apt/sources.list.d/kubuntu-ppa-backports-trusty.list
    #if ! ${SKIP_APT_GET_UPDATE}; then
      sudo apt-get update
    #fi

    # Check the version we want is there:
    #
    #   apt-cache show digikam

    # If you look at the policy, aptitude favors the normals repos:
    #
    #   apt-cache policy digikam
    #
    # so we have to tell it otherwise.

    # WHATEVER: I thought there was a way to tell aptitude which repo/ppa to
    #           use, but none of these worked:
    #   sudo apt-get install -t ppa:philip5/extra digikam
    #   sudo apt-get install digikam/extra
    #   sudo apt-get install digikam/philip5-extra

    if [[ ! -e /etc/apt/preferences.d/philip5-extra-ppa ]]; then
      echo 'CODE: SELECT ALL
  Package: *
  Pin: release o=LP-PPA-philip5-extra
  Pin-Priority: 700
  ' | sudo tee /etc/apt/preferences.d/philip5-extra-ppa
    fi

    if [[ ! -e /etc/apt/preferences.d/philip5-kubuntu-backports-ppa ]]; then
      echo 'CODE: SELECT ALL
  Package: *
  Pin: release o=LP-PPA-philip5-kubuntu-backports
  Pin-Priority: 700
  ' | sudo tee /etc/apt/preferences.d/philip5-kubuntu-backports-ppa
    fi

    # And then check your work again:
    #
    #   apt-cache policy digikam

  fi

  sudo apt-get install -y digikam
  #sudo apt-get install -y showfoto

} # end: stage_4_digikam_from_distro

stage_4_digikam5_from_distro () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_digikam5_from_distro"

  echo
  echo "FIXME: doesn't work on trusty: stage_4_digikam5_from_distro"
  echo
  return

  set +e
  command -v digikam5
  exit_code=$?
  reset_errexit
  if [[ ${exit_code} -eq 0 ]]; then
    echo
    echo "${REINSTALL_OR_SKIP}: Already installed: \`digikam5\` command"
    echo
    if ! ${FORCE_REINSTALL}; then
      return
    fi
  fi

  sudo apt-add-repository ppa:philip5/extra
  #if ! ${SKIP_APT_GET_UPDATE}; then
    sudo apt-get update
  #fi
  sudo apt-get install -y digikam5

# Not supported on trusty/14.04!
# digikam5  4:5.1.0-xenial~ppa1  Philip Johnsson (2016-08-09)
# digikam5  4:5.1.0-wily~ppa1

} # end: stage_4_digikam5_from_distro

stage_4_digikam_install_appimage () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_digikam_install_appimage"

  pushd ${OPT_DLOADS} &> /dev/null

  wget -N https://download.kde.org/stable/digikam/digikam-5.5.0-01-x86-64.appimage

  cd ${OPT_BIN}

  # 2017-05-20: Ubuntu 14.04:
  #   $ digikam --version
  #   Qt: 4.8.6
  #   KDE Development Platform: 4.14.2
  #   digiKam: 4.14.0

  /bin/ln -s ${OPT_DLOADS}/digikam-5.5.0-01-x86-64.appimage digikam5

  # $ digikam5 &
  # -- Use 'help' as CLI argument to know all available options
  #
  # Dialog:
  #
  #   Would you like to integrate
  #     /path/to/digikam-5.5.0-01-x86-64.appimage
  #   with your system?
  #
  #   This will add it to your applications menu and install icons.
  #   If you don't do this you can still launch the application by
  #   double-clicking on the AppImage.
  #
  # Dialog:
  #
  #   Should this question be permanently disabled for digiKam?
  #
  #   To re-enable this question you have to delete
  #
  # "/${HOME}/.local/share/appimagekit/digiKam_no_desktopintegration"
  #
  # I declined and will just background it instead.
  # Though maybe I should have for the appbar...
  #
  # Backgrounding digikim5::
  #
  #   digikim5 > /dev/null 2>&1 &

  # Setup suggests storing SQLite db on SSD.

  popd &> /dev/null

} # end: stage_4_digikam_install_appimage

stage_4_gimp_plugins () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_gimp_plugins"

  # GIMP Export Layers to Directory as PNGs
  #   http://registry.gimp.org/node/28268
  #   https://github.com/khalim19/gimp-plugin-export-layers

  pushd ${OPT_DLOADS} &> /dev/null

  if [[ -e gimp-plugin-export-layers ]]; then
    echo
    echo "${REINSTALL_OR_SKIP}: Already installed: ${OPT_DLOADS}/gimp-plugin-export-layers"
    echo
    if ! ${FORCE_REINSTALL}; then
      return
    fi
  fi

  if [[ ! -d ${HOME}/.gimp-2.8/plug-ins ]]; then
    echo
    echo "=============================================="
    echo "WARNING: Not Found: ${HOME}/.gimp-2.8/plug-ins"
    echo "=============================================="
    echo
    # 2016-11-12: Does this ever happen? Maybe on a new version of Gimp....
    exit 1
    # FIXME/TESTME: This happens if you haven't run gimp ever...
    #               So can we just create the directory?
    mkdir -p ${HOME}/.gimp-2.8/plug-ins
  fi

  if [[ ! -d gimp-plugin-export-layers ]]; then
    git clone https://github.com/khalim19/gimp-plugin-export-layers.git
    cd gimp-plugin-export-layers
  else
    cd gimp-plugin-export-layers
    git pull
  fi
  /bin/cp -a export_layers.py ${HOME}/.gimp-2.8/plug-ins/
  /bin/cp -ar export_layers ${HOME}/.gimp-2.8/plug-ins/

  popd &> /dev/null

} # end: stage_4_gimp_plugins

stage_4_gimp_docs () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_gimp_docs"

  # GIMP docs.
  /bin/mkdir -p ${OPT_DOCS}/gimp
  pushd ${OPT_DOCS}/gimp &> /dev/null

  wget -N http://docs.gimp.org/2.8/quickreference/gimp-keys-en.pdf

  # Bah, why no PDF of the help for 2.8?
  # http://docs.gimp.org/2.8/en/
  wget -N http://docs.gimp.org/2.4/pdf/en.pdf

  # From 31 Aug 2014:
  wget -N http://gimp.linux.it/www/meta/gimp-en.pdf

  # From 1999:
  #  wget -N ftp://ftp.ccsf.edu/pub/Util/gimp-User_Manual.pdf

  popd &> /dev/null

} # end: stage_4_gimp_docs

stage_4_python_source () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_python_source"

  pushd ${OPT_DLOADS} &> /dev/null

  if [[ ! -d ${OPT_SRC}/Python-2.7.10 ]]; then
    cd ${OPT_DLOADS}
    wget -N https://www.python.org/ftp/python/2.7.10/Python-2.7.10.tgz
    cd ${OPT_SRC}
    tar xvzf ${OPT_DLOADS}/Python-2.7.10.tgz
  fi

  if [[ ! -d ${OPT_SRC}/Python-3.3.6 ]]; then
    cd ${OPT_DLOADS}
    wget -N https://www.python.org/ftp/python/3.3.6/Python-3.3.6.tgz
    cd ${OPT_SRC}
    tar xvzf ${OPT_DLOADS}/Python-3.3.6.tgz
  fi

  if [[ ! -d ${OPT_SRC}/Python-3.4.3 ]]; then
    cd ${OPT_DLOADS}
    wget -N https://www.python.org/ftp/python/3.4.3/Python-3.4.3.tgz
    cd ${OPT_SRC}
    tar xvzf ${OPT_DLOADS}/Python-3.4.3.tgz
  fi

  popd &> /dev/null

} # end: stage_4_python_source

stage_4_funstuff () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "A bore: stage_4_funstuff"

  if false; then

    # 2015.07.30: Old Notes. Thought I had Euchre working at some point.
    #
    # http://downloads.sourceforge.net/project/euchre/euchre/euchre-0.8/euchre-0.8.tar.gz
    # sudo apt-get install libgtk2.0-dev
    # ./configure
    # make
    # make install
    #
    # Game.cpp: In member function ‘virtual void Game::run()’:
    # Game.cpp:63:71: error: cast from ‘gpointer {aka void*}’ to ‘unsigned int’ loses precision [-fpermissive]
    #      Event ev = (Event) (unsigned int) g_slist_nth_data(itsEventList, 0);
    #     Event ev = (Event) (unsigned long) g_slist_nth_data(itsEventList, 0);
    :

  fi

} # end: stage_4_funstuff

stage_4_updatedb_locate_conf () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "Noop: stage_4_updatedb_locate_conf"

  # FIXME: See /etc/updatedb.conf
  #
  # See: ~/.waffle/dev/${HOSTNAME}/etc
  #  I wonder where the appropriate place to do this is...
  #  maybe a custom_setup.private.$HOSTNAME.sh type file.
  #
  # Exclude backup drives, e.g.,
  # PRUNEPATHS="/tmp /var/spool /home/.ecryptfs /media/${USER}/thingy
  :

} # end: stage_4_updatedb_locate_conf

stage_4_python_35 () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_python_35"

  # Only do this for machines without python3.5.
  set +e
  command -v python3.5 &> /dev/null
  exit_code=$?
  reset_errexit
  if [[ ${exit_code} -eq 0 ]]; then
    echo
    echo "${REINSTALL_OR_SKIP}: Already installed: python3.5"
    echo
    if ! ${FORCE_REINSTALL}; then
      return
    fi
  fi
  # And not if better than py3.5, either.
  py3_minor_vers=$(python3 --version | /bin/sed -r 's/^Python 3\.([0-9]+)\.[0-9]+$/\1/')
  if [[ ${py3_minor_vers} -ge 5 ]]; then
    echo
    echo "${REINSTALL_OR_SKIP}: Already installed: python3.5 or better"
    echo
    if ! ${FORCE_REINSTALL}; then
      return
    fi
  fi

  sudo add-apt-repository -y ppa:fkrull/deadsnakes
  #if ! ${SKIP_APT_GET_UPDATE}; then
    sudo apt-get update -y
  #fi
  sudo apt-get install -y python3.5
  # 2016-11-28: Yas:
  sudo apt-get install -y python3.5-dev
  # 2016-11-28: So obscure. I accidentally ran `less.bashrc-client` [sans space]
  # and got a "No module named '_gdbm'". This, after upgrading to deadsnakes 3.5.
  # -- Because Bash's "command not found" handler is a Python script.
  # FIXME/MAYBE: What other libraries am I missing? I tried installing all
  #              the python3-* libraries from setup_ubuntu.sh but none of
  #              them matched. So far just -dev and -gdbm.
  #              I really should've thought twice about trying to override
  #              the distro's preferred Python installation...
  sudo apt-get install -y python3.5-gdbm

  # Bump!
  # 2016-11-28: Just doing this on 14.04, which uses 3.4.
  if [[ $(readlink -f /usr/bin/python3) == "/usr/bin/python3.4" ]]; then
    sudo /bin/ln -sf /usr/bin/python3.5 /usr/bin/python3
  fi

} # end: stage_4_python_35

stage_4_garmin_software () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_garmin_software"

  # $ apt-cache show qlandkartegt-garmin
  # N: Can't select versions from package 'qlandkartegt-garmin' as it is purely virtual
  # N: No packages found
  # # But $? is 0!
  #
  # $ apt-cache show you-never-heard-of-this
  # N: Unable to locate package you-never-heard-of-this
  # E: No packages found
  # # And $? is 100.
  #
  # Argh, apt-cache show prints to stderr but redirection isn't working.
  # $ apt-cache show qlandkartegt-garmin 2>&1 | grep No

  #sudo apt-get install -y qlandkartegt qlandkartegt-garmin
  sudo apt-get install -y qlandkartegt

  # For Garmin Connect to work in a Windows 10 VirtualBox.

  sudo apt-get install -y gnome-system-tools

  # NOTE: You can probably run Connect via wine, but I never
  #       use wine, so I can't vouch for wine.

  echo
  echo "###################################################################"
  echo
  echo "FOLLOW UP: See 'Windows 10 VirtualBox Setup' for setting up Garmin software."
  echo
  echo "###################################################################"
  echo

} # end: stage_4_garmin_software

stage_4_android_studio () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_android_studio"

  pushd ${OPT_DLOADS} &> /dev/null

  # For Kernel Virtual Machine (KVM).
  sudo apt-get install -y qemu-kvm libvirt-bin bridge-utils virt-manager
  set +e
  groups | grep libvirtd &> /dev/null
  exit_code=$?
  reset_errexit
  if [[ ${exit_code} -ne 0 ]]; then
    sudo adduser ${USER} libvirtd
    echo
    echo "ALERT: You have to logoff and log back in to enable Android Studio KVM."
    echo
  fi

  # https://developer.android.com/sdk/index.html#downloads

  # 2016-04-22: Version 2.0.0.20 / 278 MB
  #ANDROID_STUDIO_VERS="2.0.0.20"
  #ANDROID_STUDIO_BUILD="143.2739321"
  # 2016-07-23: 2.2.0.5 / XXX MB
  #ANDROID_STUDIO_VERS="2.2.0.5"
  #ANDROID_STUDIO_BUILD="145.3070098"
  ANDROID_STUDIO_VERS="2.2.2.0"
  ANDROID_STUDIO_BUILD="145.3360264"

  ANDROID_STUDIO_BASE="android-studio-ide-${ANDROID_STUDIO_BUILD}-linux"
  ANDROID_STUDIO_NAME="${ANDROID_STUDIO_BASE}.zip"

  if [[ -f ${ANDROID_STUDIO_NAME} ]]; then
    echo
    echo "${REINSTALL_OR_SKIP}: Already downloaded: ${ANDROID_STUDIO_NAME}"
    echo
    if ! ${FORCE_REINSTALL}; then
      return
    fi
  fi

  # $ lS
  # rmrm android-studio-ide-141.2456560-linux.zip
  # hrmmm... should i automate /bin/rm?
  OLD_DLS=($(\
    /bin/ls -1 android-studio-ide-*-linux.zip 2> /dev/null \
      | /bin/sed -r "s/${ANDROID_STUDIO_NAME}//g" \
  ))
  # /bin/rm stderrs on empty lines:
  #  echo ${OLD_DLS[@]} | xargs /bin/rm
  for old_file in ${OLD_DLS[@]}; do
    #echo "old_file: ${old_file}"
    if [[ -n "${old_file}" ]]; then
      /bin/rm "${old_file}"
      old_unpacked=$(dirname -- "${old_file}")
      if [[ -d ${old_unpacked} ]]; then
        echo "Removing old_unpacked: ${old_unpacked}"
        /bin/rm -rf ${old_unpacked}
      fi
    fi
  done

  wget -N \
    "https://dl.google.com/dl/android/studio/ide-zips/${ANDROID_STUDIO_VERS}/${ANDROID_STUDIO_NAME}"

  # https://developer.android.com/sdk/installing/index.html

  # Android Studio needs Java 1.8 or better.
  #
  #   $ javac -version
  #   javac 1.7.0_95

  # Android Studio warns about using OpenJDK, which is this:
  #
  #   $ sudo apt-get install -y gcj-4.8-jdk
  #
  # and also the open source java is probably installed:
  #
  #   $ java -version
  #   java version "1.7.0_95"
  #   OpenJDK Runtime Environment (IcedTea 2.6.4) (7u95-2.6.4-0ubuntu0.14.04.2)
  #   OpenJDK 64-Bit Server VM (build 24.95-b01, mixed mode)
  #
  # So remove OpenJDK,
  # and install the <cough> *proper* proprietary Java from Oracle.
  set +e
  java -version 2>&1 | grep OpenJDK &> /dev/null
  exit_code=$?
  reset_errexit
  if [[ ${exit_code} -eq 0 ]]; then
    sudo apt-get purge -y openjdk-\*
    # Make sure the new java comes first in your PATH, else:
    #   $ java -version
    #   java version "1.5.0"
    #   gij (GNU libgcj) version 4.8.4
    #   $ dpkg -S /usr/bin/gij-4.8
    #   gcj-4.8-jre-headless: /usr/bin/gij-4.8
  fi

  # Argh, you have to sign a EULA; use a browser to download the JDK...
  # 2016-12-03: Latest link:
  #  http://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html
  #  http://download.oracle.com/otn-pub/java/jdk/8u111-b14/jdk-8u111-linux-x64.tar.gz
  if false; then

    #JAVA_SE_DEV_KIT_VERS="8u91"
    #JAVA_SE_DEV_KIT_NAME="jdk-${JAVA_SE_DEV_KIT_VERS}-linux-x64.tar.gz"
    #JAVA_SE_DEV_DIR_NAME="jdk1.8.0_91"

    JAVA_SE_OLD_DIR_NAME=()
    JAVA_SE_OLD_DIR_NAME+=("jdk1.8.0_91")
    JAVA_SE_OLD_DIR_NAME+=("jdk1.8.0_101")
    JAVA_SE_OLD_DIR_NAME+=("jdk1.8.0_111")

    JAVA_SE_DEV_KIT_VERS="8u111"
    JAVA_SE_DEV_KIT_NAME="jdk-${JAVA_SE_DEV_KIT_VERS}-linux-x64.tar.gz"
    JAVA_SE_DEV_DIR_NAME="jdk1.8.0_111"

    JAVA_SE_DEV_KIT_PATH="http://download.oracle.com/otn-pub/java/jdk/${JAVA_SE_DEV_KIT_VERS}-b14/${JAVA_SE_DEV_KIT_NAME}"

    wget -N ${JAVA_SE_DEV_KIT_PATH}

    # DEVs: Download from web: Oracle Java Downloads:
    #
    #   http://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html
    #
    # ===================
    # Then continue here:
    # ===================

    pushd ${OPT_BIN} &> /dev/null
    for ((i = 0; i < ${#JAVA_SE_OLD_DIR_NAME[@]}; i++)); do
      OLD_JDK="${JAVA_SE_OLD_DIR_NAME[$i]}"
      #echo "OLD_JDK: ${OLD_JDK}"
      /bin/rm -rf ${OLD_JDK}
    done
    popd &> /dev/null

    pushd ${OPT_DLOADS} &> /dev/null
    /bin/mv ~/Downloads/jdk-${JAVA_SE_DEV_KIT_VERS}-linux-x64.tar.gz .
    tar xvzf jdk-${JAVA_SE_DEV_KIT_VERS}-linux-x64.tar.gz
    /bin/mv ${JAVA_SE_DEV_DIR_NAME} ${OPT_BIN}
    popd &> /dev/null

    pushd ${OPT_BIN} &> /dev/null
    if [[ -h jdk ]]; then
      /bin/rm jdk
    fi
    /bin/ln -sf ${JAVA_SE_DEV_DIR_NAME} jdk
    popd &> /dev/null

    #grep "[:\"]\/usr\/local\/games[:\"]" /etc/environment &> /dev/null
    set +e
    grep "^JAVA_HOME=${OPT_BIN}/jdk$" /etc/environment &> /dev/null
    exit_code=$?
    reset_errexit
    if [[ ${exit_code} -ne 0 ]]; then
      echo "JAVA_HOME=${OPT_BIN}/jdk
JRE_HOME=\$JAVA_HOME/jre
PATH=\$PATH:\$JAVA_HOME/bin:\$JRE_HOME/bin
export JAVA_HOME
export JRE_HOME
export PATH" | sudo tee -a /etc/environment
    else
      echo
      echo "ALERT: /etc/environment probably already up to date."
      echo
    fi
  else
    if false; then
      # From:
      #  https://www.atlantic.net/community/howto/install-java-ubuntu-14-04/
      sudo apt-get install -y python-software-properties
      sudo add-apt-repository -y ppa:webupd8team/java
      #if ! ${SKIP_APT_GET_UPDATE}; then
        sudo apt-get update
      #fi
# FIXME/2016-09-15: I just ran this to update Firefox's plugin. Should this just be in package list?
      sudo apt-get install oracle-java8-installer
# 2016-09-15: To get southpark.cc.com's flash player to work...
# sudo apt-get install hal-info
# cd ~/.adobe/Flash_Player
# /bin/rm -rf NativeCache AssetCache APSPrivateData2
      # If you have multiple versions of Java installed on your server,
      # then you have the ability to select a default version.
      # Check your alternatives with the following command:
      #   sudo update-alternatives --config java
      # Also something about:
      #   sudo nano /etc/environment
      #   JAVA_HOME="/usr/lib/jvm/java-8-oracle"
      #   source /etc/environment
      #   echo $JAVA_HOME
    else
      echo
      echo "################################################################"
      echo
      echo "WARNING: Please install Oracle JDK yourself."
      echo
      echo "Try: http://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html"
      echo "     or thereabouts"
      echo
      echo "MAYBE: Fix this script. Is there an oracle repo we can apt-get from?"
      echo
      echo "################################################################"
      echo
    fi
  fi

  # 2017-02-03: See IcedTea, an OpenJDK "build harness".
  #   http://icedtea.classpath.org/wiki/Main_Page

  # MAYBE: Download Oracle Java JDK/JRE Documentation
  # http://www.oracle.com/technetwork/java/javase/documentation/java-se-7-doc-download-435117.html
  # jdk-7u40-apidocs.zip

  # Android Studio install docs say to install the following libraries.
  sudo apt-get install -y lib32z1 lib32ncurses5 lib32bz2-1.0 lib32stdc++6

  pushd ${OPT_DLOADS} &> /dev/null
  UNPACK_PATH="${OPT_BIN}/${ANDROID_STUDIO_BASE}"
  if [[ ! -e ${UNPACK_PATH} ]]; then
    #unzip -d ${UNPACK_PATH} ${ANDROID_STUDIO_NAME}
    if [[ ! -e "android-studio" ]]; then
      unzip ${ANDROID_STUDIO_NAME}
      /bin/mv "android-studio" ${UNPACK_PATH}
    else
      echo
      echo "WARNING: Path exists. Remove it you'self."
      echo
      echo "         /bin/rm -rf ${OPT_DLOADS}/android-studio"
      echo
    fi
  else
    echo
    echo "WARNING: Path exists. Remove it you'self. If you want a do over."
    echo
    echo "         /bin/rm -rf ${UNPACK_PATH}"
    echo
  fi
  popd &> /dev/null

  pushd ${OPT_BIN} &> /dev/null
  if [[ -h ${OPT_BIN}/android-studio ]]; then
    /bin/rm ${OPT_BIN}/android-studio
  fi
  #/bin/ln -s ${UNPACK_PATH} ${OPT_BIN}/android-studio-ide-2.x-linux
  #/bin/ln -s ${UNPACK_PATH} ${OPT_BIN}/android-studio-ide-linux
  #/bin/ln -s ${UNPACK_PATH} ${OPT_BIN}/android-studio-ide
  /bin/ln -s ${ANDROID_STUDIO_BASE} ${OPT_BIN}/android-studio
  popd &> /dev/null

  popd &> /dev/null

  # Then run
  # $ studio.sh &
  /bin/mkdir -p ${OPT_BIN}/android-sdk

  # For lots more notes, see docacks/the_knowledge/Android_Development.rst

  stage_curtains "stage_4_android_studio"

echo "NEXT STEPS:
Run studio &
File > Settings... (Ctrl+Alt+S)
Settings -> Appearance & Behavior -> System Settings -> Android SDK
Check box of latest SDK. Apply. [Download commences.]
"

} # end: stage_4_android_studio

stage_4_zoneminder () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_zoneminder"

  if [[ -f /etc/init.d/zoneminder ]]; then
    echo
    echo "${REINSTALL_OR_SKIP}: Already installed: zoneminder"
    echo
    if ! ${FORCE_REINSTALL}; then
      return
    fi
  fi

  #pushd ${OPT_DLOADS} &> /dev/null

  sudo add-apt-repository -y ppa:iconnor/zoneminder
  # NOTE: To remove the repository:
  #  sudo /bin/rm /etc/apt/sources.list.d/iconnor-zoneminder-trusty.list

  sudo apt-get install -y zoneminder

  #popd &> /dev/null

} # end: stage_4_zoneminder

stage_4_google_drive_drive () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_google_drive_drive"

  set +e
  command -v drive
  exit_code=$?
  reset_errexit
  if [[ ${exit_code} -eq 0 ]]; then
    echo
    echo "${REINSTALL_OR_SKIP}: Already installed: Google Drive \`drive\` command"
    echo
    if ! ${FORCE_REINSTALL}; then
      return
    fi
  fi

  # https://github.com/odeke-em/drive

  # http://www.howtogeek.com/196635/
  #  an-official-google-drive-for-linux-is-here-sort-of-maybe-this-is-all-well-ever-get/

  # Skip:
  #  sudo apt-get install golang
  # you'll want to install manually instead (repo version is 1.2.1).

  pushd ${OPT_DLOADS} &> /dev/null

  # FIXME/EXPLAIN/2016-11-12: I don't think I use this github repo.
  if [[ ! -d drive ]]; then
    git clone https://github.com/odeke-em/drive
  else
    cd drive
    git pull
  fi

  # FIRST ATTEMPT
  #
  # $ go get -u github.com/odeke-em/drive/cmd/drive
  # package github.com/odeke-em/drive/cmd/drive: cannot download, $GOPATH not set.
  #  For more details see: go help gopath
  # Add to bashrc:
  #  export GOPATH=${HOME}/.gopath
  #  #export PATH=${PATH}:${GOPATH}:${GOPATH}/bin
  #  path_add_part "${GOPATH}"
  #  path_add_part "${GOPATH}/bin"

  # SECOND ATTEMPT
  #
  # $ go get -u github.com/odeke-em/drive/cmd/drive
  # # golang.org/x/sys/unix
  # src/golang.org/x/sys/unix/syscall_solaris.go:38: clen redeclared in this block
  #   previous declaration at src/golang.org/x/sys/unix/syscall_linux.go:817
  # src/golang.org/x/sys/unix/syscall_solaris.go:51: ParseDirent redeclared in this block
  #   previous declaration at src/golang.org/x/sys/unix/syscall_linux.go:830
  # src/golang.org/x/sys/unix/syscall_solaris.go:77: Pipe redeclared in this block
  #   previous declaration at src/golang.org/x/sys/unix/syscall_linux_amd64.go:110
  # src/golang.org/x/sys/unix/syscall_solaris.go:89: (*SockaddrInet4).sockaddr redeclared in this block
  #   previous declaration at src/golang.org/x/sys/unix/syscall_linux.go:311
  # src/golang.org/x/sys/unix/syscall_solaris.go:103: (*SockaddrInet6).sockaddr redeclared in this block
  #   previous declaration at src/golang.org/x/sys/unix/syscall_linux.go:325
  # src/golang.org/x/sys/unix/syscall_solaris.go:118: (*SockaddrUnix).sockaddr redeclared in this block
  #   previous declaration at src/golang.org/x/sys/unix/syscall_linux.go:340
  # src/golang.org/x/sys/unix/syscall_solaris.go:144: Getsockname redeclared in this block
  #   previous declaration at src/golang.org/x/sys/unix/syscall_linux.go:525
  # src/golang.org/x/sys/unix/syscall_solaris.go:153: ImplementsGetwd redeclared in this block
  #   previous declaration at src/golang.org/x/sys/unix/syscall_linux.go:184
  # src/golang.org/x/sys/unix/syscall_solaris.go:157: Getwd redeclared in this block
  #   previous declaration at src/golang.org/x/sys/unix/syscall_linux.go:188
  # src/golang.org/x/sys/unix/syscall_solaris.go:178: Getgroups redeclared in this block
  #   previous declaration at src/golang.org/x/sys/unix/syscall_linux.go:201
  # src/golang.org/x/sys/unix/syscall_solaris.go:178: too many errors
  # # golang.org/x/net/context/ctxhttp
  # src/golang.org/x/net/context/ctxhttp/ctxhttp_pre17.go:36: req.Cancel undefined
  #  (type *http.Request has no field or method Cancel)

  # $ go version
  # go version go1.2.1 linux/amd64
  wget -N https://storage.googleapis.com/golang/go1.6.2.linux-amd64.tar.gz
  # Add to bashrc:
  #  #export PATH=$PATH:/usr/local/go/bin
  #  path_add_part "/usr/local/go/bin"
  sudo tar -C /usr/local -xzf go1.6.2.linux-amd64.tar.gz

  # THIRD ATTEMPT
  #
  # CAUTION: This command runs silently for a half minute or so. Be patient.
  go get -u github.com/odeke-em/drive/cmd/drive

  # SWEET! Finally. Installed.

  #mkdir /jus/bkups/bkup-google.drive
  if [[ -d /jus/bkups ]]; then
    echo
    echo "ALERT: Mandatory User Interaction Required"
    echo
    drive init /jus/bkups/bkup-google.drive
  else
    echo
    echo "WHATEVER: Pick a spot for dumb google drive and init it, e.g.,:"
    echo
    echo "          git init /path/to/my/drive"
    echo
  fi

  # Visit this URL to get an authorization code
  # https://accounts.google.com/o/oauth2/auth?...
  # Paste the authorization code: ...

  # If I ever cared to de-init (perhaps after syncing on laptop, say):
  #  drive deinit [--no-prompt]

  # For all the gory:
  #  https://github.com/odeke-em/drive#usage

  __interesting_commands_="

  cd /path/to/bkup-google.drive

  drive list

  drive quota

  drive pull
  #drive push

  drive pull -fix-clashes
  drive pull

  drive trash|untrash|emptytrash|delete
  "

  # ARGH: The `drive pull` features links to google docs (.desktop files)
  # but doesn't backup docs files -- AFAIK I gotta do that manually....

  popd &> /dev/null

} # end: stage_4_google_drive_drive

stage_4_td_ameritrade_thinkorswim () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_td_ameritrade_thinkorswim"

  if [[ -f ${HOME}/thinkorswim/thinkorswim ]]; then
    echo
    echo "${REINSTALL_OR_SKIP}: Already installed: thinkorswim"
    echo
    if ! ${FORCE_REINSTALL}; then
      return
    fi
  fi

  pushd ${OPT_DLOADS} &> /dev/null

  sudo apt-add-repository -y ppa:webupd8team/java
  #if ! ${SKIP_APT_GET_UPDATE}; then
    sudo apt-get update -y
  #fi
  sudo apt-get install -y oracle-java7-installer

  wget -N http://mediaserver.thinkorswim.com/installer/InstFiles/thinkorswim_installer.sh

  echo
  echo "ALERT: Mandatory User Interaction Required"
  echo
  sh ./thinkorswim_installer.sh

  popd &> /dev/null

} # end: stage_4_td_ameritrade_thinkorswim

stage_4_optipng () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_optipng"

  set +e
  command -v optipng
  exit_code=$?
  reset_errexit
  if [[ ${exit_code} -eq 0 ]]; then
    echo
    echo "${REINSTALL_OR_SKIP}: Already installed: \`optipng\` command"
    echo
    if ! ${FORCE_REINSTALL}; then
      return
    fi
  fi

  pushd ${OPT_DLOADS} &> /dev/null

  wget -N http://downloads.sourceforge.net/project/optipng/OptiPNG/optipng-0.7.6/optipng-0.7.6.tar.gz

  tar -xvzf optipng-0.7.6.tar.gz
  cd optipng-0.7.6
  ./configure
  make
  make test
  sudo make install

  # optipng -h

  popd &> /dev/null

} # end: stage_4_optipng

# *** Password Store and lots of subcomponents.

stage_4_setup_gnupg_public_key () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_setup_gnupg_public_key"

  # https://www.gnupg.org/signature_key.html
echo "-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: GnuPG v2

mQENBE0ti4EBCACqGtKlX9jI/enhlBdy2cyQP6Q7JoyxtaG6/ckAKWHYrqFTQk3I
Ue8TuDrGT742XFncG9PoMBfJDUNltIPgKFn8E9tYQqAOlpSA25bOb30cA2ADkrjg
jvDAH8cZ+fkIayWtObTxwqLfPivjFxEM//IdShFFVQj+QHmXYBJggWyEIil8Bje7
KRw6B5ucs4qSzp5VH4CqDr9PDnLD8lBGHk0x8jpwh4V/yEODJKATY0Vj00793L8u
qA35ZiyczUvvJSLYvf7STO943GswkxdAfqxXbYifiK2gjE/7SAmB+2jFxsonUDOB
1BAY5s3FKqrkaxZr3BBjeuGGoCuiSX/cXRIhABEBAAG0Fldlcm5lciBLb2NoIChk
aXN0IHNpZymJAT4EEwECACgFAk0ti4ECGwMFCRDdnwIGCwkIBwMCBhUIAgkKCwQW
AgMBAh4BAheAAAoJECSbOdJPJeO2PlMIAJxPtFXf5yozPpFjRbSkSdjsk9eru05s
hKZOAKw3RUePTU80SRLPdg4AH+vkm1JMWFFpwvHlgfxqnE9rp13o7L/4UwNUwqH8
5zCwu7SHz9cX3d4UUwzcP6qQP4BQEH9/xlpQS9eTK9b2RMyggqwd/J8mxjvoWzL8
Klf/wl6jXHn/yP92xG9/YA86lNOL1N3/PhlZzLuJ6bdD9WzsEp/+kh3UDfjkIrOc
WkqwupB+d01R4bHPu9tvXy8Xut8Sok2zku2xVkEOsV2TXHbwuHO2AGC5pWDX6wgC
E4F5XeCB/0ovao2/bk22w1TxzP6PMxo6sLkmaF6D0frhM2bl4C/uSsqInAQQAQIA
BgUCTS2NBAAKCRBTtiDQHODGMEZPBACLmrMjpwmyVvI6X5N4NlWctXQWY+4ODx2i
O9CtUM/F96YiPFlmgwsJUzyXLwALYk+shh83TjQLfjexohzS1O07DCZUy7Lsb9R7
HbYJ1Yf/QcEykbiAW465CZb1BAOMR2HUODBTaABaidfnhmUzJtayz7Y0KKRHAx+V
VS6kfnsFq5kBDQRUUF8HAQgAh1mo8r+kVWVTNsNlyurm2tdZKiQbdeVgpBgcDnqI
3fAV58C3nC8DVuK5qVGZPB/jbu42jc8BXGP1l6UP+515LQL5GpTtV0pRWUO02WOu
TLZBVQcq53vzbg1xVo31rWV96mqGAPs8lGUCm09fpuiVKQojO6/Ihkg7/bnzeSbc
X5Xk9eKLhyB7tnakuYJeRYm4bjs+YDApK8IFQyevYF8pjTcbLTSNJPW9WLCsozsy
11r4xdfRcTWjARVz5VzTnQ+Px8YtsnjQ3qwNJBpsqMLCdDN7YGhh/mlwPjgdq/UF
f5+bY6f3ew0vshBqInBQycBSmYyoX0Ye3sAS/OR4nu5ZaQARAQABtD5EYXZpZCBT
aGF3IChHbnVQRyBSZWxlYXNlIFNpZ25pbmcgS2V5KSA8ZHNoYXdAamFiYmVyd29j
a3kuY29tPokBPgQTAQIAKAUCVFBfBwIbAwUJCbp27gYLCQgHAwIGFQgCCQoLBBYC
AwECHgECF4AACgkQBDdvPuCFaVmIoQf+POxCWkCTicRVlq0kust/iwYO1egK9FWG
130e2Irnv2lAZZN/0S5ibjHCYFp9gfMgmtVTF5oWXjSDAy/kIykQBBcUVx4SCJbd
MtKSdsSIQMz6P4DxXumxQm79msOsbi5TsdtUwjqdrbu2sHloE7ck/hTXUCkX3zuq
txY7W23BCQxVVT5qUaFuAHkkQaaBgAb8gdgixmkIBfu9u8k3k9zUKm/PNfMjxClv
ORkP8gev+XyzNgcXM49h5YYlmDT+Ahv99nUM1wg8yJTjefBAY0fL982Scx30nDQO
3w7ihALUoj5+TXQjhs3sWPJ8u3pstr9XcfzEZC77/CZmRYNr8g5hBokBHAQQAQgA
BgUCVFOBbwAKCRAkmznSTyXjtmHeB/0X00v959Oyc0EsSLOlfC52qsEn5cU7vxFb
+KY9aKtG4+hApJxemkqpCgA5+xZwXp3SQOf0sYFwz5OsukIjRF0HgSEdjoMTH6b7
lT0nCwKo8AMU0nJbopVIJikHOzk2gUqh1gxu5iml1RbSkmFhiGjYeqM+ONQynCeX
Gg3LLZCQ1eeoaX69bvbWQFDtTIn2HYvjZLjuGC6PGH/naZ7GchiiiK0bs4UOdJFX
HtITC/7DcgEiHMHOMT3XlwINTexZG0grl2LuWuyyhurJh5IO6geArPKUmR8SjJjV
azpwbutZhYjTzfUpPvKK8kCSan9Df5eeekDrKCU8x8aqLDVyoQcRmQENBFRQOyMB
CADmEHA30Xc6op/72ZcJdQMriVvnAyN22L3rEbTiACfvBajs6fpzme2uJlC5F1Hk
Ydx3DvdcLoIV6Ed6j95JViJaoE0EB8T1TNuQRL5xj7jAPOpVpyqErF3vReYdCDIr
umlEb8zCQvVTICsIYYAo3oxX/Z/M7ogZDDeOe1G57f/Y8YacZqKw0AqW+20dZn3W
7Lgpjl8EzX25AKBl3Hi/z+s/T7JCqxZPAlQq/KbHkYh81oIm+AX6/5o+vCynEEx/
2OkdeoNeeHgujwL8axAwPoYKVV9COy+/NQcofZ6gvig1+S75RrkG4AdiL64C7OpX
1N2kX08KlAzI9+65lyUw8t0zABEBAAG0Mk5JSUJFIFl1dGFrYSAoR251UEcgUmVs
ZWFzZSBLZXkpIDxnbmlpYmVAZnNpai5vcmc+iQE8BBMBCAAmBQJUUDsjAhsDBQkD
wmcABQsHCAkDBBUICQoFFgIDAQACHgECF4AACgkQIHGwijO9PwZ1/wgA0LKal1wF
Za8FPUonc2GzwE9YhkZiJB8KA/a7T6//cW4N46/GswiqZJxN1RdKs1B+rp7EMMU3
bhoXstLBcIYveljqh4lPBWCsTT2+/OpwAmgnzjgdTHcpnCMTEOdZktD5SKrTj2tV
aWXAlWK/UsEEanA3cvzofy44n7rm+Eoa7P1YGCHL++Ihsi66ElbehilTT/xxckHX
Uji1XDvoagEENEHk5j4Z2mhWtjnGclvuiBkS4XezezNMW/fPAypZX4bkURNbGd8j
tkb3Eqt+bv+ZQoSA+Ukv8APaAzj8lRSw+CYjDxpoM0jtmiPrk+u/Do46COVA/IX2
2aYNT2Y2KoWJV4kBHAQQAQgABgUCVFOCHQAKCRAkmznSTyXjtoIhB/0ZE/ppI2Gc
qDxSwPKkRkkoMD8oXdKkPxjUF2jgP+bceHKiz1F78cx/eZltB4av8OujO1IwqH2C
0aVr46W3eSyIcpmmw6F9sjLcTfyZJfWJrvobb7WQSKvWw0eHFgNGR6Z+BA3ohjws
aCZtzzkH2gXI+EM7qaZozMw+eSkZ4qTE9B4/hkMZZpBO0oGy9PQzSlADGftyyuTt
oSUvepfs+EvYSddQ7skXWq0zePuOhng2Mppl690A+aTywyetbPvVeqjiAbI7NB5f
8Tw7dk0Febe9NHvbwzgiStMPmIKrTcthvgIClBkZvmkBFWAPxYPdHfLzAlpDGxJt
R31c0zNFBH68mQENBFRDqVIBCAC0k8eZKDmNqdmawOlJ/m62L2g8uXT/+/vAEGb1
yaib09xI6tfGXzbqlDwrLIZcJsSIT/nt/ajJnIVbc3137va4XbwMzsDpAMH4mmiT
oqk+izEChGm2knzrLwhoflR8aGsKL35QoZT/erdjfgPeCRLvf25fHsN2Jb0WIMzC
56VkMeFoza+9HZ5hrkemmm+gPvIvhEUopxCyOS8mK5WjB4zzIdyDJfkqVpHvafNP
0N4LIsedKdyHcj/K3kY4Kejl99GW1z1snBgPamoN2/e52Pf6KTw2FjsSGZ72oalc
rkBR4wacUizGxKcRD2Y6Xa0g9mwToWdNBQCIII+uTzOzq1EDABEBAAG0IVdlcm5l
ciBLb2NoIChSZWxlYXNlIFNpZ25pbmcgS2V5KYkBPQQTAQgAJwUCVEOpUgIbAwUJ
C6oF9QULCQgHAgYVCAkKCwIEFgIDAQIeAQIXgAAKCRCKhhscfv1g2aH7B/wIW6mV
mTmzW2xc1q1MUdssExQBhEeONrbWJ/HiGZP/MaabgQ/+wZuThTAwfGM5zFQBOvrB
OGURhINU6lYQlcOrVo+V8Z1mNQKFWaKxJaY5Ku1bB1OuX9FHLEiMibogHu5fjJIX
BE8XrnvueejyFQ5g/uX2xcGgCWlMe49sR3K+lEl3n93xTmSNhP52r0gTjMjbqKWK
UaIGJ5OcWSrvawdfqLXkxR8phq2AlHHEfxpcZsOp9mZirWYQ5jcgGgFP0LYXUw/R
nxFpOcrj45qufmyEL9QJKjBV5RaHJbqukefwUInPQtVUmINqQxztSh5QxQP2tsUP
IeEi5RAoCwLJam8ziQEcBBABCAAGBQJUU4JUAAoJECSbOdJPJeO2c+cH+wevKc8w
bkWSoGOJiYDglVMJa4x5utgHyXP4PyqelIQ7yibfQq3YyOU9RWRGxfvuofPXpx1E
u/XtCGgw03r4HZhauauYe27IDpA5P/Go7+WqufT6gMBoZf/1cD2ykQZpFyszEKHf
Y+BlzqPJcRaXy4+uQG3O+bh/R2eIGAJDao/AclJI+kfckeY5DzRTibPex+rGAkxZ
8qHtlCb0WeUbL3mgl9f3LlbPH77w1on6XqqIaQ+ODSS/3CUOIhNI3lrGO7mIqhSC
0n+rpqLHeVLpLkz0IFvsJOp9UOHDCA8oL0cQtJGP1pN7muKR9nCVtoNuN41JapoO
4ZaHe5Y0r5MIofSYjgRDt/rHAQQA0JkZeitcyQMqk2xGd/5mGoc4+YNwQo8OSmVw
IvY8UAI3tBorhF6ha9niaqZU4vdldTnXMU0j1oPckAhOgRPaOvaEZhYUTF0F/15p
iAF5dkZQ6dsmXVUkPNYMZTpkc2nA+IACBiOmygGBkLFuXvHRW1i6SNz28iRH/UZc
YLi/2iEAIIFWUJm0Jldlcm5lciBLb2NoIChkaXN0IHNpZykgPGRkOWpuQGdudS5v
cmc+iLwEEwECACYCGwMGCwkIBwMCBBUCCAMEFgIDAQIeAQIXgAUCTS2MtwUJClRO
YQAKCRBTtiDQHODGMPB4A/0U1DJR9LbkWuBs8Ko6KJoKLMVI6iYNJBhAtm3dxWeU
xA16eYDWW/b9Lk5KnjtSWuGOeqa7MCsXnkyHkO88KE9IcM3mFnhfFN2qagd/nRch
l9MPsdOgf/ug7j72Alv2V8s28R10HTjfwySe/omXWwK3qn8ou6N7ID+EwCV7i2e2
u5kBogQ1oh4eEQQA/pdK4Oafa1uDN7Cr5nss4bNpg8YUSg01VVJ08KTCEdpCAPaU
+NzaP3KD2ow74WU2gzP70s9uSGQ2Vie4BLvOkaaBHba/3ivBrg3ILFrxbOfmKQg8
Fhtncd/TBOwzfkkbxBNcVJuBPRtjZ3dlDbS4IPNsIIv2SuCIfQmA8qNGvWsAoIrJ
90b2fzERCZkKtfkoyYA8fnNrBADhJ8RmIrKiCnDk3Tzk04nu6O8fp3ptrmnO7jlu
vDfsEVsYRjyMbDnbnjCGu1PeFoP2HZ+H9lp4CaQbyjWh2JlvI9UOc72V16SFkV0r
8k0euNQXHhhzXWIkfz4gwSbBkN2nO5+6cIVeKnsdyFYkQyVs+Q86/PMfjo7utyrc
WLq1CAQAou3da1JR6+KJO4gUZVh2F1NoaVCEPAvlDhNV10/hwe5mS0kTjUJ1jMl5
6mwAFvhFFF9saW+eAnrwIOHjopbdHrPBmTJlOnNMHVLJzFlqjihwRRZQyL8iNu2m
farn9Mr28ut5BQmp0CnNEJ6hl0Cs7l2xagWFtlEK2II144vK3fG0J1dlcm5lciBL
b2NoIChnbnVwZyBzaWcpIDxkZDlqbkBnbnUub3JnPohhBBMRAgAhAheABQkOFIf9
BQJBvGheBgsJCAcDAgMVAgMDFgIBAh4BAAoJEGi3q4lXVI3NBJMAn01313ag0tgj
rGUZtDlKYbmNIeMeAJ0UpVsjxpylBcSjsPE8MAki7Hb2Rw==
=W3eM
-----END PGP PUBLIC KEY BLOCK-----" \
  | gpg --import
} # end: stage_4_setup_gnupg_public_key

stage_4_pass__libgpg_error () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_pass__libgpg_error"

  libgpg_path="/usr/local/lib/libgpg-error.so.0.19.1"
  if [[ -f ${libgpg_path} ]]; then
    echo
    echo "${REINSTALL_OR_SKIP}: Already installed: ${libgpg_path}"
    echo
    if ! ${FORCE_REINSTALL}; then
      return
    fi
  fi

  pushd ${OPT_DLOADS} &> /dev/null

  # For libassuan.
  # ftp://ftp.gnupg.org/gcrypt/libgpg-error/

  wget -N ftp://ftp.gnupg.org/gcrypt/libgpg-error/libgpg-error-1.24.tar.gz
  wget -N ftp://ftp.gnupg.org/gcrypt/libgpg-error/libgpg-error-1.24.tar.gz.sig
  set +e
  gpg --verify libgpg-error-1.24.tar.gz.sig
  exit_code=$?
  reset_errexit
  if [[ ${exit_code} -ne 0 ]]; then
    echo "FATAL: Failed to verify downloaded file signature: libgpg-error-1.24.tar.gz"
    exit 1
  fi
  tar xvzf libgpg-error-1.24.tar.gz
  cd libgpg-error-1.24/
  ./configure
  #./configure --prefix=/usr
  make
  make check
  sudo make install

  popd &> /dev/null

} # end: stage_4_pass__libgpg_error

stage_4_pass__libassuan () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_pass__libassuan"

  libassuan_path="/usr/local/lib/libassuan.so.0.7.3"
  if [[ -f ${libassuan_path} ]]; then
    echo
    echo "${REINSTALL_OR_SKIP}: Already installed: ${libassuan_path}"
    echo
    if ! ${FORCE_REINSTALL}; then
      return
    fi
  fi

  pushd ${OPT_DLOADS} &> /dev/null

  # For GPG2.
  # ftp://ftp.gnupg.org/gcrypt/libassuan/

  wget -N ftp://ftp.gnupg.org/gcrypt/libassuan/libassuan-2.4.3.tar.bz2
  wget -N ftp://ftp.gnupg.org/gcrypt/libassuan/libassuan-2.4.3.tar.bz2.sig
  set +e
  gpg --verify libassuan-2.4.3.tar.bz2.sig
  exit_code=$?
  reset_errexit
  if [[ ${exit_code} -ne 0 ]]; then
    echo "FATAL: Failed to verify downloaded file signature: libassuan-2.4.3.tar.bz2"
    exit 1
  fi
  tar xvjf libassuan-2.4.3.tar.bz2
  cd libassuan-2.4.3/
  ./configure
  #./configure --prefix=/usr
  make
  make check
  sudo make install

  popd &> /dev/null

} # end: stage_4_pass__libassuan

stage_4_pass__libksba () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_pass__libksba"

  libksba_path="/usr/local/lib/libksba.so.8.11.5"
  if [[ -f ${libksba_path} ]]; then
    echo
    echo "${REINSTALL_OR_SKIP}: Already installed: ${libksba_path}"
    echo
    if ! ${FORCE_REINSTALL}; then
      return
    fi
  fi

  pushd ${OPT_DLOADS} &> /dev/null

  # For GPG2.
  # ftp://ftp.gnupg.org/gcrypt/libksba/

  wget -N ftp://ftp.gnupg.org/gcrypt/libksba/libksba-1.3.4.tar.bz2
  wget -N ftp://ftp.gnupg.org/gcrypt/libksba/libksba-1.3.4.tar.bz2.sig

  set +e
  gpg --verify libksba-1.3.4.tar.bz2.sig
  exit_code=$?
  reset_errexit
  if [[ ${exit_code} -ne 0 ]]; then
    echo "FATAL: Failed to verify downloaded file signature: libksba-1.3.4.tar.bz2"
    exit 1
  fi

  tar xvjf libksba-1.3.4.tar.bz2
  cd libksba-1.3.4/
  ./configure
  #./configure --prefix=/usr
  make
  make check
  sudo make install

  popd &> /dev/null

} # end: stage_4_pass__libksba

stage_4_pass__libpth () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_pass__libpth"

  LIBPTH_VERS="2.0.7"

  libpth_path="/usr/local/lib/libpth.so.20.0.27"
  if [[ -f ${libpth_path} ]]; then
    echo
    echo "${REINSTALL_OR_SKIP}: Already installed: ${libpth_path}"
    echo
    if ! ${FORCE_REINSTALL}; then
      return
    fi
  fi

  pushd ${OPT_DLOADS} &> /dev/null

  # For GPG2.
  # ftp://ftp.gnu.org/gnu/pth/
  # 2016-08-17: I did not try this:
  #  sudo apt-get install -y libpth-dev
  wget -N ftp://ftp.gnu.org/gnu/pth/pth-${LIBPTH_VERS}.tar.gz
  wget -N ftp://ftp.gnu.org/gnu/pth/pth-${LIBPTH_VERS}.tar.gz.sig

# 2016-11-14: I think this is fixed by stage_4_setup_gnupg_public_key.
# 2016-08-17: Whhere's their public key?
#  gpg: Signature made Thu 08 Jun 2006 01:18:31 PM CDT using DSA key ID A9C09E30
#  gpg: Can't check signature: public key not found
  set +e
  gpg --verify pth-${LIBPTH_VERS}.tar.gz.sig
  exit_code=$?
  reset_errexit
  if [[ ${exit_code} -ne 0 ]]; then
    echo "FATAL: Failed to verify downloaded file signature: pth-${LIBPTH_VERS}.tar.gz"
    exit 1
  fi

  tar xvzf pth-${LIBPTH_VERS}.tar.gz
  cd pth-${LIBPTH_VERS}
  ./configure
  #./configure --prefix=/usr
  make
  make test
  sudo make install

  popd &> /dev/null

} # end: stage_4_pass__libpth

stage_4_pass__libgcrypt () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_pass__libgcrypt"

  LIBGCRYPT_VERS="1.7.3"

  lib_path="/usr/local/lib/libgcrypt.so.20.1.3"
  if [[ -f ${lib_path} ]]; then
    echo
    echo "${REINSTALL_OR_SKIP}: Already installed: ${lib_path}"
    echo
    if ! ${FORCE_REINSTALL}; then
      return
    fi
  fi

  pushd ${OPT_DLOADS} &> /dev/null

  wget -N ftp://ftp.gnupg.org/gcrypt/libgcrypt/libgcrypt-${LIBGCRYPT_VERS}.tar.gz
  wget -N ftp://ftp.gnupg.org/gcrypt/libgcrypt/libgcrypt-${LIBGCRYPT_VERS}.tar.gz.sig

  set +e
  gpg --verify libgcrypt-${LIBGCRYPT_VERS}.tar.gz.sig
  exit_code=$?
  reset_errexit
  if [[ ${exit_code} -ne 0 ]]; then
    echo "FATAL: Failed to verify downloaded file signature: libgcrypt-${LIBGCRYPT_VERS}.tar.gz"
    exit 1
  fi

  tar xvzf libgcrypt-${LIBGCRYPT_VERS}.tar.gz
  cd libgcrypt-${LIBGCRYPT_VERS}
  #./configure
  ./configure --prefix=/usr
  make
  make check
  sudo make install

  popd &> /dev/null

} # end: stage_4_pass__libgcrypt

stage_4_pass__gnupg_2 () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_pass__gnupg_2"

  #GPG2_VERS="2.0.30"
  GPG2_VERS="2.1.15"

  gpg2_path="/usr/local/bin/gpg2"
  if [[ -f ${gpg2_path} ]]; then
    gpg2_version=$(/usr/local/bin/gpg2 --version | head -1)
    if [[ ${gpg2_version} == "gpg (GnuPG) ${GPG2_VERS}" ]]; then
      echo
      echo "${REINSTALL_OR_SKIP}: Already installed: ${gpg2_path}"
      echo
      if ! ${FORCE_REINSTALL}; then
        return
      fi
    else
      echo
      echo "Detected different version of GnuPG: ${gpg2_version}"
      echo
    fi
  fi

  pushd ${OPT_DLOADS} &> /dev/null

  # Prerequisites.
  # 2016-11-14: I got library complaints on 16.04 that I didn't have on 14.04.
  sudo apt-get install -y libgcrypt11-dev
  # 2016-11-14: Also on 16.04, during `make check`:
  #   ../../agent/gpg-agent: error while loading shared libraries: libpth.so.20:
  #     cannot open shared object file: No such file or directory
  # and adjusting configure didn't work:
  #   ./configure --build=x86_64-pc-linux-gnu LDFLAGS="-L/usr/local/lib"
  # Fortunately, this works:
  sudo apt-get install -y libpth-dev
  # From 2.0.30 to 2.1.15, new requirments.
  sudo apt-get install -y libnpth0-dev
  # Not required.
  sudo apt-get install -y libgnutls-dev

  # Mint 17.3 upstream [2016-08-17]:
  #
  #   $ gpg2 --version
  #   gpg (GnuPG) 2.0.22
  #   libgcrypt 1.5.3
  #
  # https://www.gnupg.org/
  # "2.1.14 is the modern version with support for ECC and many other new features
  #  2.0.30 is the stable version which is currently mostly used."

  wget -N https://www.gnupg.org/ftp/gcrypt/gnupg/gnupg-${GPG2_VERS}.tar.bz2
  wget -N https://www.gnupg.org/ftp/gcrypt/gnupg/gnupg-${GPG2_VERS}.tar.bz2.sig
  # You'll need the public key loaded. See:
  #   stage_4_setup_gnupg_public_key
  set +e
  # gpg --verify gnupg-2.0.30.tar.bz2.sig gnupg-2.0.30.tar.bz2
  gpg --verify gnupg-${GPG2_VERS}.tar.bz2.sig
  exit_code=$?
  reset_errexit
  if [[ ${exit_code} -ne 0 ]]; then
    echo "FATAL: Failed to verify downloaded file signature: gnupg-${GPG2_VERS}.tar.bz2"
    exit 1
  fi

  tar -xvjf gnupg-${GPG2_VERS}.tar.bz2

  cd gnupg-${GPG2_VERS}
  make clean
  #   $ ./configure
  #   checking for GPG Error - version >= 1.11... yes (1.24)
  #   configure: WARNING:
  #   ***
  #   *** The config script /usr/local/bin/gpg-error-config was
  #   *** built for x86_64-pc-linux-gnu and thus may not match the
  #   *** used host x86_64-unknown-linux-gnu.
  #   *** You may want to use the configure option --with-gpg-error-prefix
  #   *** to specify a matching config script or use $SYSROOT.
  #   ***
  #   checking for libgcrypt-config... /usr/bin/libgcrypt-config
  #   checking for LIBGCRYPT - version >= 1.5.0... yes (1.5.3)
  #   checking LIBGCRYPT API version... okay
  #   configure: WARNING:
  #   ***
  #   *** The config script /usr/bin/libgcrypt-config was
  #   *** built for x86_64-pc-linux-gnu and thus may not match the
  #   *** used host x86_64-unknown-linux-gnu.
  #   *** You may want to use the configure option --with-libgcrypt-prefix
  #   *** to specify a matching config script or use $SYSROOT.
  #./configure --build=x86_64-pc-linux-gnu
  #./configure --build=x86_64-pc-linux-gnu --prefix=/usr
  ./configure LDFLAGS="-L/usr/lib"
  make
  make check
  sudo make install

  # WHATEVER: On 14.04, I had weird error. Doesn't seem to be an issue on 16.04.
  # Crap...
  #
  # $ cmd gpg2
  # /usr/bin/gpg2
  #
  # $ /usr/local/bin/gpg2 --version
  # /usr/local/bin/gpg2: /lib/x86_64-linux-gnu/libgpg-error.so.0:
  #   no version information available (required by /usr/local/bin/gpg2)
  # gpg (GnuPG) 2.0.30
  # libgcrypt 1.5.3
  #
  # FIXME: 2016-08-17: I was able to install Password Store, but I did not finish getting gpg2 installed.
  #        Well, it's sort of installed, but
  #        1. it's not the first gpg2 on the path; and
  #        2. it complains about libgpg-error.so.0
  #            which I'm not sure matters, as I haven't tested the binary I just built
  #            and I'm going to drop this task until I care again.
  #            See you in the future!
  #
  # 2016-11-14: On 16.04:
  #
  #   $ /usr/bin/gpg2 --version
  #   gpg (GnuPG) 2.1.11
  #   libgcrypt 1.6.5
  #
  #   $ ll /usr/bin/gpg2
  #   -rwxr-xr-x 1 root root 896K Apr  8  2016 /usr/bin/gpg2*
  #
  #   $ /usr/local/bin/gpg2 --version
  #   gpg (GnuPG) 2.1.15
  #   libgcrypt 1.7.3
  #   $ ll /usr/local/bin/gpg2
  #   -rwxr-xr-x 1 root root 3.5M Nov 14 14:44 /usr/local/bin/gpg2*

  popd &> /dev/null

} # end: stage_4_pass__gnupg_2

stage_4_pass__xclip () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_pass__xclip"

  xclip_path="/usr/local/bin/xclip-copyfile"
  if [[ -f ${xclip_path} ]]; then
    echo
    echo "${REINSTALL_OR_SKIP}: Already installed: ${xclip_path}"
    echo
    if ! ${FORCE_REINSTALL}; then
      return
    fi
  fi

  pushd ${OPT_DLOADS} &> /dev/null

  # https://github.com/astrand/xclip

  # ./configure fails without libXmu headers.
  #   checking for X11/Xmu/Atoms.h... no
  #   configure: error: *** X11/Xmu/Atoms.h is missing ***
  sudo apt-get install -y libxmu-dev
  git clone https://github.com/astrand/xclip
  cd xclip/
  # https://github.com/astrand/xclip/blob/master/INSTALL
  # create configuration files
  autoreconf
  # create the Makefile
  #./configure
  ./configure --prefix=/usr
  # build the binary
  make
  # install xclip
  sudo make install
  # install man page
  sudo make install.man

  popd &> /dev/null

} # end: stage_4_pass__xclip

stage_4_pass__tree () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_pass__tree"

  tree_path="/usr/bin/tree"
  if [[ -f ${tree_path} ]]; then
    echo
    echo "${REINSTALL_OR_SKIP}: Already installed: ${tree_path}"
    echo
    if ! ${FORCE_REINSTALL}; then
      return
    fi
  fi

  pushd ${OPT_DLOADS} &> /dev/null

  # 2016-08-17: Dern it, Mint 17.3:
  #
  #   $ tree --version
  #   tree v1.6.0 (c) 1996 - 2011 by Steve Baker, Thomas Moore, Francesc Rocher, Kyosuke Tokoro
  #
  # http://mama.indstate.edu/users/ice/tree/

  wget -N ftp://mama.indstate.edu/linux/tree/tree-1.7.0.tgz
  tar xvzf tree-1.7.0.tgz
  cd tree-1.7.0/
  make
  sudo make install

  popd &> /dev/null

} # end: stage_4_pass__tree

stage_4_pass__util_linux () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_pass__util_linux"

  echo
  echo "WARNING: Do not build util-linux and install it!"
  echo
  return

  # 2016-11-12/WHATEVER:
  #   You don't need util-linux (it's already installed),
  #   and if you build and install it anew,
  #
  #     You'll BORK Your SYSTEM!
  #
  # At least building works:
  #
  #   ~ $ cd ..
  #   .downloads $ wipefs --version
  #   wipefs from util-linux 2.20.1
  #
  #   util-linux-2.28.1 $ ./wipefs --version
  #   lt-wipefs from util-linux 2.28.1
  #
  # But `sudo make install` DOOMS you:
  #
  #   $ wipefs --version
  #   wipefs: /lib/x86_64-linux-gnu/libblkid.so.1: version `BLKID_2.21' not found (required by wipefs)
  #
  #   $ mount
  #   mount: /lib/x86_64-linux-gnu/libmount.so.1: version `MOUNT_2.25' not found (required by mount)
  #   mount: /lib/x86_64-linux-gnu/libmount.so.1: version `MOUNT_2.23' not found (required by mount)
  #   mount: /lib/x86_64-linux-gnu/libmount.so.1: version `MOUNT_2.21' not found (required by mount)
  #   mount: /lib/x86_64-linux-gnu/libmount.so.1: version `MOUNT_2.24' not found (required by mount)
  #   mount: /lib/x86_64-linux-gnu/libmount.so.1: version `MOUNT_2.22' not found (required by mount)
  #
  # I was able to recover wipefs, but still not mount.
  #
  #   ~ $ wipefs --version
  #   wipefs from util-linux 2.20.1
  #
  #   # http://packages.ubuntu.com/trusty/amd64/util-linux/download
  #   wget -N http://mirrors.kernel.org/ubuntu/pool/main/u/util-linux/util-linux_2.20.1-5.1ubuntu20_amd64.deb
  #   sudo dpkg -i util-linux_2.20.1-5.1ubuntu20_amd64.deb
  #
  #   wget -N http://mirrors.kernel.org/ubuntu/pool/main/u/util-linux/libblkid1_2.20.1-5.1ubuntu20_amd64.deb
  #   sudo dpkg -i libblkid1_2.20.1-5.1ubuntu20_amd64.deb
  #
  #   # THIS WORKED! mount is restored!
  #   wget -N http://mirrors.kernel.org/ubuntu/pool/main/u/util-linux/mount_2.20.1-5.1ubuntu20_amd64.deb
  #   sudo dpkg -i mount_2.20.1-5.1ubuntu20_amd64.deb
  #
  # I'm trying all the commands under /srv/opt/.downloads/util-linux-2.28.1 to see what works.
  #
  #   Broken:
  #     eject
  #     lslocks
  #     mountpoint
  #
  #   # Fix eject:
  #   wget -N http://mirrors.kernel.org/ubuntu/pool/main/e/eject/eject_2.1.5+deb1+cvs20081104-13.1_amd64.deb
  #   sudo dpkg -i eject_2.1.5+deb1+cvs20081104-13.1_amd64.deb
  #
  #   # Fix mountpoint:
  #   wget -N http://mirrors.kernel.org/ubuntu/pool/main/s/sysvinit/initscripts_2.88dsf-41ubuntu6_amd64.deb
  #   sudo dpkg -i initscripts_2.88dsf-41ubuntu6_amd64.deb
  #
  # I GIVE UP: `lslocks` is borked on my desktop in Mint 17.
  #            I wonder if the machine will reboot...
  #
  #   # Still nothing.
  #   sudo apt-get -f install

  #UTILL_VERS="2.28.1"
  #UTILL_VERS="2.28.2"
  UTILL_VERS="2.29"

  pushd ${OPT_DLOADS} &> /dev/null

  # 2016-08-17: Linux Mint 17.3:
  #
  #   $ getopt --version
  #   getopt from util-linux 2.20.1
  #
  # Latest archive:
  #
  #   http://www.kernel.org/pub/linux/utils/util-linux/

  sudo apt-get install -y libncurses5-dev
  # Avoid: /usr/bin/ld: cannot find -lncursesw
  sudo apt-get install -y libncursesw5-dev

  wget -N \
    https://www.kernel.org/pub/linux/utils/util-linux/v${UTILL_VERS}/util-linux-${UTILL_VERS}.tar.xz
  tar -xJvf util-linux-${UTILL_VERS}.tar.xz
  cd util-linux-${UTILL_VERS}
  # Just guessing here, as there are no build instructions.
  #./configure
  ./configure --prefix=/usr
  make
  # No `make test`?
  # ARGH:
  #  This fails (obviously):
  #    make test
  #  And this overwrites basic commands but leaves you with a library problem!
  #  DO NOT DO THIS:
  #    sudo make install

  # YIKES!/2016-11-12: I probably shouldn't have install util-linux!

  # FRAK! Didn't help:
  #
  #   sudo apt-get install --reinstall util-linux
  #   sudo apt-get install -f util-linux --reinstall
  #
  #   sudo apt-get update && sudo apt-get install -f

  popd &> /dev/null

} # end: stage_4_pass__util_linux

stage_4_pass__password_store () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_pass__password_store"

  PASS_VERS="1.6.5"

  set +e
  command -v pass
  exit_code=$?
  reset_errexit
  if [[ ${exit_code} -eq 0 ]]; then
    set +e
    pass --version | grep "${PASS_VERS}"
    exit_code=$?
    reset_errexit
    if [[ ${exit_code} -eq 0 ]]; then
      echo
      echo "${REINSTALL_OR_SKIP}: Already installed: \`pass\` v${PASS_VERS} command"
      echo
      if ! ${FORCE_REINSTALL}; then
        return
      fi
    fi
  fi

  pushd ${OPT_DLOADS} &> /dev/null

  # Finally.
  # https://www.passwordstore.org/

  wget -N https://git.zx2c4.com/password-store/snapshot/password-store-${PASS_VERS}.tar.xz
  #tar xvzf password-store-${PASS_VERS}.tar.xz
  tar --xz -xvf password-store-${PASS_VERS}.tar.xz
  cd password-store-${PASS_VERS}
  sudo make install

  popd &> /dev/null

} # end: stage_4_pass__password_store

stage_4_pass__fix_gnome_keyring_hijack () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_pass__fix_gnome_keyring_hijack"

  pushd ${OPT_DLOADS} &> /dev/null

  if false; then
    # 2016-10-07: Make gpg ask for your password more than just once.
    # https://confluence.clazzes.org/display/KH/Preventing+Gnome-Keyring+from+caching+GPG+keys+forever
    # "no idea what this means, my XFCE4 desktops have it set to false"
    #gsettings set org.gnome.crypto.cache gpg-cache-authorize false
    # values are 'session', 'idle', 'timeout'. Default is 'session'.
    #gsettings set org.gnome.crypto.cache gpg-cache-method 'session'
    gsettings set org.gnome.crypto.cache gpg-cache-method 'timeout'
    # The time-to-live value is in seconds, default is 300.
    #gsettings set org.gnome.crypto.cache gpg-cache-ttl 300
  fi

  # The Gnome Keyring (GKR) plays man-in-the-middle and caches
  # your pass passwords in its cache, protected by your normal
  # login credentials! Nuts to that.
  # https://wiki.gnupg.org/GnomeKeyring
  # $ pass some/key
  # gpg: WARNING: The GNOME keyring manager hijacked the GnuPG agent.
  # gpg: WARNING: GnuPG will not work properly -
  #  please configure that tool to not interfere with the GnuPG system!
  sudo dpkg-divert --local --rename \
    --divert /etc/xdg/autostart/gnome-keyring-gpg.desktop-disable \
    --add /etc/xdg/autostart/gnome-keyring-gpg.desktop
  # If you later decide to reenable it, then you can use:
  #  sudo dpkg-divert --rename --remove /etc/xdg/autostart/gnome-keyring-gpg.desktop
  # And then do this.
  mkdir -p ${HOME}/.config/autostart
  cd ${HOME}/.config/autostart
  for gk_path in /etc/xdg/autostart/gnome-keyring-*; do
    gk_file=$(basename -- "${gk_path}")
    if [[ ! -e ${HOME}/.config/autostart/${gk_file} ]]; then
      /bin/cp /etc/xdg/autostart/${gk_file} ${HOME}/.config/autostart/
      echo 'Hidden=true' >> ${HOME}/.config/autostart/${gk_file}
    fi
  done
  # "... but then GPG will use yet another graphical prompt! To finally
  # stay in your terminal, create the file ~/.gnupg/gpg-agent.conf with
  # the following content:"
  sudo apt-get install -y pinentry-curses
  if [[ ! -e ${HOME}/.gnupg/gpg-agent.conf ]]; then
    echo 'pinentry-program /usr/bin/pinentry-curses' >> ${HOME}/.gnupg/gpg-agent.conf
  fi
  # WHAT!? None of the above worked. This does!
  # FINALLY
  # https://gist.github.com/julienfastre/9a91e3116505f6109e84
  # $ gpg-agent --daemon
  # GPG_AGENT_INFO=/tmp/gpg-Kd7kIC/S.gpg-agent:4415:1; export GPG_AGENT_INFO; #copy this line below
  # $ GPG_AGENT_INFO=/tmp/gpg-Kd7kIC/S.gpg-agent:4415:1; export GPG_AGENT_INFO;
  set +e
  eff_off_gkr=$(gpg-agent --daemon)
  exit_code=$?
  set -e
  if [[ ${exit_code} -eq 0 ]]; then
    eval "$eff_off_gkr"
  else
    echo
    echo "WARNING: gpg-agent --daemon returned nonzero error code, possible because it's already running."
    echo
  fi

  popd &> /dev/null

} # end: stage_4_pass__fix_gnome_keyring_hijack

stage_4_password_store () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  # Password management tool.

  # 2016-08-17: Version in aptitude for Linux Mint 17.3 is v1.4.5; current pass is v1.6.5.

  # See also: https://qtpass.org/
  # Unable to locate package??:
  #  sudo apt-get install -y qtpass
  #
  # See: https://github.com/IJHack/qtpass

  stage_announcement "stage_4_password_store"

  # https://www.passwordstore.org/
  # Says it Depends on:
  # - bash
  #   http://www.gnu.org/software/bash/
  # - GnuPG2
  #   http://www.gnupg.org/
  # - git
  #   http://www.git-scm.com/
  # - xclip
  #   http://sourceforge.net/projects/xclip/
  # - pwgen
  #   http://sourceforge.net/projects/pwgen/
  # - tree >= 1.7.0
  #   http://mama.indstate.edu/users/ice/tree/
  # - GNU getopt
  #   http://www.kernel.org/pub/linux/utils/util-linux/

  # $ bash --version
  # GNU bash, version 4.3.11(1)-release (x86_64-pc-linux-gnu)
  #
  # Latest bash is 2016-07-11 bash-4.4-beta2, but not too many before that
  #                2016-06-17 bash43-046[4.3-patches]
  #                2016-02-24 bash-4.4-rc1
  #                2015-10-12 bash-4.4-beta
  #                2014-11-07 bash-4.2.53
  #                2014-11-07 bash-4.3.30
  #                2014-04-10 bash43-011 [4.3-patches]
  #                2014-02-26 bash-4.3
  #
  # so whatever. Not like I want to touch Bash, anyway.

  stage_4_setup_gnupg_public_key

  stage_4_pass__libgpg_error

  stage_4_pass__libassuan

  stage_4_pass__libksba

  # On 14.04, install libpth; on 16.04, use apt.
  stage_4_pass__libpth

  stage_4_pass__libgcrypt

  stage_4_pass__gnupg_2

  stage_4_pass__xclip

  stage_4_pass__tree

  # We shouldn't need util-linux (already installed) and building it
  # and installing it yourself just fucks everything up (see fcn.).
  #stage_4_pass__util_linux

  stage_4_pass__password_store

  stage_4_pass__fix_gnome_keyring_hijack

} # end: stage_4_password_store

# *** Continuing along.

stage_4_oracle_java_jre () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_oracle_java_jre"

  #JDK_TAR="jdk-8u101-linux-x64.tar.gz"
  #JDK_VERS="jdk1.8.0_101"
  JDK_TAR="jdk-8u111-linux-x64.tar.gz"
  JDK_VERS="jdk1.8.0_111"

  JDK_DLOAD="${OPT_DLOADS}/${JDK_TAR}"
  #if [[ -f ${JDK_DLOAD} ]]; then
  if [[ -h ${OPT_BIN}/jdk ]]; then
    echo
    echo "${REINSTALL_OR_SKIP}: Already installed: ${OPT_BIN}/jdk"
    echo
    if ! ${FORCE_REINSTALL}; then
      return
    fi
  fi

  pushd ${OPT_DLOADS} &> /dev/null

  # $ cmd java
  # /srv/opt/bin/jdk/bin/java
  #
  # $ /srv/opt/bin/jdk/bin/java -version
  # java version "1.8.0_91"
  # Java(TM) SE Runtime Environment (build 1.8.0_91-b14)
  # Java HotSpot(TM) 64-Bit Server VM (build 25.91-b14, mixed mode)

  # This is just the runtime:
  #  #wget -N http://javadl.oracle.com/webapps/download/AutoDL?BundleId=211989
  #  wget -O jre-8u101-linux-x64.tar.gz http://javadl.oracle.com/webapps/download/AutoDL?BundleId=211989
  #  tar xzvf jre-8u101-linux-x64.tar.gz

  # Update the JDK instead.

  # From:
  #  http://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html
  # Argh, the link doesn't work. Manually download using broswer.
  #wget -N http://download.oracle.com/otn-pub/java/jdk/8u101-b13/${JDK_TAR}

  if [[ ! -f ${OPT_DLOADS}/${JDK_TAR} ]]; then
    echo
    echo "USER INTERACTION REQUIRED"
    echo
    echo "DOWNLOAD JDK FROM:"
    echo
    echo "   http://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html"
    echo
    echo "Look for: ${JDK_TAR}"
    echo
    echo -n "Press any key to continue "
    read -n 1 ignored

    if [[ ! -e ~/Downloads/${JDK_TAR} ]]; then
      echo
      echo "ERROR: No JDK"
      echo
      # Just let the mv die.
      #exit 1
    fi

    echo "Found it, thanks!"

    /bin/mv -f ~/Downloads/${JDK_TAR} ${OPT_DLOADS}
  fi

  tar xvzf ${JDK_TAR}
  /bin/mv ${JDK_VERS} ${OPT_BIN}
  pushd ${OPT_BIN} &> /dev/null
  if [[ -h jdk ]]; then
    /bin/rm jdk
  fi
  /bin/ln -sf ${JDK_VERS} jdk
  popd &> /dev/null

  popd &> /dev/null

} # end: stage_4_oracle_java_jre

stage_4_py_chjson () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_py_chjson"

  chjson2_7_path="/usr/local/lib/python2.7/dist-packages/python_chjson-1.2.0-py2.7-linux-x86_64.egg"
  chjson3_4_path="/usr/local/lib/python3.4/dist-packages/python_chjson-1.2.0-py3.4-linux-x86_64.egg"
  if [[ -f ${chjson2_7_path} && -f ${chjson3_4_path} ]]; then
    echo
    echo "${REINSTALL_OR_SKIP}: Already installed: ${chjson2_7_path}"
    echo "${REINSTALL_OR_SKIP}: Already installed: ${chjson3_4_path}"
    echo
    if ! ${FORCE_REINSTALL}; then
      return
    fi
  fi

  pushd ${OPT_DLOADS} &> /dev/null

  sudo apt-get install -y libpython3-dev

  if [[ ! -d chjson ]]; then
    git clone https://github.com/landonb/chjson
    cd chjson
  else
    cd chjson
    git pull -a
  fi

  sudo chown -R ${USER}:${USER} ${OPT_DLOADS}/chjson
  /bin/rm -rf build/ dist/ python_chjson.egg-info/

  python3 ./setup.py clean
  #CFLAGS='-Wall -O0 -g' python3 ./setup.py build
  python3 ./setup.py build
  # 2016-11-13: So now I gotta sudo?
  #python3 ./setup.py install
  sudo python3 ./setup.py install

  sudo chown -R ${USER}:${USER} ${OPT_DLOADS}/chjson
  /bin/rm -rf build/ dist/ python_chjson.egg-info/

  python2 ./setup.py clean
  #CFLAGS='-Wall -O0 -g' python2 ./setup.py build
  python2 ./setup.py build
  #python2 ./setup.py install
  sudo python2 ./setup.py install

  sudo chown -R ${USER}:${USER} ${OPT_DLOADS}/chjson
  /bin/rm -rf build/ dist/ python_chjson.egg-info/

  popd &> /dev/null

} # end: stage_4_py_chjson

stage_4_hipchat_client () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_hipchat_client"

  set +e
  command -v hipchat4
  exit_code=$?
  reset_errexit
  if [[ ${exit_code} -eq 0 ]]; then
    echo
    echo "${REINSTALL_OR_SKIP}: Already installed: \`hipchat4\` command"
    echo
    if ! ${FORCE_REINSTALL}; then
      return
    fi
  fi

  if [[ ! -f /etc/apt/sources.list.d/atlassian-hipchat4.list ]]; then
    sudo sh -c 'echo "deb https://atlassian.artifactoryonline.com/atlassian/hipchat-apt-client $(lsb_release -c -s) main" > /etc/apt/sources.list.d/atlassian-hipchat4.list'
  fi
  # sudo apt-key list
  wget -O - https://atlassian.artifactoryonline.com/atlassian/api/gpg/key/public | sudo apt-key add -
  #if ! ${SKIP_APT_GET_UPDATE}; then
    sudo apt-get update
  #fi
  sudo apt-get install hipchat4

} # end: stage_4_hipchat_client

stage_4_install_docker () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_install_docker"

  set +e
  command -v docker
  exit_code=$?
  reset_errexit
  if [[ ${exit_code} -eq 0 ]]; then
    echo
    echo "${REINSTALL_OR_SKIP}: Already installed: \`docker\` command"
    echo
    if ! ${FORCE_REINSTALL}; then
      return
    fi
  fi

  pushd ${OPT_DLOADS} &> /dev/null

  # https://docs.docker.com/engine/installation/linux/ubuntulinux/

  # These should both already be installed.
  sudo apt-get install -y apt-transport-https ca-certificates

  sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 \
    --recv-keys 58118E89F3A912897C070ADBF76221572C52609D

  if [[ ! -f /etc/apt/sources.list.d/docker.list ]]; then
    source /etc/lsb-release
    if [[ ${DISTRIB_CODENAME} = 'xenial' || ${DISTRIB_CODENAME} = 'sarah' ]]; then
      echo "deb https://apt.dockerproject.org/repo ubuntu-xenial main" | \
        sudo tee /etc/apt/sources.list.d/docker.list
    elif [[ ${DISTRIB_CODENAME} = 'trusty' || ${DISTRIB_CODENAME} = 'rebecca' ]]; then
      echo "deb https://apt.dockerproject.org/repo ubuntu-trusty main" | \
        sudo tee /etc/apt/sources.list.d/docker.list
    else
      echo
      echo "ERROR: Unknown distro to us. Refuse to install Docker."
      exit 1
    fi
  fi

  #if ! ${SKIP_APT_GET_UPDATE}; then
    sudo apt-get update
  #fi

  # Purge the old repo, if it exists.
  set +e
  sudo apt-get purge lxc-docker
  set -e

  # Verify that APT is pulling from the right repository.
  apt-cache policy docker-engine

  # The linux-image-extra-* packages allows you use the aufs storage driver.
  #sudo apt-get install linux-image-extra-$(uname -r) linux-image-extra-virtual
  # Should this worry me? 2016-09-27 on Xenial/Sarah.
  #   landonb@terpsichore:danweaver ⚓ $ sudo apt-get install linux-image-extra-virtual
  #   Reading package lists... Done
  #   Building dependency tree
  #   Reading state information... Done
  #   Some packages could not be installed. This may mean that you have
  #   requested an impossible situation or if you are using the unstable
  #   distribution that some required packages have not yet been created
  #   or been moved out of Incoming.
  #   The following information may help to resolve the situation:
  #
  #   The following packages have unmet dependencies:
  #    linux-image-extra-virtual : Depends: linux-image-generic (= 4.4.0.38.40) but it is not going to be installed
  #   E: Unable to correct problems, you have held broken packages.
  sudo apt-get install -y linux-image-extra-$(uname -r) linux-image-extra-virtual linux-image-generic

  # Install Docker.
  sudo apt-get install -y docker-engine

  # Start the docker daemon.
  sudo service docker start

  # Verify docker is installed correctly.
  sudo docker run hello-world

  # Create a docker group so your user doesn't have to sudo to docker.
  # https://docs.docker.com/engine/installation/linux/ubuntulinux/#/create-a-docker-group
  # This group already exists, at least on xenial after installing docker.
  set +e
  sudo groupadd docker
  reset_errexit
  sudo usermod -aG docker $USER
  # After logoff/logon, or sudo su $USER, you can test without sudo:
  #   docker run hello-world
  #
  # Something something unset DOCKER_HOST if docker fails with the message:
  #  "Cannot connect to the Docker daemon. Is 'docker daemon' running on this host?"
  if [[ -n ${DOCKER_HOST} ]]; then
    echo
    echo "ERROR: Unexpected: DOCKER_HOST is set. Please unset. Forever."
    exit 1
  fi

# MAYBE: Adjust memory and swap accounting.
# Incurs 1% memory overhead and 10% performance degradation.
# But prevents messages like:
# "WARNING: Your kernel does not support cgroup swap limit. WARNING: Your
#  kernel does not support swap limit capabilities. Limitation discarded."
# https://docs.docker.com/engine/installation/linux/ubuntulinux/#/adjust-memory-and-swap-accounting
# sudo vim /etc/default/grub
#  GRUB_CMDLINE_LINUX="cgroup_enable=memory swapaccount=1"
# sudo update-grub
# sudo /sbin/shutdown -r now

# MAYBE: Configure a DNS server for use by Docker
# Avoid warning:
# "WARNING: Local (127.0.0.1) DNS resolver found in resolv.conf and containers
#  can't use it. Using default external servers : [8.8.8.8 8.8.4.4]"
# https://docs.docker.com/engine/installation/linux/ubuntulinux/#/configure-a-dns-server-for-use-by-docker

# MAYBE: Start Docker on boot.
# For 15.04 and up, to configure the docker daemon to start on boot, run
#  sudo systemctl enable docker
# For 14.10 and below the above installation method automatically configures upstart to start the docker daemon on boot

  # Upgrade Docker, obv:
  #  sudo apt-get upgrade docker-engine
  # Uninstall Docker, not as obv:
  #  Basic uninstall:
  #   sudo apt-get purge docker-engine
  #  Uninstall dependencies, too:
  #   sudo apt-get autoremove --purge docker-engine
  #  Delete all images, containers, and volumes:
  #   rm -rf /var/lib/docker

  popd &> /dev/null

} # end: stage_4_install_docker

stage_4_install_docker_compose () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_install_docker_compose"

# FIXME/MAYBE: 2016-11-13: Getting 403 on the wget.
# 2016-11-13 06:36:57 ERROR 403: Forbidden.

  #DKRCPS_VERS="1.8.1"
# 2016-11-13: Leave at rc1, which is installed, until this 403 error goes away.
  DKRCPS_VERS="1.9.0-rc1"
  #DKRCPS_VERS="1.9.0-rc4"

  set +e
  command -v docker-compose
  exit_code=$?
  reset_errexit
  if [[ ${exit_code} -eq 0 ]]; then
    set +e
    docker-compose --version | grep "docker-compose version ${DKRCPS_VERS}, build"
    exit_code=$?
    reset_errexit
    if [[ ${exit_code} -eq 0 ]]; then
      echo
      echo "${REINSTALL_OR_SKIP}: Already installed: \`docker-compose\` v${DKRCPS_VERS} command"
      echo
      if ! ${FORCE_REINSTALL}; then
        return
      fi
    fi
  fi

  pushd ${OPT_DLOADS} &> /dev/null

  # See first stage_4_install_docker.

  DC_BIN="docker-compose-`uname -s`-`uname -m`"
  DC_REMOTE="https://github.com/docker/compose/releases/download/${DKRCPS_VERS}"
  #curl -L ${DC_REMOTE}/${DC_BIN} | sudo tee /usr/local/bin/docker-compose
  wget -N ${DC_REMOTE}/${DC_BIN}
  #sudo cp -a ${DC_BIN} /usr/local/bin/docker-compose
  #sudo chmod +x /usr/local/bin/docker-compose
  chmod +x ${DC_BIN}
  /bin/ln -s ${OPT_DLOADS}/${DC_BIN} ${OPT_BIN}/docker-compose

  # 2016-10-25:
  docker-compose --version
  ##docker-compose version: 1.8.1
  #docker-compose version: 1.9.0-rc1

  popd &> /dev/null

} # end: stage_4_install_docker_compose

stage_4_openshift_client () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_openshift_client"

  set +e
  command -v oc
  exit_code=$?
  reset_errexit
  if [[ ${exit_code} -eq 0 ]]; then
    echo
    echo "${REINSTALL_OR_SKIP}: Already installed: \`oc\` command"
    echo
    if ! ${FORCE_REINSTALL}; then
      return
    fi
  fi

  pushd ${OPT_DLOADS} &> /dev/null

  #wget -N \
  #  https://github.com/openshift/origin/releases/download/v1.2.0/openshift-origin-client-tools-v1.2.0-2e62fab-linux-64bit.tar.gz
  #tar xvzf openshift-origin-client-tools-v1.2.0-2e62fab-linux-64bit.tar.gz

  # 2017-04-25: Huh. OPs' instructions were wrong. Server is running 1.2.1, so match that.
  #wget -N \
  #  https://github.com/openshift/origin/releases/download/v1.3.0/openshift-origin-client-tools-v1.3.0-3ab7af3d097b57f933eccef684a714f2368804e7-linux-64bit.tar.gz
  #tar xvzf openshift-origin-client-tools-v1.3.0-3ab7af3d097b57f933eccef684a714f2368804e7-linux-64bit.tar.gz

  wget -N \
    https://github.com/openshift/origin/releases/download/v1.2.1/openshift-origin-client-tools-v1.2.1-5e723f6-linux-64bit.tar.gz
  tar xvzf openshift-origin-client-tools-v1.2.1-5e723f6-linux-64bit.tar.gz

  popd &> /dev/null

  pushd ${OPT_BIN} &> /dev/null

  #/bin/ln -sf \
  #  ${OPT_DLOADS}/openshift-origin-client-tools-v1.3.0-3ab7af3d097b57f933eccef684a714f2368804e7-linux-64bit/oc

  /bin/ln -sf \
    ${OPT_DLOADS}/openshift-origin-client-tools-v1.2.1-5e723f6-linux-64bit/oc

  popd &> /dev/null

} # end: stage_4_openshift_client

stage_4_jq_cli_json_processor () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_jq_cli_json_processor"

# FIXME/MAYBE: 2016-11-13: Getting 403 on the wget.
# 2016-11-13 06:36:57 ERROR 403: Forbidden.

  JQ_VERS="jq-1.5"

  set +e
  command -v jq
  exit_code=$?
  reset_errexit
  if [[ ${exit_code} -eq 0 ]]; then
    set +e
    jq --version | grep "^${JQ_VERS}$"
    exit_code=$?
    reset_errexit
    if [[ ${exit_code} -eq 0 ]]; then
      echo
      echo "${REINSTALL_OR_SKIP}: Already installed: \`jq\` v${JQ_VERS} command"
      echo
      if ! ${FORCE_REINSTALL}; then
        return
      fi
    fi
  fi

  pushd ${OPT_BIN} &> /dev/null

  wget -N https://github.com/stedolan/jq/releases/download/${JQ_VERS}/jq-linux64
  chmod 775 jq-linux64

  /bin/ln -sf jq-linux64 jq

  popd &> /dev/null

} # end: stage_4_jq_cli_json_processor

stage_4_gnome_encfs_manager () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_gnome_encfs_manager"

# FIXME/MAYBE: 2016-11-13: Getting 403 on the wget.
# 2016-11-13 06:36:57 ERROR 403: Forbidden.

  ENCFS_VERS="1.9.1"

  set +e
  command -v encfs
  exit_code=$?
  reset_errexit
  if [[ ${exit_code} -eq 0 ]]; then
    set +e
    # encfs --version prints to stderr.
    encfs --version 2>&1 | grep "^encfs version ${ENCFS_VERS}$"
    exit_code=$?
    reset_errexit
    if [[ ${exit_code} -eq 0 ]]; then
      echo
      echo "${REINSTALL_OR_SKIP}: Already installed: \`encfs\` v${ENCFS_VERS} command"
      echo
      if ! ${FORCE_REINSTALL}; then
        return
      fi
    fi
  fi

  if false; then
    # 2016-09-29
    #   Before
    #     $ encfs --version
    #     encfs version 1.7.4
    #   After
    #     same damn thing...
    #   HAHA This is just a GUI app. Dork!
    sudo add-apt-repository -y ppa:gencfsm/ppa
    #if ! ${SKIP_APT_GET_UPDATE}; then
      sudo apt-get update
    #fi
    sudo apt-get install -y gnome-encfs-manager
  fi

  pushd ${OPT_DLOADS} &> /dev/null

  # https://github.com/vgough/encfs/blob/master/INSTALL.md

  # * fuse : the userspace filesystem layer
  # * openssl : used for cryptographic primitives
  # * tinyxml2 : for reading and writing XML configuration files
  # * gettext : internationalization support
  # * libintl : internationalization support
  #
  # While trying to build, I installed these but they didn't help (some
  # were suggested! just not the correct development headers version):
  #
  #  fuse
  #  libgettextpo-dev - GNU Internationalization library development files
  #  libgettextpo0 [already installed]
  #
  # And these these I never tried:
  #  libfuse2 \
  #  libssl-dev
  #
  # And I haven't solved the FindIntl.cmake problem but I don't think it matters.
  sudo apt-get install -y \
    libfuse-dev \
    openssl \
    libtinyxml2-dev \
    gettext \
    libintl-perl \
    libintl-xs-perl

  wget -N https://github.com/vgough/encfs/releases/download/v${ENCFS_VERS}/encfs-${ENCFS_VERS}.tar.gz

  tar xzf encfs-${ENCFS_VERS}.tar.gz

  cd encfs-${ENCFS_VERS}

  mkdir build
  cd build

  # cmake complains:
  #   -- Enabled syslog logging support
  #   CMake Warning at CMakeLists.txt:131 (find_package):
  #     By not providing "FindIntl.cmake" in CMAKE_MODULE_PATH this project has
  #     asked CMake to find a package configuration file provided by "Intl", but
  #     CMake did not find one.
  #
  #     Could not find a package configuration file provided by "Intl" with any of
  #     the following names:
  #
  #       IntlConfig.cmake
  #       intl-config.cmake
  #
  #     Add the installation prefix of "Intl" to CMAKE_PREFIX_PATH or set
  #     "Intl_DIR" to a directory containing one of the above files.  If "Intl"
  #     provides a separate development package or SDK, be sure it has been
  #     installed.
  #
  #   -- Found Gettext: /usr/bin/msgmerge (found version "0.18.3")
  #   -- Configuring done
  #   -- Generating done
  #   -- Build files have been written to: /srv/opt/.downloads/encfs-1.9.1/build
  # but who cares.

  # Default install path is /usr/local, i.e., /usr/local/bin
  #
  # 2016-09-29: Figure this out on another machine.
  # The PATH thing weirds me out -- something in /usr/local/bin
  # should be used before /usr/bin.....
  #
  cmake ..
  #cmake .. -DCMAKE_INSTALL_PREFIX=/usr

  # One option is redo the cmake above:
  #
  #   cmake .. -DCMAKE_INSTALL_PREFIX=/usr/bin
  #
  # Another option is to move the original.
  #
  #   if [[ -e /usr/bin/encfs ]]; then
  #     /bin/mv -i /usr/bin/encfs /usr/bin/encfs-ORIG
  #   fi
  #
  # Another option is to re-order your PATH...
  #  Wait, what?!
  #     $ echo $PATH
  #     ... :/usr/local/bin:/usr/bin:/bin:...
  #  so /usr/local/bin was already in front?
  #  Then why was the other encfs picking up?
  #  Frak.
  #  2016-09-29: Anyway, at home I blew away
  #  the system repo's /usr/bin/encfs and installed
  #  my own. Hope I don't have issues!

# FIXME: On laptop, try to make PATH behave correctly!
#        /usr/local/bin should override.

  make

  make test

  sudo make install

  # Et voilà!
  #
  #   $ encfs --version
  #   encfs version 1.9.1

  popd &> /dev/null

} # end: stage_4_gnome_encfs_manager

stage_4_exosite_setup () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_exosite_setup"

  if false; then
    EXOLINE_VERS="0.10.0"
    set +e
    command -v exo
    exit_code=$?
    reset_errexit
    if [[ ${exit_code} -eq 0 ]]; then
      set +e
      exo --version | grep "^Exosite Command Line ${EXOLINE_VERS}$"
      exit_code=$?
      reset_errexit
      if [[ ${exit_code} -eq 0 ]]; then
        echo
        echo "${REINSTALL_OR_SKIP}: Already installed: \`exo\` v${EXOLINE_VERS} command"
        echo
        if ! ${FORCE_REINSTALL}; then
          return
        fi
      fi
    fi
  fi

  pushd ${OPT_DLOADS} &> /dev/null

  # 2016-09-29: So, this worked (at work!) on Linux Mint "Sarah" 16.04,
  # but not at home, on Mint "Rebecca" 14.04, and they should have the
  # same everything installed, AFAIK, but pip failed in 14.04 at:
  #    No package 'libffi' found
  #    c/_cffi_backend.c:15:17: fatal error: ffi.h: No such file or directory
  #     #include <ffi.h>
  # Fortunately, a simple apt-get fixed it.
  # Making note of it in case this is a common problem,
  # and not just particular to my machines.
  sudo apt-get install libffi-dev

  #sudo pip install --upgrade exoline
  # 2016-11-16: I see exoline in py3 but not py2. Looks like `pip` is `pip3`.
  sudo pip2 install --upgrade exoline
  sudo pip3 install --upgrade exoline

  popd &> /dev/null

} # end: stage_4_exosite_setup

stage_4_go_get_go () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_go_get_go"

  pushd ${OPT_DLOADS} &> /dev/null

  # See:
  #
  #   https://storage.googleapis.com
  #
  # <Contents>
  # <Key>go1.8rc2.linux-amd64.tar.gz</Key>
  # <Generation>1484863045251000</Generation>
  # <MetaGeneration>1</MetaGeneration>
  # <LastModified>2017-01-19T21:57:25.243Z</LastModified>
  # <ETag>"26e244367d2cae4af2e5fc1c44becf88"</ETag>
  # <Size>91223748</Size>
  # <Owner/>
  # </Contents>
  # <Contents>
  # <Key>go1.8rc2.linux-amd64.tar.gz.sha256</Key>
  # <Generation>1484863045715000</Generation>
  # <MetaGeneration>1</MetaGeneration>
  # <LastModified>2017-01-19T21:57:25.698Z</LastModified>
  # <ETag>"911dbf6b46a12f5a90018ba5bcf7a9af"</ETag>
  # <Size>64</Size>
  # <Owner/>
  # </Contents>

  #sudo apt-get update
  # 2017-01-20: Mothereffing Oracle is taking 4evs [50m!] on the 175M jdk-8u121 upgrade. Gah, what year is this?
  #sudo apt-get upgrade
  #sudo apt-get dist-upgrade

  #GO_VERS="go1.8rc2"
  GO_VERS="go1.8.1"
  GO_TBAL="${GO_VERS}.linux-amd64.tar.gz"
  wget -N https://storage.googleapis.com/golang/${GO_TBAL}
  wget -N https://storage.googleapis.com/golang/${GO_TBAL}.sha256
  GO_SHA256=$(cat ${GO_TBAL}.sha256)
  if [[ $(sha256sum ${GO_TBAL} | awk '{print $1}') != ${GO_SHA256} ]]; then
    echo "FATAL: SHA256 mismatch: $(sha256sum ${GO_TBAL}) / expected: ${GO_SHA256}"
    exit 1
  fi

  # `sudo tar` so sudo owns.
  sudo tar -xvzf ${GO_TBAL}
  if [[ -d /usr/local/go ]]; then
    sudo /bin/mv /usr/local/go /usr/local/go-`date +%Y.%m.%d-%T`
  fi
  sudo mv go /usr/local

  if [[ $(go version) != "go version ${GO_VERS} linux/amd64" ]]; then
    echo "FATAL: install go failed: $(go version) / expected: ${GO_VERS}"
    exit 1
  fi

  popd &> /dev/null

} # end: stage_4_go_get_go

stage_4_go_delve_debugger () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_go_delve_debugger"

  pushd ${OPT_DLOADS} &> /dev/null

  # `go get` requires one to set GOPATH.
  #    mkdir -p gocode
  #    export GOPATH="${OPT_DLOADS}/gocode"
  # However, this just hangs:
  #    go get github.com/derekparker/delve/cmd/dlv
  # and when I ctrl-c, I see gocode/src/github.com/derekparker
  # and it's empty.

  mkdir -p ${HOME}/.gopath
  export GOPATH=${HOME}/.gopath

  # The Delve Makefile expects to find the source under GOPATH
  # at github.com/derekparker.
  mkdir -p ${HOME}/.gopath/src/github.com/derekparker

  pushd ${HOME}/.gopath/src/github.com/derekparker &> /dev/null

  if [[ ! -d delve ]]; then
    #git clone ssh://git@github.com/derekparker/delve
    git clone https://github.com/derekparker/delve
    cd delve
  else
    cd delve
    git pull
  fi

  make install

  # ll gocode

# FIXME
#      ll ~/.gopath/src/github.com/landonb
#      ln -s /kit/sturdy/delve

  popd &> /dev/null

} # end: stage_4_go_delve_debugger

stage_4_go_get_crap () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_go_get_crap"

  JSONQ_SRC="${HOME}/.gopath/src/github.com/jmoiron/jsonq/"

  if [[ -d ${JSONQ_SRC} ]]; then
    echo
    echo "${REINSTALL_OR_SKIP}: Already installed: ${JSONQ_SRC}"
    echo
    if ! ${FORCE_REINSTALL}; then
      return
    fi
  fi

  #pushd ${OPT_DLOADS} &> /dev/null

  # Installs to:
  #  ~/.gopath/src/github.com/jmoiron/jsonq/
  go get github.com/jmoiron/jsonq

  # 2017-01-05
  go get github.com/landonb/gocovmerge

  #popd &> /dev/null

} # end: stage_4_go_get_crap

stage_4_fix_firefox_vertical_scrollbar_warp_to_click () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_fix_firefox_vertical_scrollbar_warp_to_click"

  pushd ${OPT_DLOADS} &> /dev/null

  # MEH: We could instead add a file at
  #       ~/.fries/once/recipe/home/.config/gtk-3.0/settings.ini
  #      and copy it over during chase_and_face
  #      but this seems just as fine.

  # 2016-10-03: WTF, Google? Or Gnome? Which is it?
  # Firefox scrollbar jumping to where I click, instead of paging.
  # You can shift-click to do opposite behavior
  #
  # https://support.mozilla.org/en-US/questions/1125603
  if [[ ! -e ~/.config/gtk-3.0/settings.ini ]]; then
    cat > ~/.config/gtk-3.0/settings.ini << EOF
[Settings]
gtk-primary-button-warps-slider = false
EOF
  fi

  popd &> /dev/null

} # end: stage_4_fix_firefox_vertical_scrollbar_warp_to_click

# 2016-10-03: Probably about a month ago my weather applet stopped working.
#             Gurgling suggests the API service was shut off.
#             Here's what the github page says, where most commits are "a year ago":
#             ``libmateweather  iwin: use new server address to fix forecast  27 days ago``
#             I think the issue is that the distro packagers probably won't rebuild it.
stage_4_libmateweather () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_libmateweather"

  if [[ -e /usr/local/lib/libmateweather.so.1.6.9 ]]; then
    echo
    echo "${REINSTALL_OR_SKIP}: Already installed: \`libmateweather.so.1.6.9\`"
    echo
    if ! ${FORCE_REINSTALL}; then
      return
    fi
  fi

  pushd ${OPT_DLOADS} &> /dev/null

  # No package 'gtk+-2.0' found
  sudo apt-get install -y libgtk2.0-dev
  # No package 'libsoup-2.4' found
  sudo apt-get install -y libsoup2.4-dev

  if [[ ! -d libmateweather ]]; then
    git clone https://github.com/mate-desktop/libmateweather
    cd libmateweather
  else
    cd libmateweather
    git pull
  fi

  ./autogen.sh
  make
  sudo make install

# FIXME/2016-10-03: I may need to logoff/on to realize the new applet.

  popd &> /dev/null

} # end: stage_4_libmateweather

stage_4_open_shift_origin_binary () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_open_shift_origin_binary"

# FIXME/MAYBE: 2016-11-13: Getting 403 on the wget.
# 2016-11-13 06:36:57 ERROR 403: Forbidden.

  # Find the checksum and releases on github:
  #   https://github.com/openshift/origin/releases

  # OpenShift v1.3.0 checksums:
  #   0d3b632fae9bc2747caee2dae7970865097a4bc1d83b84afb31de1c05b356054
  #     openshift-origin-client-tools-v1.3.0-3ab7af3d097b57f933eccef684a714f2368804e7-linux-64bit.tar.gz
  #   cadb7408c45be8c19dde30c82e59f21cec1ba4f23f07131f9a6c8c20b22c3f73
  #     openshift-origin-server-v1.3.0-3ab7af3d097b57f933eccef684a714f2368804e7-linux-64bit.tar.gz

  # 2016-10-04: Employer is using v1.2.0 still.
  # OpenShift v1.2.0 checksums:
  #   8e903e6a81e9a8415532c6d7fbc86ab4c84818a4dad8fcf118776fa90424e95c  openshift-origin-client-tools-v1.2.0-2e62fab-linux-32bit.tar.gz
  #   62d309592b27e42a84102a950d92a8c1b6b61ea488f7c2f3433bf38f64cea68b  openshift-origin-client-tools-v1.2.0-2e62fab-linux-64bit.tar.gz
  #   a911c918426fd474330d60c5ec651308385b54fd0f0866e888328f38d8ee7671  openshift-origin-client-tools-v1.2.0-2e62fab-mac.zip
  #   3df3d7f31d5f50fa49f94312883107ebee1a0877b598eada32dce1b029f6c3f2  openshift-origin-client-tools-v1.2.0-2e62fab-windows.zip
  #   f6e46dec27f166a7f05554bd6b9364cead8c36a39836f75e16e16ee29b9e1a2f  openshift-origin-server-v1.2.0-2e62fab-linux-64bit.tar.gz

  # LATER: v1.3.0.
  #SERVER_BASENAME="openshift-origin-server-v1.3.0"
  #SERVER_ID=3ab7af3d097b57f933eccef684a714f2368804e7
  #SERVER_ARCH="linux-64bit"
  #SERVER_BASENAME="${SERVER_BASENAME}-${SERVER_ID}-${SERVER_ARCH}"
  SERVER_VERSION="v1.3.0"
  SERVER_BASENAME="openshift-origin-server-v1.3.0-3ab7af3d097b57f933eccef684a714f2368804e7-linux-64bit"
  # 2016-10-04: For now...
  SERVER_VERSION="v1.2.0"
  SERVER_BASENAME="openshift-origin-server-v1.2.0-2e62fab-linux-64bit"

  # E.g., "openshift-origin-server-v1.3.0-3ab7af3d097b57f933eccef684a714f2368804e7-linux-64bit.tar.gz"
  TARNAME="${SERVER_BASENAME}.tar.gz"

  pushd ${OPT_DLOADS} &> /dev/null

  if [[ -f ${TARNAME} ]]; then
    echo
    echo "${REINSTALL_OR_SKIP}: Already installed: ${TARNAME}"
    echo
    if ! ${FORCE_REINSTALL}; then
      return
    fi
  fi

  wget -N https://github.com/openshift/origin/releases/download/${SERVER_VERSION}/${TARNAME}
  cd ${OPT_BIN}
  tar xzf ${OPT_DLOADS}/${TARNAME}
  if [[ -h openshift-origin-server ]]; then
    /bin/rm openshift-origin-server
  fi
  /bin/ln -sf ${SERVER_BASENAME} openshift-origin-server
  # And then add to PATH... see .bashrc.

  # Launch the server:
  #  sudo ${OPT_BIN}/openshift-origin-server/openshift start

  popd &> /dev/null

} # end: stage_4_open_shift_origin_binary

stage_4_prep_home_fries () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_prep_home_fries"

  pushd ${OPT_DLOADS} &> /dev/null

  if false; then

# FIXME: These permissions get "fixed" on reboot.
#        You'll need to figure out a better way to do this... via sudoers??
#        Via a root cronjob?
#        Could I schedule a service to start on boot that just "fixes" the permissions,
#          or maybe better yet just disables wake-on-lid??
    # So that bashrc.core.sh can
    #   echo " LID" | sudo tee /proc/acpi/wakeup
    # but without the sudo.
    sudo chown root:sudo /proc/acpi/wakeup
    sudo chmod g+w /proc/acpi/wakeup

  fi

  popd &> /dev/null

} # end: stage_4_prep_home_fries

stage_4_setup_whiteinge_diffconflicts () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_setup_whiteinge_diffconflicts"

  echo
  echo "WARNING: Deprecated: stage_4_setup_whiteinge_diffconflicts"
  echo
  return

  # From ~/.fries/bin/diffconflicts-setup.sh, 2016 Mar 24.
  # Has something to do with resolving merge conflicts.
  # I've just been doing it raw via text editor....

  if false; then

    pushd ${OPT_DLOADS} &> /dev/null

    # See:
    #  http://vim.wikia.com/wiki/A_better_Vimdiff_Git_mergetool

    mkdir -p /srv/opt/.downloads/whiteinge
    pushd /srv/opt/.downloads/whiteinge &> /dev/null
    git clone https://github.com/whiteinge/dotfiles.git
    popd &> /dev/null

    pushd ${HOME}/.fries/bin &> /dev/null
    /bin/ln /srv/opt/.downloads/whiteinge/dotfiles/bin/diffconflicts .
    popd &> /dev/null

    git config --global merge.tool diffconflicts
    git config --global mergetool.diffconflicts.cmd 'diffconflicts vim $BASE $LOCAL $REMOTE $MERGED'
    git config --global mergetool.diffconflicts.trustExitCode true
    git config --global mergetool.keepBackup false

    popd &> /dev/null

  fi

} # end: stage_4_setup_whiteinge_diffconflicts

stage_4_download_log4sh () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  echo
  echo "WARNING: Deprecated: stage_4_download_log4sh"
  echo
  return

  if false; then

    stage_announcement "stage_4_download_log4sh"

    pushd ${OPT_DLOADS} &> /dev/null

    # https://sites.google.com/a/forestent.com/projects/log4sh

    # 1.4.x Stable — SVN: browse, repository
    # Version   Date              MD5 Sum
    # 1.4.2     Sat Jun 02 2007   b2177ab1f84a6cd91faf123bce74c899
    # 1.4.1     Sun May 06 2007   1f4f3bf9b6c26380a276777e43c27a6e
    # 1.4.0     Fri Jan 05 2007   b8cf7d33b0aaa0dcc8b0f6a6e4cb7f9c
    if false; then
      wget -N http://downloads.sourceforge.net/log4sh/log4sh-1.4.2.tgz
      tar xzf log4sh-1.4.2.tgz
      cd log4sh-1.4.2
      make test-prep
      cd test
      if false; then
        ./hello_world
        ./test-prop-config
        ./test-runtime-config
      fi
    fi

    # 1.5.x Development — SVN: browse, repository
    # Version   Date              MD5 Sum
    #     Comments
    # 1.5.0     Mon May 07 2007   4fc80cd6eab3b804e28e2ef73c349609
    #     Known issues. Please use the HEAD version.
    wget -N http://downloads.sourceforge.net/log4sh/log4sh-1.5.0.tgz
    if true; then
      tar xzf log4sh-1.5.0.tgz
      cd log4sh-1.5.0/
    fi

    popd &> /dev/null

  fi

} # end: stage_4_download_log4sh

stage_4_install_disable_wakeup_on_lid () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_install_disable_wakeup_on_lid"

  PREFIX=${HOME}/.fries/once/recipe/etc/init.d

  if [[ -e ${PREFIX}/home-fries-disable-wakeup-on-lid ]]; then
    if [[ -e /etc/init.d/home-fries-disable-wakeup-on-lid ]]; then
      echo "CLOBBERING: Exists: /etc/init.d/home-fries-disable-wakeup-on-lid"
    fi
    sudo /bin/cp -f ${PREFIX}/home-fries-disable-wakeup-on-lid /etc/init.d/
    sudo /bin/chmod 755 /etc/init.d/home-fries-disable-wakeup-on-lid
    sudo /bin/chown root /etc/init.d/home-fries-disable-wakeup-on-lid
    sudo /bin/chgrp root /etc/init.d/home-fries-disable-wakeup-on-lid
    sudo update-rc.d home-fries-disable-wakeup-on-lid defaults
  fi

} # end: stage_4_install_disable_wakeup_on_lid

stage_4_install_fluentd_er_td_agent () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_install_fluentd_er_td_agent"

  echo
  echo "WARNING: Deprecated: stage_4_install_fluentd_er_td_agent"
  echo
  return

  # http://docs.fluentd.org/articles/install-by-deb

  # Fluentd td-agent, used with ELK stack (Elasticsearch, Logstash, Kibana).
  # 2016-11-06: I don't really need this; don't use it.

  # 2016-10-25: Following comments and code were cribbed from:
  #
  #   curl -L https://toolbelt.treasuredata.com/sh/install-ubuntu-trusty-td-agent2.sh
  #
  # - [lb]

  if [[ ! -f /etc/apt/sources.list.d/treasure-data.list ]]; then
    # run inside sudo
    sudo sh <<SCRIPT
      curl https://packages.treasuredata.com/GPG-KEY-td-agent | apt-key add -

      # add treasure data repository to apt
        echo "deb http://packages.treasuredata.com/2/ubuntu/trusty/ trusty contrib" \
          > /etc/apt/sources.list.d/treasure-data.list

      # update your sources
      apt-get update

      # install the toolbelt
      apt-get install -y --force-yes td-agent
SCRIPT

  fi

  # To start the engine:
  #   sudo /etc/init.d/td-agent restart
  #   sudo /etc/init.d/td-agent status

  # See logs at:
  #   tail -f /var/log/td-agent/td-agent.log
  # and test via http:
  #   curl -X POST -d 'json={"json":"message"}' http://localhost:8888/debug.test

  popd &> /dev/null

} # end: stage_4_install_fluentd_er_td_agent

stage_4_install_arduino () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_install_arduino"

  ARDUINO_IDE="${OPT_DLOADS}/arduino-1.6.12/arduino"

  if [[ -f ${ARDUINO_IDE} ]]; then
    echo
    echo "${REINSTALL_OR_SKIP}: Already installed: ${ARDUINO_IDE}"
    echo
    if ! ${FORCE_REINSTALL}; then
      return
    fi
  fi

  pushd ${OPT_DLOADS} &> /dev/null

  ARDUINO_VERS="arduino-1.6.12"

  wget http://www.arduino.cc/download.php?f=/${ARDUINO_VERS}-linux64.tar.xz

  /bin/mv -f \
    "download.php?f=%2F${ARDUINO_VERS}-linux64.tar.xz" \
    "${ARDUINO_VERS}-linux64.tar.xz"

  tar xvf arduino-1.6.12-linux64.tar.xz

  cd arduino-1.6.12

  ./install.sh
  # "Adding desktop shortcut, menu item and file associations for Arduino IDE... done!"

  # Fix it so normal users can hook US port (otherwise you have to `sudo arduino`, blech).
  sudo usermod -a -G dialout $USER
  #sudo chmod a+rw /dev/ttyACM0

  popd &> /dev/null

} # end: stage_4_install_arduino

stage_4_install_google_earth () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_install_google_earth"

  pushd ${OPT_DLOADS} &> /dev/null

  wget -N https://dl.google.com/dl/earth/client/current/google-earth-stable_current_amd64.deb
  sudo apt-get install -y lsb-core
  sudo apt-get -f install
  sudo dpkg -i google-earth-stable_current_amd64.deb
  # Crashes, at least when viewing the moon.
  # Also, the planet dropdown doesn't display,
  #  but you can down-arrow and hit Enter and guess.

  popd &> /dev/null

} # end: stage_4_install_google_earth
# DEVs: CXPX above template for easy-making new function.

stage_4_install_opera () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_install_opera"

  pushd ${OPT_DLOADS} &> /dev/null

  # 2016-11-16: I'm having issues with a certain financial
  # website and am curious if a fresh browser will trick it.
  # And it works! Ug.

  # wget https://www.opera.com/download/get/?id=40294&location=411&nothanks=yes&sub=marine
  # What, open Firefox and have user fetch it?
  #
  #  firefox https://opera.com
  #  cd ~/Downloads
  #  sudo dpkg -i opera-stable_41.0.2353.56_amd64.deb
  #  # Asks to install to apt, writes
  #  #   /etc/apt/sources.list.d/opera-stable.list
  #  #   deb https://deb.opera.com/opera-stable/ stable non-free #Opera Browser (final releases)

  popd &> /dev/null

} # end: stage_4_install_opera

stage_4_install_virtualenv () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_install_virtualenv"

  pushd ${OPT_DLOADS} &> /dev/null

  #sudo apt-get install -y virtualenvwrapper
  sudo pip2 install virtualenv virtualenvwrapper
  sudo pip3 install virtualenv virtualenvwrapper

  # See bashrc for:
  #   source /usr/share/virtualenvwrapper/virtualenvwrapper.sh

  popd &> /dev/null

} # end: stage_4_install_virtualenv

stage_4_install_heroku () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_install_heroku"

  pushd ${OPT_DLOADS} &> /dev/null

  # This installation courtest Heroku's installer script:
  #
  #   wget -N https://toolbelt.heroku.com/install-ubuntu.sh
  #   sudo sh install-ubuntu.sh
  #
  # which was a little annoying because it edited ~/.bashrc
  # (who does that without asking?) but at least it worked.

  # run inside sudo
  sudo sh <<SCRIPT

  # add heroku repository to apt
  echo "deb http://toolbelt.heroku.com/ubuntu ./" > /etc/apt/sources.list.d/heroku.list

  # install heroku's release key for package verification
  wget -O- https://toolbelt.heroku.com/apt/release.key | apt-key add -

  # update your sources
  apt-get update

  # install the toolbelt
  apt-get install -y heroku-toolbelt

  # install ruby if needed (vervet)
  # 2016-11-18: [lb] notes the easy use of `type` vs `command -v`.
  if ! type ruby >/dev/null 2>&1; then
    apt-get install -y ruby
  fi

SCRIPT

  popd &> /dev/null

} # end: stage_4_install_heroku

stage_4_install_interactive_python_notebooks () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_install_interactive_python_notebooks"

  pushd ${OPT_DLOADS} &> /dev/null

  # FIXME: I should just have an array of package I pip2 and pip3 install,
  #        like I do with apt-get.
  #        2016-11-19: So far it's, like, a dozen packages or so. Not a lot.
  #        See existing:
  #         stage_4_all_the_young_pips

  # bypthon runs in your terminal and does fancy autocomplete and
  # syntax highlighting, unlike the built-in Python interpreter.
  #
  # There's also a Rewind feature to undo? previous commands
  # so you can replay them -- try Ctrl-r.
  #
  # http://bpython-interpreter.org/about.html
  sudo pip2 install bpython
  sudo pip3 install bpython

  # IPython uses a web browser for your interaction
  #
  # Ton of features
  # http://ipython.readthedocs.io/en/stable/overview.html
  #
  # http://jupyter.readthedocs.io/en/latest/running.html#running
  # http://jupyter.readthedocs.io/en/latest/ipython/content-ipython.html
  # http://ipython.readthedocs.io/en/stable/
  sudo pip2 install jupyter
  sudo pip3 install jupyter
  # Takes care of:
  #  sudo pip2 install ipython
  #  sudo pip3 install ipython
  # And this is all, "Requirement already satisfied:"
  #  python -m pip install ipykernel

  # Not really sure what this does but did it.
  # http://ipython.readthedocs.io/en/stable/install/index.html
  # Says: "register an IPython kernel with Jupyter"
  #python -m ipykernel install [--user] [--name <machine-readable-name>] [--display-name <"User Friendly Name">]
  python -m ipykernel install --user

  # Starting it.
  #
  # Here's the bigger apps web notebook.
  #
  # $ jupyter notebook
  #
  # Here's in interactive IPython shell.
  #
  # $ ipython
  #
  # And here's your Python browser notebook.
  #
  # $ ipython notebook
  # which looks the same as the jupyter notebook.
  #
  # Choose: New > Python notebook

  # Some help:
  #
  # https://geosci.uchicago.edu/~rtp1/PrinciplesPlanetaryClimate/Python/NotebookQuickstart/InstantNotebooks.html

  popd &> /dev/null

} # end: stage_4_install_interactive_python_notebooks

stage_4_install_node_js () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_install_node_js"

  pushd ${OPT_DLOADS} &> /dev/null

  # Start with node's package manager,
  #   `npm <https://www.npmjs.com/>`__.

  # 2016-11-21: On older desktop, 14.04:
  #   $ sudo apt-get install -y npm
  #   ...
  #   The following packages have unmet dependencies:
  #   ...
  #
  #   $ sudo apt-get update
  #   $ sudo apt-get upgrade
  #   $ sudo apt-get install -f
  #   $ sudo apt-get install -y npm
  #
  #   but this didn't fix things....
  #
  #   $ sudo apt-get autoremove
  #   # didn't help
  #
  #   $ npm -v
  #   3.10.8
  #
  # askubuntu says install nodejs, not npm.
  #
  #   http://askubuntu.com/questions/462337/couldnt-install-npm-on-ubuntu
  #
  #sudo apt-get install -y npm
  sudo apt-get install -y nodejs

  # Next, download and compile ``node``.

  #LATEST_VERS="v0.10.35"
  #LATEST_VERS="v6.9.1"
  LATEST_VERS="v6.11.1"
  #LATEST_VERS="v7.1.0"

  # 2017-07-20: v6.9.1 was not x64?
  #wget -N http://nodejs.org/dist/${LATEST_VERS}/node-${LATEST_VERS}.tar.gz
  wget -N http://nodejs.org/dist/${LATEST_VERS}/node-${LATEST_VERS}-linux-x64.tar.gz

  if [[ ${LATEST_VERS} == "v6.9.1" ]]; then
    tar -xvzf node-${LATEST_VERS}.tar.gz
    cd node-${LATEST_VERS}
    ./configure
    make
    sudo make install
  else
    # 2017-07-20: v6.11.1 ships pre-built.
    tar -xvzf node-${LATEST_VERS}-linux-x64.tar.gz
    cd ${OPT_BIN} &> /dev/null
    /bin/ln -sf ${OPT_DLOADS}/node-${LATEST_VERS}-linux-x64/bin/node
    /bin/ln -sf ${OPT_DLOADS}/node-${LATEST_VERS}-linux-x64/bin/npm
  fi

  popd &> /dev/null

} # end: stage_4_install_node_js

stage_4_install_mocha () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_install_mocha"

  # See:
  #  http://dareid.github.io/chakram/

  pushd ${OPT_DLOADS} &> /dev/null

  # I think this is what you run in the directory you want to
  # create tests in.
  #   npm init
  #   npm install --save-dev chakram
  sudo npm install -g mocha

  popd &> /dev/null

} # end: stage_4_install_mocha

stage_4_install_zoom_cloud_meetings () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_install_zoom_cloud_meetings"

  pushd ${OPT_DLOADS} &> /dev/null

  # https://www.zoom.us

  mkdir -p zoom.us
  cd zoom.us

  wget -N https://www.zoom.us/linux/download/pubkey
  wget -N https://www.zoom.us/client/latest/zoom_amd64.deb

  # 2016-11-22: How did I not need this at home, 14.04? But I do on new 16.04.
  sudo apt-get install -y rpm
  sudo rpm --import pubkey
  sudo dpkg -i zoom_amd64.deb

  # 2016-11-22: And this, too? Weird.
  sudo apt-get install -y libxcb-xtest0-dev libxcb-xtest0

  # And then, naturally.

  popd &> /dev/null

} # end: stage_4_install_zoom_cloud_meetings


stage_4_install_visual_studio_code () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_install_visual_studio_code"

  echo
  echo "FIXME: Install Visual Studio code yourself"
  echo
  return

  # Wanting to debug node.js. Apparently VS is risen.

  pushd ${OPT_DLOADS} &> /dev/null

  # FIXME: This is not quite automation friendly.
  wget -N https://go.microsoft.com/fwlink/?LinkID=760868
  /bin/mv index.html\?LinkID=760868 code_1.7.2-1479766213_amd64.deb
  # FIXME: Where's their signature??
  sudo dpkg -i code_1.7.2-1479766213_amd64.deb

  # How obnoxious! Or pretentious. They called it `code`. Bwah.
  # To run:
  #   code &

  popd &> /dev/null

} # end: stage_4_install_visual_studio_code

stage_4_install_ttygif () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_install_ttygif"

  pushd ${OPT_DLOADS} &> /dev/null

  # 2016-12-09: These packages were *not* added to Big List in setup_ubuntu.sh.
  #   http://nethack.wikia.com/wiki/Ttyrec#ttyrec_format
  sudo apt-get install -y imagemagick ttyrec gcc x11-apps
  git clone https://github.com/icholy/ttygif.git
  cd ttygif
  make
  sudo make install

  # Then:
  #   ttyrec myrecording
  #   ^D # or `exit`, if you disabled terminal Ctrl-D.
  #   ttygif myrecording

  popd &> /dev/null

} # end: stage_4_install_ttygif

stage_4_install_cassandra () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_install_cassandra"

  pushd ${OPT_DLOADS} &> /dev/null

  # https://cassandra.apache.org/download/

  echo "deb http://www.apache.org/dist/cassandra/debian 39x main" \
    | sudo tee -a /etc/apt/sources.list.d/cassandra.sources.list

  curl https://www.apache.org/dist/cassandra/KEYS | sudo apt-key add -

  sudo apt-get update

  sudo apt-get install -y cassandra

  # See also:
  #   https://www.influxdata.com/
  #   https://github.com/influxdata/influxdb

  popd &> /dev/null

} # end: stage_4_install_cassandra

stage_4_make_install_multitail () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_make_install_multitail"

  pushd ${OPT_DLOADS} &> /dev/null

  # 2017-01-23: multitail "prints hats" bug:
  #   https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=824430
  #   > Package: multitail
  #   > Version: 6.4.2-1
  #   > Severity: normal
  # Ubuntu 14.04's repo installs 6.0.
  # I would see output like
  #   ^`^`^`^`^`^`^`^`^`^`^`^`^`^`^`^`^`^`^`^`^`^`^`^`^`^`^`^`^`^
  #   `^`^`^`^`^`^`^`^`^`^`^`^`^`^`^`^`^`^`^`^`^`^`^`^`^`^`^`^`^`
  #   ^`^`^`^`^`^`^`^`^`^`^`^`^`^`^`^`^`^`^`^`^`^`^`^`^`^`^`^`^`^
  #   `^`^`^`^`^`^`^`^`^`^`^`^`^`^`^`^`^`^`^`^`^`^`^`^`^`^`^`^`^`
  # 2017-01-23: Crud. After updating to 6.4.2, it still happens!
  #   Fortunately you can just Ctrl-c and start multitail again,
  #   but it's a little annoying.

  # Installing from github did not work::
  #
  #    $ make
  #    cc --std=c99 -Wall -Wextra -Wno-unused-parameter -funsigned-char -O3 -DUTF8_SUPPORT ...
  #    mt.c: In function ‘do_color_print’:
  #    mt.c:624:43: warning: comparison between signed and unsigned integer expressions [-Wsign-compare]
  #       if (mbsrtowcs(&wcur, &dummy, 1, &state) == -1) {
  #    ...
  #
  # Fortunately installing from source archive does

  local mt_vers="6.4.2"

  wget https://www.vanheusden.com/multitail/multitail-${mt_vers}.tgz
  tar xvzf multitail-${mt_vers}.tgz
  cd multitail-${mt_vers}
  make
  sudo make install

  popd &> /dev/null

} # end: stage_4_make_install_multitail

stage_4_janus_sam_ba () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_janus_sam_ba"

  pushd ${OPT_DLOADS} &> /dev/null

  #wget -N http://www.janus-rc.com/Documentation/sam-ba_2.10.zip
  #unzip -d sam-ba_2.10 sam-ba_2.10.zip
  #cd sam-ba_2.10/sam-ba_cdc_linux/

  wget -N http://www.janus-rc.com/Documentation/sam-ba_2.11_linux_janus_04302014.tar.bz2
  tar xvjf sam-ba_2.11_linux_janus_04302014.tar.bz2
  /bin/mv sam-ba_janus sam-ba_janus-2.11
  cd sam-ba_janus-2.11

  # Run:
  #
  #   ./sam-ba

  popd &> /dev/null

} # end: stage_4_janus_sam_ba

stage_4_sdkmanbang () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_sdkmanbang"

  pushd ${OPT_DLOADS} &> /dev/null

  curl -s "https://get.sdkman.io" > get-sdkman.sh
  chmod 775 get-sdkman.sh
  ./get-sdkman.sh

  sdk install gradle 3.4

  popd &> /dev/null

} # end: stage_4_sdkmanbang

stage_4_spatialite_for_android () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

return

  stage_announcement "stage_4_spatialite_for_android"

  pushd ${OPT_DLOADS} &> /dev/null

  if [[ ! -d ${OPT_DLOADS}/spatialite-android ]]; then
    # https://code.google.com/archive/p/spatialite-android/
    git clone https://code.google.com/p/spatialite-android
    cd spatialite-android
  else
    cd ${OPT_DLOADS}/spatialite-android
    git pull origin
  fi

  cd spatialite-android/spatialite-android-library/jni/
  wget http://download.osgeo.org/proj/proj-4.8.0.tar.gz
  wget http://download.osgeo.org/geos/geos-3.3.6.tar.bz2
  wget http://www.sqlite.org/2013/sqlite-amalgamation-3071602.zip
  wget http://www.gaia-gis.it/gaia-sins/libspatialite-sources/libspatialite-4.0.0.tar.gz
  tar -xvzf proj-4.8.0.tar.gz
  tar -xvjf geos-3.3.6.tar.bz2
  unzip sqlite-amalgamation-3071602.zip
  tar -xvzf libspatialite-4.0.0.tar.gz
  cd proj-4.8.0/
  ./configure --build=x86_64-pc-linux-gnu --host=arm-linux-eabi
  cd ..
  cd geos-3.3.6
  ./configure --build=x86_64-pc-linux-gnu --host=arm-linux-eabi
  cd ..
  cd libspatialite-4.0.0/
  ./configure --build=x86_64-pc-linux-gnu --host=arm-linux-eabi
  cd ..
  # Build the native library
  /usr/local/android-ndk-r8b/ndk-build -j10

  popd &> /dev/null

} # end: stage_4_spatialite_for_android

stage_4_libreoffice () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_libreoffice"

  pushd ${OPT_DLOADS} &> /dev/null

  # Remove old installs, lest their binaries clash on tab-complete.
  # E.g.,
  #  sudo apt-get remove --purge libreoffice5.2*
  #  # Or:
  #  dpkg -S /usr/bin/libreoffice
  #  sudo apt-get remove --purge libreoffice-common
  sudo apt-get remove --purge libreoffice*

  #LIBRE_LATEST="5.2.6"
  #LIBRE_LATESTT="5.2.6.2"
  #
  LIBRE_LATEST="5.4.1"
  LIBRE_LATESTT="5.4.1.2"

  wget -N http://download.documentfoundation.org/libreoffice/stable/${LIBRE_LATEST}/deb/x86_64/LibreOffice_${LIBRE_LATEST}_Linux_x86-64_deb.tar.gz

  tar xvzf LibreOffice_${LIBRE_LATEST}_Linux_x86-64_deb.tar.gz

  cd LibreOffice_${LIBRE_LATESTT}_Linux_x86-64_deb/DEBS

  sudo dpkg -i *.deb

  popd &> /dev/null

} # end: stage_4_libreoffice

stage_4_jruby () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_jruby"

  pushd ${OPT_DLOADS} &> /dev/null

  wget https://s3.amazonaws.com/jruby.org/downloads/9.1.8.0/jruby-bin-9.1.8.0.tar.gz
  tar xvzf jruby-bin-9.1.8.0.tar.gz
  mv jruby-9.1.8.0/ ${OPT_BIN}

  # You can run jruby as-is:
  #
  #   $ cd ${OPT_BIN}/jruby-9.1.8.0
  #   $ bin/jruby -v
  #   jruby 9.1.8.0 (2.3.1) 2017-03-06 90fc7ab Java HotSpot(TM)
  #     64-Bit Server VM 25.111-b14 on 1.8.0_111-b14 +jit [linux-x86_64]
  #
  # But you cannot run irb because your PATH isn't setup. E.g.,
  #
  #   $ bin/irb -v
  #   /usr/bin/env: jruby: No such file or directory
  #
  # You can update your PATH, as such:
  #
  #   $ export PATH=/srv/opt/bin/jruby-9.1.8.0/bin:$PATH
  #   $ irb -v
  #   Ignoring byebug-9.0.6 because its extensions are not built.
  #     Try: gem pristine byebug --version 9.0.6
  #   irb 0.9.6(09/06/30)
  #
  # And then I did as it said -- but while running gem pristine, I
  # worried I'd screw up my existing, non-Java ruby installation!
  # But I don't think I did.
  #
  # Nonetheless, the command failed -- but, oddly,
  # the "Ignoring byebug-9.0.6" went away after this!
  #
  #   $ gem pristine byebug --version 9.0.6
  #   Restoring gems to pristine condition...
  #   Building native extensions.  This could take a while...
  #   ERROR:  While executing gem ... (Gem::Ext::BuildError)
  #       ERROR: Failed to build gem native extension.
  #
  #       current directory: /home/user/.gem/ruby/2.3.0/gems/byebug-9.0.6/ext/byebug
  #   /srv/opt/bin/jruby-9.1.8.0/bin/jruby -r ./siteconf20170417-3391-1w2jst5.rb extconf.rb
  #   creating Makefile
  #
  #   current directory: /home/user/.gem/ruby/2.3.0/gems/byebug-9.0.6/ext/byebug
  #   make "DESTDIR=" clean
  #
  #   current directory: /home/user/.gem/ruby/2.3.0/gems/byebug-9.0.6/ext/byebug
  #   make "DESTDIR="
  #   make: *** No rule to make target
  #     `/srv/opt/bin/jruby-9.1.8.0/lib/ruby/include/ruby/ruby.h',
  #     needed by `breakpoint.o'.  Stop.
  #
  #   make failed, exit code 2
  #
  #   Gem files will remain installed in /home/user/.gem/ruby/2.3.0/gems/byebug-9.0.6 for inspection.
  #   Results logged to /home/user/.gem/ruby/2.3.0/extensions/universal-java-1.8/2.3.0/byebug-9.0.6/gem_make.out
  #
  # With my PATH temporarily updated, I tried a few things.
  #
  # On thing I noticed is the lag between running a command
  # and seeing a response.
  #
  # For instance, `irb -v` replies immediately against the normal
  # ruby executable, but against jruby, there's a pause.
  #
  #   $ irb -v
  #                          <---------------- 1-2 sec. pause.
  #     irb 0.9.6(09/06/30)
  #
  # As such, I've installed jruby to ${OPT_BIN}, but I did not
  # add its path to PATH in any home-fries .bashrc setup. That
  # is left as an exercise for the reader, should they want to
  # tinker more with jruby.

  popd &> /dev/null

} # end: stage_4_jruby

stage_4_abcde_cd_ripper () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_abcde_cd_ripper"

  pushd ${OPT_DLOADS} &> /dev/null

  # https://abcde.einval.com/download/HEADER.html
  #
  # say:
  #
  #    abcde downloads
  #
  #    Here are current and some historical abcde releases in tar.gz format.
  #    The matching tar.gz.sign files are detached PGP signatures using
  #    either of the following keys:
  #
  #    Steve's key: 587979573442684E
  #    Andrew's key: f8fb375d9cc820b3
  #    Both of these keys are readily available on PGP keyservers.
  #
  #    Enjoy!

  wget -N https://abcde.einval.com/download/abcde-2.8.1.tar.gz
  wget -N https://abcde.einval.com/download/abcde-2.8.1.tar.gz.sign

  # Use gpg to verify PGP signature.
  #   $ gpg abcde-2.8.1.tar.gz.sign
  #   gpg: Signature made Wed 18 Jan 2017 07:57:18 AM CST using RSA key ID 3442684E
  #   gpg: Can't check signature: public key not found
  # Ha, no response:
  #   $ gpg --keyserver abcde.einval.com --recv-key
  # This is no key for Andrew listed
  #   https://pgp.mit.edu/pks/lookup?search=einval.com&op=index
  # So just get Steve's.
  # I saw some suggestions to use MIT keyserver.
  #   $ gpg --keyserver pgp.mit.edu --search-keys steve@einval.com
  # But we can use gpg's built-in list.
  #   $ gpg --search-keys steve@einval.com
  #   gpg: searching for "steve@einval.com" from hkp server keys.gnupg.net
  #   (1)	Steve McIntyre <steve@einval.com>
  #   	  4096 bit RSA key 3442684E, created: 2014-06-16 (revoked)
  #   (2)	Steve McIntyre <steve@einval.com>
  #   	  1024 bit RSA key 88C7C1F7, created: 2014-06-16 (revoked)
  #   (3)	Steve McIntyre <93sam@debian.org>
  #   	Steve McIntyre <steve@einval.com>
  #   	Steve McIntyre <stevem@chiark.greenend.org.uk>
  #   	  4096 bit RSA key 3442684E, created: 2009-05-09
  #   (4)	Steve McIntyre <93sam@debian.org>
  #   	Steve McIntyre <steve@einval.com>
  #   	Steve McIntyre <stevem@chiark.greenend.org.uk>
  #   	Debian CD signing key <debian-cd@lists.debian.org>
  #   	  1024 bit DSA key 88C7C1F7, created: 1999-01-30 (revoked)
  #   Keys 1-4 of 4 for "steve@einval.com".  Enter number(s), N)ext, or Q)uit > 
  # Well, (1) and (2) are revoked. and (3) matches the key in HEADER.html.
  # Out of curiosity:
  #   $ gpg  --recv-key 587979573442684E
  #   gpg: requesting key 3442684E from hkp server keys.gnupg.net
  #   gpg: key 3442684E: public key "Steve McIntyre <steve@einval.com>" imported
  #   gpg: 3 marginal(s) needed, 1 complete(s) needed, PGP trust model
  #   gpg: depth: 0  valid:   1  signed:   0  trust: 0-, 0q, 0n, 0m, 0f, 1u
  #   gpg: Total number processed: 1
  #   gpg:               imported: 1  (RSA: 1)
  # Cute. Run it again:
  #   $ gpg --recv-key 587979573442684E
  #   gpg: requesting key 3442684E from hkp server keys.gnupg.net
  #   gpg: key 3442684E: "Steve McIntyre <steve@einval.com>" not changed
  #   gpg: Total number processed: 1
  #   gpg:              unchanged: 1
  # But not using MIT keyserver:
  #   $ gpg --keyserver pgp.mit.edu --recv-key 587979573442684E
  #   gpg: requesting key 3442684E from hkp server pgp.mit.edu
  #   gpgkeys: key 587979573442684E partially retrieved (probably corrupt)
  #   gpg: invalid radix64 character 2E skipped
  #   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ [repeats 15 x with diff chars]
  #   gpg: malformed CRC
  #   gpg: read_block: read error: invalid keyring
  #   gpg: Total number processed: 0
  gpg --recv-key 587979573442684E
  #gpg --keyserver pgp.mit.edu --recv-key 587979573442684E
  gpg abcde-2.8.1.tar.gz.sign
  # gpg: Signature made Wed 18 Jan 2017 07:57:18 AM CST using RSA key ID 3442684E
  # gpg: Good signature from "Steve McIntyre <steve@einval.com>"
  # gpg:                 aka "Steve McIntyre <93sam@debian.org>"
  # gpg:                 aka "Steve McIntyre <stevem@chiark.greenend.org.uk>"
  # gpg: WARNING: This key is not certified with a trusted signature!
  # gpg:          There is no indication that the signature belongs to the owner.
  # Primary key fingerprint: CEBB 5230 1D61 7E91 0390  FE16 5879 7957 3442 684E
  tar xvzf abcde-2.8.1.tar.gz
  
  # Wow! It's just bash scripts!

  # https://ubuntuforums.org/showthread.php?t=109429
  # Dependencies:
  #   cd-discid (0.9-1)
  #   liboggflac3 (1.1.2-1ubuntu2) <--- NOTE: Not finding this in 14.04...
  #   vorbis-tools (1.0.1-1.4)
  # For MP3:
  #   lame
  # cdreader (from CDROMREADERSYNTAX var in abcde.conf):
  #   cdparanoia libcdio icedax cdda2wav dagrab pird flac
  #   Just wondering (Ubuntu 14.04):
  #     $ sudo apt-get install cdparanoia libcdio icedax cdda2wav dagrab pird flac
  #     Note, selecting 'icedax' instead of 'cdda2wav'
  #     E: Unable to locate package libcdio
  #     E: Unable to locate package dagrab
  #     E: Unable to locate package pird
  #     $ sudo apt-get install cdparanoia libcdio13 icedax flac
  # Also, you'll want bsd-mailx.

  # Hrmm. Getting error. Or warning.
  #
  # Can't locate MusicBrainz/DiscID.pm in @INC (you may need to install the MusicBrainz::DiscID module)
  #   (@INC contains: /etc/perl /usr/local/lib/perl/5.18.2 /usr/local/share/perl/5.18.2 /usr/lib/perl5 /usr/share/perl5 /usr/lib/perl/5.18 /usr/share/perl/5.18 /usr/local/lib/site_perl .)
  #   at /srv/opt/.downloads/abcde-2.8.1/abcde-musicbrainz-tool line 18.
  #   BEGIN failed--compilation aborted at /srv/opt/.downloads/abcde-2.8.1/abcde-musicbrainz-tool line 18.
  #
  # I tried glyr, to no success:
  #   # https://github.com/sahib/glyr
  #   # "Glyr is a music related metadata searchengine, both with commandline interface and C API"
  #   git clone https://github.com/sahib/glyr.git
  #   cd glyr
  #   cmake -DCMAKE_INSTALL_PREFIX=/usr .
  #   make
  #   sudo make install
  #
  # I tried finding DiscID.pm:
  # Already installed:
  #   libdiscid0
  #   libmusicbrainz3-6
  #   libmusicbrainz5-0
  # Didn't get rid of error:
  #   python-libdiscid
  #   python-musicbrainz2
  #   python3-libdiscid
  # Oh, dummy! It's Perl -- .pm.
  #   https://github.com/njh/perl-musicbrainz-discid
  # Did not help:
  #   libmusicbrainz-discid-perl - Perl interface to the MusicBrainz libdiscid library
  # This is it!:
  #   libwebservice-musicbrainz-perl - XML based Web service API to the MusicBrainz database

  cd abcde-2.8.1/
  if [[ ! -e ~/.abcde.conf ]]; then
    /bin/cp abcde.conf ~/.abcde.conf
    # Then you'll want to set CDROM and OUTPUTDIR.
    # NOTE: Really, you'll just add ~/.abcde.conf to ~/.curly repo.
  fi
  # To run, simply:
  #   export PATH="${PATH}:${OPT_DLOADS}/abcde-2.8.1"
  #   ./abcde

  popd &> /dev/null

} # end: stage_4_abcde_cd_ripper
# DEVs: CXPX above template for easy-making new function.

stage_4_remarkable_markdown_ide () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_remarkable_markdown_ide"

  pushd ${OPT_DLOADS} &> /dev/null

  # https://remarkableapp.github.io/
  #
  # https://github.com/jamiemcg/remarkable

  # Prereqs. I tried pip but I need aptitude versions instead, it seems.
  #
  # " error-tolerant HTML parser for Python"
  sudo apt-get install -y python-bs4
  # "Command line utilities to convert html to pdf or image using WebKit"
  sudo apt-get install -y wkhtmltopdf
  # "text-to-HTML conversion library/tool (Python 3 version)"
  sudo apt-get install -y python3-markdown
  # *Spellchecking not enabled.
  # *To enable spellchecking install pygtkspellcheck
  # *https://pypi.python.org/pypi/pygtkspellcheck/
  # pip search pygtkspellcheck
  #sudo pip install pygtkspellcheck
  #sudo pip3 install pygtkspellcheck
  # "The directory '${HOME}/.cache/pip/http' or its parent directory is not
  #   owned by the current user and the cache has been disabled. Please check
  #   the permissions and owner of that directory. If executing pip with sudo,
  #   you may want sudo's -H flag.
  # "The directory '${HOME}/.cache/pip' or its parent directory is not owned
  #   by the current user and caching wheels has been disabled. check the
  #   permissions and owner of that directory. If executing pip with sudo,
  #   you may want sudo's -H flag."
  # -H, --set-home
  #   "Request that the security policy set the HOME environment variable to
  #   the home directory specified by the target user's password database entry.
  #   Depending on the policy, this may be the default behavior."
  sudo -H pip install pygtkspellcheck
  sudo -H pip3 install pygtkspellcheck

  wget -N https://remarkableapp.github.io/files/remarkable_1.87_all.deb
  # FIXME: HERE-AND-EVERYWHERE: Verify Checksums of Downloaded File!s
  sudo dpkg -i remarkable_1.87_all.deb

  popd &> /dev/null

} # end: stage_4_remarkable_markdown_ide

# 2017-08-14: I upgraded from Linux Mint 18.0 to 18.2 and the Clock applet broke:
#
#    $ /usr/lib/mate-panel/clock-applet  
#
#    (clock-applet:16378): Gtk-ERROR **: GTK+ 2.x symbols detected.
#      Using GTK+ 2.x and GTK+ 3 in the same process is not supported
#    Trace/breakpoint trap
#
# Building from scratch fixed it. And repaired what had been a broken
# weather applet for the past half a year or so.
#
# See
#
#   https://pub.mate-desktop.org/releases/1.19
#
# E.g.,
#
#   https://pub.mate-desktop.org/releases/1.19/mate-session-manager-1.19.0.tar.xz
#   https://pub.mate-desktop.org/releases/1.19/mate-applets-1.19.0.tar.xz
#   https://pub.mate-desktop.org/releases/1.19/libmateweather-1.19.1.tar.xz
#   https://pub.mate-desktop.org/releases/1.19/mate-panel-1.19.3.tar.xz
#
# This fcn. installs the latest version of libmateweather, which mate-panel needs,
# and then installs the latest version of mate-panel.
stage_4_update_mate_panel () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_update_mate_panel"

  pushd ${OPT_DLOADS} &> /dev/null

  # Prerequisites for mate-panel.
  sudo apt-get install -y libgtk-3-dev
  sudo apt-get install -y libmate-desktop-dev
  sudo apt-get install -y libmate-menu-dev
  sudo apt-get install -y libdbus-glib-1-dev
  sudo apt-get install -y libwnck-3-dev
  sudo apt-get install -y itstool

  # Install libmateweather.
  cd ${OPT_DLOADS}
  wget https://pub.mate-desktop.org/releases/1.19/libmateweather-1.19.1.tar.xz
  tar xf libmateweather-1.19.1.tar.xz
  cd libmateweather-1.19.1
  ./configure
  make
  make check
  sudo make install
  make installcheck
  make clean

  # Install mate-panel.
  cd ${OPT_DLOADS}
  wget https://pub.mate-desktop.org/releases/1.19/mate-panel-1.19.3.tar.xz
  tar xf mate-panel-1.19.3.tar.xz
  cd mate-panel-1.19.3/
  ./configure
  make
  make check
  sudo make install
  make installcheck
  make clean

  popd &> /dev/null

} # end: stage_4_update_mate_panel

stage_4_fcn_meld () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_fcn_meld"

  # Ubuntu 16.04+:
  try_meld="meld-3.17.4"
  try_major="3.17"
  source /etc/lsb-release
  if [[ $DISTRIB_CODENAME == 'rebecca' ]]; then
    # Mint 17.X is rebecca is trusty is Ubuntu 14.04.

    # On Ubuntu 14.04, on setup.py install, you'll see:
    #   unable to execute 'gtk-update-icon-cache': No such file or directory
    #   error: command 'gtk-update-icon-cache' failed with exit status 1
    # Or, if you run bin/meld, you'll see, e.g.,:
    #    $ meld-3.15.3/bin/meld
    #    Meld requires GTK+ 3.14 or higher.
    try_meld="meld-3.14.2"
    try_major="3.14"
  fi

  pushd ${OPT_DLOADS} &> /dev/null
  wget https://download.gnome.org/sources/meld/${try_major}/${try_meld}.tar.xz
  tar xvf ${try_meld}.tar.xz

  # On 16.04, I tried symlinking from bin, but the old version shadows it.
  #   cd ${OPT_BIN}
  #   ln -s /srv/opt/.downloads/${try_meld}/bin/meld
  # Even running it directly ran the old version.
  #   $OPT_BIN/meld
  # May be a redirection issue? I.e., wrapper script loads python module,
  #   but path is to old meld package.
  if [[ $DISTRIB_CODENAME == 'rebecca' ]]; then
    # The build fails on 14.04.
    #    $ sudo python3 setup.py install --prefix=/usr
    #    ...
    #    copying build/help/es/flattened-view.page -> /usr/share/help/es/meld
    #    running gtk-update-icon-cache
    #    gtk-update-icon-cache -q -t /usr/share/icons/hicolor
    #    unable to execute 'gtk-update-icon-cache': No such file or directory
    #    error: command 'gtk-update-icon-cache' failed with exit status 1
    # But don't bother trying to install gtk-update-icon-cache.
    # That relies on gettext being updated, but you don't want to
    # change your gettext version (and you certainly don't want to
    # change your GLib version, either).
    cd ${OPT_BIN}
    ln -s /srv/opt/.downloads/${try_meld}/bin/meld
    sudo mv /usr/bin/meld /usr/bin/TBD-meld
  else
    cd ${try_meld}
    sudo apt-get install -y itstool
    sudo python3 setup.py install --prefix=/usr
  fi

  popd &> /dev/null

  # =======================================================================

} # end: stage_4_fcn_meld

stage_4_long_live_oh_what_ok_goodbye_awesomegrep () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_long_live_oh_what_ok_goodbye_awesomegrep"

  pushd ${OPT_DLOADS} &> /dev/null

  # Old version remains installed...
  #sudo apt-get remove silversearcher-ag
  # Update >= 0.33.0 so .ignore files are recognized.
  wget -O the_silver_searcher-2.1.0.tar.gz https://github.com/ggreer/the_silver_searcher/archive/2.1.0.tar.gz
  tar xvzf the_silver_searcher-2.1.0.tar.gz
  cd the_silver_searcher-2.1.0
  sudo apt-get install -y automake pkg-config libpcre3-dev zlib1g-dev liblzma-dev
  ./build.sh
  sudo make install

  popd &> /dev/null

} # end: stage_4_long_live_oh_what_ok_goodbye_awesomegrep

stage_4_long_live_silver_searcher_hoorah_ripgrep () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_long_live_silver_searcher_hoorah_ripgrep"

  pushd ${OPT_DLOADS} &> /dev/null

  LATEST_BURNT_SUSHI_RIPGREP_VERSION=0.6.0

  wget -N \
    https://github.com/BurntSushi/ripgrep/releases/download/${LATEST_BURNT_SUSHI_RIPGREP_VERSION}/ripgrep-${LATEST_BURNT_SUSHI_RIPGREP_VERSION}-i686-unknown-linux-musl.tar.gz

  tar xvzf ripgrep-${LATEST_BURNT_SUSHI_RIPGREP_VERSION}-i686-unknown-linux-musl.tar.gz
  #cd ripgrep-${LATEST_BURNT_SUSHI_RIPGREP_VERSION}-i686-unknown-linux-musl
  #cd ${OPT_BIN}
  #/bin/ln -s /srv/opt/.downloads/ripgrep-${LATEST_BURNT_SUSHI_RIPGREP_VERSION}-i686-unknown-linux-musl/rg
  # Argh. It needs to be on Vim's $PATH...
  #  " NOTE: :TabMessage echo $PATH
  #  "   /usr/local/sbin
  #  "  :/usr/local/bin
  #  "  :/usr/sbin
  #  "  :/usr/bin
  #  "  :/sbin
  #  "  :/bin
  #  "  :/usr/games
  #  "  :/usr/local/games
  #  "  :/home/landonb/.rvm/bin
  cd /usr/local/bin
  # FIXME/2017-09-13: I am guessing you'll need a -f here the next time you install-OS.
  sudo /bin/ln -s /srv/opt/.downloads/ripgrep-${LATEST_BURNT_SUSHI_RIPGREP_VERSION}-i686-unknown-linux-musl/rg

  popd &> /dev/null

} # end: stage_4_long_live_silver_searcher_hoorah_ripgrep

stage_4_fcn_template () {
  if ${SKIP_EVERYTHING}; then
    return
  fi

  stage_announcement "stage_4_fcn_template"

  pushd ${OPT_DLOADS} &> /dev/null

  popd &> /dev/null

} # end: stage_4_fcn_template
# DEVs: CXPX above template for easy-making new function.

# ==============================================================
# Application Main()

setup_customize_extras_go () {
  echo "-------------------------"
  echo "setup_customize_extras_go"
  echo "-------------------------"

  # Make the `staff` group owner of root-level /srv/.
  if [[ -n ${USE_STAFF_GROUP_ASSOCIATION} ]]; then
    sudo chgrp ${USE_STAFF_GROUP_ASSOCIATION} /srv
    sudo chmod g+w /srv
  fi

  if ! ${SKIP_APT_GET_UPDATE}; then
    sudo apt-get update
  fi

  # *** Interactive installers. Get 'em done first.

  # Ballickwad.
  stage_4_google_drive_drive

  # Invalid selection.
  stage_4_td_ameritrade_thinkorswim

  stage_4_oracle_java_jre

  # *** Non-interactive Important installers.

  # 2016-11-28: Do py3.5 now so pip3 installs its mod'ls.
  #
  # Install Python 3.5 from deadsnakes.
  # FIXME: This should be distro-dependent.
  stage_4_python_35

  # *** Non-interactive installers.

  # Tell Hamster to start on login.
  stage_4_hamster_time_tracker_setup
  stage_4_hamster_briefs_setup

  # Tell Pidgin to start on login.
  # 2016-09-26: Disabling. Using HipChat now.
  # No one really chats to me on XMPP. At Cyclopath, sure,
  # and at Excensus, yeah, one guy, but no one personally
  # really does anymore. It's either SMS or Facebook Messenger.
  #stage_4_pidgin_setup_autostart

  # Tell Gmail Notifier to start on login.
  stage_4_gmail_notifier_setup

  # Quicktile lets you easily resize windows.
  stage_4_quicktile_install

  # Configure Postgresql.
  # This really only sets 'staff' as the group for the config files.
  stage_4_psql_configure

  # Configure Apache.
  #stage_4_apache_configure

  # Install the dropbox.py script.
  stage_4_dropbox_install

  # Configure Web browsers.
  # - Firefox fcn. is a no-op.
  stage_4_firefox_configure
  # - wget and dpkg Chrome.
  stage_4_chrome_install
  # - set up plugins manually; this is also a no-op.
  stage_4_https_everywhere_install

  # Woop! Woop! for VirtualBox.
  stage_4_virtualbox_install

  # Install Abode Reader.
  stage_4_reader_install

  # Install a simple reST renderer using pip.
  stage_4_restview_install

  # The Worst Metric Ever: Count Lines of Code!
  # - wget to /srv/opt/bin, pretty simple.
  stage_4_cloc_install

  # Install parT for Dubsacks Vim.
  # - This is probably already installed by vendor_dubsacks.sh.
  stage_4_parT_install

  # 2015.01.24: The Todo.txt project seems nifty, as does
  #                 ti — A silly simple time tracker, but
  #                 perhaps Ultimate Time Tracker has a few
  #                 tricks that ti could learn (I like the
  #                 feel of ti but the features of utt...
  #                 no, wait, punch-time-tracking seems cool).

  # Cookiecutter is a boilerplate maker.
  # - Which I haven't really ever needed to use
  #   because I really start projects from scratch.
  stage_4_cookiecutter_install

  # Rock you like a hurricane!
  stage_4_spotify_install
  stage_4_relocate_spotify_cache

  # Ah, classic open source GIS tools, I honor thee.
  stage_4_openjump_install

  # Install pip, and use pip to install uncommitted and argcomplete.
  # 2016-11-19: And why not more pips while we're at it.
  stage_4_all_the_young_pips

  # 2016-12-06: Now it's Ruby's time?
  stage_4_install_ruby_install
  stage_4_shiny_precious_gems

  # Put ~/.fonts at /srv/opt/.fonts so we don't incur an SSD or
  # encrypted home cost.
  stage_4_indirect_user_fonts

  # Some open source fonts I've found that I include. Unicode and more.
  stage_4_font_mania

  # A very nice font for text editing.
  # Probably already installed for Dubsacks Vim.
  stage_4_font_typeface_hack

  # 2016-10-10: Today, Google release NoTo -- No Tofu.
  stage_4_font_google_noto

  # Ah, Sqlite. Sometimes you're there, and sometimes
  # you're not, but if you weren't and I was looking
  # for you, I'd be distressed.
  stage_4_sqlite3

  # Exoohno.
  state_4_mod_spatialite

  # Dark Table is a sophisticated RAW image editor.
  # Fortunately we can apt it from a third party repo.
  stage_4_darktable

  # DigiKam is a decent photo organization tool. It's
  # also a pain to build from scratch.
  ##stage_4_digikam_from_scratch
  #stage_4_digikam_from_distro
  # 2016-09-17: Aha!
  # 2016-11-13: Wait, not on trusty?
  # FIXME: See if this works on xenial.
  #stage_4_digikam5_from_distro
  # 2017-05-20: Sweet! Using Linux AppImage!
  stage_4_digikam_install_appimage

  # Dah Gimp Dah Gimp Dah Gimp!
  stage_4_gimp_plugins
  stage_4_gimp_docs

  # Lettuce route please.
  stage_4_garmin_software

  # Yerp!
  stage_4_android_studio

  # Zoinks.
  stage_4_zoneminder

  # PNG minifimizer.
  stage_4_optipng

  stage_4_password_store

  stage_4_py_chjson

  stage_4_hipchat_client

  stage_4_install_docker

  stage_4_install_docker_compose

  source ./installers/git_from_repo.sh
  git_install_from_git_core_ppa

  stage_4_openshift_client

  stage_4_jq_cli_json_processor

  stage_4_gnome_encfs_manager

  stage_4_exosite_setup

  stage_4_go_get_go

  stage_4_go_delve_debugger

  stage_4_go_get_crap

  stage_4_fix_firefox_vertical_scrollbar_warp_to_click

  stage_4_libmateweather

  stage_4_open_shift_origin_binary

  stage_4_install_disable_wakeup_on_lid

  # Nope!
  #
  #  stage_4_setup_whiteinge_diffconflicts
  #
  #  stage_4_download_log4sh

  # Docker container logger collector.
  # 2016-10-26: I'll stick to the syslog logger for now.
  #stage_4_install_fluentd_er_td_agent

  stage_4_install_arduino

  #stage_4_install_google_earth

  stage_4_install_opera

  stage_4_install_virtualenv

  stage_4_install_heroku

  stage_4_install_interactive_python_notebooks

  stage_4_install_node_js

  stage_4_install_mocha

  stage_4_install_zoom_cloud_meetings

  stage_4_install_visual_studio_code

  stage_4_install_ttygif

  # 2016-12-12: For work!
  stage_4_install_cassandra

  # 2017-01-31: For awesome!
  stage_4_make_install_multitail

  # 2017-02-07: For work!
  stage_4_janus_sam_ba

  source ./installers/vim_from_source.sh
  vim_clone_compile_install

  stage_4_sdkmanbang

  stage_4_spatialite_for_android

  stage_4_libreoffice

  stage_4_jruby

  stage_4_abcde_cd_ripper

  #stage_4_remarkable_markdown_ide

  # 2017-08-14: Added this but not enabling; may/may not be necessary.
  #stage_4_update_mate_panel

  # 2017-09-06: Why, oh why, do I run such an old OS...
  stage_4_fcn_meld

  # 2017-09-13: And away we go. New grepper. Greppers like to Grep.
  # Grepper Need to Grep.
  stage_4_long_live_oh_what_ok_goodbye_awesomegrep
  stage_4_long_live_silver_searcher_hoorah_ripgrep

  # Add before this'n: stage_4_fcn_template.

  # FIXME/MAYBE: These commands are stubbed.
  # ========================================

  # Setup /etc/updatedb.conf, except this is machine-specific,
  # so there's just a FIXME comment therein for now; a no-op.
  stage_4_updatedb_locate_conf

  # DISABLED/PROBABLY DISABLED SETUPS
  # =================================

  # Configure Meld.
  # - Currently a no-op; not written.
  stage_4_meld_configure

  # Disables and Uninstalls Samba service,
  # which probably definitely doesn't exist
  # in first place.
  stage_4_disable_services

  # Install modern.ie VMs.
  # - Disabled. You're better off copying files locally.
  stage_4_modern_ie_install

  # Install expect, so we can do tty tricks.
  # - This is a no-op since apt-get can install `expect`.
  stage_4_dev_testing_expect_install

  # 2016-03-23: Pencil install is disabled since not used.
  stage_4_pencil_install

  # 2015.01: [lb] still playing around w/ the RssOwl reader...
  #          its inclusion here is not an endorsement, per se.
  # - This is disabled.
  stage_4_rssowl_install

  # Disabled:
  stage_4_jsctags_install

  # 2016-03-23: What's LiClipse again? An Eclipse... Flash debugger?
  #             Python debugger? I can't remembugger.
  #stage_4_liclipse_install

  # Games!
  # - Is no longer any fun; a no-op.
  # Just open Dubsacks Vim and play Tetris(r).
  stage_4_funstuff

  # Intel OpenCL (Open Computing Language) for heavy algorithms,
  # I think, like travelling salesperson problem.
  # 2016-03-23: Disabling; probably just manually install if you
  # need it or find yourself finally writing the alleycat app.
  #stage_4_opencl

  echo
  echo "===================================================================="
  echo
  echo "All done."

} # end: setup_customize_extras_go

if [[ "$0" == "$BASH_SOURCE" ]]; then
  # Only call the setup fcns. if this script is being run and not sourced.
  setup_customize_extras_go
# else, $BASH_SOURCE is not the name of this script; it's
#       the name of the script that's sourcing this script.
fi

# See: stage_4_fcn_template
