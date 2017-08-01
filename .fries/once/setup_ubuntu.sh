#!/bin/bash

# File: setup_ubuntu.sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Last Modified: 2017.08.01
# Project Page: https://github.com/landonb/home_fries
# Summary: Linux Mint MATE Automated Developer Environment Setterupper.
# License: GPLv3
# -------------------------------------------------------------------
# Copyright © 2011-2017 Landon Bouma.
#
# This program is free software: you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation, either version 3 of
# the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>
# or write Free Software Foundation, Inc., 51 Franklin Street,
#                     Fifth Floor, Boston, MA 02110-1301, USA.
# ===================================================================

set -e

# ------------------------------------------
# About

# This script `apt-get install`s a ton of packages,
# it configures Mint and MATE to a particular developer's tastes,
# and it downloads, compiles and installs a few non-apt apps.
#
# If you're familiar with and trust this script, go ahead and
# run it on a fresh Linux installation. If this script is new
# to you, or if you've been incrementally updating the script
# to include software you've installed since last running the
# script, you'll probably want to double-check the tasks down
# below to make sure this script will fulfill all your needs.

# 2015.01.26: I mucked with the script (created all
#             the subscripts) and need to test it.
# 2016.03.23: And away we go. Setting up a keepertrapper.
# 2016.03.24: It works!

# FIXME/NEXT-TIME: Search for NEXT-TIME for questions to
#                  answer the next time you run this script.

# ------------------------------------------
# Velcome

if false; then
  echo
  echo "Too Many Steps Setup Script"
  echo
  echo "- For Linux Mint 17.x and MATE"
  echo "- Configures Mint and MATE to a Particular Liking"
  echo "- You already Installed Handy Bash Scripts with This Script, and"
  echo "   This Script Installs Handy Vim Scripts"
  echo "- Installs a Bunch of Applications and Tools"
  echo
else
  echo
  echo "home-fries OS standup script"
  echo
  echo " .. tested most recently on"
  echo "      - Linux Mint MATE 18 Sarah"
  echo "      - Ubuntu MATE 16.04 Xenial"
  echo "    and has previously worked on"
  echo "      - Linux Mint MATE 17.x (14.04)"
  echo "      - Ubuntu MATE 15.10"
  echo
  echo 'Good luck!'
  echo
fi

# ------------------------------------------
# Bootstrap

if [[ ! -e ../lib/bash_base.sh ]]; then
  echo "Error: Expected to find ../lib/bash_base.sh."
  exit 1
fi
DEBUG_TRACE=false
source ../lib/bash_base.sh
# ${script_absbase} is now the absolute path to this script's directory.

# ------------------------------------------
# Configuration

if [[ ! -e ./linux_setup_base.sh ]]; then
  echo "Error: Expected to find ./linux_setup_base.sh."
  exit 1
fi
DEBUG_TRACE=false
source ./linux_setup_base.sh
# This sets a bunch of environment variables shared by the setup scripts.
# E.g.:
#   USE_DOMAIN
#   USE_MOUNTPT
#   USE_PROJECT_USERGROUPS
#   USE_PROJECT_PSQLGROUPS
#   USE_STAFF_GROUP_ASSOCIATION
#   OPT_BIN
#   OPT_DLOADS
#   USE_MINT_MENU_ICON
#   USE_SETUP_HG
#   HG_USER_NAME
#   HG_USER_EMAIL
#   HG_DEFAULT_PATH
#   INCLUDE_ADOBE_READER
#   DO_INSTALL_DUBSACKS

# ------------------------------------------
# Let's get started! I mean, let's start a timer!

# Start a timer.
setup_time_0=$(date +%s.%N)

# ------------------------------------------
# Charge sudo powers.

# *** EVERY BOOT: Always get a fresh sudo, so we don't ask for the
#                 password at some random time during the install.

# E.g.,
#   $ sudo -n -v
#   sudo: a password is required
if ! `sudo -n -v`; then
  echo
  echo "Please enter your root password to get started..."
  echo
  sudo -v
fi

# ------------------------------------------
# Helper fcns. and setup.

# This script runs multiple times and reports its running time each time.
print_install_time () {
  local setup_time_n=$(date +%s.%N)
  echo
  echo "Install started at: $setup_time_0"
  echo "Install finishd at: $setup_time_n"
  time_elapsed=$(echo "$setup_time_n - $setup_time_0" | bc -l)
  echo "Elapsed: $time_elapsed secs."
}

ensure_directory_hierarchy_exists ${OPT_DLOADS}
#ensure_directory_hierarchy_exists ${OPT_BIN}
#ensure_directory_hierarchy_exists ${OPT_SRC}
#ensure_directory_hierarchy_exists ${OPT_DOCS}
#ensure_directory_hierarchy_exists ${OPT_FONTS}

# If you'd like to automate future installs, you can compare
# your home directory before and after setting up the window
# manager and applications just the way you like.
#
# To test:
#   cd ~/Downloads
#   RELAT=new_01
#   user_home_conf_dump $RELAT
#
# DEVs: Make true if you'd like to make conf dumps.
MAKE_CONF_DUMPS=false
#MAKE_CONF_DUMPS=true

user_home_conf_dump() {

  if ${MAKE_CONF_DUMPS} && [[ ${IS_HEADED_MACHINE_ANSWER} == "Y" ]]; then

    RELAT=$1

    /bin/mkdir -p $RELAT

    pushd $RELAT

    gsettings list-recursively > cmd-gsettings.txt

    gconftool-2 --dump / > cmd-gconftool-2.txt

    dconf dump / > cmd-dconf.txt

    /bin/cp -raf \
      /home/$USER/.config \
      /home/$USER/.gconf \
      /home/$USER/.gnome2 \
      /home/$USER/.gnome2_private \
      /home/$USER/.linuxmint \
      /home/$USER/.local \
      /home/$USER/.mozilla \
      .

    popd

    tar cvzf $RELAT-user_home_conf_dump.tar.gz $RELAT

  fi

}

# *** Print all environment variables, should the developer want to
#     copy-and-paste anything to make debugging this script easier.

setup_ready_print_env () {

  # FIXME: 2015.01.26: This script is probably out-of-sync.
  set | grep "=" | grep \
    -e script_relbase \
    -e script_absbase \
    -e script_path \
    -e USE_DOMAIN \
    -e USE_MOUNTPT \
    -e USE_PROJECT_USERGROUPS \
    -e USE_PROJECT_PSQLGROUPS \
    -e USE_STAFF_GROUP_ASSOCIATION \
    -e OPT_BIN \
    -e OPT_DLOADS \
    -e HG_USER_NAME \
    -e HG_USER_EMAIL \
    -e HG_DEFAULT_PATH \
    -e INCLUDE_ADOBE_READER
}

echo "Here's how the script is configured:"
echo
# MEH: For some reason the `set | grep...` command is echoed after it runs...
setup_ready_print_env

LOGOUT_NECESSARY=false
REBOOT_NECESSARY=false

if [[ -z ${WM_IS_MATE+x} ]]; then
  WM_IS_MATE=false
fi
if [[ -z ${WM_IS_CINNAMON+x} ]]; then
  WM_IS_CINNAMON=false
fi
if [[ -z ${USE_MINT16_CUSTOM_LOGIN+x} ]]; then
  USE_MINT16_CUSTOM_LOGIN=false
fi

# ------------------------------------------
# STAGE 1

# *** FIRST/FRESH BOOT: Upgrade and Install Packages

setup_mint_17_stage_1_apt_get_install () {

  echo
  echo "Welcome to the installer!"
  echo
  #echo "We're going to install lots of packages and then reboot."
  #echo
  if ${DO_INSTALL_MYSQL}; then
    echo "NOTE: The Mysql installer will ask you for a new password."
    echo
  fi
  echo "Let's get moving, shall we?"

  # Six digits is max that works for seconds, and 0 is auto-answer,
  # -1 does nothing, so, yeah, MAYBE: ask_yes_no_default with a no-
  # timeout option. Or maybe just call `read` directly.
  ask_yes_no_default 'Y' 999999
  # Works, but the display is blank:
  #ask_yes_no_default 'Y' 99999999
  # Auto-answers 'Y':
  #ask_yes_no_default 'Y' 9999999999999999999999999999999

  if [[ $the_choice != "Y" ]]; then

    echo "Awesome! See ya!!"
    exit 1

  else

    # *** Make a snapshot of the user's home directory.

    #sudo apt-get install dconf-tools
    sudo apt-get install -y dconf-cli
    user_home_conf_dump "${script_absbase}/conf_dump/new_01"

    # *** Install wmctrl so we can determine the window manager.

    sudo apt-get install -y wmctrl
    # NOTE: In Mint MATE, calling gsettings now (before update/upgrade)
    #       doesn't seem to stick. So we'll wait 'til a little later in
    #       this function to call determine_window_manager and gsettings.

    # Are we in a virtual machine?
    sudo apt-get install -y virt-what
    # FIXME: What about Are we in a chroot? Does it matter?

    # *** Make sudo'ing a little easier (just ask once per terminal).

    # Tweak sudoers: Instead of a five-minute sudo timeout, disable it.
    # You'll be asked for a password once per terminal. If you care about
    # sudo not being revoked after a timeout, just close your terminal when
    # you're done with it, Silly.

    if sudo grep "Defaults:$USER" /etc/sudoers 1> /dev/null; then
      echo
      echo "Skipping: /etc/sudoers already edited."
      echo
      echo "Sorry you have to run this script again... hahaha, sucker"
      echo
    else
      sudo /bin/cp /etc/sudoers /etc/sudoers-ORIG
      sudo chmod 0660 /etc/sudoers
      # For more info on the Defaults, see `man sudoers`.
      # - tty_tickets is on by default.
      # - timestamp_timeout defaults to 5 (minutes).
      # Note the sudo tee trick, since you can't run e.g.,
      #       sudo echo "" >> to a write-protected file,
      #      since the append command happens outside the sudo.
      # Disable sudo password-entering timeout.
      echo "
# Added by ${0}:${USER} at `date +%Y.%m.%d-%T`.
Defaults tty_tickets
Defaults:${USER} timestamp_timeout=-1
# Is this safe? Passwordless chroot.
${USER} ALL= NOPASSWD: /usr/sbin/chroot
" | sudo tee -a /etc/sudoers &> /dev/null
      sudo chmod 0440 /etc/sudoers
    fi

    sudo visudo -c
    if [[ $? -ne 0 ]]; then
      echo "WARNING: We messed up /etc/sudoers!"
      echo
      echo "To recover: login as root, since sudo is broken,"
      echo "and restore the original file."
      echo
      echo "$ su"
      echo "$ /bin/cp /etc/sudoers-ORIG /etc/sudoers"
      exit 1
    fi

    # *** Upgrade and install packages.

    # Update the cache.
    sudo apt-get -y update

    # Update all packages.
    sudo apt-get -y upgrade

    # Update distribution packages.
    sudo apt-get -y dist-upgrade

    source /etc/lsb-release
    if [[ $DISTRIB_ID == 'Ubuntu' || $DISTRIB_ID == 'LinuxMint' ]]; then
      # Ubuntu 16.04 LTS xenial
      sudo apt-get install -y dkms build-essential
    else
      sudo apt-get install -y dkms build-essentials
    fi
    # 2016-04-04: I don't think you need to reboot here... do you??
    #             There was a comment here earlier that a reboot was
    #             necessary, but I lost track installing Ubuntu MATE 15.10
    #             and maybe it's not necessary anymore....
    #
    # FIXME/NEXT-TIME: Well, except for this comment from apt-get install nginx, below:
    #
    # nginx and nginx-core fail if you don't reboot at some point
    # i had installed build-essentials and dkms without rebooting
    # and i ran apt-get dist-upgrade, too...
    #
    #Setting up nginx-core (1.9.3-1ubuntu1.1) ...
    #Job for nginx.service failed because the control process exited with error code.
    # See "systemctl status nginx.service" and "journalctl -xe" for details.
    #invoke-rc.d: initscript nginx, action "start" failed.
    #dpkg: error processing package nginx-core (--configure):
    # subprocess installed post-installation script returned error exit status 1
    #dpkg: dependency problems prevent configuration of nginx:
    # nginx depends on nginx-core (>= 1.9.3-1ubuntu1.1) | nginx-full (>= 1.9.3-1ubuntu1.1)
    #   | nginx-light (>= 1.9.3-1ubuntu1.1) | nginx-extras (>= 1.9.3-1ubuntu1.1); however:
    #  Package nginx-core is not configured yet.
    #  Package nginx-full is not installed.
    #  Package nginx-light is not installed.
    #  Package nginx-extras is not installed.
    # nginx depends on nginx-core (<< 1.9.3-1ubuntu1.1.1~) | nginx-full (<< 1.9.3-1ubuntu1.1.1~)
    #   | nginx-light (<< 1.9.3-1ubuntu1.1.1~) | nginx-extras (<< 1.9.3-1ubuntu1.1.1~); however:
    #  Package nginx-core is not configured yet.
    #  Package nginx-full is not installed.
    #  Package nginx-light is not installed.
    #  Package nginx-extras is not installed.
    #
    #dpkg: error processing package nginx (--configure):
    # dependency problems - leaving unconfigured
    #Processing triggers for sgml-base (1.26+nmNo apport report written because
    #the error message indicates its a followup error from a previous failure.
    #                                                 u4ubuntu1) ...
    #
    #Errors were encountered while processing:
    # nginx-core
    # nginx
    #E: Sub-process /usr/bin/dpkg returned an error code (1)
    #
    #
    # So, well, you might need to reboot after all.....

    # *** Disable screen locking so user can move about the cabin freely.

    determine_window_manager

    if ${WM_IS_MATE} && [[ ${IS_HEADED_MACHINE_ANSWER} == "Y" ]]; then
      # Disable screensaver and lock-out.
      # gsettings doesn't seem to stick 'til now.
      #?: sudo gsettings set org.mate.screensaver lock-enabled false
      # Or did it just require an apt-get update to finally work?
      gsettings set org.mate.screensaver idle-activation-enabled false
      gsettings set org.mate.screensaver lock-enabled false
    elif $WM_IS_CINNAMON; then
      set +ex
      gsettings set org.cinnamon.desktop.screensaver lock-enabled false \
        &> /dev/null
      reset_errexit
    fi

    # -- Install packages.

    # NOTE: This installs a lot of packages. The list has grown over the years.
    #       It's a mix of packages needed for Cyclopath, packages that [lb]
    #       likes, and most recently packages for other projects. It would be
    #       tedious and unnecessary to cull the list; it only takes hard drive
    #       space and doesn't waste computation resources to have all this
    #       installed. So feel free to keep adding packages.

    # -- Install MySQL early, because it's interactive.

    if ${DO_INSTALL_MYSQL}; then
      # NOTE: The Mysql package wants you to enter a password.
      #       [lb] figured all package installers are not interactive,
      #       but I guess there are some exceptions. Or maybe there's
      #       an apt-get switch I'm missing.
      #
      # FIXME: You could use `expect` here to send the pwd to the terminal.
      #
      sudo apt-get install -y pwgen
      if [[ ! -e ${script_absbase}/fries-setup-mysql.pwd ]]; then
        MYSQL_PASSWORD=$(pwgen -n 16 -s -N 1 -y)
        echo "${MYSQL_PASSWORD}" > ${script_absbase}/fries-setup-mysql.pwd
      else
        MYSQL_PASSWORD=`cat ${script_absbase}/fries-setup-mysql.pwd`
      fi
      echo
      echo "*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!"
      echo "Try this for a Mysql password: ${MYSQL_PASSWORD}"
      echo "*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!"
      echo "Which is saved also to the file: fries-setup-mysql.pwd"
      echo
      sudo apt-get -y install \
        \
        mysql-server
    fi

    # -- encfs warning (also interactive).

    # -- Install postfix (also interactive).

    # FIXME: Which package does this? It's another interactive installer.
    # 2016.03.23: It's one of: libpam0g-dev openssh-server signing-party.
    # You'll be prompted to "Please select the mail server configuration
    #                        type that best meets your needs."
    # Just choose "Internet Site", or even "Local only".

    # For "System mail name" just use... I dunno, whatever, $USE_DOMAIN.

    # -- Stop Apache.
    #
    # 2016-07-17: Cyclopath Resuscitation. apt-get install nginx fails
    # because nginx cannot start because port 80 in use. Huh.

    if [[ -f /etc/init.d/apache2 ]]; then
      sudo /etc/init.d/apache2 stop
    fi

    # -- Install the rest of the packages.

    # This remaining packages will install without need for human interaction.

    # 2014.11.09: Differences between Mint 16 and Mint 17:
    #   "Note, selecting 'apache2-dev' instead of 'apache2-threaded-dev'"
    #   "Package libicu48 is not available, but is referred to by another pkg."
    #     --> It's now 52.
    #   "E: Unable to locate package postgresql-server-dev-9.1"
    #   "E: Couldn't find any package by regex 'postgresql-server-dev-9.1'"
    #     --> It's now 9.3.

    # MAYBE: Categorize and Group these packages, possibly listing
    #        the same package in different groups. I.e., make a
    #        list of packages of Dubsacks VIM, another list of
    #        packages for Cyclopath, a list of packages you use
    #        for development, etc. For now, whatever, it's a big,
    #        long list, but at least the list is an array so we
    #        can add comments.

    local CORE_PACKAGE_LIST=(

      # Kernel goodies.
      dkms
      build-essential

      # Vim (See later: Dubsacks Vim.)
      vim-gtk
      # Text columnizer.
      par
      # Ctags.
      exuberant-ctags
      # Ruby dev tools for Command-T.
      ruby-dev

      # `most` is pretty lame; author prefers `less`.
      #most
      # `less` is made better with color.
      python-pygments

      # The better grepper.
      silversearcher-ag
      # 2016-11-18 Well, why not be inclusive. Every now
      # and then you copy and paste someone elses ack.
      ack-grep

      # Un-Zip-a-Dee-Doo-Dah
      unzip

      # All your repositories are belong to too many managers.
      git
      git-core

      # One would think whois would be standard.
      whois
      # nslookup is... stale, to be polite. Use dig instead.

      htop

      # I like the build-in pass cmd better.
      #keepassx

      encfs
      # I thought scrub was a default program, too; guess not.
      # Also, if you're doing it right, you won't need scrub:
      #   on disk, your data should *always* be encrypted;
      #   it is only in memory or on screen that data should be
      #   plain.
      scrub
      #
      pinentry-gtk2
      pinentry-doc

      expect

      gnupg2

      pwgen

      libpam0g-dev
      openssh-server
      signing-party

      # 2016-07-17: Ubuntu missing bc. What a weirdo.
      bc

      # 2016-10-04: Missing until now? Not so surprising.
      # Though surprising I did not face this in 16.04, just 14.04.
      rake

    ) # end: CORE_PACKAGE_LIST

    local CORE_DESKTOP_LIST=(

      # CLI OS and Window Manager customizers.
      dconf-cli
      gconf-editor
      wmctrl
      xdotool

      # Awesomest graphical diff.
      meld

      # Eye of Gnome, a slideshow image viewer.
      eog

      # Hexadecimal file viewer.
      ghex

      # Hexadecimal diff.
      vbindiff
      #hexdiff

      chromium-browser

    ) # end: CORE_DESKTOP_LIST

    local BIG_PACKAGE_LIST=(

      logcheck
      logcheck-database

      logtail
      # A colorful, more clever tail command.
      multitail

      socket

      # Addition, non-core repo tools.
      subversion
      mercurial
      # A beautiful, colorful git browser/helper.
      tig

      apache2
      apache2-dev
      apache2-utils

      nginx

      postgresql
      postgresql-client

      libxml2-dev
      libjpeg-dev
      libpng++-dev
      imagemagick
      libmagick++-dev
      texlive
      autoconf
      vsftpd
      libcurl3
      pcregrep
      gir1.2-gtop-2.0
      libgd-dev
      libxslt1-dev
      xsltproc
      libicu-dev

      python-dev
      python-setuptools
      libapache2-mod-python
      python-simplejson
      python-logilab-common
      python-gtk2
      python-wnck
      python-xlib
      python-dbus
      libpython3-dev

      # 2016-04-04: I just had this error but I think I figured it out...
      #     Setting up pylint (1.3.1-3ubuntu1) ...
      #     ERROR: pylint is broken - called emacs-package-install
      #            as a new-style add-on, but has no compat file.
      # Install pylint for emacs.
      # QUESTION: Why -for emacs-? I can lint from wherever I want....
      #           I guess not that I lint, though, in Cyclopath we had a kazillion
      #           errors and at my current emploer we (currently) do not lint.
      pylint

      # FIXME/MAYBE: Can/Should these be virtualenv-installed?
      python-egenix-mxdatetime
      python-egenix-mxtools
      python-subversion
      python-levenshtein

      # Skipping: virtualenvwrapper (see: pip install instead)
      #virtualenvwrapper
      # Install via virtualenv and pip:
      #  python-pytest
      python-pytest
      # FIXME: There are more python modules, like levenshtein,
      #        that should be installed via virtualenv, too.
      # For tox, install multiple Python versions.
      #python2.6
      #python3.2
      #python3.3
      # See pip (so we can install current version):
      #  cookiecutter

      # FIXME/MAYBE/MIGHT NOT MATTER: Just pip these in requirements.txts?
      python-tox
      python-coverage
      python3-coverage
      python-flake8
      python3-flake8

      libagg-dev
      libedit-dev
      mime-construct

      libproj-dev
      proj-bin
      proj-data

      libipc-signal-perl
      libmime-types-perl
      libproc-waitstat-perl

      python-nltk
      python-matplotlib
      python-tk

      # artha: off-line English thesaurus.
      # 2016-03-23: What uses this? You, from the command line?
      artha

      fabric
      # Know ye also there is a get-pip.py installer, too.
      python-pip
      python3-pip
      python3-sphinx

      curl

      # Node.js package manager.
      npm

      autoconf2.13

      # Color picker.
      gcolor2

      # Hopefully never: Windoes emulator and something about its browser.
      #  wine
      #  wine-gecko1.4

      # Interactive bash debugger. To set a breakpoint:
      #   source /usr/share/bashdb/bashdb-trace
      #   _Dbg_debugger
      # http://bashdb.sourceforge.net/
      bashdb

      # More exo stuff.
      sqlite3
      libsqlite3-dev
      spatialite-bin
      # Should already be installed:
      #libspatialite5

      unison

      # exFAT, MS format used on 32GB+ flash drives.
      exfat-fuse
      exfat-utils

      # ogrinfo et al
      gdal-bin
      gpx2shp

      streamripper

      # Maybe some day...
      zsh

      # For getting at automated emails sent by daemons.
      #mail
      #mutt
      ##mutt-patched
      #alpine
      # You can also just do:
      #  sudo cat /var/spool/mail/root
      #  sudo tail -n 1000 /var/spool/mail/root
      #  sudo grep "cron" /var/spool/mail/root

      # GUI git log tool and commit comparison [visual diff] tool
      gitk

      # 2016-09-30: Weird. I swore this was already part of setup.
      # 2016-10-03: I installed adb first, then android-tools-adb,
      # and the latter uninstalled the former. Hmmm.
      #adb
      android-tools-adb

      # Run `do-release-upgrade` to upgrade from one LTS to the
      # next LTS [point release], e.g., from 14.04 to 16.04.1.
      # (You can `do-release-upgrade -d` to upgrade to initial release,
      # e.g., 16.04.)
      # https://help.ubuntu.com/lts/serverguide/installing-upgrading.html#do-release-upgrade
      # https://wiki.ubuntu.com/YakketyYak/ReleaseNotes
      ubuntu-release-upgrader-core

      inotify-tools

      # 2017-05-23: What is with wanting to save color output to a file?
      # ls --color=always | aha --black > ls-with-colors.html
      aha
      # You can also pygmentize exiting files.
      #   pygmentize file.pl | \
      #     grep -i --color=always version | \
      #     aha --black > ls-with-colors.html

    ) # end: BIG_PACKAGE_LIST

    # 2016-09-26: What? I ran this script last Thursday, but did it not
    #             do this BIG_DESKTOP_LIST? Wireshark was not installed.
    #             Nor was dia. Nor anything else in this list! (dia,
    #             inkscape; fakeroot was fine, as was thunderbird;
    #             evince was not installed, nor akregator, nor any fonts:
    #             ttf-ancient-fonts, fonts-cantarell, lmodern, ttf-*
    #             (except ttf-bitstream-vera was okay), tv-fonts;
    #             nor digikam-doc, cmake, qt4-qmake, qt5-qmake,
    #             kdevplatform-dev, gnome-color-manager;
    #             hamster-applet and hamster-indicator were installed;
    #             finally, python-wxgtk2.8 IS NOT AVAILABLE!!!
    #
    #             HAHAHA, I bet you it failed because wxgtk2.8!!
    #
    #             FIXME: Is there not `set +e` set when running this script?
    #
    # FIXME: DELETE THIS COMMENT AFTER ANOTHER LINUX MINT 18 INSTALL
    #        and verifying that, e.g., wireshark installed.
    #        I'm pretty sure it was because of a package name with
    #        a version that applied to Mint 17 but not to Mint 18.

    local BIG_DESKTOP_LIST=(

      # Excellent diagramming.
      dia

      # SVG editor.
      inkscape

      # Pencil Project is a prototyping tool that
      # also support dia-ish diagram drawing.
      #  http://pencil.evolus.vn
      # But wait! The pencil package in Ubuntu is a different app.
      #  No: pencil
      #  See: stage_4_pencil_install

      # Well, when I was your age, we called it Ethereal.
      # NOTE: You will be prompted to answer Yes/No to should non-users be
      #       able to capture packets. Default is No. Answer YES instead.
      wireshark
      # Woozuh, some funky root-faking mechanism Wireshark uses.
      fakeroot
      #
      # Terminal-based Wireshark alternatives
      ssldump
      tshark

      thunderbird
      # Mutt bark bark better than mail (see also: elm)
      mutt

      # PDF/Document readers.
      # 2015.02.26: [lb] cannot get okular to open any PDFs...
      #             and all menu items but one are disabled,
      #             and choosing it crashes okular.
      #okular
      # 2015.02.26: One PDF I opened with acroread does not
      #             use the correct fonts... maybe because
      #             the version is so old (and acroread is
      #             no longer maintained). And, though I
      #             thought evince was installed by default,
      #             it appears not.
      #             Ug. use libreoffice to print PDFs.
      evince

      akregator

      # Symbola font for emojis.
      ttf-ancient-fonts
      # All the fonts.
      fonts-cantarell
      lmodern
      ttf-aenigma
      ttf-georgewilliams
      ttf-bitstream-vera
      ttf-sjfonts
      tv-fonts
      #ubuntustudio-font-meta

      # Ok, the distro version lags and has bugs. We will build later from source.
      #digikam
      digikam-doc
      # hrmmmm / 759 MB / for digikam
      #kde-full
      cmake
      qt4-qmake
      qt5-qmake
      kdevplatform-dev
      # Color mgmt.
      gnome-color-manager
      #dispcalgui

      # Time tracking applet.
      hamster-applet
      hamster-indicator

      # DVD burning software.
      # Already installed.
      #brasero

      # For the qq command.
      gnome-screensaver

      # Webcam software.
      # https://help.ubuntu.com/community/Webcam
      cheese

      # Lua scripting.
      lua5.2
      lua5.2-doc

      # Yaml linter. Because you always wanted more Yaml in your life.
      yamllint

      # For abcde CD ripper.
      cd-discid
      # vorbis-tools is probably already installed:
      vorbis-tools
      # lame is for MP3s.
      lame
      # Audio extraction tools.
      #   cdparanoia - audio extraction tool for sampling CDs
      #   libcdio13 - library to read and control CD-ROM
      #   icedax - Creates WAV files from audio CDs
      #   flac - Free Lossless Audio Codec - command line tools
      cdparanoia
      libcdio13
      icedax
      flac
      # mailx. Postfix. for cddb-tool
      bsd-mailx
      # Misc.
      # cd-discid - CDDB DiscID utility
      cd-discid
      # id3v2 - A command line id3v2 tag editor
      id3v2
      # vorbis-tools - several Ogg Vorbis tools
      vorbis-tools
      # mkcue - Generates a CUE sheet from a CD
      mkcue
      # $ apt-cache search cdrtools
      # simpleburn - Minimalistic application for burning and extracting CDs and DVDs
      simpleburn
      # abcde complains that cddb-tool not found. Is this close enough?
      python-cddb
      # What's the `musicbrainz` equivalent?
      # Picard is a cross-platform music tagger written in Python.
      picard
      # libwebservice-musicbrainz-perl - XML based Web service API to the MusicBrainz database
      libwebservice-musicbrainz-perl
      # Needed for lame encoding.
      # eyed3 - Display and manipulate id3-tags on the command-line
      # python-eyed3 - Python module for id3-tags manipulation
      eyed3

      # mount.nfs
      nfs-common

    ) # end: BIG_DESKTOP_LIST

    local BIG_DESKTOP_LIST_MINT_17=(
      # wxPython. Widgets!
      python-wxgtk2.8
    ) # end: BIG_DESKTOP_LIST_MINT_17

    local BIG_DESKTOP_LIST_MINT_18=(

      python-wxgtk3.0

      # On 14.04, ruby 1.9 is default. On 16.04, ruby 2.3 is default.
      ruby2.3
      ruby2.3-dev
      ruby2.3-doc

    ) # end: BIG_DESKTOP_LIST_MINT_18

    local BIG_PACKAGE_LIST_LMINT_17X=(

      postgresql-server-dev-9.3

      apache2-mpm-worker

      libicu52

      ia32-libs

      ttf-tuffy

      libproj0
      libspatialite5

      kde-full
      kde-workspace-dev

      # NOTE: If you have two-step authentication enabled for Gmail,
      #       rather than using your normal password, logon to google.com
      #       and generate a special application password.
      # checkgmail - alternative Gmail Notifier for Linux via Atom feeds
      #   sudo perl -MCPAN -e 'install Crypt::SSLeay'
      #   sudo perl -MCPAN -e 'install Crypt::Simple'
      #   Needs a patch:
      #     http://community.linuxmint.com/tutorial/view/1392
      #     http://sourceforge.net/p/checkgmail/bugs/105/
      #   but code is no longer maintained....
      # mailnag
      #   https://github.com/pulb/mailnag:
      #   sudo add-apt-repository ppa:pulb/mailnag
      #   # NOTE: To remove the repository:
      #   #  sudo /bin/rm /etc/apt/sources.list.d/pulb-mailnag-trusty.list
      #   sudo apt-get update
      #   sudo apt-get install mailnag
      # gmail-notify - Notify the arrival of new mail on Gmail
      #   Returns: "Login appears to be invalid."
      # Apps I did not try:
      #   conduit - synchronization tool for GNOME
      #   desktop-webmail - Webmail for Linux Desktops
      #   enigmail - GPG support for Thunderbird and Debian Icedove
      #   gm-notify - highly Ubuntu integrated GMail notifier
      #   gnome-do-plugins - Extra functionality for GNOME Do
      #   gnome-gmail - support for Gmail as the preferred email application in GNOME
      #   mail-notification - mail notification in system tray
      #   unity-webapps-gmail - Unity Webapp for Gmail
      # Works fine:
      #   gnome-gmail-notifier - A Gmail Inbox Notifier for the GNOME Desktop
      gnome-gmail-notifier

      # 2016-09-23: For some reason the desktop stopped being locked after suspend.
      # For the xss-lock!
      xscreensaver

      # On 14.04, ruby 1.9 is default. On 16.04, ruby 2.3 is default.
      ruby2.0
      ruby2.0-dev
      ruby2.0-doc

    ) # end: BIG_PACKAGE_LIST_LMINT_17X

    local BIG_PACKAGE_LIST_UMATE_15X=(

      # MAYBE: Need any of the packages in BIG_PACKAGE_LIST_LMINT_17X?

      # I tried gm-notify first and it works, and it doesn\'t use a
      # tray icon, which is fine because my inbox is never empty and
      # gnome-gmail-notifier\'s icon only indicates the non-emptiness
      # of the inbox -- I\'d maybe care for an icon if there was a
      # count of unread email, but really I just want a simple popup;
      # and gm-nofity works fine. Not great, not bad, just fine; I\'d say
      # I really like it if the desktop popup looked better, but that
      # might be Gnome\'s fault, and the simplicity is starting to appeal
      # to me. [-2016.03.25]
      #  "gm-notify - highly Ubuntu integrated GMail notifier"
      gm-notify
      # I tried "gmail-notify" but it did not like my creds.
      #  "gmail-notify - Notify the arrival of new mail on Gmail"
      # There is also gnome-gmail which I did not try.
      # "gnome-gmail - support for Gmail as the preferred email application in GNOME"

    ) # end: BIG_PACKAGE_LIST_UMATE_15X

    local BIG_PACKAGE_LIST_NOT_UBUNTU_16X=(

      # On Ubuntu: eNote, selecting libgd-dev instead of libgd2-xpm-dev
      libgd2-xpm-dev

      # Ick. PHP *and* MySQL.
      #libapache2-mod-php5
      #php5-dev
      #php5-mysql
      #dh-make-php

      python-logilab-astng

      nspluginwrapper

    ) # end: BIG_PACKAGE_LIST_NOT_UBUNTU_16X

    local BIG_PACKAGE_LIST_UBUNTU_16X=(

      # Cyclopath. runic.cs. apt-get is there, but not the other one.
      aptitude

      libgd-dev

      # I am sure I no longer need anything doing with either php or mysql.
      #libapache2-mod-php5
      #php-mysql
      #php7.0-mysql
      # Not sure what this is but do not care.
      #dh-make-php

      # python-logilab-astng is python-astroid
      python-astroid
      python3-astroid

      # Read a blog post that said to pull in the main multiverse
      # but I still got an Unable to locate package response.
      #  Add to /etc/apt/sources.list:
      #   deb http://us.archive.ubuntu.com/ubuntu xenial main multiverse
      #nspluginwrapper

      #postgresql-server-dev-9.3
      postgresql-server-dev-9.5

      # Not Ubuntu 16.04:
      #  apache2-mpm-worker
      # Maybe?:
      #  libapache2-mpm-itk

      # Probably already installed:
      #libicu52
      libicu55

      # No clue what equivalent(s) is(are) or if needed:
      #  ia32-libs

      #ttf-tuffy
      # Maybe it is:
      fonts-tuffy
      # though I cannot imagine what it is for. LibreOffice?

      # already installed:
      #libproj0
      libproj9
      #libspatialite5
      libspatialite7

      # Cyclopath needs this to build Mapserver.
      #  g++ ... -lselinux in is packages libselinux1 libselinux1-dev
      libselinux1
      libselinux1-dev
      #  g++ ... -lgssapi_krb5 in is package libkrb5-dev
      libkrb5-dev

      # For fiona.
      libgdal1-dev

      # For Cyclopath flashclient build via fcsh.
      # Follow symlinks on dpkg -S /usr/bin/java
      #openjdk-8-jre-headless

      # For Cyclopaths mr_do.
      python-lxml

    ) # end: BIG_PACKAGE_LIST_UBUNTU_16X

    local BIG_PACKAGE_LIST_UBUNTU_1604_AND_BEYOND=(
      # I.e., Ubuntu 16.04

      digikam

      # 2016-09-23: For some reason the desktop stopped being locked after suspend.
      # For the xss-lock!
      xscreensaver

    ) # end: BIG_PACKAGE_LIST_UBUNTU_1604_AND_BEYOND

    # 2016-07-17: Cyclopath Resuscitation. Why didn't a failed apt-get
    # cause this script to die? I can't figure out where the errexit
    # got taken away, but it did!
    # 2016-09-26: I think I had the same issue with BIG_DESKTOP_LIST
    # because python-wxgtk2.8. So adding USING_ERREXIT. Hrmmmmm.
    USING_ERREXIT=true
    reset_errexit

    # One core package, and maybe
    # One Giant MASSIVE package install.

    sudo apt-get install -y ${CORE_PACKAGE_LIST[@]}
    if [[ $? -ne 0 ]]; then
      echo
      echo "WARNING: FAILED: CORE_PACKAGE_LIST"
      echo
    fi

    if [[ ${IS_HEADED_MACHINE_ANSWER} == "Y" ]]; then
      sudo apt-get install -y ${CORE_DESKTOP_LIST[@]}
      if [[ $? -ne 0 ]]; then
        echo
        echo "WARNING: FAILED: CORE_DESKTOP_LIST"
        echo
      fi
    fi

    if [[ ${INSTALL_ALL_PACKAGES_ANSWER} == "Y" ]]; then

      # 2016-10-28: On mnemosyne, error said nginx and nginx-core
      # failed to install, and something about a dpkg error.
      # I rebooted and all is well.
      sudo apt-get install -y ${BIG_PACKAGE_LIST[@]}

      source /etc/lsb-release
      # 2016-09-26: The Ubuntu 16.04 package list is obviously compatible with Mint 18!
      if [[ $DISTRIB_ID == 'Ubuntu' || ( $DISTRIB_ID == 'LinuxMint' && $DISTRIB_RELEASE -ge 18 ) ]]; then
        sudo apt-get install -y ${BIG_PACKAGE_LIST_UBUNTU_16X[@]}
        if [[ $? -ne 0 ]]; then
          echo
          echo "WARNING: FAILED: BIG_PACKAGE_LIST_UBUNTU_16X"
          echo
        fi
      else
        sudo apt-get install -y ${BIG_PACKAGE_LIST_NOT_UBUNTU_16X[@]}
        if [[ $? -ne 0 ]]; then
          echo
          echo "WARNING: SKIPPING: BIG_PACKAGE_LIST_NOT_UBUNTU_16X"
          echo
        fi
      fi
      if [[ $DISTRIB_ID == 'LinuxMint' && $DISTRIB_RELEASE -ge 18 ]]; then
        # 2016-09-26: FIXME: This won't work forever, will it?
        #             Or will Mint always increment ordinally to an integer?
        sudo apt-get install -y ${BIG_PACKAGE_LIST_UBUNTU_1604_AND_BEYOND[@]}
        if [[ $? -ne 0 ]]; then
          echo
          echo "WARNING: FAILED: BIG_PACKAGE_LIST_UBUNTU_1604_AND_BEYOND"
          echo
        fi
      fi
      if [[ ${IS_HEADED_MACHINE_ANSWER} == "Y" ]]; then
        echo
        echo "SUCCESS: YES INSTALLING: BIG_DESKTOP_LIST"
        echo
        sudo apt-get install -y ${BIG_DESKTOP_LIST[@]}
        if [[ $? -ne 0 ]]; then
          echo
          echo "WARNING: FAILED: BIG_DESKTOP_LIST"
          echo
        fi

        if [[ $DISTRIB_ID == 'LinuxMint' && $DISTRIB_RELEASE -lt 18 ]]; then
          sudo apt-get install -y ${BIG_DESKTOP_LIST_MINT_17[@]}
          if [[ $? -ne 0 ]]; then
            echo
            echo "WARNING: FAILED: BIG_DESKTOP_LIST_MINT_17"
            echo
          fi
        elif [[ $DISTRIB_ID == 'LinuxMint' && $DISTRIB_RELEASE -ge 18 ]]; then
          sudo apt-get install -y ${BIG_DESKTOP_LIST_MINT_18[@]}
          if [[ $? -ne 0 ]]; then
            echo
            echo "WARNING: FAILED: BIG_DESKTOP_LIST_MINT_18"
            echo
          fi
        else
            echo
            echo "WARNING: FAILED: NOT MINT: NOT INSTALLING BIG_DESKTOP_LIST_MINT_*"
            echo
        fi

      else
        # FIXME/2016-09-26: Tracking issue not installing BIG_DESKTOP_LIST
        echo
        echo "WARNING: NOT INSTALLING: BIG_DESKTOP_LIST"
        echo
      fi
    fi

    if [[ ${INSTALL_ALL_PACKAGES_ANSWER} == "Y" ]]; then
      sudo apt-get install -y apt-file
      sudo apt-file update
    fi

    # Install additional MATE theme, like BlackMATE. We don't change themes,
    # but it's nice to be able to see what the other themes look like.

    if $WM_IS_MATE; then
      sudo apt-get install -y mate-themes
    fi

    # All done.

  fi # upgrade all packages and install extras that we need

} # end: setup_mint_17_stage_1_apt_get_install

# ------------------------------------------
# STAGE 2

# *** SECOND BOOT: Install Guest Additions

setup_mint_17_stage_2_virtualbox_guest_additions () {

  if ! ${IN_VIRTUALBOX_VM}; then
    echo
    echo "ERROR: VBoxGuestAddition: Skipping Stage 2: Not a VirtualBox."
    echo
    return
  fi

  set +e
  # NOTE: This doesn't work for checking $? (the 2&> replaces it?)
  #        ll /opt/VBoxGuestAdditions* 2&> /dev/null
  ls -la /opt/VBoxGuestAdditions* &> /dev/null
  exit_code=$?
  reset_errexit
  if [[ $exit_code -eq 0 ]]; then
    echo
    echo "SKIPPING: VBoxGuestAddition: Already installed."
    echo
    return
  fi

  if $WM_IS_CINNAMON || $WM_IS_MATE; then
    not_done=true
    while $not_done; do
      if [[ `ls /media/$USER | grep VBOXADDITIONS` ]]; then
        not_done=false
      else
        echo
        echo "PLEASE: From the VirtualBox menu bar, choose"
        echo "         Devices > Insert Guest Additions CD Image..."
        echo "        and then press any key to continue."
        echo
        read -n 1 __ignored__
      fi
    done
    cd /media/$USER/VBOXADDITIONS_*/
  elif $WM_IS_XFCE; then
    echo
    echo "PLEASE: Insert the Guest Additions CD Image"
    echo "        and then press any key to continue."
    echo
    read -n 1 __ignored__
    sudo /bin/mkdir /media/VBOXADDITIONS
    sudo mount -r /dev/cdrom /media/VBOXADDITIONS
    cd /media/VBOXADDITIONS
  fi

  # You'll see a warning and have to type 'yes': "You appear to have a
  # version of the VBoxGuestAdditions software on your system which was
  # installed from a different source or using a different type of
  # installer." Type 'yes' to continue.

  set +e
  sudo sh ./VBoxLinuxAdditions.run
  echo "Run return code: $?"
  reset_errexit

  echo
  echo "All done! You should reboot now."
  echo
  echo "Are you ready to reboot?"
  #echo
  #echo "Hint: Shutdown instead if you want to remove the Guest Additions image"
  #echo "      or just right-click the CD image on the desktop and Eject it"
  ask_yes_no_default 'Y' 999999

  if [[ $the_choice != "Y" ]]; then
    echo "Ohhhh... kay."
    exit 1
  else
    echo "Swizzle! See you on the other side!!"
    /sbin/shutdown -r now
    exit 0
  fi

} # end: setup_mint_17_stage_2_virtualbox_guest_additions

# ------------------------------------------
# STAGE 3

# *** THIRD BOOT: Setup Bash and Home Scripts and User Groups

setup_mint_17_stage_3_groups_etc () {

  # Setup user group(s) and user-group associations.

  # Let the user access any mounted VBox drives.
  # 2016-03-23: The group is added by guest additions, and
  # the user manually added their user to the same group,
  # so this code should not do anything that's not already
  # done.
  if ${IN_VIRTUALBOX_VM}; then
    set +e
    groups | grep vboxsf
    exit_code=$?
    set -e
    if [[ $exit_code -ne 0 ]]; then
      sudo groupadd vboxsf
      sudo usermod -aG vboxsf $USER
      LOGOUT_NECESSARY=true
    fi
  fi

  # Make the user a member of the staff group, or whatever it's called.

  # 20160323: This is currently just "staff".
  if [[ -n ${USE_STAFF_GROUP_ASSOCIATION} ]]; then
    set +e
    groups | grep ${USE_STAFF_GROUP_ASSOCIATION}
    exit_code=$?
    set -e
    if [[ $exit_code -ne 0 ]]; then
      sudo groupadd ${USE_STAFF_GROUP_ASSOCIATION}
      sudo usermod -a -G ${USE_STAFF_GROUP_ASSOCIATION} $USER
      LOGOUT_NECESSARY=true
    fi
  fi

  # Always associate current user group with postgres and web server.

  # 2016-03-23: Currently not set.
  if ! `array_in "$USER" "${USE_PROJECT_USERGROUPS[@]}"`; then
    USE_PROJECT_USERGROUPS+=("$USER")
  fi

  # Usually,
  #  groupname=("$USER")
  for groupname in ${USE_PROJECT_USERGROUPS[@]}; do
    set +e
    groups | grep ${groupname}
    exit_code=$?
    set -e
    if [[ $exit_code -ne 0 ]]; then
      # Add the ${groupname} group. It's okay if you've already done it
      # manually: the command will just return $? == 9 and complain to
      # stderr, e.g., "groupadd: group '...' already exists".
      set +e
      sudo groupadd ${groupname}
      set -e

      # Add the active user to the group.
      sudo usermod -a -G ${groupname} ${USER}

      # Make postgres a member so its easier to read its logs.
      # E.g., in Cyclopath, the logs are writ to /ccp/var/log/postgresql
      # (which, on the production server, is mapped to different drive
      # that where most of the Linux OS resides).
      sudo usermod -a -G ${groupname} postgres

      # Also make apache a member of the group for similar reasons.
      # E.g., in Cyclopath, www-data logs to /ccp/var/log/apache2.
      #
      # FIXME: Is this a security issue if we make www-data part of
      #        this group? If someone compromised www-data they could
      #        conceivably access all group files, and not just
      #        what's under htdocs/, right? Hmmm.
      sudo usermod -a -G ${groupname} ${httpd_user}

      LOGOUT_NECESSARY=true
    fi
  done

  # Configure Wireshark so that it can be run unprivileged.

  # Add the wireshark group and tell dumpcap to run privileged.
  # References:
  #  http://ask.wireshark.org/questions/7523/ubuntu-machine-no-interfaces-listedn
  #  http://wiki.wireshark.org/CaptureSetup/CapturePrivileges

  #   ┌────────────────┤ Configuring wireshark-common ├─────────────────┐
  #   │                                                                 │
  #   │ Dumpcap can be installed in a way that allows members of        │
  #   │ the "wireshark" system group to capture packets. This is        │
  #   │ recommended over the alternative of running Wireshark/Tshark    │
  #   │ directly as root, because less of the code will run with        │
  #   │ elevated privileges.                                            │
  #   │                                                                 │
  #   │ For more detailed information please see                        │
  #   │ /usr/share/doc/wireshark-common/README.Debian.                  │
  #   │                                                                 │
  #   │ Enabling this feature may be a security risk, so it is          │
  #   │ disabled by default. If in doubt, it is suggested to            │
  #   │ leave it disabled.                                              │
  #   │                                                                 │
  #   │ Should non-superusers be able to capture packets?               │
  #   │                                                                 │
  #   │                  <Yes>                 <No>                     │
  #
  # ANSWER: YES

  if [[ ${INSTALL_ALL_PACKAGES_ANSWER} == "Y" \
      && ${IS_HEADED_MACHINE_ANSWER} == "Y" ]]; then
    sudo dpkg-reconfigure wireshark-common
    # Add the user to the new group.
    set +e
    groups | grep wireshark
    exit_code=$?
    set -e
    if [[ $exit_code -ne 0 ]]; then
      sudo usermod -a -G wireshark ${USER}
      # You need to logout or reboot to see changes.
      LOGOUT_NECESSARY=true
    fi
  fi

  # Try to mount the host drive.
  #
  # Do this now because the user has to reboot before
  # their new access to the vboxsf group is realized.
  #
  # 2016-03-23: Also no longer necessary and done otherways.
  if [[ -n ${USE_MOUNTPT} && -n ${DST_MOUNTPT} ]]; then
    sudo /bin/mkdir -p ${DST_MOUNTPT}
    sudo chmod 2775 ${DST_MOUNTPT}
    if ! ${IN_VIRTUALBOX_VM}; then
      sudo mount -t ntfs ${USE_MOUNTPT} ${DST_MOUNTPT}
    else
      sudo mount -t vboxsf ${USE_MOUNTPT} ${DST_MOUNTPT}
    fi
    if [[ $? -ne 0 ]]; then
      echo "WARNING: Could not mount host drive using the command:"
      echo "         sudo mount -t vboxsf ${USE_MOUNTPT} ${DST_MOUNTPT}"
      exit 1
    fi

    # Fix the VBox mount. After the reboot, the user will
    # have access to the auto-mount, so just symlink it.
    echo "Fixing VBox mount."
    if ! ${IN_VIRTUALBOX_VM}; then
      #
      # FIXME: Append to /etc/fstab.
      #        See code in Excensus_Developer_Setup_Guide.rst.
      :
    else
      sudo umount ${USE_MOUNTPT}
      sudo /bin/rmdir ${DST_MOUNTPT}
      sudo /bin/ln -s /media/sf_${USE_MOUNTPT} ${DST_MOUNTPT}
    fi
  fi

  # 2017-04-04: How have I never had a problem with this?
  # Already in "plugdev", but "fuse" is "nuse" to me.
  sudo usermod -a -G plugdev,fuse ${USER}

} # end: setup_mint_17_stage_3_groups_etc

# ------------------------------------------
# STAGE 4

# *** FOURTH BOOT: Configure Window Manager and Compile and Install Apps.

setup_mint_17_stage_4_extras () {

  # *** Make a snapshot of the user's home directory, maybe.

  user_home_conf_dump "${script_absbase}/conf_dump/usr_04"

  # *** Install Dubsacks VIM.

  echo
  echo "Installing Dubsacks Vim..."
  echo
  ${script_absbase}/vendor_dubsacks.sh

  # *** Tweak the Window Manager Configuration.

  # Disable passwords and require SSH keys.

  stage_4_sshd_configure

  # *** Customize the distro and window manager.

  # FIXME: Should check we're actually installing on Mint first...
  #if ${WM_IS_MATE} && [[ ${IS_HEADED_MACHINE_ANSWER} == "Y" ]]; then
  if [[ ${IS_HEADED_MACHINE_ANSWER} == "Y" ]]; then
    stage_4_wm_customize_mint
  fi

  # The new hot: MATE on Mint.
  if $WM_IS_MATE; then
    echo "Sourcing custom_setup.mate.sh"
    source ${script_absbase}/custom_setup.mate.sh
  fi

  # Setup third-party apps that are not found in the official repos.
  # We'll find them in third-party repos, or by downloading and compiling
  # source.
  if [[ ${INSTALL_ALL_PACKAGES_ANSWER} == "Y" ]]; then
    echo
    echo "Installing Extras..."
    source ${script_absbase}/custom_setup.extras.sh
    if [[ ${IS_HEADED_MACHINE_ANSWER} == "Y" ]]; then
      setup_customize_extras_go
    else
      :
      #setup_customize_extras_go
      stage_4_psql_configure
      stage_4_apache_configure
      stage_4_cloc_install
      stage_4_all_the_young_pips
      stage_4_sqlite3
      stage_4_python_35
      stage_4_updatedb_locate_conf
      stage_4_disable_services
      stage_4_dev_testing_expect_install
    fi
  # else, this is a keypass/lite machine; don't do anyextras.
  fi

  # Install "vendor" add-ons, or your personal projects.

  # 2016.03.23: Disabling for now; not really used except
  #             vendor_dubsacks.sh which was already called.
  echo
  echo "Skipping vendor setup files:"
  for vfname in $(find ${script_absbase} \
                    -maxdepth 1 \
                    -type f \
                    -name "vendor_*.sh"); do
    #source ${script_absbase}/${vfname}
    echo "${script_absbase}/${vfname}"
  done

  # Update the `locate` db.

  # Be nice and update the user's `locate` database.
  # (It runs once a day, but run it now because we
  # might make a virtual machine image next.)
  echo
  echo "Updating locatedb..."
  sudo updatedb

  # Remind the user about manual steps left to perform.

  echo "#######################################################"
  echo "#                                                     #"
  echo "#  ============                                       #"
  echo "#  MANUAL STEPS                                       #"
  echo "#  ============                                       #"
  echo "#                                                     #"
  echo "#  This scripts automated what it could.              #"
  echo "#                                                     #"
  echo "#  You'll have to do some things manually, like:      #"
  echo "#                                                     #"
  echo "#    - Customize MATE panels.                         #"
  echo "#                                                     #"
  echo "#    - Install web browser plugins.                   #"
  echo "#                                                     #"
  echo "#    - And a few other things...                      #"
  echo "#                                                     #"
  echo "#  Refer to the helpful manual steps readme:          #"
  echo "#                                                     #"
  echo "#   A_Manual_MATE_Setup_Guide.rst                     #"
  echo "#                                                     #"
  echo "#######################################################"

  # All done.

} # end: setup_mint_17_stage_4_extras

stage_4_sshd_configure () {

  # Setup sshd.

  # If you didn't apt-get install openssh-server, this file isn't there.

  # Turn off password auth, so users can only connect with SSH keys.
  # Otherwise, you'll see thousands of attacks on port 21 trying
  #   to get in your machinepants.
  # See: https://help.ubuntu.com/community/SSH/OpenSSH/Keys
  # This is also more convenient -- you won't be prompted for a password
  # whenever you try to log into this machine.

  echo "Setting up sshd"

  # 2016-11-14: I got a sed complaint but rerunning the script worked.
  # Setting up sshd
  # /bin/sed: -e expression #1, char 75: unknown option to `s'

  if [[ -e /etc/ssh/sshd_config ]]; then
    if [[ ${IS_HEADED_MACHINE_ANSWER} == "Y" ]]; then
      set +e
      grep "PasswordAuthentication no" /etc/ssh/sshd_config &> /dev/null
      exit_code=$?
      reset_errexit
      if [[ $exit_code -ne 0 ]]; then
        sudo /bin/sed -i.bak \
          "s/^#PasswordAuthentication yes$/#PasswordAuthentication yes\n# Added by ${0}:${USER} at `date +%Y.%m.%d-%T`.\nPasswordAuthentication no/" \
          /etc/ssh/sshd_config
        #sudo service ssh restart
        sudo service sshd restart
      else
        # FIXME: Set up SSH keys on HEADLESS before requiring them.
        #        MAYBE: See travel.sh. It complains if PasswordAuthentication
        #        is not disabled. Will that be enough of a reminder when
        #        I set up a headless machine?
        :
        echo
        echo "CAVEAT: This is a HEADLESS machine."
        echo
        echo "  Set up your SSH keys and then disable SSH PasswordAuthentication"
        echo
      fi
    fi

    # You can test logging in with `ssh localhost`.
    # To debug: `ssh -vvv localhost` but oftentimes the server log
    # is more useful: `tail -F /var/log/auth.log`, e.g.,
    #   Mar 25 01:47:41 kalliope sshd[3946]: Authentication refused:
    #     bad ownership or modes for directory /home/$USER
    chmod g-w ~
  fi

  echo "sshd setup"

} # end: stage_4_sshd_configure

stage_4_wm_customize_mint () {

  # From the Mint Menu in the lower-left, remove the text and
  # change the icon (e.g., to a playing die with five pips showing).

  set +ex
  GSETTINGS_MENU="com.linuxmint.mintmenu"
  gsettings list-schemas | grep "${GSETTINGS_MENU}" &> /dev/null
  if [[ $? -ne 0 ]]; then
    GSETTINGS_MENU="org.mate.mate-menu"
    gsettings list-schemas | grep "${GSETTINGS_MENU}" &> /dev/null
    if [[ $? -ne 0 ]]; then
      GSETTINGS_MENU=""
      echo
      echo "WARNING: Could not determine gsettings schema for menu keys."
      exit 1
    fi
  fi
  reset_errexit

  if [[ -e ${USE_MINT_MENU_ICON} ]]; then
    USER_BGS=/home/${USER}/Pictures/.backgrounds
    /bin/mkdir -p ${USER_BGS}
    /bin/cp \
      ${USE_MINT_MENU_ICON} \
      ${USER_BGS}/mint_menu_custom.png
    gsettings set ${GSETTINGS_MENU} applet-icon \
      "${USER_BGS}/mint_menu_custom.png"
  fi
  # The default applet-icon-size is 22.
  gsettings set ${GSETTINGS_MENU} applet-icon-size 22
  # The default applet-text is 'Menu'.
  gsettings set ${GSETTINGS_MENU} applet-text ''

  # FIXME/MAYBE: Currently, you have to manually setup the panels
  # and panel launchers. Though we could maybe do it programmatically.
  # See the dconf settings, e.g.,
  #
  # $ dconf list /org/mate/panel/objects/
  # ...
  # $ dconf list /org/mate/panel/objects/object_0/
  # ...
  # $ dconf read /org/mate/panel/objects/object_0/launcher-location
  # '/usr/share/applications/firefox.desktop'
  # $ dconf read /org/mate/panel/objects/object_2/launcher-location
  # 'my_launcher.desktop'
  # $ dconf write ...

  # FIXME/MAYBE: Maybe move this to a Vim install/setup script?
  #
  # The default mapping to open the MATE Menu is the Windows/Super key
  # ('<Super>'), but I fat-finger it sometimes so add the shift key.
  gsettings set ${GSETTINGS_MENU} hot-key '<Super>Shift_L'

  # MAYBE: Move these thoughts to a reST article, specifically a dead one.

  # Didn't make the cut:
  #
  # Roll Up and Down a Window
  #
  #   Go to Menu > Control Center > Personal
  #   Click "Windows" to open up "Window Preferences".
  #   In "Titlebar Action" under the "Behaviour" tab,
  #     select "Roll up" from the drop-down list.
  #
  # Comments: Rolling windows is nostalgic and
  #           "neat" but not part of my workflow.

  # Advanced File Browser
  #
  #   Go to Menu > Applications > Preferences > Main Menu
  #   Select "Accessories" in the left panel
  #     and click "New Item" in the right panel.
  #   Enter a name such as Advanced File Browser in the "Name" box.
  #   Enter `gksu caja` in the "Command" field.
  #   Click the "OK" button and the "Close" button.
  #
  # Comments: Using `caja` is probably nice but I rarely, if ever,
  #           use a file browser.
  #
  # You could also set double-click to open Vim on text files, but
  # who ever opens a file other than with the terminal or the editor?
  #
  #   Personal > Preferred Applications > System [tab]
  #     > Text Editor > GVim [from "Text Editor"]

  # 2017-07-13: Alt-tab is very slow -- there's a secondish delay.
  #   Seems to be caused by "Compositing" in the Window Manager.
  #
  # https://askubuntu.com/questions/43875/how-do-i-adjust-the-alt-tab-speed
  #
  # Default (see also: Mint Menu > Preferences > Desktop Settings > Windows > Window Manger)
  #   $ gsettings get com.linuxmint.desktop mate-window-manager
  #   'marco-composite'
  #
  # 2017-07-19: Aha! I was wondering why this wasn't a problem at home:
  #   on 12.04, there's a checkbox for "Use compositing" that's unchecked,
  #   and Marco and Compwiz are the only two window managers
  #   (so there's no marco-composite and marco-compton).
  # So in 14.04, compositing was added to the window manager option
  #   as a bundled option, in a sense (though not sure what "compton"
  #   means -- is it just non-compositing, or is it something more?).
  #
  gsettings set com.linuxmint.desktop mate-window-manager 'marco-compton'

} # end: stage_4_wm_customize_mint

# ==============================================================
# Application Main()

# *** Call this fcn. from a wrapper script.
#     Or source this script and run it yourself.

setup_ubuntu_go () {

  if [[ -z ${INSTALL_ALL_PACKAGES_ANSWER+x} ]]; then
    echo
    echo "Is this a dev machine? Do you want all the dev packages?"
    ask_yes_no_default 'Y' 999999
    INSTALL_ALL_PACKAGES_ANSWER=$the_choice
  fi
  if [[ -z ${IS_HEADED_MACHINE_ANSWER+x} ]]; then
    echo
    echo "Is this a headed machine (not headless)? Do you want GUI apps?"
    ask_yes_no_default 'Y' 999999
    IS_HEADED_MACHINE_ANSWER=$the_choice
  fi

  # Call `sudo apt-get install -y [lots of packages]`.
  setup_mint_17_stage_1_apt_get_install

  # There are a number of ways to check if we're running in a virtual machine.
  # You could check PCI and USB devices for their names, or dmesg, e.g.,
  #   lspci | grep VirtualBox
  #   lsusb | grep VirtualBox
  #   dmesg | grep VirtualBox
  # but those are, well, hacks.
  # The better way is to use a specific utility, like virt-what or imvert.
  # 2016-03-23: Since when did virt-what start giving back more?:
  #   $ sudo virt-what
  #   virtualbox
  #   kvm
  #if [[ `sudo virt-what` != 'virtualbox' ]]; then ...; fi
  set +e
  IN_VIRTUALBOX_VM=false
  sudo virt-what | grep 'virtualbox' &> /dev/null
  if [[ $? -eq 0 ]]; then
    IN_VIRTUALBOX_VM=true
  fi
  reset_errexit

  # Now that wmctrl is installed...
  # Set WM_IS_MATE, etc.
  determine_window_manager

  if ${IN_VIRTUALBOX_VM}; then
    # 2016.03.23: It's best if the user just installs guest additions manually
    # right after installing an OS, before running this script, so not calling
    #    setup_mint_17_stage_2_virtualbox_guest_additions
    #  See: ubuntu_mate_15.10.rst for easy instructions.
    setup_mint_17_stage_2_virtualbox_guest_additions
  fi

  # Setup usergroups and the user's home directory.
  setup_mint_17_stage_3_groups_etc

  # Download, compile, and configure lots of software.
  setup_mint_17_stage_4_extras

  print_install_time

  echo
  echo "TESTING: /bin/bash"
  echo
  /bin/bash -c "echo HELLO"

  # C'est ca!
  echo
  echo "All done!"

  if ${LOGOUT_NECESSARY} || ${REBOOT_NECESSARY}; then
    echo "You'll have to logout or reboot to realize group or other changes."
    bluu=`tput setaf 4; tput smul;`
    rset=`tput sgr0`
    echo "Would you like to ${bluu}L${rset}ogout or ${bluu}R${rset}eboot?"
    ask_yes_no_default 'L' 999999 'R'
    if [[ $the_choice == "R" ]]; then
      /sbin/shutdown -r now
      exit 0
    elif [[ $the_choice == "L" ]]; then
      if ``command -v mate-session-save >/dev/null 2>&1``; then
        mate-session-save --logout
      elif ``command -v gnome-session-save >/dev/null 2>&1``; then
        gnome-session-save --logout
      else
        echo
        echo "ERROR: Unknown window manager. Don't know how to logout."
        echo
        exit 1
      fi
    else
      echo "But I was trying to be nice to you!"
      exit 1
    fi
  fi

  exit 0

} # end: setup_ubuntu_go

# Only run when not being sourced.
if [[ "$0" == "$BASH_SOURCE" ]]; then
  setup_ubuntu_go
else
  echo "WARNING: setup_ubuntu.sh was sourced."
  echo "BEWARE the \`exit\`s"
fi

# Vim modeline:
# vim:tw=0:ts=2:sw=2:et:norl:

