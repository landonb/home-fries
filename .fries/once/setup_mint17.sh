#!/bin/bash

# File: setup_mint17.sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Last Modified: 2016.03.23
# Project Page: https://github.com/landonb/home_fries
# Summary: Linux Mint MATE Automated Developer Environment Setterupper.
# License: GPLv3
# -------------------------------------------------------------------
# Copyright © 2011-2016 Landon Bouma.
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





# FIXME: Move following to the laptop setup script:

# FIXME: Document git'ing home-fries and setting up that way.
# FIXME: Document copying over sync-script file and setting up that way.
# cd ~/Documents/packered_larry_2015_12_30_13h33m45s/home/landonb
# cp -ari * ~
# cp -arn * ~
#         Especially ~/.ssh and cheat/
# FIXME: /kit and /srv/excensus should link from ${HOME}/Documents if home dir is encrypted...
#          look for: ${HOME}/.ecryptfs
#          look in /home/.ecryptfs/$USER/.ecryptfs/Private.mnt
#                  for home directory path
#          look for mount point: df ${HOME}
# Filesystem              1K-blocks Used      Available Use% Mounted on
# /home/username/.Private 315482376 101351268 198105472  34% /home/username
#
# BEST TO USE
#   ecryptfs-verify --home &> /dev/null
#   and then check $?
#
# Check if swap encrypted:
#
# sudo blkid | grep swap
# and should check for an output similar to
# /dev/mapper/cryptswap1: UUID="95f3d64d-6c46-411f-92f7-867e92991fd0" TYPE="swap" 
#
# sudo cryptsetup status /dev/mapper/cryptswap1
# and check $?
# (to see swap name: swapon -s)
#
# FIXME: laptop not using encrypted swap!
#

# FIXME: Setup .fries, .erectus, etc.
# FIXME: 2016.01.07: Setup ~/.fries/cheat and other missing doodads...
#         need to figure out

# FIXME: See below:
#         Fix /etc/default/grub here for host OS install.




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
  echo ' .. tested on Linux Mint MATE 17.x and Ubuntu MATE 15.10. Good luck!'
  echo
fi

# ------------------------------------------
# Bootstrap

if [[ ! -e ../bin/bash_base.sh ]]; then
  echo "Error: Expected to find ../bin/bash_base.sh."
  exit 1
fi
DEBUG_TRACE=false
source ../bin/bash_base.sh
# ${script_absbase} is now the absolute path to this script's directory.

# ------------------------------------------
# Configuration

if [[ ! -e ./mint17_setup_base.sh ]]; then
  echo "Error: Expected to find ./mint17_setup_base.sh."
  exit 1
fi
DEBUG_TRACE=false
source ./mint17_setup_base.sh
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
# Figure out what stage we're on.

DO_STAGE_DANCE=false

if ${DO_STAGE_DANCE}; then
  # MAGIC_NUMBER: There are four stages (and logouts/reboots between each).
  stages_count=4
  if [[ ! -e ${script_absbase}/fries-setup-stage.num ]]; then
    # First time here.
    stage_num=1
    echo "${stage_num}" > ${script_absbase}/fries-setup-stage.num
  else
    stage_num=`cat fries-setup-stage.num`
    # Validate the stage number.
    if [[ ${stage_num} -lt 1 || ${stage_num} -gt ${stages_count} ]]; then
      echo "Unexpected stage_num: ${stage_num}"
      exit 1
    fi
  fi
  echo "On stage number ${stage_num} of ${stages_count}"
else
  stage_num=-1
fi

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

USING_ERREXIT=true
reset_errexit

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

  if $MAKE_CONF_DUMPS; then

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
    -e USE_SETUP_HG \
    -e HG_USER_NAME \
    -e HG_USER_EMAIL \
    -e HG_DEFAULT_PATH \
    -e INCLUDE_ADOBE_READER
}

echo "Here's how the script is configured:"
echo
# MEH: For some reason the `set | grep...` command is echoed after it runs...
setup_ready_print_env

REBOOT_WILL_BE_NECESSARY=false

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

IS_DEV_MACHINE_ANSWER=''

setup_mint_17_stage_1 () {

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
  ask_yes_no_default 'Y' 999999

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
      echo "UNEXPECTED: /etc/sudoers already edited."
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

    # *** Disable screen locking so user can move about the cabin freely.

    determine_window_manager

    if $WM_IS_MATE; then
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

    # -- Install postfix (also interactive).

    # FIXME: Which package does this? It's another interactive installer.
    # 2016.03.23: It's one of: libpam0g-dev openssh-server signing-party.
    # You'll be prompted to "Please select the mail server configuration
    #                        type that best meets your needs."
    # Just choose "Internet Site", or even "Local only".

    # For "System mail name" just use... I dunno, whatever, $USE_DOMAIN.

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

      # CLI OS and Window Manager customizers.
      dconf-cli
      gconf-editor
      wmctrl
      xdotool

      # Vim (See later: Dubsacks Vim.)
      vim-gtk
      # Text columnizer.
      par
      # Ctags.
      exuberant-ctags
      # Ruby dev tools for Command-T.
      ruby-dev

      # Awesomest graphical diff.
      meld

      # Eye of Gnome, a slideshow image viewer.
      eog

      # Hexadecimal file viewer.
      ghex

      # Hexadecimal diff.
      vbindiff
      #hexdiff

      # `most` is pretty lame; author prefers `less`.
      #most
      # `less` is made better with color.
      python-pygments

      # The better grepper.
      silversearcher-ag

      # Un-Zip-a-Dee-Doo-Dah
      unzip

      # All your repositories are belong to too many managers.
      git
      git-core

      # One would think whois would be standard.
      whois
      # nslookup is... stale, to be polite. Use dig instead.

      htop

      # Meh. Keepassx is convenient for people who like GUIs, but I
      # think gpg or encfs is just as easy for someone comfy on the CLI.
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

    ) # end: CORE_PACKAGE_LIST

    local BIG_PACKAGE_LIST=(

      logcheck
      logcheck-database

      logtail

      socket

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

      # Addition, non-core repo tools.
      subversion
      mercurial
      # A beautiful, colorful git browser/helper.
      tig

      # Well, when I was your age, we called it Ethereal.
      wireshark
      # Woozuh, some funky root-faking mechanism Wireshark uses.
      fakeroot

      apache2
      apache2-dev
      apache2-mpm-worker
      apache2-utils

      nginx

      postgresql
      postgresql-client
      postgresql-server-dev-9.3

      php5-dev
      php5-mysql
      libapache2-mod-php5
      dh-make-php

      libxml2-dev
      libjpeg-dev
      libpng++-dev
      libgd-dev
      imagemagick
      libmagick++-dev
      texlive
      autoconf
      vsftpd
      libcurl3
      pcregrep
      gir1.2-gtop-2.0
      libgd-dev
      libgd2-xpm-dev
      libxslt1-dev
      xsltproc
      libicu52
      libicu-dev

      python-dev
      python-setuptools
      libapache2-mod-python
      python-simplejson
      python-logilab-astng
      python-logilab-common
      python-gtk2
      python-wnck
      python-xlib
      python-dbus
      pylint

      # FIXME/MAYBE: Can/Should these be virtualenv-installed?
      python-egenix-mxdatetime
      python-egenix-mxtools
      python-logilab-astng
      python-logilab-common
      python-subversion
      python-levenshtein

      # MAYBE?:
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
      libproj0
      proj-bin
      proj-data

      libipc-signal-perl
      libmime-types-perl
      libproc-waitstat-perl

      ia32-libs
      nspluginwrapper

      python-nltk
      python-matplotlib
      python-tk

      # artha: off-line English thesaurus.
      # 2016-03-23: What uses this? You, from the command line?
      artha

      thunderbird

      fabric
      # Know ye also there is a get-pip.py installer, too.
      python-pip
      python3-pip
      python3-sphinx

      curl

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
      libspatialite5

      unison

      # exFAT, MS format used on 32GB+ flash drives.
      exfat-fuse
      exfat-utils

      # ogrinfo et al
      gdal-bin
      gpx2shp

      chromium-browser

      # Symbola font for emojis.
      ttf-ancient-fonts
      # All the fonts.
      fonts-cantarell
      lmodern
      ttf-aenigma
      ttf-georgewilliams
      ttf-bitstream-vera
      ttf-sjfonts
      ttf-tuffy
      tv-fonts
      #ubuntustudio-font-meta

      streamripper

      # Ok, the distro version lags and has bugs. We will build later from source.
      #digikam
      digikam-doc
      # hrmmmm / 759 MB / for digikam
      kde-full
      cmake
      qt4-qmake
      qt5-qmake
      kde-workspace-dev
      kdevplatform-dev
      # Color mgmt.
      gnome-color-manager
      #dispcalgui

      # Time tracking applet.
      hamster-applet
      hamster-indicator

      # Maybe some day...
      zsh

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

    ) # end: BIG_PACKAGE_LIST

    # One core package, and maybe
    # One Giant MASSIVE package install.

    echo
    echo "Is this a dev machine? Do you want all the packages?"
    ask_yes_no_default 'N' 999999
    IS_DEV_MACHINE_ANSWER=$the_choice

    sudo apt-get install -y ${CORE_PACKAGE_LIST[@]}
    if [[ ${IS_DEV_MACHINE_ANSWER} == "Y" ]]; then
      sudo apt-get install -y ${BIG_PACKAGE_LIST[@]}
    fi

    if [[ ${IS_DEV_MACHINE_ANSWER} == "Y" ]]; then
      sudo apt-get install -y apt-file
      sudo apt-file update
    fi

    # Install additional MATE theme, like BlackMATE. We don't change themes,
    # but it's nice to be able to see what the other themes look like.

    if $WM_IS_MATE; then
      sudo apt-get install -y mate-themes
    fi


# FIXME: Fix /etc/default/grub here for host OS install.
#
#   #GRUB_HIDDEN_TIMEOUT=0
#   GRUB_HIDDEN_TIMEOUT=3
#   #GRUB_HIDDEN_TIMEOUT_QUIET=true
#   GRUB_HIDDEN_TIMEOUT_QUIET=false
#   #GRUB_TIMEOUT=10
#   GRUB_TIMEOUT=0
#
# See: cli_gk12.sh
#                sudo /bin/cp -a /etc/default/grub /etc/default/grub_$(date +%Y_%m_%d_%Hh%Mm%Ss)
#                sudo /bin/cp -af ${SCRIPT_DIR}/resources/dev-upstart.grub /etc/default/grub
#                #sudo grub-mkconfig
#                sudo update-grub


    # All done.

    if ${DO_STAGE_DANCE}; then
      echo "$((${stage_num} + 1))" > ${script_absbase}/fries-setup-stage.num
    fi

  fi # upgrade all packages and install extras that we need

} # end: setup_mint_17_stage_1

# ------------------------------------------
# STAGEs 2 through 4

# *** SECOND and SUBSEQUENT BOOTs

# 2016-03-23: The way things are called now, this isn't really necessary.
check_build_essential_installed () {
  if ${DO_STAGE_DANCE}; then
    if [[ ${stage_num} -gt 1 ]]; then
      set +ex
      dpkg -s build-essential &> /dev/null
      if [[ $? -ne 0 ]]; then
        echo
        echo "Unexpected: build-essential not installed. Try again."
        echo
      fi
      reset_errexit
      # Now that wmctrl is installed...
      determine_window_manager
    fi
  fi
} # end: check_build_essential_installed

# ------------------------------------------
# STAGE 2

# *** SECOND BOOT: Install Guest Additions

DO_EXTRA_UNNECESSARY_VBOX_STUFF=false

setup_mint_17_stage_2 () {

  if ! ${IN_VIRTUALBOX_VM}; then
    echo "ERROR: Skipping Stage 2: Not a VirtualBox."
  else
    set +ex
    # NOTE: This doesn't work for checking $? (the 2&> replaces it?)
    #        ll /opt/VBoxGuestAdditions* 2&> /dev/null
    ls -la /opt/VBoxGuestAdditions* &> /dev/null
    if [[ $? -eq 0 ]]; then
      echo
      echo "Unexpected: VBoxGuestAdditions already installed."
      echo
    fi
    reset_errexit

    echo 
    echo "Great, so this is your second reboot."
    echo
    echo "You've just upgraded and installed packages."
    echo
    echo "Now we're ready to install VirtualBox Guest Additions."
    echo
    echo "NOTE: The installer will bark at you about an existing version"
    echo "      of VBoxGuestAdditions software. Type 'yes' to continue."
    echo
    echo "I sure hope you're ready"'!'
    ask_yes_no_default 'Y' 999999

    if $WM_IS_CINNAMON || $WM_IS_MATE; then
      not_done=true
      while $not_done; do
        if [[ `ls /media/$USER | grep VBOXADDITIONS` ]]; then
          not_done=false
        else
          echo
          echo "PLEASE: From the VirtualBox menu bar, choose"
          echo "         Devices > Insert Guest Additions CD Image..."
          echo "        and hit Enter when you're ready."
          echo
          read -n 1 __ignored__
        fi
      done
      if [[ $the_choice != "Y" ]]; then
        echo "Nice! Catch ya later!!"
        exit 1
      fi
      cd /media/$USER/VBOXADDITIONS_*/
    elif $WM_IS_XFCE; then
      sudo /bin/mkdir /media/VBOXADDITIONS
      sudo mount -r /dev/cdrom /media/VBOXADDITIONS
      cd /media/VBOXADDITIONS
    fi

    # You'll see a warning and have to type 'yes': "You appear to have a
    # version of the VBoxGuestAdditions software on your system which was
    # installed from a different source or using a different type of
    # installer." Type 'yes' to continue.

    set +ex
    sudo sh ./VBoxLinuxAdditions.run
    echo "Run return code: $?"
    reset_errexit

    if ${DO_STAGE_DANCE}; then
      echo "$((${stage_num} + 1))" > ${script_absbase}/fries-setup-stage.num
    fi

    echo
    echo "All done! Are you ready to reboot?"
    echo "Hint: Shutdown instead if you want to remove the Guest Additions image"
    echo "      or just right-click the CD image on the desktop and Eject it"
    ask_yes_no_default 'Y' 999999

    if [[ $the_choice != "Y" ]]; then
      echo "Ohhhh... kay."
    else
      SETUP_DO_REBOOT=true
    fi

  fi

} # end: setup_mint_17_stage_2

# ------------------------------------------
# STAGE 3

# *** THIRD BOOT: Setup Bash and Home Scripts and User Groups

setup_mint_17_stage_3 () {

  if ${DO_STAGE_DANCE}; then
    echo
    echo "Wow, after two or three reboots, you've come back for more"'!'
  fi
  echo
  echo "Now we're ready to setup some groups and install Bash scripts."
  echo
  echo "NOTE: If we mess up your Bash scripts, it could break your"
  echo "account so that you cannot logon. So after this script runs,"
  echo "be sure to open a new terminal window to test that everything"
  echo "works before logging off."
  echo
  echo "Now, are you ready to let 'er rip?"
  # Six digits is max that works for seconds, and 0 is auto-answer,
  # -1 does nothing, so, yeah, MAYBE: ask_yes_no_default with a no-
  # timeout option. Or maybe just call `read` directly.
  ask_yes_no_default 'Y' 999999
  # Works, but the display is blank:
  #ask_yes_no_default 'Y' 99999999
  # Auto-answers 'Y':
  #ask_yes_no_default 'Y' 9999999999999999999999999999999

  if [[ $the_choice != "Y" ]]; then

    echo "Great! Peace, ya'll"'!!'
    exit 1

  else

    # Setup user group(s) and user-group associations.

    # In case any of these have been run before, let 'em fail.
    set +ex

    # Let the user access any mounted VBox drives.
    # 2016-03-23: The group is added by guest additions, and
    # the user manually added their user to the same group,
    # so this code should not do anything that's not already
    # done.
    if ${DO_EXTRA_UNNECESSARY_VBOX_STUFF}; then
      if ${IN_VIRTUALBOX_VM}; then
        sudo groupadd vboxsf
        sudo usermod -aG vboxsf $USER
      fi
    fi

    # Make the user a member of the staff group, or whatever it's called.

    # 20160323: This is currently just "staff".
    if [[ -n ${USE_STAFF_GROUP_ASSOCIATION} ]]; then
      sudo groupadd ${USE_STAFF_GROUP_ASSOCIATION}
      sudo usermod -a -G ${USE_STAFF_GROUP_ASSOCIATION} $USER
    fi

    # Always associate current user group with postgres and web server.

    # 2016-03-23: Currently not set.
    if ! `array_in "$USER" "${USE_PROJECT_USERGROUPS[@]}"`; then
      USE_PROJECT_USERGROUPS+=("$USER")
    fi

    # Usually,
    #  groupname=("$USER")
    for groupname in ${USE_PROJECT_USERGROUPS[@]}; do

      # CAVEAT: After adding a user to a group, `groups` won't show the new
      #         association until after a reboot... or probably until at
      #         least an X log-out/-backin. This script asks the user to
      #         reboot a few times, so we stick with the reboot approach.

      # Add the group. It's okay if you've already done it manually:
      # the command will just return $? == 9 and complain to stderr,
      # e.g., "groupadd: group '...' already exists".
      sudo groupadd ${groupname}

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

    done

    reset_errexit

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

    if [[ ${IS_DEV_MACHINE_ANSWER} == "Y" ]]; then
      sudo dpkg-reconfigure wireshark-common
      # Add the user to the new group.
      sudo usermod -a -G wireshark ${USER}
      # You need to logout or reboot to see changes.
      REBOOT_WILL_BE_NECESSARY=true
    fi

    # Try to mount the host drive.

    # Do this now because the user has to reboot before
    # their new access to the vboxsf group is realized.
    # 2016-03-23: Also no longer necessary and done otherways.
    if ${DO_EXTRA_UNNECESSARY_VBOX_STUFF}; then
      if [[ -n ${USE_MOUNTPT} ]]; then
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
      fi
    fi

    # Install Dubsacks VIM.
    #
    # 2016-03-23: This is usually done manually during first OS boot.
    source ${script_absbase}/vendor_dubsacks.sh

    # Finish this stage and logout/reboot.

    if ${DO_STAGE_DANCE}; then
      echo "$((${stage_num} + 1))" > ${script_absbase}/fries-setup-stage.num
    fi

    # Fix the VBox mount. After the reboot, the user will
    # have access to the auto-mount, so just symlink it.
    if [[ -n ${USE_MOUNTPT} ]]; then
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

    # 2016-03-23: What was this for? Home-fries is installed manually...
    #             hasn't it always? For one, this script is part of
    #             home.fries, and so are the bash scripts. Hrmm.
    #             Maybe delete this someday and clean up this whole script
    #             of old fluff that's all false-d-out.
    if false; then
      echo
      echo "NOTE: Open a new terminal window now and test the new bash scripts."
      echo
      echo "If you get a shell prompt, it means everything worked."
      echo
      echo "If you see any error messages, it means it kind of worked."
      echo
      echo "But if you do not get a prompt, you'll want to cancel this script."
      echo
      echo "Then, run:"
      echo
      echo "   /bin/rm ~/.bashrc"
      echo
      echo "Finally, open a new new terminal and make sure you get a prompt."
      echo
      echo -en "Were you able to open a new terminal window? (y/n) "
      read -n 1 the_choice
      if [[ $the_choice != "y" && $the_choice != "Y" ]]; then
        echo "Sorry about that! You'll have to take it from here..."
        exit 1
      else
        echo
        echo "Sweet!"
        echo "You'll have to logout or reboot to realize group changes."
        if ${DO_STAGE_DANCE}; then
          bluu=`tput setaf 4; tput smul;`
          rset=`tput sgr0`
          echo "Would you like to ${bluu}L${rset}ogout or ${bluu}R${rset}eboot?"
          ask_yes_no_default 'L' 999999 'R'
          if [[ $the_choice == "R" ]]; then
            SETUP_DO_REBOOT=true
          elif [[ $the_choice == "L" ]]; then
            SETUP_DO_LOGOUT=true
          else
            echo "But I was trying to be nice to you!"
            exit 1
          fi
        fi
      fi
    fi

  fi

} # end: setup_mint_17_stage_3

# ------------------------------------------
# STAGE 4

# *** FOURTH BOOT: Configure Window Manager and Compile and Install Apps.

setup_mint_17_stage_4 () {

  if ${DO_STAGE_DANCE}; then
    echo 
    echo "Swizzle, so you've rebooted a bunch already!"
  fi
  if false; then
    echo
    echo "This should be the last step."
    echo
    echo "We're going to configure your system, and we're"
    echo "going to download and compile lots of software."
    echo
    echo "NOTE: You might need to perform a few actions throughout."
    echo
    echo "Are we golden?"
    ask_yes_no_default 'Y' 999999
    if [[ $the_choice != "Y" ]]; then
      echo "Obviously not. Ya have a nice day, now."
      exit 1
    fi
  fi

  # *** Make a snapshot of the user's home directory, maybe.

  user_home_conf_dump "${script_absbase}/conf_dump/usr_04"

  # *** Tweak the Window Manager Configuration.

  # Disable passwords and require SSH keys.

  stage_4_sshd_configure

  # Configure /etc/hosts with the mock domain
  # and any project domain aliases.

  stage_4_etc_hosts_setup

  # Customize the distro and window manager.

  stage_4_wm_customize_mint

  # The new hot: MATE on Mint.
  if $WM_IS_MATE; then
    source ${script_absbase}/custom_mint17.mate.sh
  fi

  # Deprecated: Author prefers Mint to Xfce or Cinnamon.
  # Note: There once was a custom_mint16.xcfe.sh but not no more.
  if $WM_IS_CINNAMON; then
    source ${script_absbase}/custom_mint16.cinnamon.sh
  fi

  # Deprecated: Mint 17 login is different than Mint 16's (MDM).
  if $USE_MINT16_CUSTOM_LOGIN; then
    source ${script_absbase}/custom_mint16.retros_bg.sh
  fi

  # Setup git, mercurial, meld, postgres, apache, quicktile, pidgin,
  # adobe reader, dropbox, expect, rssowl, cloc, todo.txt, ti, utt, etc.
  if [[ ${IS_DEV_MACHINE_ANSWER} == "Y" ]]; then
    source ${script_absbase}/custom_mint17.extras.sh
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
  sudo updatedb

  # Remind the user about manual steps left to perform.

  echo
  echo "NEXT STEPS"
  echo "=========="
  echo
  echo "For help on installing useful browser plugins"
  echo "(like mouse gestures and HTTPS Everywhere),"
  echo "for advice on manually configuring MATE,"
  echo "for help on setting up Pidgin and relaying"
  echo "postix email through gmail, see:"
  echo
  echo " ${script_absbase}/A_General_Linux_Setup_Guide_For_Devs.rst"
  echo
  echo "Look for: Optional Setup Tasks"

  # All done.

  if ${DO_STAGE_DANCE}; then
    echo "$((${stage_num} + 1))" > ${script_absbase}/fries-setup-stage.num
  fi

} # end: setup_mint_17_stage_4

stage_4_sshd_configure () {

  # Setup sshd.

  # If you didn't apt-get install openssh-server, this file isn't there.

  # Turn off password auth, so users can only connect with SSH keys.
  # Otherwise, you'll see thousands of attacks on port 21 trying
  #   to get in your machinepants.
  # See: https://help.ubuntu.com/community/SSH/OpenSSH/Keys
  # This is also more convenient -- you won't be prompted for a password
  # whenever you try to log into this machine.

  if [[ -e /etc/ssh/sshd_config ]]; then

    sudo /bin/sed -i.bak \
      "s/^#PasswordAuthentication yes$/#PasswordAuthentication yes\nPasswordAuthentication no/" \
      /etc/ssh/sshd_config

    sudo service ssh restart

  fi

} # end: stage_4_sshd_configure

stage_4_etc_hosts_setup () {

  # 2016-03-23: /etc/hosts has 
  #                127.0.1.1	localhost
  #                127.0.1.1	${HOSTNAME}
  #             so we probably don't need to do anything.
  #
  #             On my main dev machine, I have a home domain:
  #                127.0.1.1	${HOSTNAME}.home.fries ${HOSTNAME}
  #
  # the target/ directory is nonstandard and probably not there.
  if [[ -e ${script_absbase}/target/common/etc/hosts ]]; then
    # Fake the local domain, and maybe setup cyclopath,
    # mediawiki, bugzilla, or any other project-specific
    # mappings defined in the /etc/hosts template.
    m4 \
      --define=HOSTNAME=$HOSTNAME \
      --define=MACH_DOMAIN=$USE_DOMAIN \
        ${script_absbase}/target/common/etc/hosts \
        | sudo tee /etc/hosts &> /dev/null
  fi

} # end: stage_4_etc_hosts_setup

stage_4_wm_customize_mint () {

  # From the Mint Menu in the lower-left, remove the text and change the
  # icon (to a playing die with five pips showing).

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

  if [[ -e $USE_MINT_MENU_ICON ]]; then
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
  # ('<Super_L'), but I fat-finger it sometimes so add the shift key.
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

} # end: stage_4_wm_customize_mint

# ==============================================================
# Application Main()

# *** Call this fcn. from a wrapper script.
#     Or source this script and run it yourself.

setup_mint_17_go () {

  SETUP_DO_REBOOT=false
  SETUP_DO_LOGOUT=false

  if [[ !${DO_EXTRA_UNNECESSARY_VBOX_STUFF} || ${stage_num} -eq 1 ]]; then
    # Call `sudo apt-get install -y [lots of packages]`.
#    setup_mint_17_stage_1
:
  fi

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
  IN_VIRTUALBOX_VM=false
  sudo virt-what | grep 'virtualbox' &> /dev/null
  if [[ $? -eq 0 ]]; then
    IN_VIRTUALBOX_VM=true
  fi

  # Now that wmctrl is installed...
  # Set WM_IS_MATE, etc.
  determine_window_manager

  if ! ${IN_VIRTUALBOX_VM}; then
    # 2016.01.14: [lb] installed Linux Mint 17.3 MATE on a laptop and did
    # not reboot or relogon between install steps, so we'll scream through
    # each step one after another.
    # SKIPPING: Stage 2, which install VBox additions.
    # Setup usergroups and the user's home directory.
    setup_mint_17_stage_3
    # Download, compile, and configure lots of software.
    setup_mint_17_stage_4
  else
    # 2016.03.23: It's best if the user just installs guest additions manually
    # right after installing an OS, before running this script, so not calling
    #    setup_mint_17_stage_2
    #  See: ubuntu_mate_15.10.rst for easy instructions.
    if ${DO_EXTRA_UNNECESSARY_VBOX_STUFF}; then
      setup_mint_17_stage_2
    fi
    # Setup usergroups and the user's home directory.
    setup_mint_17_stage_3
    # Download, compile, and configure lots of software.
    setup_mint_17_stage_4

    # 2016-03-23: I'm guessing all the DO_STAGE_DANCE is deletable.
    # Reboot if we have more setup to go.
    if ${DO_STAGE_DANCE}; then
      if $SETUP_DO_REBOOT; then
        echo
        echo "$((${stage_num} + 1))" > ${script_absbase}/fries-setup-stage.num
        echo "NOTICE: Rebooting before running next step."
        echo "Run this script again after rebooting."
        sudo /sbin/shutdown -r now
      elif $SETUP_DO_LOGOUT; then
        echo
        echo "NOTICE: Logging out before running next step."
        echo "Run this script again after logging back on."
        # The logout commands vary according to distro, so check what's there.
        # Bash has three built-its that'll tell is if a command exists on
        # $PATH. The simplest, ``command``, doesn't print anything but returns
        # 1 if the command is not found, while the other three print a not-found
        # message and return one. The other two commands are ``type`` and ``hash``.
        # All commands return 0 is the command was found.
        #  $ command -v foo >/dev/null 2>&1 || { echo >&2 "Not found."; exit 1; }
        #  $ type foo       >/dev/null 2>&1 || { echo >&2 "Not found."; exit 1; }
        #  $ hash foo       2>/dev/null     || { echo >&2 "Not found."; exit 1; }
        # Thanks to http://stackoverflow.com/questions/592620/
        #             how-to-check-if-a-program-exists-from-a-bash-script
        if ``command -v mate-session-save >/dev/null 2>&1``; then
          mate-session-save --logout
        elif ``command -v gnome-session-save >/dev/null 2>&1``; then
          gnome-session-save --logout
        else
          # This is the most destructive way to logout, so don't do it:
          #   Kill everything but kill and init using the special -1 PID.
          #   And don't run this as root or you'll be sorry (like, you'll
          #   kill kill and init, I suppose). This will cause a logout.
          #   http://aarklonlinuxinfo.blogspot.com/2008/07/kill-9-1.html
          #     kill -9 -1
          # Apparently also this, but less destructive
          #     sudo pkill -u $USER
          echo
          echo "WARNING: Logout command not found; cannot logout."
          echo "FIXME: Hey, dev, please update the install script."
          exit 1
        fi
      fi
    else
      #echo
      #echo "VirtualBox OS setup is complete!"
      :
    fi
  fi

  print_install_time

  # C'est ca!
  echo
  echo "All done!"

  if ${REBOOT_WILL_BE_NECESSARY}; then
    echo
    echo "One or more operations require a reboot before working (e.g., Wireshark)."
  fi

} # end: setup_mint_17_go

# Only run when not being sourced.
if [[ "$0" == "$BASH_SOURCE" ]]; then
  # If you want to override any options but not checkin the changes to the
  # repository (e.g., add passwords to this script) use a wrapper script.
  # See: setup-exc-mint17-custom.sh.template
  if [[ ! -v SETUP_WRAPPERED ]]; then
    echo
    echo "Not being called by wrapper script: installing using default options."
    setup_mint_17_go
  fi
fi

# ==================================================================
# Copy-n-paste Convenience! Some commands to run on Very Fresh Mint.

# The basics: you might want to run this quick after first installing:
__just_the_basics__ () {
  gsettings set org.mate.caja.desktop computer-icon-visible false
  gsettings set org.mate.caja.desktop home-icon-visible false
  gsettings set org.mate.caja.desktop volumes-visible false
  gsettings set org.mate.screensaver idle-activation-enabled false
  gsettings set org.mate.screensaver lock-enabled false
  #
  # Gestures for Mozilla Firefox
  #* https://addons.mozilla.org/en-US/firefox/addon/firegestures/
  # CrxMouse for Google Chrome
  #* https://chrome.google.com/webstore/detail/crxmouse/jlgkpaicikihijadgifklkbpdajbkhjo

  # HTTPS Everywhere
  # https://www.eff.org/files/https-everywhere-latest.xpi
  # Chrome: https://www.eff.org/https-everywhere
  #
  # Customize (Keyboard) Shortcuts for Firefox
  # https://addons.mozilla.org/en-US/firefox/addon/customizable-shortcuts/
  #  --> then you can remap Ctrl-Shift-C, which brings up the
  #      Firefox Developer Tools Inspector, but I usually type
  #      it by accident because that's how you copy selected text
  #      from the terminal (since Ctrl-C sends sigterm).
  #      I changed Inspector shortcut from Ctrl+Shift+C to Ctrl+Shift+D.
  #      And I changed Console from Ctrl+Shiht+K to Ctrl+Shiht+X
  #        (obscuring Text Switch Directions, which is... weird for Latin).

  if false; then
    # Linux Mint 17 Adode Flash update:
    sudo add-apt-repository "deb http://archive.canonical.com/ rebecca partner"
    sudo apt-get update
    sudo apt-get install -y flashplugin-installer
  fi

  if true; then
    # Linux Mint 17.1 Adode Flash update.
    sudo add-apt-repository "deb http://archive.canonical.com/ rebecca partner"
    sudo apt-get update
    sudo apt-get install -y adobe-flashplugin
  fi
}

__just_a_test__ () {
  echo "Just a test!"
}
#__just_a_test__

# Vim modeline:
# vim:tw=0:ts=2:sw=2:et:norl:

