# File: custom_mint17.extras.sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Last Modified: 2015.03.18
# Project Page: https://github.com/landonb/home_fries
# Summary: Third-party tools downloads compiles installs.
# License: GPLv3

stage_4_git_configure () {

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

stage_4_psql_configure () {

  # Postgres config. Where POSTGRESABBR is, e.g., "9.1".

  if [[ -z ${POSTGRESABBR} ]]; then
    echo
    echo "ERROR: POSTGRESABBR is not set."
    exit 1
  fi

  # Add the postgres group(s).
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

  #
  sudo /bin/cp \
    ${script_absbase}/common/etc/postgresql/${POSTGRESABBR}/main/pg_hba.conf \
    /etc/postgresql/${POSTGRESABBR}/main/pg_hba.conf

  #
  m4 \
    --define=HTTPD_USER=${httpd_user} \
    --define=TARGETUSER=$USER \
      ${script_absbase}/common/etc/postgresql/${POSTGRESABBR}/main/pg_ident.conf \
    | sudo tee /etc/postgresql/${POSTGRESABBR}/main/pg_ident.conf \
    &> /dev/null

  # NOTE: Deferring installing postgresql.conf until /ccp/var/log
  #       is created (otherwise the server won't start) and until we
  #       configure/install other things so that the server won't not
  #       not start because of some shared memory limit issue.

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

  # Make the Apache configs group-writeable.
  if [[ -n ${USE_STAFF_GROUP_ASSOCIATION} ]]; then
    sudo /bin/chgrp -R ${USE_STAFF_GROUP_ASSOCIATION} /etc/apache2/
    sudo /bin/chmod 664  /etc/apache2/apache2.conf
    sudo /bin/chmod 664  /etc/apache2/ports.conf
    sudo /bin/chmod 2775 /etc/apache2/sites-available
    sudo /bin/chmod 2775 /etc/apache2/sites-enabled
    sudo /bin/chmod 664  /etc/apache2/sites-available/*.conf
  fi

  # Avoid an apache gripe and set ServerName.
  m4 \
    --define=HOSTNAME=${HOSTNAME} \
    --define=MACH_DOMAIN=${USE_DOMAIN} \
      ${script_absbase}/target/common/etc/apache2/apache2.conf \
      > /etc/apache2/apache2.conf

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
      cd ${OPT_DLOADS}
      # http://github.com/ssokolow/quicktile/tarball/master
      git clone git://github.com/ssokolow/quicktile
    else
      cd ${OPT_DLOADS}/quicktile
      git pull origin
    fi
    cd ${OPT_DLOADS}/quicktile
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
  fi

} # end: stage_4_quicktile_install

stage_4_pidgin_setup_autostart () {

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

stage_4_firefox_configure () {

  # Configure Firefox.

  # FIXME: MAYBE: Do this... cp or maybe use m4.
  #cp ~/.mozilla/firefox/*.default/prefs.js ...
  ## Diff the old Firefox's file and the new Firefox's file?
  #cp ... ~/.mozilla/firefox/*.default/prefs.js

  : # http://stackoverflow.com/questions/12404661/what-is-the-use-case-of-noop-in-bash
    # http://unix.stackexchange.com/questions/31673/what-purpose-does-the-colon-builtin-serve

} # end: stage_4_firefox_configure

stage_4_chrome_install () {

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
  # Cleanup. We can probably always get this file again, eh?
  /bin/rm ${OPT_DLOADS}/google-chrome-stable_current_amd64.deb

  # Firefox Google Search Add-On
  # Hrm, [lb] thinks the user has to do this themselves...
  #mkdir -p ${OPT_DLOADS}/firefox-google-search-add_on
  #cd ${OPT_DLOADS}/firefox-google-search-add_on
  #wget -N \
  #  https://addons.mozilla.org/firefox/downloads/file/157593/google_default-20120704.xml?src=search

} # end: stage_4_chrome_install

stage_4_https_everywhere_install () {

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
    cd ${OPT_DLOADS}/https-everywhere
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
  fi

} # end: stage_4_https_everywhere_install

stage_4_virtualbox_install () {

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

  # Get the latest Debian package. At least if this script is uptodate.
  LATEST_VBOX_PKG="virtualbox-4.3_4.3.26-98988~Ubuntu~raring_amd64.deb"
  LATEST_VBOX_EXTPACK="Oracle_VM_VirtualBox_Extension_Pack-4.3.26-98988.vbox-extpack"
  cd ${OPT_DLOADS}
  wget -N \
    http://download.virtualbox.org/virtualbox/4.3.26/${LATEST_VBOX_PKG}
  sudo dpkg -i ${LATEST_VBOX_PKG}
  #/bin/rm ${LATEST_VBOX_PKG}

  # This Guy, for USB 2.
  wget -N \
    http://download.virtualbox.org/virtualbox/4.3.26/${LATEST_VBOX_EXTPACK}
# FIXME: Unless there's a scripty way to add the extension pack,
#        tell user to run `virtualbox &`, navigate to File > Preferences...,
#        click Extensions group,
#        click Icon for Add Package
#        enter: /srv/opt/.downloads/Oracle_VM_VirtualBox_Extension_Pack-4.3.26-98988.vbox-extpack

  # FIXME/MAYBE: One doc [lb] read says add youruser to 'lp' and 'users' groups,
  # in addition to obvious 'vboxsf' and 'vboxusers' group. See: /etc/group.

# FIXME: Need this here or in the guest??:
#      virtualbox-guest-additions-iso
# Add to vboxusers? and lp and users?
  #sudo usermod -a -G lp ${USER}
  #sudo usermod -a -G users ${USER}
  sudo usermod -a -G vboxsf ${USER}
  sudo usermod -a -G vboxusers ${USER}

} # end: stage_4_virtualbox_install

stage_4_reader_install () {

  # 2014.11.10: On Windows and Mac it's Adobe 11 but on Linux it's still 9.5.5,
  # because Adobe discountinued their Linux work.

  # See also other PDF applications, like
  # evince (Ubuntu), atril (Mint fork of evince) and okular.

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

stage_4_dropbox_install () {

  /bin/mkdir -p ${OPT_BIN}
  cd ${OPT_BIN}
  wget -O ${OPT_BIN}/dropbox.py \
    "https://www.dropbox.com/download?dl=packages/dropbox.py"

  # Set the permissions so you can execute the CLI interface:
  chmod +x ${OPT_BIN}/dropbox.py

  # Changing the shebang is unnecessary unless you remap /usr/bin/python.
  #
  #  sudo /bin/sed -i.bak \
  #    "s/^#!\/usr\/bin\/python$/#!\/usr\/bin\/python2/" \
  #    ${OPT_BIN}/dropbox.py

  # FIXME: Is this step missing?
  #        Install the daemon: dropbox.py start -i
  #        except you're prompted to agree to install proprietary daemon

} # end: stage_4_dropbox_install

stage_4_dev_testing_expect_install () {

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

  # Weird. This installs restview with ownership as my ${USER}.
  sudo su -c "pip install restview"

} # end: stage_4_restview_install

# FIXME: Is there a way to automatically get the latest
#        packages from SourceForge without hardcoding here?

stage_4_rssowl_install () {
  echo
  echo "WARNING: Skipping: stage_4_rssowl_install"
  echo
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

  /bin/mkdir -p ${OPT_BIN}
  cd ${OPT_BIN}
  wget -N \
    http://downloads.sourceforge.net/project/cloc/cloc/v1.62/cloc-1.62.pl

  # Set the permissions so you can execute the CLI interface:
  chmod +x ${OPT_BIN}/cloc-1.62.pl

} # end: stage_4_cloc_install

stage_4_todo_txt_install () {

  /bin/mkdir -p ${OPT_DLOADS}
  cd ${OPT_DLOADS}
  wget -N \
    https://github.com/downloads/ginatrapani/todo.txt-cli/todo.txt_cli-2.9.tar.gz
  tar xvzf todo.txt_cli-2.9.tar.gz

  chmod +x todo.txt_cli-2.9/todo.sh

  /bin/rm todo.txt_cli-2.9.tar.gz

  /bin/ln -s todo.txt_cli-2.9 todo.txt_cli

  /bin/ln -s ${OPT_DLOADS}/todo.txt_cli-2.9/todo.sh ${OPT_BIN}/todo.sh

  # See: ~/.fries/.bashrc/bashrc.core.sh for
  #   source ${OPT_DLOADS}/todo.txt_cli/todo_completion

  mkdir $HOME/.todo
  # FIXME: You may have to edit the config file to add the path to it.
  cp ${OPT_DLOADS}/todo.txt_cli-2.9/todo.cfg $HOME/.todo/config

} # end: stage_4_todo_txt_install

stage_4_punch_tt_install () {

  if false; then
    /bin/mkdir -p ${OPT_DLOADS}
    cd ${OPT_DLOADS}
    wget -N \
      https://punch-time-tracking.googlecode.com/files/punch-time-tracking-1.3.zip
    unzip -d punch-time-tracking punch-time-tracking-1.3.zip
    chmod +x punch-time-tracking/Punch.py
    /bin/ln -s ${OPT_DLOADS}/punch-time-tracking/Punch.py ${OPT_BIN}/Punch.py
  fi

} # end: stage_4_punch_tt_install

stage_4_ti_time_tracker_install () {

  if false; then
    /bin/mkdir -p ${OPT_BIN}
    cd ${OPT_BIN}
    wget -N \
      https://raw.githubusercontent.com/sharat87/ti/master/bin/ti

    chmod +x ti
  fi

} # end: stage_4_ti_time_tracker_install

stage_4_utt_time_tracker_install () {

  # Ultimate Time Tracker

  if false; then
    /bin/mkdir -p ${OPT_DLOADS}
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

  # 2015.02.06: Cookiecutter in the distro is 0.6.4,
  #             but >= 0.7.0 is where it's at.

  sudo pip install cookiecutter

  # WTW?                            -rwxrwx--x
  # 2015.02.19: On fresh Mint 17.1: -rwxr-x--x
  # Anyway, 'other' is missing the read bit.
  sudo chmod 755 /usr/local/bin/cookiecutter

} # end: stage_4_cookiecutter_install

stage_4_keepassx_install () {

  # Funny; there's a build problem in the latest version of the source:
  # a missing include. However, we can also just install keepassx with
  # apt-get... though I think a text file and encfs or gpg is probably
  # simpler to use than keepassx. The only security difference is that
  # keepassx automatically clears the clipboard for you; if you use an
  # encrypted file, you'll have to remember to clear the clipboard, or
  # at least to not accidentally paste your password to, say, a web
  # browser search field.

  if false; then

    /bin/mkdir -p ${OPT_DLOADS}
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

  /bin/mkdir -p ${OPT_DLOADS}
  cd ${OPT_DLOADS}
  wget -N http://evoluspencil.googlecode.com/files/evoluspencil_2.0.5_all.deb
  sudo dpkg -i evoluspencil_2.0.5_all.deb
  #/bin/rm ${OPT_DLOADS}/evoluspencil_2.0.5_all.deb

} # end: stage_4_pencil_install

stage_4_jsctags_install () {

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

  # 2015.02.22: From /var/log/auth.log, lines like
  #   Feb 22 14:55:05 philae smbd[30165]: pam_unix(samba:session):
  #     session closed for user nobody
  # but no "session started" or "session opened" lines. Whatever.
  # I don't Samba. https://en.wikipedia.org/wiki/Samba_%28software%29

  # Stop it now.
  sudo service smbd stop

  # Have it not start in the future.
  sudo update-rc.d -f smbd remove
  # Restore with:
  #   sudo update-rc.d -f smbd defaults

} # end: stage_4_disable_services

stage_4_spotify_install () {

  /bin/mkdir -p ${OPT_DLOADS}
  cd ${OPT_DLOADS}

  # From:
  #  https://www.spotify.com/us/download/previews/
  echo "deb http://repository.spotify.com stable non-free" \
    | sudo tee -a /etc/apt/sources.list &> /dev/null
  sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 94558F59
  sudo apt-get update

  # FIXME: More post-install reminders:
  #         Disable the annoying notification popup when a new track starts.
  #         (Though I do kinda like it to know when ads are finished playing.)
  if false; then
    echo "ui.track_notifications_enabled=false" \
      >> ~/.config/spotify/Users/*/prefs
  fi

} # end: stage_4_spotify_install

# ==============================================================
# Application Main()

setup_customize_extras_go () {

    if [[ -n ${USE_STAFF_GROUP_ASSOCIATION} ]]; then
      sudo chgrp ${USE_STAFF_GROUP_ASSOCIATION} /srv
      sudo chmod g+w /srv
    fi

    # Configure Git.

    stage_4_git_configure

    # Configure Mercurial

    stage_4_hg_configure

    # Configure Meld.

    stage_4_meld_configure

    # Configure Postgresql.

    stage_4_psql_configure

    # Configure Apache.

    stage_4_apache_configure

    # Quicktile lets you easily resize windows.

    stage_4_quicktile_install

    # Tell Pidgin to start on login.

    stage_4_pidgin_setup_autostart

    # Configure Web browsers.

    stage_4_firefox_configure
    stage_4_chrome_install
    stage_4_https_everywhere_install

    # Woop! Woop! for VirtualBox.
    stage_4_virtualbox_install

    # Install Abode Reader.

    stage_4_reader_install

    # Install the dropbox.py script.

    stage_4_dropbox_install

    # Install expect, so we can do tty tricks.

    stage_4_dev_testing_expect_install

    stage_4_restview_install

    # 2015.01: [lb] still playing around w/ the RssOwl reader...
    #          its inclusion here is not an endorsement, per se.

    stage_4_rssowl_install

    # The Worst Metric Ever: Count Lines of Code!

    stage_4_cloc_install

    # 2015.01.24: The Todo.txt project seems nifty, as does
    #                 ti — A silly simple time tracker, but
    #                 perhaps Ultimate Time Tracker has a few
    #                 tricks that ti could learn (I like the
    #                 feel of ti but the features of utt...
    #                 no, wait, punch-time-tracking seems cool).

    stage_4_todo_txt_install

    stage_4_punch_tt_install

    stage_4_ti_time_tracker_install

    stage_4_utt_time_tracker_install

    stage_4_cookiecutter_install

    stage_4_keepassx_install

    stage_4_pencil_install

    stage_4_jsctags_install

    stage_4_disable_services

    stage_4_spotify_install

} # end: setup_customize_extras_go

setup_customize_extras_go

