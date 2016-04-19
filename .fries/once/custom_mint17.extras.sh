# File: custom_mint17.extras.sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Last Modified: 2016.04.07
# Project Page: https://github.com/landonb/home_fries
# Summary: Third-party tools downloads compiles installs.
# License: GPLv3

# NOTE: If you're copying and pasting manually, source this guy first!:
#         source ./mint17_setup_base.sh

# Unless you source bash_base.sh, gotta make sure some things are set.
if [[ -z ${WM_IS_MATE+x} ]]; then
  WM_IS_MATE=false
fi

stage_4_setup_ensure_dirs () {
  if [[ -z ${OPT_BIN+x} || -z ${OPT_DLOADS+x} || -z ${OPT_SRC+x} ]]; then
    #echo
    #echo "ERROR: Cannot proceed unless (OPT_BIN, OPT_DLOADS, OPT_SRC,) defined."
    #exit 1
    if [[ ! -e ./mint17_setup_base.sh ]]; then
      echo "Error: Expected to find ./mint17_setup_base.sh."
      exit 1
    fi
    DEBUG_TRACE=false
    source ./mint17_setup_base.sh
  fi
  /bin/mkdir -p ${OPT_BIN}
  /bin/mkdir -p ${OPT_DLOADS}
  /bin/mkdir -p ${OPT_SRC}
}
stage_4_setup_ensure_dirs

stage_announcement () {
  echo
  echo "===================================================================="
  echo $1
  echo
  echo
}

stage_4_dropbox_install () {

  stage_announcement "stage_4_dropbox_install"

  pushd ${OPT_BIN} &> /dev/null

  if [[ -e ${OPT_BIN}/dropbox.py ]]; then
    DROPBOX_OLDER="${OPT_BIN}/dropbox.py-`date +%Y.%m.%d-%T`"
    /bin/mv ${OPT_BIN}/dropbox.py ${DROPBOX_OLDER}
    chmod -x ${DROPBOX_OLDER}
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

stage_4_git_configure () {

  stage_announcement "stage_4_git_configure"

  # Create and configure ~/.gitconfig.

  # Configure `git diff|log|mergetool` to use less to display text. With -R,
  # less interprets ANSI color codes, otherwise they're raw, e.g., [ESCapes234.
  # See also: bash's export EDITOR= command.
  git config --global core.pager "less -R"

  # `git mergetool` makes intermediate *.orig files but doesn't delete
  # them unless we tell it to delete them.
  git config --global mergetool.keepBackup false

  # Choose meld as the default diff tool.
  git config --global merge.tool meld

  # MAYBE: Configure your username and email.
  #
  # git config --global user.name "Your Name Comes Here"
  # git config --global user.email you@yourdomain.example.com

  # EXPLAIN: What's cr-at-eol do and why did I copy it here?
  # git config --global core.whitespace cr-at-eol

} # end: stage_4_git_configure

stage_4_hg_configure () {

  stage_announcement "stage_4_hg_configure (enabled? $USE_SETUP_HG)"

  if $USE_SETUP_HG; then
    source_file="${script_absbase}/target/home/user/.hgrc"
    target_file="/home/$USER/.hgrc"
    copy_okay=true
    if [[ ! -e $source_file ]]; then
      echo "Source file absent: Skipping: $source_file"
      copy_okay=false
    fi
    if [[ -e $target_file ]]; then
      echo "Target file exists: Skipping: $target_file"
      copy_okay=false
    fi
    if $copy_okay; then
      m4 \
        --define=HG_USER_NAME="$HG_USER_NAME" \
        --define=HG_USER_EMAIL="$HG_USER_EMAIL" \
        --define=HG_DEFAULT_PATH="$HG_DEFAULT_PATH" \
        $source_file > $target_file
    fi
  fi

} # end: stage_4_hg_configure

stage_4_meld_configure () {

  stage_announcement "Skipping: stage_4_meld_configure"

  # Take a look at custom_mint17.landon.sh for manual steps to setup meld.
  # (This script could edit ~/.gconf/apps/meld/%gconf.xml but the file
  # filters are a little dependent on the user, so make the user do it.)
  :

} # end: stage_4_meld_configure

stage_4_psql_configure () {

  stage_announcement "stage_4_psql_configure"

  # Postgres config. Where POSTGRESABBR is, e.g., "9.1".

  if [[ ! -d /etc/postgresql ]]; then
    echo
    echo "WARNING: Postgres is not installed."
    return
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
    if [[ -e ${script_absbase}/target/common/etc/postgresql/${POSTGRESABBR}/main/pg_hba.conf ]]; then
      sudo /bin/cp -a \
        ${script_absbase}/target/common/etc/postgresql/${POSTGRESABBR}/main/pg_hba.conf \
        /etc/postgresql/${POSTGRESABBR}/main/pg_hba.conf
    fi
  fi

  # MEH: If you implement this, be sure to backup pg_ident.conf.
  if false; then
    if [[ -e ${script_absbase}/common/etc/postgresql/${POSTGRESABBR}/main/pg_ident.conf ]]; then
      m4 \
        --define=HTTPD_USER=${httpd_user} \
        --define=TARGETUSER=$USER \
          ${script_absbase}/common/etc/postgresql/${POSTGRESABBR}/main/pg_ident.conf \
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

  stage_announcement "stage_4_apache_configure"

  if [[ ! -d /etc/apache2 ]]; then
    echo
    echo "WARNING: Apache2 is not installed."
    return
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
    if [[ -e ${script_absbase}/target/common/etc/apache2/apache2.conf ]]; then
      m4 \
        --define=HOSTNAME=${HOSTNAME} \
        --define=MACH_DOMAIN=${USE_DOMAIN} \
          ${script_absbase}/target/common/etc/apache2/apache2.conf \
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

  stage_announcement "stage_4_quicktile_install"

  # QuickTile by ssokolow (similar to WinSplit Revolution) is an edge tiling
  # window feature. It lets you quickly resize and move windows to
  # pre-defined tiles. This is similar to a behavior in Windows 7, GNOME 3,
  # and Cinnamon, when you drag a window to the top, bottom, left or right
  # of the screen and it assumes a window size half of the screen).
  #  See: http://ssokolow.com/quicktile/
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
    set +ex
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

  stage_announcement "stage_4_pidgin_setup_autostart"

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
    sudo apt-get update
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

  if [[ ! -e ${OPT_DLOADS}/hamster-applet ]]; then
    git clone https://github.com/landonb/hamster-applet
  else
    pushd ${OPT_DLOADS}/hamster-applet &> /dev/null
    git pull
    popd &> /dev/null
  fi

  if [[ -f /usr/share/pyshared/hamster/overview.py ]]; then
    HAMSTER_PKGS=/usr/share/pyshared/hamster
  elif [[ -f /usr/lib/python2.7/dist-packages/hamster/overview.py ]]; then
    HAMSTER_PKGS=/usr/lib/python2.7/dist-packages/hamster
  else
    echo
    echo "WARNING: Where's hamster? Try:"
    echo "    locate overview_totals.py"
    exit 1
  fi

  if [[    -e ${HAMSTER_PKGS}/overview.py.ORIG \
        || -e ${HAMSTER_PKGS}/overview_totals.py.ORIG ]]; then
    echo
    echo "WARNING: Skipping hamster install -- possibly already done."
    return
  fi

  pkill -f hamster-service
  pkill -f hamster-windows-service

  sudo /bin/cp -a \
      ${HAMSTER_PKGS}/overview.py \
      ${HAMSTER_PKGS}/overview.py.ORIG
  sudo /bin/cp -a \
      ${HAMSTER_PKGS}/overview_totals.py \
      ${HAMSTER_PKGS}/overview_totals.py.ORIG

  sudo /bin/cp -af \
      hamster-applet/src/hamster/overview.py \
      ${HAMSTER_PKGS}/overview.py
  sudo /bin/cp -af \
      hamster-applet/src/hamster/overview_totals.py \
      ${HAMSTER_PKGS}/overview_totals.py

  popd &> /dev/null

  # Symlink hamster.db to dropbox version.

  # FIXME: Make a bash var for this path...
  HAMSTER_DB_PATH=".local/share/hamster-applet/hamster.db"
  if [[ -d ${HOME}/Dropbox/.fries/home/${HAMSTER_DB_PATH} ]]; then
    if [[ -e ${HOME}/${HAMSTER_DB_PATH} && \
          ! -L ${HOME}/${HAMSTER_DB_PATH} ]]; then
      /bin/mv \
        ${HOME}/${HAMSTER_DB_PATH} \
        ${HOME}/${HAMSTER_DB_PATH}-`date +%Y.%m.%d-%T`
    fi
    /bin/ln -sf \
      ${HOME}/Dropbox/.fries/home/.local/share/hamster-applet/hamster.db \
      ${HOME}/.local/share/hamster-applet
  fi

  # Auto-start hamster on boot.

  mkdir -p $HOME/.config/autostart

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
" > $HOME/.config/autostart/hamster-time-tracker.desktop
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
" > $HOME/.config/autostart/hamster-indicator.desktop

  # Start hamster.

  hamster-indicator &

} # end: stage_4_hamster_time_tracker_setup

stage_4_hamster_briefs_setup () {

  stage_announcement "stage_4_hamster_briefs_setup"

  pushd ${OPT_DLOADS} &> /dev/null

  if [[ ! -e ${OPT_DLOADS}/hamster_briefs ]]; then
    git clone https://github.com/landonb/hamster_briefs
  else
    pushd ${OPT_DLOADS}/hamster_briefs &> /dev/null
    git pull
    popd &> /dev/null
  fi

  /bin/ln -sf ${OPT_DLOADS}/hamster_briefs/hamster_briefs.py ${OPT_BIN}

  popd &> /dev/null

} # end: stage_4_hamster_briefs_setup

stage_4_gmail_notifier_setup () {

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
  cd ${OPT_DLOADS}

  wget -N \
    https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb

  sudo dpkg -i google-chrome-stable_current_amd64.deb

  # Firefox Google Search Add-On
  # Hrm, [lb] thinks the user has to do this themselves...
  #mkdir -p ${OPT_DLOADS}/firefox-google-search-add_on
  #cd ${OPT_DLOADS}/firefox-google-search-add_on
  #wget -N \
  #  https://addons.mozilla.org/firefox/downloads/file/157593/google_default-20120704.xml?src=search

} # end: stage_4_chrome_install

stage_4_https_everywhere_install () {

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
#sudo apt-get update
#sudo apt-get install virtualbox-5.0

  # Get the latest Debian package. At least if this script is uptodate.
  #
  #   https://www.virtualbox.org/wiki/Downloads
  #
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
  LATEST_VBOX_VERS_MAJOR="5.0"
  LATEST_VBOX_VERS_MINOR="16"
  LATEST_VBOX_VERS_BUILD="105871"
  LATEST_VBOX_VERSION_BASE="${LATEST_VBOX_VERS_MAJOR}.${LATEST_VBOX_VERS_MINOR}"
  LATEST_VBOX_VERSION_FULL="${LATEST_VBOX_VERSION_BASE}-${LATEST_VBOX_VERS_BUILD}"
  # Load the release codename, e.g., raring, trusty, wily, etc.
  source /etc/lsb-release
  if [[ $DISTRIB_CODENAME == 'rebecca' ]]; then
    # Mint 17.X is rebecca is trusty.
    DISTRIB_CODENAME=trusty
  fi
  LATEST_VBOX_DEB_PKG="\
virtualbox-${LATEST_VBOX_VERS_MAJOR}_${LATEST_VBOX_VERSION_FULL}~Ubuntu~${DISTRIB_CODENAME}_amd64.deb"
  #LATEST_VBOX_EXTPACK="\
#Oracle_VM_VirtualBox_Extension_Pack-${LATEST_VBOX_VERS_MAJOR}.${LATEST_VBOX_VERSION_FULL}.vbox-extpack"
  #https://www.virtualbox.org/download/testcase/VBoxGuestAdditions_5.0.17-106140.iso

  if [[ -e ${OPT_DLOADS}/${LATEST_VBOX_DEB_PKG} ]]; then
    echo
    echo "WARNING: Skipping VirtualBox install -- Already downloaded."
    echo "Remove download if you want to start over: ${OPT_DLOADS}/${LATEST_VBOX_DEB_PKG}"
    echo
    return
  fi

  pushd ${OPT_DLOADS} &> /dev/null

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

# FIXME: Unless there's a scripty way to add the extension pack,
#        tell user to run `virtualbox &`, navigate to File > Preferences...,
#        click Extensions group,
#        click Icon for Add Package
#        enter: /srv/opt/.downloads/Oracle_VM_VirtualBox_Extension_Pack-4.3.30-101610.vbox-extpack
# 2015.11.19: Actually, just running virtualbox should have it ask you to update the extension pack.

  # FIXME/MAYBE: One doc [lb] read says add youruser to 'lp' and 'users' groups,
  # in addition to obvious 'vboxsf' and 'vboxusers' group. See: /etc/group.

# FIXME: Need this here or in the guest??:
#      virtualbox-guest-additions-iso
# Add to vboxusers? and lp and users?
  #sudo usermod -a -G lp ${USER}
  #sudo usermod -a -G users ${USER}
  sudo usermod -a -G vboxsf ${USER}
  sudo usermod -a -G vboxusers ${USER}

  popd &> /dev/null

} # end: stage_4_virtualbox_install

stage_4_reader_install () {

  stage_announcement "stage_4_reader_install"

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
    cd ${OPT_DLOADS}
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
  fi

  # Here's how to uninstall it:
  # cd /opt/Adobe/Reader9/bin && sudo ./UNINSTALL

} # end: stage_4_reader_install

stage_4_libreoffice_install () {

  stage_announcement "Nope: stage_4_libreoffice_install"

  # 2016.03.23: There's a libreoffice installed by default, right?
  #             Just maybe not libreoffice5...

# FIXME: This fcn. So far I've just done this manually, I think.
  if false; then

    # FIXME: Download libreoffice
    #        then unpack, cd inside, and:
    sudo dpkg -i *.deb

  fi

} # end: stage_4_libreoffice_install

stage_4_modern_ie_install () {

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

  stage_announcement "Don't expect: stage_4_dev_testing_expect_install"

  # Unleash this code if you don't want to just `apt-get install -y expect`.

  if false; then

    # FIXME: Move all the apt-get installs from the big list above
    #        to the setup function that needs them?
    sudo apt-get install -y tcl tcl-dev

    cd ${OPT_DLOADS}
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

  fi

} # end: stage_4_dev_testing_expect_install

stage_4_restview_install () {

  stage_announcement "stage_4_restview_install"

  # Weird. This installs restview with ownership as my ${USER}.
  sudo su -c "pip install restview"

} # end: stage_4_restview_install

# FIXME: Is there a way to automatically get the latest
#        packages from SourceForge without hardcoding here?

stage_4_rssowl_install () {

  stage_announcement "Skipping: stage_4_rssowl_install"

  # RSSOwl RSS Client
  # FIXME: Test RSSOwl and decide if this should be excluded.
  if false; then
    cd ${OPT_DLOADS}
    wget "http://downloads.sourceforge.net/project/rssowl/rssowl%202/2.2.1/rssowl-2.2.1.linux.x86_64.zip"
    unzip rssowl-2.2.1.linux.x86_64.zip -d rssowl-2.2.1
    cd rssowl-2.2.1/rssowl/
# FIXME: Move the installation folder somewhere...
#        or add to PATH...
# ${OPT_DLOADS}/rssowl-2.2.1/rssowl/RSSOwl
  fi

} # end: stage_4_rssowl_install

stage_4_cloc_install () {

  stage_announcement "stage_4_cloc_install"

  pushd ${OPT_BIN} &> /dev/null

  wget -N \
    http://downloads.sourceforge.net/project/cloc/cloc/v1.62/cloc-1.62.pl

  # Set the permissions so you can execute the CLI interface:
  chmod +x ${OPT_BIN}/cloc-1.62.pl

  popd &> /dev/null

} # end: stage_4_cloc_install

stage_4_parT_install () {

  stage_announcement "stage_4_parT_install"

  pushd ${OPT_DLOADS} &> /dev/null

  if [[ ! -e ${OPT_DLOADS}/parT ]]; then
    git clone https://github.com/landonb/parT
  else
    pushd parT &> /dev/null
    git pull
    popd &> /dev/null
  fi

  pushd parT &> /dev/null

  ./build.sh
  sudo /bin/cp -af parT /usr/bin
  sudo chown root:root /usr/bin/parT

  popd &> /dev/null
  popd &> /dev/null

} # end: stage_4_parT_install

stage_4_todo_txt_install () {

  stage_announcement "stage_4_todo_txt_install"

  pushd ${OPT_DLOADS} &> /dev/null

  mkdir $HOME/.todo

  if false; then
    wget -N \
      https://github.com/downloads/ginatrapani/todo.txt-cli/todo.txt_cli-2.9.tar.gz
    tar xvzf todo.txt_cli-2.9.tar.gz
    chmod +x todo.txt_cli-2.9/todo.sh
    /bin/rm todo.txt_cli-2.9.tar.gz
    /bin/ln -s todo.txt_cli-2.9 todo.txt_cli
    /bin/ln -s ${OPT_DLOADS}/todo.txt_cli-2.9/todo.sh ${OPT_BIN}/todo.sh
    # See: ~/.fries/.bashrc/bashrc.core.sh for
    #   source ${OPT_DLOADS}/todo.txt_cli/todo_completion
    # FIXME: You may have to edit the config file to add the path to it.
    /bin/cp ${OPT_DLOADS}/todo.txt_cli-2.9/todo.cfg $HOME/.todo/config
  fi

  if true; then
    git clone https://github.com/landonb/todo.txt-cli
    if [[ ! -e $HOME/.todo/config ]]; then
      /bin/cp ${OPT_DLOADS}/todo.txt_cli/todo.cfg $HOME/.todo/config
    fi
    /bin/ln -s ${OPT_DLOADS}/todo.txt_cli/todo.sh ${OPT_BIN}/todo.sh
    /bin/ln -s ${OPT_BIN}/todo.sh ${OPT_BIN}/to
    # Install addons to /${HOME}/.todo.actions.d/
    #  or probably better yet /${HOME}/actions/
  fi

  popd &> /dev/null

} # end: stage_4_todo_txt_install

stage_4_punch_tt_install () {

  stage_announcement "Skipping: stage_4_punch_tt_install"

  if false; then
    cd ${OPT_DLOADS}
    wget -N \
      https://punch-time-tracking.googlecode.com/files/punch-time-tracking-1.3.zip
    unzip -d punch-time-tracking punch-time-tracking-1.3.zip
    chmod +x punch-time-tracking/Punch.py
    /bin/ln -s ${OPT_DLOADS}/punch-time-tracking/Punch.py ${OPT_BIN}/Punch.py
  fi

} # end: stage_4_punch_tt_install

stage_4_ti_time_tracker_install () {

  stage_announcement "Skipping: stage_4_ti_time_tracker_install"

  if false; then
    cd ${OPT_BIN}
    wget -N \
      https://raw.githubusercontent.com/sharat87/ti/master/bin/ti

    chmod +x ti
  fi

} # end: stage_4_ti_time_tracker_install

stage_4_utt_time_tracker_install () {

  stage_announcement "Skipping: stage_4_utt_time_tracker_install"

  # Ultimate Time Tracker

  if false; then
    cd ${OPT_DLOADS}
    git clone https://github.com/larose/utt.git
    cd utt
    # Untested, but I think it'd be:
    #  python setup.py build
    #  python setup.py install
  fi

  sudo pip install utt

} # end: stage_4_utt_time_tracker_install

stage_4_cookiecutter_install () {

  stage_announcement "stage_4_cookiecutter_install"

  # 2015.02.06: Cookiecutter in the distro is 0.6.4,
  #             but >= 0.7.0 is where it's at.

  sudo pip install cookiecutter

  # WTW?                            -rwxrwx--x
  # 2015.02.19: On fresh Mint 17.1: -rwxr-x--x
  # Anyway, 'other' is missing the read bit.
  sudo chmod 755 /usr/local/bin/cookiecutter

} # end: stage_4_cookiecutter_install

stage_4_keepassx_install () {

  stage_announcement "Skipping: stage_4_keepassx_install"

  # Funny; there's a build problem in the latest version of the source:
  # a missing include. However, we can also just install keepassx with
  # apt-get... though I think a text file and encfs or gpg is probably
  # simpler to use than keepassx. The only security difference is that
  # keepassx automatically clears the clipboard for you; if you use an
  # encrypted file, you'll have to remember to clear the clipboard, or
  # at least to not accidentally paste your password to, say, a web
  # browser search field.

  if false; then

    cd ${OPT_DLOADS}
    wget -N http://www.keepassx.org/releases/keepassx-0.4.3.tar.gz
    tar xvzf keepassx-0.4.3.tar.gz

    cd keepassx-0.4.3

    # This list contains extraneous pacakges.
    # I'm not sure which ones are required; I experimented to find the ones.
    sudo apt-get install -y qt4-qmake qt4-dev-tools qt4-bin-dbg
    # I'm pretty sure these two are required. I know the second one is.
    sudo apt-get install -y libqt4-dev libxtst-dev

    # Fix: lib/random.cpp:98:19: error: ‘getpid’ was not declared in this scope
    # See: https://www.keepassx.org/forum/viewtopic.php?f=4&t=3177
    /bin/sed -i.bak \
      "s/#include \"random.h\"/#include \"random.h\"\n#include <unistd.h>/" \
      src/lib/random.cpp

    qmake
    make
    sudo make install

  fi

}
# end: stage_4_keepassx_install

stage_4_pencil_install () {

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

  stage_announcement "Pretend: stage_4_disable_services"

  # 2015.02.22: From /var/log/auth.log, lines like
  #   Feb 22 14:55:05 philae smbd[30165]: pam_unix(samba:session):
  #     session closed for user nobody
  # but no "session started" or "session opened" lines. Whatever.
  # I don't Samba. https://en.wikipedia.org/wiki/Samba_%28software%29

  # 2016.03.23: Samba's not installed by default;
  #             this is all a no-op, right?

  # Stop it now.
  sudo service smbd stop

  # Have it not start in the future.
  sudo update-rc.d -f smbd remove
  # Restore with:
  #   sudo update-rc.d -f smbd defaults

} # end: stage_4_disable_services

stage_4_spotify_install () {

  stage_announcement "stage_4_spotify_install"

  pushd ${OPT_DLOADS} &> /dev/null

  # From:
  #  https://www.spotify.com/us/download/previews/

  grep repository.spotify.com /etc/apt/sources.list &> /dev/null
  if [[ $? -ne 0 ]]; then
    echo "deb http://repository.spotify.com stable non-free" \
      | sudo tee -a /etc/apt/sources.list &> /dev/null
  fi

  # 2015.05.31: Is adding the key still necessary?
  #             This step not listed on the spotify page.
  sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 94558F59

  sudo apt-get update

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

stage_4_openjump_install () {

  stage_announcement "stage_4_openjump_install"

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

  if [[ ! -e ${OPT_DLOADS}/OpenJUMP-1.8.0-r4164-CORE/bin/oj_linux.sh ]]; then
    unzip OpenJUMP-Portable-1.8.0-r4164-CORE.zip -d OpenJUMP-1.8.0-r4164-CORE-unzip/
    mv OpenJUMP-1.8.0-r4164-CORE-unzip/OpenJUMP-1.8.0-r4164-CORE .
    rmdir OpenJUMP-1.8.0-r4164-CORE-unzip
    ln -sf ${OPT_DLOADS}/OpenJUMP-1.8.0-r4164-CORE/bin/oj_linux.sh ${OPT_BIN}/oj_linux.sh
  fi

  popd ${OPT_DLOADS} &> /dev/null

} # end: stage_4_openjump_install

stage_4_liclipse_install () {

  stage_announcement "stage_4_liclipse_install"

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

  stage_announcement "stage_4_all_the_young_pips"

  pushd ${OPT_DLOADS} &> /dev/null

  was_umask=$(umask)
  umask 0002

  wget -N https://bootstrap.pypa.io/get-pip.py
  sudo python2 get-pip.py
  sudo python3 get-pip.py

  # My ~/.vim/bundle_/ contains a dozenish sub-gits. Uncommitted helps.
  sudo pip install uncommitted
  sudo chmod 755 /usr/local/bin/uncommitted
  # Be sure to specify -l to use locate.
  # E.g., `uncommitted -l ~/.vim`, or `uncommitted -l -v ~/.vim`.

  # https://argcomplete.readthedocs.org/en/latest/#activating-global-completion%20argcomplete
# FIXME:
# The directory '/home/landonb/.cache/pip' or its parent directory is not owned by the current user and caching wheels has been disabled. check the permissions and owner of that directory. If executing pip with sudo, you may want sudo's -H flag.
  sudo pip install argcomplete
  sudo pip3 install argcomplete
  sudo activate-global-python-argcomplete
  # To upgrade:
  sudo pip install --upgrade argcomplete
  sudo pip3 install --upgrade argcomplete

  umask ${was_umask}

  popd &> /dev/null

} # end: stage_4_all_the_young_pips

stage_4_font_mania () {

  stage_announcement "stage_4_font_mania"

  mkdir -p ${HOME}/.fonts

  pushd ${HOME}/.fonts &> /dev/null

  wget -N http://dl.1001fonts.com/santos-dumont.zip
  # Unpack SANTO___.TTF et al
  unzip -o -d santos-dumont santos-dumont.zip
  /bin/mv santos-dumont/SANTO___.TTF .

  wget -N http://dl.1001fonts.com/pinewood.zip
  unzip -o -d pinewood pinewood.zip
  /bin/mv pinewood/Pinewood.ttf .

  # Google Open Sans by Steve Matteson
  wget -N http://dl.1001fonts.com/open-sans.zip
  unzip -o -d open-sans open-sans.zip

  popd &> /dev/null

  # Build font information cache files.
  sudo fc-cache -fv

} # end: stage_4_font_mania

stage_4_font_typeface_hack () {

  stage_announcement "stage_4_font_typeface_hack"

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

stage_4_sqlite3 () {

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
    diff ${SQLITE_BASE}/${SQLITE_BASE}/sqlite3 /usr/bin/sqlite3 &> /dev/null
    if [[ $? -ne 0 ]]; then
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

  popd &> /dev/null

} # end: stage_4_sqlite3

stage_4_opencl () {

  stage_announcement "stage_4_opencl"

  pushd ${OPT_DLOADS} &> /dev/null

  #https://software.intel.com/en-us/intel-opencl

  # https://software.intel.com/en-us/articles/opencl-drivers#ubuntu64
  # https://software.intel.com/en-us/articles/intel-code-builder-for-opencl-api
  # To install both the Code Builder and the OpenCL runtime packages for Linux*, use the following public key: Intel-E901-172E-EF96-900F-B8E1-4184-D7BE-0E73-F789-186F.pub

  wget -N http://registrationcenter.intel.com/irc_nas/5193/intel_code_builder_for_opencl_2015_ubuntu_5.0.0.43_x64.tgz

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

  stage_announcement "stage_4_darktable"

  # NOTE: pmjdebruijn's builds are generally the latest-greatest.
  if true; then
    #deb http://ppa.launchpad.net/pmjdebruijn/darktable-release/ubuntu trusty main
    #deb-src http://ppa.launchpad.net/pmjdebruijn/darktable-release/ubuntu trusty main
    sudo add-apt-repository -y ppa:pmjdebruijn/darktable-release
    # NOTE: To remove the repository:
    #  sudo /bin/rm /etc/apt/sources.list.d/pmjdebruijn-darktable-release-trusty.list
    sudo apt-get update
    sudo apt-get install -y darktable
  else

    # From scratch!

    pushd ${OPT_DLOADS} &> /dev/null

    # Download libgphoto2-2.5.8.tar.bz2 (6.9 MB).
    # http://sourceforge.net/projects/gphoto/files/latest/download?source=files
    sudo apt-get install -y gphoto2 libgphoto2-dev libgphoto2-2-dev libgphoto2-6

    sudo apt-get install -y libgtk2.0-dev libcurl4-gnutls-dev
    # libcurlpp-dev

    # wget -N https://github.com/darktable-org/darktable/archive/release-1.6.9.tar.gz
    # https://github.com/darktable-org/darktable/releases/download/release-1.6.9/darktable-1.6.9.tar.xz
    git clone -b release-1.6.9 git@github.com:darktable-org/darktable.git
    cd darktable
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

  stage_announcement "stage_4_digikam_from_scratch"

  pushd ${OPT_DLOADS} &> /dev/null

  echo
  echo "NOTICE: 2016-02-04: Building digikam 4.14.0 does not work."
  echo "        Don't waste your time."
  echo "        Call stage_4_digikam_from_distro instead."
  echo

  exit 1

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
  fi;

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

  stage_announcement "stage_4_digikam_from_distro"

  # 2016.03.24: 4.12.0 is on 15.10.
  #             So the backport code is just for Mint 17.x.
  #
  # Load the release codename, e.g., raring, trusty, wily, etc.
  source /etc/lsb-release
  if [[ ${DISTRIB_CODENAME} = 'trusty' ]]; then

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
    sudo apt-get update

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

stage_4_gimp_plugins () {

  stage_announcement "stage_4_gimp_plugins"

  # GIMP Export Layers to Directory as PNGs
  #   http://registry.gimp.org/node/28268
  #   https://github.com/khalim19/gimp-plugin-export-layers

  pushd ${OPT_DLOADS} &> /dev/null

  if [[ -e gimp-plugin-export-layers ]]; then
    echo
    echo "WARNING: Already exists: ${OPT_DLOADS}/gimp-plugin-export-layers"
    return
  fi

  if [[ ! -d ${HOME}/.gimp-2.8/plug-ins ]]; then
    echo
    echo "WARNING: Not Found or Not a Dir: ${HOME}/.gimp-2.8/plug-ins"
    # FIXME/TESTME: This happens if you haven't run gimp ever...
    #               So can we just create the directory?
    mkdir -p ${HOME}/.gimp-2.8/plug-ins
  fi

  git clone https://github.com/khalim19/gimp-plugin-export-layers.git
  /bin/cp -a ./gimp-plugin-export-layers/export_layers.py ${HOME}/.gimp-2.8/plug-ins
  /bin/cp -ar ./gimp-plugin-export-layers/export_layers ${HOME}/.gimp-2.8/plug-ins

  popd &> /dev/null

  # GIMP docs.
  /bin/mkdir -p ${OPT_DOCS}/gimp
  pushd ${OPT_DOCS}/gimp &> /dev/null
  wget -N http://docs.gimp.org/2.8/quickreference/gimp-keys-en.pdf
  # Bah, why no PDF of the help for 2.8?
  # http://docs.gimp.org/2.8/en/
  wget -N http://docs.gimp.org/2.4/pdf/en.pdf
  /bin/ln -s gimp-
  # From 31 Aug 2014:
  wget -N http://gimp.linux.it/www/meta/gimp-en.pdf
  # From 1999:
  #  wget -N ftp://ftp.ccsf.edu/pub/Util/gimp-User_Manual.pdf
  popd &> /dev/null

} # end: stage_4_gimp_plugins

stage_4_python_source () {

  stage_announcement "stage_4_python_source"

  pushd ${OPT_DLOADS} &> /dev/null

  wget -N https://www.python.org/ftp/python/2.7.10/Python-2.7.10.tgz
  wget -N https://www.python.org/ftp/python/3.3.6/Python-3.3.6.tgz
  wget -N https://www.python.org/ftp/python/3.4.3/Python-3.4.3.tgz

  popd &> /dev/null

  pushd ${OPT_SRC} &> /dev/null

  tar xvzf ${OPT_DLOADS}/Python-2.7.10.tgz
  tar xvzf ${OPT_DLOADS}/Python-3.3.6.tgz
  tar xvzf ${OPT_DLOADS}/Python-3.4.3.tgz

  popd &> /dev/null

} # end: stage_4_python_source

stage_4_funstuff () {

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

  stage_announcement "Noop: stage_4_updatedb_locate_conf"

  # FIXME: See /etc/updatedb.conf
  #
  # See: ~/.waffle/dev/${HOSTNAME}/etc
  #  I wonder where the appropriate place to do this is...
  #  maybe a custom_mint17.private.$HOSTNAME.sh type file.
  #
  # Exclude backup drives, e.g.,
  # PRUNEPATHS="/tmp /var/spool /home/.ecryptfs /media/landonb/FREEDUB1 /media/landonb/bubbly"
  :

} # end: stage_4_updatedb_locate_conf

stage_4_python_35 () {

  stage_announcement "stage_4_python_35"

  # Only do this for machines without python3.5.
  command -v python3.5 &> /dev/null
  if [[ $? -ne 0 ]]; then
    sudo add-apt-repository -y ppa:fkrull/deadsnakes
    sudo apt-get update -y
    sudo apt-get install -y python3.5
    #sudo apt-get install -y python3.5-dev
  fi

} # end: stage_4_python_35

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

  # Tell Hamster to start on login.
  stage_4_hamster_time_tracker_setup
  stage_4_hamster_briefs_setup

  # Tell Pidgin to start on login.
  stage_4_pidgin_setup_autostart

  # Tell Gmail Notifier to start on login.
  stage_4_gmail_notifier_setup

  # Quicktile lets you easily resize windows.
  stage_4_quicktile_install

  # Configure Postgresql.
  # This really only sets 'staff' as the group for the config files.
  stage_4_psql_configure

  # Configure Apache.
  stage_4_apache_configure

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

  # Ah, classic open source GIS tools, I honor thee.
  stage_4_openjump_install

  # Install pip, and use pip to install uncommitted and argcomplete.
  stage_4_all_the_young_pips

  # Some open source fonts I've found that I include. Unicode and more.
  stage_4_font_mania

  # A very nice font for text editing.
  # Probably already installed for Dubsacks Vim.
  stage_4_font_typeface_hack

  # Ah, Sqlite. Sometimes you're there, and sometimes
  # you're not, but if you weren't and I was looking
  # for you, I'd be distressed.
  stage_4_sqlite3

  # Dark Table is a sophisticated RAW image editor.
  # Fortunately we can apt it from a third party repo.
  stage_4_darktable

  # DigiKam is a decent photo organization tool. It's
  # also a pain to build from scratch.
  #stage_4_digikam_from_scratch
  stage_4_digikam_from_distro

  # Dah Gimp Dah Gimp Dah Gimp!
  stage_4_gimp_plugins

  # Install Python 3.5 from deadsnakes.
  # FIXME: This should be distro-dependent.
  stage_4_python_35

  # FIXME/MAYBE: These commands are stubbed.
  # ========================================

  # Configure Git.
  # See ~/.gitconfig. No need to call `git config`.
  #
  # FIXME: Do something like
  #          m4 ... ~/.gitconfig.m4 ...
  #
  #stage_4_git_configure

  # Setup /etc/updatedb.conf, except this is machine-specific,
  # so there's just a FIXME comment therein for now; a no-op.
  stage_4_updatedb_locate_conf

  # Install LibreOffice.
  # FIXME: This is a no-op; how have I been installing libreoffice5?
  stage_4_libreoffice_install

  # DISABLED/PROBABLY DISABLED SETUPS
  # =================================

  # Configure Mercurial.
  # - Only iff $USE_SETUP_HG.
  stage_4_hg_configure

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

  # I've wanted to want to try to like password managers
  # in the past but find myself just using, like, and
  # trusting my system better...
  # - so this is a no-op.
  stage_4_keepassx_install

  # 2016-03-23: Pencil install is disabled since not used.
  stage_4_pencil_install

  # 2015.01: [lb] still playing around w/ the RssOwl reader...
  #          its inclusion here is not an endorsement, per se.
  # - This is disabled.
  stage_4_rssowl_install

  # Disabled:
  stage_4_jsctags_install

  # 2016.03.23: Check out hamster and
  #   https://github.com/landonb/hamster_briefs
  if false; then
    stage_4_todo_txt_install
    stage_4_punch_tt_install
    stage_4_ti_time_tracker_install
    stage_4_utt_time_tracker_install
  fi

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
  echo "All done."

} # end: setup_customize_extras_go

if [[ "$0" == "$BASH_SOURCE" ]]; then
  # Only call the setup fcns. if this script is being run and not sourced.
  setup_customize_extras_go
# else, $BASH_SOURCE is not the name of this script; it's
#       the name of the script that's sourcing this script.
fi

