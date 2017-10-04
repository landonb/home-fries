# File: vendor_bugzilla.sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Last Modified: 2017.10.04
# Project Page: https://github.com/landonb/home-fries
# Summary: Bugzilla setup script.
# License: GPLv3

# Very Dated/Very Unused: Bugzilla Install
# ========================================

source_deps() {
  local curdir=$(dirname -- "${BASH_SOURCE[0]}")
  # Load: ask_yes_no_default
  source "${curdir}/../lib/interact_util.sh"
}
source_deps

# Bugzilla installation options
# -----------------------------

#bzilla_basename="bugzilla-4.4.4"
bzilla_basename="bugzilla-4.4.6"
bzilla_basepath=/ccp/var/cms/${bzilla_basename}

# Bugzilla installation function
# ------------------------------

stage_4_bugzilla_install () {

  # *** Bugzilla Install

  echo "WARNING: Bugzilla Install Code Old and Untested"
  echo "Do you want to continue?"
  ask_yes_no_default 'Y'

# FIXME: Bugzilla:
#
#
# Checking for           IO-stringy (any)       ok: found v2.110 
# WARNING: We could not check the configuration of Apache. This sometimes
# happens when you are not running checksetup.pl as root. To see the
# problem we ran into, run: /usr/sbin/apachectl -t -D DUMP_MODULES
# 
# ***********************************************************************
# * OPTIONAL MODULES                                                    *
# ***********************************************************************
# * Certain Perl modules are not required by Bugzilla, but by           *
# * installing the latest version you gain access to additional         *
# * features.                                                           *
# *                                                                     *
# * The optional modules you do not have installed are listed below,    *
# * with the name of the feature they enable. Below that table are the  *
# * commands to install each module.                                    *
# ***********************************************************************
# *      MODULE NAME * ENABLES FEATURE(S)                               *
# ***********************************************************************
# *               GD * Graphical Reports, New Charts, Old Charts        *
# *            Chart * New Charts, Old Charts                           *
# *      Template-GD * Graphical Reports                                *
# *       GDTextUtil * Graphical Reports                                *
# *          GDGraph * Graphical Reports                                *
# *         mod_perl * mod_perl                                         *
# * Apache-SizeLimit * mod_perl                                         *
# ***********************************************************************
# COMMANDS TO INSTALL OPTIONAL MODULES:
# 
#              GD: /usr/bin/perl install-module.pl GD
#           Chart: /usr/bin/perl install-module.pl Chart::Lines
#     Template-GD: /usr/bin/perl install-module.pl Template::Plugin::GD::Image
#      GDTextUtil: /usr/bin/perl install-module.pl GD::Text
#         GDGraph: /usr/bin/perl install-module.pl GD::Graph
#        mod_perl: /usr/bin/perl install-module.pl mod_perl2
# Apache-SizeLimit: /usr/bin/perl install-module.pl Apache2::SizeLimit
# 
# 
# To attempt an automatic install of every required and optional module
# with one command, do:
# 
#   /usr/bin/perl install-module.pl --all
# 
# Reading ./localconfig...
# Checking for            DBD-mysql (v4.001)    ok: found v4.025 
# There was an error connecting to MySQL:
# 
#     Access denied for user 'bugs'@'localhost' (using password: NO)
# 
# This might have several reasons:
# 
# * MySQL is not running.
# * MySQL is running, but there is a problem either in the
#   server configuration or the database access rights. Read the Bugzilla
#   Guide in the doc directory. The section about database configuration
#   should help.
# * Your password for the 'bugs' user, specified in $db_pass, is 
#   incorrect, in './localconfig'.
# * There is a subtle problem with Perl, DBI, or MySQL. Make
#   sure all settings in './localconfig' are correct. If all else fails, set
#   '$db_check' to 0.

# FIXME/BEWARE: 2014.06.12: This install might still be incompletely automated.

  cd ${OPT_DLOADS}
  wget -N \
    http://ftp.mozilla.org/pub/mozilla.org/webtools/${bzilla_basename}.tar.gz
  # Make the final directory, e.g., /ccp/var/cms/${bzilla_basename}.
  if [[ -d ${bzilla_basepath} ]]; then
    echo
    echo "WARNING: Bugzilla installation already exists. Skipping."
    echo
  else
    /bin/rm -rf ${bzilla_basename}
    tar -zxvf ${bzilla_basename}.tar.gz
    /bin/mkdir -p /ccp/var/cms/
    /bin/mv ${bzilla_basename} ${bzilla_basepath}
  fi
  cd ${bzilla_basepath}
  # Old apache versions: chmod a+w config
  sudo chown -R www-data:${USE_PROJECT_GROUP_MAIN} ${bzilla_basepath}
  sudo chmod 2775 ${bzilla_basepath}

  # Reading '~/.cpan/source/modules/02packages.details.txt.gz'
  #   Database was generated on Mon, 10 Nov 2014 03:41:02 GMT
  # ..............
  #   New CPAN.pm version (v2.05) available.
  #   [Currently running version is v2.00]
  #   You might want to try
  #     install CPAN
  #     reload cpan
  #   to both upgrade CPAN.pm and run the new version without leaving
  #   the current session.
  # 
  # ..............................................................DONE
  # 
  # ...

  # Install mod_perl for Apache.
  # 2014.05.27: Skip mod_perl. While it might be faster than mod_cgi,
  # it's newer, it takes a lot more RAM, and it doesn't necessarily
  # play well with other mod_perl-enabled sites.
  #
  #  sudo apt-get install -y libapache2-mod-perl2

  # Make an apache config.
  m4 \
    --define=MWIKI_BASENAME=$bzilla_basename \
    --define=MACH_DOMAIN=$USE_DOMAIN \
      ${SCRIPT_DIR}/common/etc/apache2/sites-available/bugzilla \
      > /etc/apache2/sites-available/bugzilla.conf
  # Activate the apache conf.
  cd /etc/apache2/sites-enabled/
  if [[ ! -e bugzilla.conf ]]; then
    ln -s ../sites-available/bugzilla.conf bugzilla.conf
  fi
  #sudo /etc/init.d/apache2 reload
  sudo /etc/init.d/apache2 restart

  cd ${bzilla_basepath}

  # Check for missing modules.
  #   ./checksetup.pl --check-modules
  # You'll see a suggestion to
  #   install CPAN
  #   reload cpan
  # but this isn't right and is not something we should worry about.
  # (If we want to update cpan, we should download and compile it
  #  ourselves.)
  # And then run either,
  #  /usr/bin/perl install-module.pl --all
  # or,
  /usr/bin/perl install-module.pl DateTime
  /usr/bin/perl install-module.pl DateTime::TimeZone
  /usr/bin/perl install-module.pl Template
  /usr/bin/perl install-module.pl Email::Send
  /usr/bin/perl install-module.pl Email::MIME
  /usr/bin/perl install-module.pl Math::Random::ISAAC
  # Install all the optional modules (why not!... except
  # this takes a few minutes, takes up hard drive space,
  # and adds complexity to the software and probably lots
  # of features we won't use).
  /usr/bin/perl install-module.pl --all
  # Check for missing modules again.
  #   ./checksetup.pl --check-modules
  # For whatever reason, two modules will be indicated as missing,
  # but when you try to install them, they'll say they're up to date.
  #   Daemon-Generic: /usr/bin/perl install-module.pl Daemon::Generic
  #   Apache-SizeLimit: /usr/bin/perl install-module.pl Apache2::SizeLimit

  # Run checksetup without the --check-modules.
  ./checksetup.pl

  # Configure db vars
  cd ${bzilla_basepath}
  #
  sudo /bin/sed -i.bak \
    "s/^\$webservergroup = 'apache';$/\$webservergroup = 'www-data';/ ; 
     s/^\$db_driver = 'mysql';$/\$db_driver = 'pg';/ ; " \
    /usr/local/lib/php.ini
  #

  # FIXME: Finish implementing permissions
  #        (move this to the setup.$HOSTNAME.sh private file)
  #$db_name = 'bugs';
  #$db_user = 'bugs';
  #$db_pass = '';

  # Run checksetup with the updated localconfig.
  ./checksetup.pl

} # end: stage_4_bugzilla_install

# ==============================================================
# Application Main()

setup_bugzilla_go () {

  # Install Bugzilla.
  # FIXME/Maybe: Bugzilla installation is hosed. See comments in fcn.
  #stage_4_bugzilla_install
  echo "WARNING: Outdated script. Baby it back to life if you care."

} # end: setup_bugzilla_go

setup_bugzilla_go

