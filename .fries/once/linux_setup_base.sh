#!/bin/bash

# File: linux_setup_base.sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Last Modified: 2016.11.03
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

# This script is sourced by the setup scripts to provide common settings.

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

# DEVs: Customize these options, maybe. See: custom_setup.template.sh

# The real or fake machine domain (e.g., "fake_domain.tld" works,
# it'll just mask anything of the real name out there in the net).
# Note: In the m4 templates, USE_DOMAIN is MACH_DOMAIN.
#USE_DOMAIN="localhost"
# FIXME: Prompt for the domain if not specified in config wrapper?
#        Or can we just use hostname's response?
#        What is hostname's response on a fresh install?
USE_DOMAIN=$(hostname --domain)
if [[ -z ${USE_DOMAIN+x} ]]; then
  USE_DOMAIN="home.fries"
fi

# If you're dual-booted or if you've configured a VirtualBox Shared Folder,
# you can set the device name here and the script will mount it for you.
# E.g., for VirtualBox,
#  USE_MOUNTPT="C_DRIVE"
#  DST_MOUNTPT="/win"
# or for a dual-boot,
#  USE_MOUNTPT="/dev/sda2"
#  DST_MOUNTPT="/fsm"
# Otherwise, just leave it blank.
USE_MOUNTPT=""
DST_MOUNTPT=""

# A few common project group name config options.

# Specify groups to create. The current user will be added to
# these groups, as will postgres and the www-data/apache user.
# This is so you can setup a shared development environment.
# DEVs: Add to this array in custom_linux.sh. Each group is
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
OPT_SRC=/srv/opt/src

# -- Mate with MATE (If you're gonna be here 60 hours each week, redecoRATE)

# The default Mint "start menu" icon is rather drab, so give it some pazazz.
# [lb] likes the dice icon that's included with Ubuntu. Poke around
# the /usr/share/icons/ files and find something you like or add you own.
if [[ -z ${USE_MINT_MENU_ICON+x} ]]; then
  USE_MINT_MENU_ICON="${script_absbase}/assets/applications-boardgames-21x21.png"
fi

# -- Mercurial setup.

if [[ -z ${USE_SETUP_HG+x} ]]; then
  #USE_SETUP_HG=true
  USE_SETUP_HG=false
fi
if $USE_SETUP_HG; then
  HG_USER_NAME="Your Name"
  HG_USER_EMAIL="Your Email"
  HG_DEFAULT_PATH="ssh://hg@bitbucket.org/your_username/your_project"
fi

# -- Install proprietary software (namely, just Adobe Reader).

# One may not distribute Adobe Reader on a virtual machine image
# per its EULA, so disable this is if you must, or if you're simply
# satisified with evince, or if you don't trust Adobe, or if you don't
# like not free as in not free beer software.
if [[ -z ${INCLUDE_ADOBE_READER+x} ]]; then
  INCLUDE_ADOBE_READER=true
  #INCLUDE_ADOBE_READER=false
fi

# -- MySQL, if you want. I needed it for Mediawiki or Redmine but run neither no more.

if [[ -z ${DO_INSTALL_MYSQL+x} ]]; then
  DO_INSTALL_MYSQL=false
fi

# -- Whether or not to install Dubsacks VIM.

if [[ -z ${DO_INSTALL_DUBSACKS+x} ]]; then
  DO_INSTALL_DUBSACKS=true
fi

# *** END: Configure these values for your environment.
########################################################

