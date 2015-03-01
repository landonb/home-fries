#!/bin/bash

# File: setup_mint17.sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Last Modified: 2015.02.26
# Project Page: https://github.com/landonb/home_fries
# Summary: Linux Mint MATE Automated Developer Environment Setterupper.
# License: GPLv3
# -------------------------------------------------------------------
# Copyright © 2011-2015 Landon Bouma.
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

# FIXME: 2015.01.26: I mucked with the script (created all
#                    the subscripts) and need to test it.
echo "FIXME: Test this script thoroughly. It's been very much changed."
exit 1

# ------------------------------------------
# Velcome

echo
echo "Too Many Steps Setup Script"
echo
echo "- For Linux Mint 17.1 and MATE"
echo "- Configures Mint and MATE to a Particular Liking"
echo "- You already Installed Handy Bash Scripts with This Script, and"
echo "   This Script Installs Handy Vim Scripts"
echo "- Installs a Bunch of Applications and Tools"
echo

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

# DEVs: Customize these options, maybe. See: custom_mint17.template.sh

# The real or fake machine domain (e.g., "fake_domain.tld" works,
# it'll just mask anything of the real name out there in the net).
# Note: In the m4 templates, USE_DOMAIN is MACH_DOMAIN.
#USE_DOMAIN="localhost"
USE_DOMAIN="home.fries"

# If you're dual-booted or if you've configured a VirtualBox Shared Folder,
# you can set the device name here and the script will mount it for you.
# E.g., for VirtualBox,
#  USE_MOUNTPT="C_DRIVE"
# or for a dual-boot,
#  USE_MOUNTPT="/dev/sda2"
# Otherwise, just leave it blank.
USE_MOUNTPT=""

# A few common project group name config options.

# Specify groups to create. The current user will be added to
# these groups, as will postgres and the www-data/apache user.
# This is so you can setup a shared development environment.
# DEVs: Add to this array in custom_mint17.sh. Each group is
# generally the name of a different project that uses different
# resources that you want postgres and apache to be able to access,
# per the specifics of whatever projects on which you're working.
# I.e., you want to make htdocs files group-readable, and not
# necessarily world-readable, and you want distinct linux users
# to all be part of the same development group. This is generally
# only necessary in a shared work environment and not on a personal
# development machine.
USE_PROJECT_USERGROUPS=()

# Some projects also have their own postgres users.
# MAYBE: Move USE_PROJECT_PSQLGROUPS and USE_PROJECT_USERGROUPS
#        to project-specific setup scripts.
# This setting is probably useful even on a personal development
# machine, as many projects hard-code the name of or use a common
# convention to name the postgres user used to connect to the db.
USE_PROJECT_PSQLGROUPS=()

# An old Cyclopath hack: Change postgres and apache config file
# group ownership so anyone in the Cyclopath group can edit any
# machine's services' config.
# Note: On the U of MN's CP network, you'd want to use the group's
# group name, e.g., `grplens`, but on your own dev machine, using
# the `staff` built-in is just fine, and it makes sense to use.
USE_STAFF_GROUP_ASSOCIATION="staff"

# -- Local resources, downloaded. Where they go.

# We could download tarballs and whatnots to ~/Downloads but so many
# applications use the home directory anyway, it's easier to keep
# track of our files (what we'll deliberately setup) by using our own
# location to store downloaded files and their compiled offsprings.
OPT_BIN=/srv/opt/bin
OPT_DLOADS=/srv/opt/.downloads

# -- Mate with MATE (If you're gonna be here 60 hours each week, redecoRATE)

# The default Mint "start menu" icon is rather drab, so give it some pazazz.
# [lb] likes the dice icon that's included with Ubuntu. Poke around
# the /usr/share/icons/ files and find something you like or add you own.
USE_MINT_MENU_ICON="${script_absbase}/assets/applications-boardgames-21x21.png"

# -- Mercurial setup.

#USE_SETUP_HG=true
USE_SETUP_HG=false
HG_USER_NAME="Your Name"
HG_USER_EMAIL="Your Email"
HG_DEFAULT_PATH="ssh://hg@bitbucket.org/your_username/your_project"

# -- Install proprietary software (namely, just Adobe Reader).

# One may not distribute Adobe Reader on a virtual machine image
# per its EULA, so disable this is if you must, or if you're simply
# satisified with evince, or if you don't trust Adobe, or if you don't
# like not free as in not free beer software.
INCLUDE_ADOBE_READER=true
#INCLUDE_ADOBE_READER=false

# -- Whether or not to install Dubsacks VIM.

DO_INSTALL_DUBSACKS=true

# *** END: Configure these values for your environment.
########################################################

# ------------------------------------------
# Figure out what stage we're on.

# MAGIC_NUMBER: There are four stages (and logouts/reboots between each).
stages_count=4
if [[ ! -e ${script_absbase}/setup-exc-stage_num ]]; then
  # First time here.
  stage_num=1
  echo "${stage_num}" > ${script_absbase}/setup-exc-stage_num
else
  stage_num=`cat setup-exc-stage_num`
  # Validate the stage number.
  if [[ ${stage_num} -lt 1 || ${stage_num} -gt ${stages_count} ]]; then
    echo "Unexpected stage_num: ${stage_num}"
    exit 1
  fi
fi

echo "On stage number ${stage_num} of ${stages_count}"

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
  echo "Install started at: $setup_time_0"
  echo "Install finishd at: $setup_time_n"
  time_elapsed=$(echo "$setup_time_n - $setup_time_0" | bc -l)
  echo "Elapsed: $time_elapsed secs."
  echo
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

  set | grep \
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

echo
echo "Here's how the script is configured:"
echo
setup_ready_print_env
echo

# ------------------------------------------
# STAGE 1

# *** FIRST/FRESH BOOT: Upgrade and Install Packages

setup_mint_17_stage_1 () {

  echo 
  echo "Welcome to the installer!"
  echo
  echo "We're going to install lots of packages and then reboot."
  echo
  echo "NOTE: The Mysql installer will ask you for a new password."
  echo
  echo "Let's get moving, shall we?"
  ask_yes_no_default 'Y'

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
      # sudo echo "" >> to a write-protected file, since
      # the append command happens outside the sudo.
      echo "
# Added by ${0} at `date +%Y.%m.%d-%T`.
Defaults tty_tickets
Defaults:$USER timestamp_timeout=-1
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

    # NOTE: The Mysql package wants you to enter a password.
    #       [lb] figured all package installers are not interactive,
    #       but I guess there are some exceptions. Or maybe there's
    #       an apt-get switch I'm missing.
    #
    # FIXME: You could use `expect` here to send the pwd to the terminal.
    #
    if [[ ! -e ${script_absbase}/setup-exc-mysql_pwd ]]; then
      MYSQL_PASSWORD=$(pwgen -n 16 -s -N 1 -y)
      echo "${MYSQL_PASSWORD}" > ${script_absbase}/setup-exc-mysql_pwd
    else
      MYSQL_PASSWORD=`cat ${script_absbase}/setup-exc-mysql_pwd`
    fi
    echo
    echo "*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!"
    echo "Try this for a Mysql password: ${MYSQL_PASSWORD}"
    echo "*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!*!"
    echo "Which is saved also to the file: setup-exc-mysql_pwd"
    echo
    sudo apt-get -y install \
      \
      mysql-server

    # -- Install postfix (also interactive).

    # FIXME: Which package does this? It's another interactive installer.
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

    local BIG_PACKAGE_LIST=(

      # Kernel goodies.
      dkms
      build-essential

      # CLI OS and Window Manager customizers.
      dconf-cli
      gconf-editor
      wmctrl
      xdotool

      # Dubsacks Vim.
      vim-gtk
      # Text columnizer.
      par
      # Ctags.
      exuberant-ctags
      # Ruby dev tools for Command-T.
      ruby-dev

      # Awesomest graphical diff.
      meld
      # Excellent diagramming.
      dia
      # Pencil Project is a prototyping tool that
      # also support dia-ish diagram drawing.
      #  http://pencil.evolus.vn
      # But wait! The pencil package in Ubuntu is a different app.
      #  No: pencil
      #  See: stage_4_pencil_install
      # Eye of Gnome, a slideshow image viewer.
      eog
      # Hexadecimal file viewer.
      ghex
      # `most` is pretty lame; author prefers `less`.
      most

      # The better grepper.
      silversearcher-ag

      # All your repositories are belong to too many managers.
      git
      git-core
      subversion
      mercurial

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
      # FIXME: There are more python modules, like levenshtein,
      #        that should be installed via virtualenv, too.
      # For tox, install multiple Python versions.
      #python2.6
      #python3.2
      #python3.3
      # See pip (so we can install current version):
      #  cookiecutter



# FIXME: Can I just pip these in requirements.txt?
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

      logcheck
      logcheck-database

      logtail

      socket

      libpam0g-dev

      openssh-server

      gnupg2
      signing-party
      pwgen

      thunderbird

      # One would think whois would be standard.
      whois
      # nslookup is... stale, to be polite. Use dig instead.
      

      apt-file

      python-nltk
      python-matplotlib
      python-tk

      artha

      fabric
      python-pip
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

      # Meh. Keepassx is convenient for people who like GUIs, but I
      # think gpg or encfs is just as easy for someone comfy on the CLI.
      #keepassx
      encfs
      # I thought scrub was a default program, too; guess not.
      # Also, if you're doing it right, you won't need scrub:
      #   on disk, your data should *always* be encrypted;
      #   it's only in memory or on screen that data should be
      #   plain.
      scrub

    )

    # One Giant MASSIVE package install.

    sudo apt-get install -y ${BIG_PACKAGE_LIST[@]}

    # Install additional MATE theme, like BlackMATE. We don't change themes,
    # but it's nice to be able to see what the other themes look like.

    if $WM_IS_MATE; then
      sudo apt-get install -y mate-themes
    fi

    # All done.

    echo "$((${stage_num} + 1))" > ${script_absbase}/setup-exc-stage_num

    print_install_time

    # *** The user has to reboot before continuing.

    echo
    echo "All done! Are you ready to reboot?"
    ask_yes_no_default 'Y' 20

    if [[ $the_choice != "Y" ]]; then
      echo "Fine, be that way."
    else
      SETUP_DO_REBOOT=true
    fi

  fi # upgrade all packages and install extras that we need

} # end: setup_mint_17_stage_1

# ------------------------------------------
# STAGEs 2 through 4

# *** SECOND and SUBSEQUENT BOOTs

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

# ------------------------------------------
# STAGE 2

# *** SECOND BOOT: Install Guest Additions

setup_mint_17_stage_2 () {

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
  ask_yes_no_default 'Y'

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

  echo "$((${stage_num} + 1))" > ${script_absbase}/setup-exc-stage_num

  print_install_time

  echo
  echo "All done! Are you ready to reboot?"
  echo "Hint: Shutdown instead if you want to remove the Guest Additions image"
  echo "      or just right-click the CD image on the desktop and Eject it"
  ask_yes_no_default 'Y' 20

  if [[ $the_choice != "Y" ]]; then
    echo "Ohhhh... kay."
  else
    SETUP_DO_REBOOT=true
  fi

} # end: setup_mint_17_stage_2

# ------------------------------------------
# STAGE 3

# *** THIRD BOOT: Setup Bash and Home Scripts and User Groups

setup_mint_17_stage_3 () {

  echo
  echo "Wow, after two or three reboots, you've come back for more"'!'
  echo
  echo "Now we're ready to setup some groups and install Bash scripts."
  echo
  echo "NOTE: If we mess up your Bash scripts, it could break your"
  echo "account so that you cannot logon. So after this script runs,"
  echo "be sure to open a new terminal window to test that everything"
  echo "works before logging off."
  echo
  echo "Now, are you ready to let 'er rip?"
  ask_yes_no_default 'Y'

  if [[ $the_choice != "Y" ]]; then

    echo "Great! Peace, ya'll"'!!'
    exit 1

  else

    # Setup user group(s) and user-group associations.

    # In case any of these have been run before, let 'em fail.
    set +ex

    # Let the user access any mounted VBox drives.
    if [[ `sudo virt-what` == 'virtualbox' ]]; then
      sudo usermod -aG vboxsf $USER
    fi

    # Make the user a member of the staff group, or whatever it's called.

    if [[ -n ${USE_STAFF_GROUP_ASSOCIATION} ]]; then
      sudo groupadd ${USE_STAFF_GROUP_ASSOCIATION}
      sudo usermod -a -G ${USE_STAFF_GROUP_ASSOCIATION} $USER
    fi

    # Always associate current user group with postgres and web server.

    if ! `elem_in_arr "$USER" "${USE_PROJECT_USERGROUPS[@]}"`; then
      USE_PROJECT_USERGROUPS+=("$USER")
    fi

    for groupname in ${USE_PROJECT_USERGROUPS[@]}; do

      # CAVEAT: After adding a user to a group, `groups` won't show the new
      #         association until after a reboot... or probably until at
      #         least an X log-out/-backin. This script asks the user to
      #         reboot a few times, so we stick with the reboot approach.

      # Add the group. It's okay if you've already done it manually:
      # the command will just return $? == 9 and complain to stderr,
      # e.g., "groupadd: group '...' already exists".
      sudo groupadd $groupname

      # Add the active user to the group.
      sudo usermod -a -G $groupname $USER

      # Make postgres a member so its easier to read its logs.
      # E.g., in Cyclopath, the logs are writ to /ccp/var/log/postgresql
      # (which, on the production server, is mapped to different drive
      # that where most of the Linux OS resides).
      sudo usermod -a -G $groupname postgres

      # Also make apache a member of the group for similar reasons.
      # E.g., in Cyclopath, www-data logs to /ccp/var/log/apache2.
      #
      # FIXME: Is this a security issue if we make www-data part of
      #        this group? If someone compromised www-data they could
      #        conceivably access all group files, and not just
      #        what's under htdocs/, right? Hmmm.
      sudo usermod -a -G $groupname ${httpd_user}

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

    sudo dpkg-reconfigure wireshark-common
    # Add the user to the new group.
    sudo usermod -a -G wireshark $USER
    # You need to logout or reboot to see changes.

    # Try to mount the host drive.

    # Do this now because the user has to reboot before
    # their new access to the vboxsf group is realized.
    if [[ -n $USE_MOUNTPT ]]; then
      sudo /bin/mkdir -p /win
      sudo chmod 2775 /win
      if [[ `sudo virt-what` == '' ]]; then
        sudo mount -t ntfs $USE_MOUNTPT /win
      elif [[ `sudo virt-what` == 'virtualbox' ]]; then
        sudo mount -t vboxsf $USE_MOUNTPT /win
      else
        echo "WARNING: Unknown Virtual machine type; cannot mount /win."
        exit 1
      fi
      if [[ $? -ne 0 ]]; then
        echo "WARNING: Could not mount host drive using the command:"
        echo "         sudo mount -t vboxsf $USE_MOUNTPT /win"
        exit 1
      fi
    fi

    # Install Dubsacks VIM.

    source ${script_absbase}/vendor_dubsacks.sh

    # Finish this stage and logout/reboot.

    echo "$((${stage_num} + 1))" > ${script_absbase}/setup-exc-stage_num

    print_install_time

    # Fix the VBox mount. After the reboot, the user will
    # have access to the auto-mount, so just symlink it.
    if [[ -n $USE_MOUNTPT ]]; then
      if [[ `sudo virt-what` == '' ]]; then
        #
        # FIXME: Append to /etc/fstab.
        #        See code in Excensus_Developer_Setup_Guide.rst.
        :
      elif [[ `sudo virt-what` == 'virtualbox' ]]; then
        sudo umount $USE_MOUNTPT
        sudo /bin/rmdir /win
        sudo /bin/ln -s /media/sf_$USE_MOUNTPT /win
      fi
    fi

    echo
    echo "NOTE: Open a new terminal window now and test the new bash scripts."
    echo
    echo "If you get a shell prompt, it means everything worked."
    echo
    echo "If you see any error messages, it means it kind of worked."
    echo
    echo "But if you do not get a prompt, you'll want to cancel this script."
    echo "Then, run: /bin/rm ~/.bashrc*"
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
      bluu=`tput setaf 4; tput smul;`
      rset=`tput sgr0`
      echo "Would you like to ${bluu}L${rset}ogout or ${bluu}R${rset}eboot?"
      ask_yes_no_default 'L' 13 'R'
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

} # end: setup_mint_17_stage_3

# ------------------------------------------
# STAGE 4

# *** FOURTH BOOT: Configure Window Manager and Compile and Install Apps.

setup_mint_17_stage_4 () {

  echo 
  echo "Swizzle, so you've rebooted a bunch already!"
  echo
  echo "This should be the last step."
  echo
  echo "We're going to configure your system, and we're"
  echo "going to download and compile lots of software."
  echo
  echo "NOTE: You might need to perform a few actions throughout."
  echo
  echo "Are we golden?"
  ask_yes_no_default 'Y'

  if [[ $the_choice != "Y" ]]; then

    echo "Obviously not. Ya have a nice day, now."
    exit 1

  else

    # *** Make a snapshot of the user's home directory.

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

    source ${script_absbase}/custom_mint17.extras.sh

    # Install "vendor" add-ons, or your personal projects.

    for f in $(find ${script_absbase} \
                      -maxdepth 1 \
                      -type f \
                      -name "vendor_*.sh"); do
      source ${script_absbase}
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
    echo " file://${script_absbase}/Generic_Linux_Dev_Setup_Guide.rst#Optional_Setup_Tasks"
    echo

    # All done.

    echo "$((${stage_num} + 1))" > ${script_absbase}/setup-exc-stage_num

    print_install_time

    echo
    echo "Thanks for installing!"
    echo

    exit 0

  fi

} # end: setup_mint_17_stage_4

stage_4_sshd_configure () {

  # Setup sshd.

  # Turn off password auth, so users can only connect with SSH keys.
  # Otherwise, you'll see thousands of attacks on port 21 trying
  #   to get in your machinepants.
  # See: https://help.ubuntu.com/community/SSH/OpenSSH/Keys
  # This is also more convenient -- you won't be prompted for a password
  # whenever you try to log into this machine.

  sudo /bin/sed -i.bak \
    "s/^#PasswordAuthentication yes$/#PasswordAuthentication yes\nPasswordAuthentication no/" \
    /etc/ssh/sshd_config

  sudo service ssh restart

} # end: stage_4_sshd_configure

stage_4_etc_hosts_setup () {

  # Fake the local domain, and maybe setup cyclopath,
  # mediawiki, bugzilla, or any other project-specific
  # mappings defined in the /etc/hosts template.

  m4 \
    --define=HOSTNAME=$HOSTNAME \
    --define=MACH_DOMAIN=$USE_DOMAIN \
      ${script_absbase}/target/common/etc/hosts \
      | sudo tee /etc/hosts &> /dev/null

} # end: stage_4_etc_hosts_setup

stage_4_wm_customize_mint () {

  # From the Mint Menu in the lower-left, remove the text and change the
  # icon (to a playing die with five pips showing).
  if [[ -e $USE_MINT_MENU_ICON ]]; then
    USER_BGS=/home/${USER}/Pictures/.backgrounds
    /bin/mkdir -p ${USER_BGS}
    /bin/cp \
      ${USE_MINT_MENU_ICON} \
      ${USER_BGS}/mint_menu_custom.png
    gsettings set com.linuxmint.mintmenu applet-icon \
      "${USER_BGS}/mint_menu_custom.png"
  fi
  # The default applet-icon-size is 22.
  gsettings set com.linuxmint.mintmenu applet-icon-size 22
  # The default applet-text is 'Menu'.
  gsettings set com.linuxmint.mintmenu applet-text ''

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
  gsettings set com.linuxmint.mintmenu hot-key '<Super>Shift_L'

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

  # There are a number of ways to check if we're running in a virtual machine.
  # You could check PCI and USB devices for their names, or dmesg, e.g.,
  #   lspci | grep VirtualBox
  #   lsusb | grep VirtualBox
  #   dmesg | grep VirtualBox
  # but those are, well, hacks.
  # The better way is to use a specific utility, like virt-what or imvert.
  if [[ ${stage_num} -eq 2 && `sudo virt-what` != 'virtualbox' ]]; then
    echo "Skipping Stage 2: Not a VirtualBox."
    stage_num=3
  fi

  if [[ ${stage_num} -eq 1 ]]; then
    # Call `sudo apt-get install -y [lots of packages]`.
    setup_mint_17_stage_1
  elif [[ ${stage_num} -eq 2 ]]; then
    # Install VBox additions.
    setup_mint_17_stage_2
  elif [[ ${stage_num} -eq 3 ]]; then
    # Setup usergroups and the user's home directory.
    setup_mint_17_stage_3
  elif [[ ${stage_num} -eq 4 ]]; then
    # Download, compile, and configure lots of software.
    setup_mint_17_stage_4
  else
    echo
    echo "Unexpected stage_num: ${stage_num}"
    echo
    exit 1
  fi

  # Reboot if we have more setup to go.
  if $SETUP_DO_REBOOT; then
    echo "$((${stage_num} + 1))" > ${script_absbase}/setup-exc-stage_num
    sudo /sbin/shutdown -r now
  elif $SETUP_DO_LOGOUT; then
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

} # end: setup_mint_17_go

# If you want to override any options but not checkin the changes to the
# repository (e.g., add passwords to this script) use a wrapper script.
# See: setup-exc-mint17-custom.sh.template
if [[ ! -v SETUP_WRAPPERED ]]; then
  echo
  echo "Not being called by wrapper script: installing using default options."
  echo
  setup_mint_17_go
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
  if false; then
    # Linux Mint 17.1 Adode Flash update:
    # FIXME: Is this repository still right?:
    #  sudo add-apt-repository "deb http://archive.canonical.com/ rebecca partner"
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

