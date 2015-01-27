# File: custom_mint17.extras.sh
# Author: Landon Bouma (home-fries &#x40; retrosoft &#x2E; com)
# Last Modified: 2015.01.26
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

  sudo chown postgres:${USE_STAFF_GROUP_ASSOCIATION} \
    /etc/postgresql/${POSTGRESABBR}/main/*
  # Is this okay?
  sudo chmod 640 /etc/postgresql/${POSTGRESABBR}/main/*

  #sudo /etc/init.d/postgresql reload
  sudo /etc/init.d/postgresql restart

} # end: stage_4_psql_configure

stage_4_apache_configure () {

  # Make the Apache configs group-writeable.

  sudo /bin/chgrp -R ${USE_STAFF_GROUP_ASSOCIATION} /etc/apache2/
  sudo /bin/chmod 664  /etc/apache2/apache2.conf
  sudo /bin/chmod 664  /etc/apache2/ports.conf
  sudo /bin/chmod 2775 /etc/apache2/sites-available
  sudo /bin/chmod 2775 /etc/apache2/sites-enabled
  sudo /bin/chmod 664  /etc/apache2/sites-available/*.conf

  # Avoid an apache gripe and set ServerName.
  m4 \
    --define=HOSTNAME=${HOSTNAME} \
    --define=MACH_DOMAIN=${USE_DOMAIN} \
      ${script_absbase}/common/etc/apache2/apache2.conf \
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
    sudo su --login -c 'cd ${OPT_DLOADS}/expect5.45 && make install'

    # NOTE: You'll have to manually setup your LD_LIBRARY_PATH. E.g.,
    #
    #   LD_LIBRARY_PATH=/usr/lib/expect5.45
    #   export LD_LIBRARY_PATH

  fi

} # end: stage_4_dev_testing_expect_install

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

  /bin/mkdir -p ${OPT_BIN}
  cd ${OPT_BIN}
  wget -N \
    https://github.com/downloads/ginatrapani/todo.txt-cli/todo.txt_cli-2.9.tar.gz
  tar xvzf todo.txt_cli-2.9.tar.gz

  chmod +x todo.txt_cli-2.9/todo.sh

  /bin/rm todo.txt_cli-2.9.tar.gz

  /bin/ln -s todo.txt_cli-2.9 todo.txt_cli

} # end: stage_4_todo_txt_install

stage_4_ti_time_tracker_install () {

  /bin/mkdir -p ${OPT_BIN}
  cd ${OPT_BIN}
  wget -N \
    https://raw.githubusercontent.com/sharat87/ti/master/bin/ti

  chmod +x ti

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

# ==============================================================
# Application Main()

setup_customize_extras_go () {

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

    # Install Abode Reader.

    stage_4_reader_install

    # Install the dropbox.py script.

    stage_4_dropbox_install

    # Install expect, so we can do tty tricks.

    stage_4_dev_testing_expect_install

    # 2015.01: [lb] still playing around w/ the RssOwl reader...
    #          its inclusion here is not an endorsement, per se.

    stage_4_rssowl_install

    # The Worst Metric Ever: Count Lines of Code!

    stage_4_cloc_install

    # 2015.01.24: The Todo.txt project seems nifty, as does
    #                 ti — A silly simple time tracker, but
    #                 perhaps Ultimate Time Tracker has a few
    #                 tricks that ti could learn (I like the
    #                 feel of ti but the features of utt...).

    stage_4_todo_txt_install

    stage_4_ti_time_tracker_install

    stage_4_utt_time_tracker_install

} # end: setup_customize_extras_go

setup_customize_extras_go

