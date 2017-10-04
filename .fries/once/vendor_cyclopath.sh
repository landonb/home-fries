# File: vendor_cyclopath.sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Last Modified: 2017.10.03
# Project Page: https://github.com/landonb/home_fries
# Summary: Cyclopath IDE setup script.
# License: GPLv3

# Cyclopath Install (Worked last on Linux Mint 16, I'm guessing)
# ==============================================================

# Cyclopath installation options
# ------------------------------

# Indicate whether or not to install Cyclopath.
# Note: Use +x trick to check that var is not actually set,
#       and not just the empty string.
if [[ -z ${DO_INSTALL_CYCLOPATH+x} ]]; then
  DO_INSTALL_CYCLOPATH=false
fi

# From whence to fetch Cyclopath.
# You've got two choices:
# 1. [lb]'s maintained fork:
#USE_HOMESRC_SVN_URI="svn://cycloplan.cyclopath.org/cyclingproject/public/ccpv3_trunk"
#USE_HOMESRC_GIT_URI="https://github.com/lbouma/Cyclopath.git"
if [[ -z ${USE_CCP_REPO_GIT} ]]; then
  USE_CCP_REPO_GIT="https://github.com/lbouma/Cyclopath.git"
fi
# 2. The GroupLens legacy SVN repository.
#    (As of 2014.11.08, most recently: v64.17, 23 Sep 2014.)
#USE_CCP_REPO_SVN="svn://cycloplan.cyclopath.org/cyclingproject/public/ccpv3_trunk"

# Load a copy of the production database, but only if you're a developer
# at the U, since the file is stored remotely and securely on a U machine.
# FIXME: Setup Cyclopath using a Shapefile, to get community developers
#        up and running.
#        See: scripts/setupcp/geofeature_io.py (a/k/a hausdorff_import.py).
# FIXME: E.g., 
#  USE_CCP_DATABASE_SCP="$USER@$CS_PRODUCTION:/ccp/var/dbdumps/ccpv3_anon.dump"
USE_CCP_DATABASE_SCP=""

# FIXME: This path:
CCP_AUTO_SCRIPTS="/ccp/dev/cp/scripts/setupcp/auto_install"
echo "WARNING: This script is dated. Please update me!"
exit 1

if false; then
  grep "^deb http://us.archive.ubuntu.com/ubuntu xenial main multiverse$" /etc/apt/sources.list &> /dev/null
  if [[ $? -ne 0 ]]; then
    # In lieu of sudo add-apt-repository,
    echo "
  # Added by ${0}:${USER} at `date +%Y.%m.%d-%T`.
  deb http://us.archive.ubuntu.com/ubuntu xenial main multiverse" \
      | sudo tee -a /etc/apt/sources.list &> /dev/null
  fi
  # Fruitless!
  sudo apt-get install -y nspluginwrapper
  # E: Unable to locate package nspluginwrapper
  #
  # So the blog post I read was wrong about the multiverse!
fi

# Miscellaneous config
# --------------------

# Add filtering rules to meld.

stage_4_meld_configure () {

  /bin/mkdir -p /home/$USER/.gconf/apps/meld
  /bin/chmod 2700 /home/$USER/.gconf/apps/meld
  if $WM_IS_MATE; then
    /bin/cp -f \
      ${SCRIPT_DIR}/target/cyclopath/home/user/.gconf/apps/meld/%gconf.xml-mate \
      /home/$USER/.gconf/apps/meld/%gconf.xml
    # MAYBE: There are also keys in gconftool-2, just after the existing meld
    #        entry. Might the absense of these conflict with the %gconf.xml?
    #   
    #        <entry>
    #          <key>/apps/gnome-settings/meld/history-fileentry</key>
    #          ...
    #        </entry>
    #        <entry>
    #          <key>/apps/meld/edit_wrap_lines</key>
    #          <value>
    #            <int>2</int>
    #          </value>
    #        </entry>
    #        <entry>
    #          <key>/apps/meld/show_line_numbers</key>
    #          <value>
    #            <bool>true</bool>
    #          </value>
    #        </entry>
    #        <entry>
    #          <key>/apps/meld/spaces_instead_of_tabs</key>
    #          <value>
    #            <bool>true</bool>
    #          </value>
    #        </entry>
    #        <entry>
    #          <key>/apps/meld/tab_size</key>
    #          <value>
    #            <int>3</int>
    #          </value>
    #        </entry>
    #        <entry>
    #          <key>/apps/meld/use_syntax_highlighting</key>
    #          <value>
    #            <bool>true</bool>
    #          </value>
    #        </entry>
    #        <entry>
    #          <key>/apps/meld/window_size_x</key>
    #          <value>
    #            <int>1680</int>
    #          </value>
    #        </entry>
    #        <entry>
    #          <key>/apps/meld/window_size_y</key>
    #          <value>
    #            <int>951</int>
    #          </value>
    #        </entry>
  elif $WM_IS_CINNAMON; then
    # Configure Meld (Monospace 9 pt font; show line numbers).
    /bin/cp -f \
      ${SCRIPT_DIR}/target/cinnamon/home/user/.gconf/apps/meld/%gconf.xml-cinnamon \
      /home/$USER/.gconf/apps/meld/%gconf.xml
  fi

} # end: stage_4_meld_configure

# Cyclopath installation function
# -------------------------------

stage_4_cyclopath_install () {

  # *** Install Cyclopath

  echo
  echo "Installing Cyclopath..."

  echo
  echo -n "Fixing permissions before overlay... "
  #sudo /ccp/dev/cp/scripts/util/fixperms.pl --public /ccp/ \
  #  > /dev/null 2>&1
  sudo find /ccp -type d -exec chmod 2775 {} +
  sudo find /ccp -type f -exec chmod u+rw,g+rw,o+r {} +
  echo "ok"

  # Reset the positional parameters
  masterhost=$HOSTNAME
  targetuser=$USER
  isbranchmgr=0
  isprodserver=0
  reload_databases=0
  svn_update_sources=0
  git_update_sources=0
  set -- $masterhost \
         $targetuser \
         $isbranchmgr \
         $isprodserver \
         $reload_databases \
         $svn_update_sources \
         $git_update_sources
  # This script is meant for user-managed machines, i.e., not those
  # on the CS net, where [[ "$MACHINE_DOMAIN" == "cs.umn.edu" ]],
  # targetgroup=grplens.
  targetgroup=$USE_CCP_PROJECT_GROUP

  echo
  echo "Using params: $*"

  # We called dir_prepare already:
  #  ./dir_prepare.sh $*

  # Setup third-party dev docs locally.
  cd $CCP_AUTO_SCRIPTS
  ./usr_dev_doc.sh $*

  # Setup Apache and Postgresql.
  cd $CCP_AUTO_SCRIPTS
  ./etc_overlay.sh $*
  #
  # We wait until now to install postgresql.conf, otherwise the server
  # won't start: it complains are the shared memory settings, or, our
  # /ccp/var/log folder doesn't exist, which also causes it not to start
  # (and not to log).

  touch /ccp/var/log/postgresql/postgresql-${POSTGRESABBR}-main.log
  sudo chown postgres /ccp/var/log/postgresql/postgresql-${POSTGRESABBR}-main.log
  sudo chmod 664 /ccp/var/log/postgresql/postgresql-${POSTGRESABBR}-main.log
  tot_sys_mem=`cat /proc/meminfo | grep MemTotal | /bin/sed s/[^0-9]//g`
  PGSQL_SHBU=$(($tot_sys_mem / 3))kB

  m4 \
    --define=PGSQL_SHBU=$PGSQL_SHBU \
      ${SCRIPT_DIR}/target/cyclopath/etc/postgresql/${POSTGRESABBR}/main/postgresql.conf \
    | sudo tee /etc/postgresql/${POSTGRESABBR}/main/postgresql.conf \
    &> /dev/null
  sudo /etc/init.d/postgresql restart

  # Setup the debug flash player.
  cd $CCP_AUTO_SCRIPTS
  # NOTE: The npconfig commands indicate a particular failure, but the plugin
  #       seems to work just fine.
  #       "And create symlink to plugin in /usr/lib/mozilla/plugins: failed!"
  ./flash_debug.sh $*

  # Compile the GIS suite.
  cd $CCP_AUTO_SCRIPTS
  ./gis_compile.sh $*

  # Prepare Cyclopath so user can hit http://ccp
  
  cd $CCP_AUTO_SCRIPTS
  USE_DOMAIN=$USE_DOMAIN \
    USE_CCP_DATABASE_SCP=$USE_CCP_DATABASE_SCP \
    CHECK_CACHES_BR_LIST="\"minnesota\" \"Minnesota\" \"minnesota\" \"Metc Bikeways 2012\"" \
    reload_databases=1 \
      ./prepare_ccp.sh $*

  # MAYBE: Copy or build tiles. Maybe setup cron jobs?

  # *** Make one last configy dump.

  # One of the sudo installs must've installed root files in the user's home
  # directory, but not to worry: it's an empty file. But fix its perms.
  if [[ -d /home/$USER/.config/menus ]]; then
    sudo chown -R $USER:$USER /home/$USER/.config/menus
  else
    echo
    echo "WARNING/EXPLAIN: 2016-11-11: Where's ~/.config/menus at?"
    echo
  fi

  if $MAKE_CONF_DUMPS; then
    cd ~/Downloads
    user_home_conf_dump "usr_04b"
  fi

  # *** Make the fake /export/scratch, if you're a remote lab dev.

  #sudo mkdir -p /export/scratch
  #sudo chmod 2755 /export
  #sudo chmod 2755 /export/scratch
  if [[ -d /export/scratch ]]; then
    sudo ln -s /ccp /export/scratch/ccp
  fi

  # *** Cleanup/Post-processing

  # For now, keep the .install directory.
  if false; then
    if [[ -d /ccp/var/.install ]]; then
      /bin/rm -rf /ccp/var/.install
    fi
  fi

} # end: stage_4_cyclopath_install

# ==============================================================
# Application Main()

setup_cyclopath_go () {

  if $DO_INSTALL_CYCLOPATH; then

    # Make the /ccp hierarcy.
    cd $CCP_AUTO_SCRIPTS
    #./dir_prepare.sh $HOSTNAME $USER
    export MACHINE_DOMAIN=$MACHINE_DOMAIN
    ./dir_prepare.sh $HOSTNAME $USER

    stage_4_meld_configure

    stage_4_cyclopath_install

  fi

} # end: setup_cyclopath_go

setup_cyclopath_go

