# File: bashrc.cyclopath.loc.home.sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Last Modified: 2016.12.11
# Project Page: https://github.com/landonb/home_fries
# Summary: Cyclopath bash startup script for remote, non-CS machines.
# License: GPLv3

# This script is loaded by bashrc.cyclopath.base.sh.

# In a chroot, [lb] sees "hostname: Name or service not known"
#  MACHINE_DOMAIN=`hostname --domain`
# so use the domainname command instead.
if [[ $(domainname) != "(none)" ]]; then
  MACHINE_DOMAIN=$(domainname)
fi
if [[ -z "$MACHINE_DOMAIN" ]]; then
   return
fi
if [[ "${MACHINE_DOMAIN}" != "${CS_HOSTDOMAIN}" ]]; then
  # == Running on local/home machine ==
  return
fi

# == Running on remote/work machine. ==

# Initialize the terminal prompt and terminal titlebar name.
# 2016-12-11: Disabled: dubs_set_terminal_prompt.
#dubs_set_terminal_prompt `hostname`

# GroupLens scripts.
# CcpV1:
#   path_add_part "/project/Grouplens/bin"
#   path_add_part "/export/scratch/ccp/opt/usr/bin"
# But in CcpV2 we've moved the scripts to ccpdev (so we can release them).
# NOTE: /ccp/opt/usr/bin is currently only GraphServer executables.
path_add_part "/ccp/bin/ccpdev/bin"
path_add_part "/export/scratch/ccp/opt/usr/bin"

# Source the TCL bash script; not sure what for;
# The default bash script from CS does this....
if [[ -f "/soft/rko-modules/tcl/init/bash" ]]; then
   # 2013.06.14: You need this for the `module` command to work.
  . /soft/rko-modules/tcl/init/bash
fi

# Activate addt'l software
# NOTE whereis module? I can't find it!
#if type -P module &>/dev/null; then
if `module --version &>/dev/null`; then
  # Base CS loads
  module load soft/gcc java perl gnu local compilers system x11
  # 2012.05.16: What is Frame and why all of a sudden am I getting 
  #      +(0):ERROR:0: Unable to locate a modulefile for 'Frame' ?
  #module load openwin modules Frame math/mathematica scheme user
  module load openwin modules math/mathematica scheme user
  # 2012.10.16:
  #   *****  The soft/gimp/v.2.0.4 module is out of date ******
  #   This module will be going away. Update your .cshrc and remove it
  #module load mozilla soft/openoffice soft/gimp
  # 2013.01.07: "The soft/openoffice/3.0.1 module is out of date"
  # "This module will be going away. Please remove it from your .cshrc"
  # FIXME: Is there another module to load?
  # module load soft/openoffice
  # 2013.11.09: "The mozilla/firefox/2.0.0.11 module is outdated and
  #              will be going away"
  #module load mozilla
  # Same error for mozilla/firefox/3.5.5, etc., too. Weird.
  #
  # Cyclopath SVN client
  # NOTE: You'll get the error, "Expected FS format '2', found format '3'."
  #       if this doesn't run for noninteractive logins. I.e., when you do
  #       an SVN command and point to somehost.cs.umn.edu, somehost runs
  #       your bashrc files. So this needs to be part of your bashrc profile.
  #module load soft/subversion/1.5-latest
  # 2013.06.10: Do this. You'll just have to update your working dirs.
  #             Or use module to downgrade.
  module load soft/subversion/1.6-latest
  # Python
  #module load soft/python/2.7
  # GIS software
  # 2010.03.02 Does the new TileCache need qgis to be disabled/not loaded?
  # 2010.07.07 QGis interferes with MapServer? Problems with GIS export?
  #            QGis' GDAL conflicts with system GDAL?
  #
  #  ==> /var/log/apache2/error.log <==
  #  mapserver/mapserv: error while loading shared
  #  libraries: libgdal.so.1: cannot open shared
  #                             # object file: No such file or directory
  #  [Thu May 27 13:24:30 2010] [error] [client 127.0.0.1]
  #                             Premature end of script headers: mapserv
  #
  #  pyserver$ ls /usr/lib | grep gdal
  #       2010-04-05 16:10 libgdal1.5.0.so.1 -> libgdal1.5.0.so.1.12.2
  #       2009-03-09 18:32 libgdal1.5.0.so.1.12.2
  #
  # Making a symbolic link works:
  #   sudo ln -s /usr/lib/libgdal1.5.0.so.1.12.2 /usr/lib/libgdal.so.1
  # 
  # Inspect with link dependencies tool:
  #    $ ldd mapserver/mapserv | grep libgdal
  #    libgdal.so.1 => /usr/lib/libgdal.so.1 (0x00007f7e49ae0000)
  #    libgeos_c.so.1 => /usr/lib/libgeos_c.so.1 (0x00007f7e498d1000)
  # 
  #module load soft/qgis
  # Dia; http://live.gnome.org/Dia/
  module load soft/dia
fi

