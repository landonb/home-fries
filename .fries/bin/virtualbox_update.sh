#!/bin/bash
# Last Modified: 2016-09-26
#
# Buggers. Oracle VirtualBox update wrapper.

if [[ -z ${OPT_DLOADS} ]]; then
  OPT_DLOADS=/srv/opt/.downloads
fi

if [[ ! -d ${OPT_DLOADS} ]]; then
  echo "Not a directory: ${OPT_DLOADS}"
  exit 1
fi

virtualbox_dubs_update () {

  pushd ${OPT_DLOADS} &> /dev/null

  # Load the release codename, e.g., raring, trusty, wily, etc.
  source /etc/lsb-release
  if [[ $DISTRIB_ID == 'LinuxMint' ]]; then
    if [[ $DISTRIB_CODENAME == 'rebecca' ]]; then
      # Mint 17.X is rebecca is trusty 14.04.
      DISTRIB_CODENAME=trusty
    elif [[ $DISTRIB_CODENAME == 'sarah' ]]; then
      # Mint 18 is sarah is xenial 16.04.
      DISTRIB_CODENAME=xenial
    else
      echo
      echo "WARNING: Unknown LinuxMint distro -- not Rebecca, nor Sarah, but: $DISTRIB_CODENAME"
      echo
    fi
  elif [[ $DISTRIB_ID != 'Ubuntu' ]]; then
    echo
    echo "WARNING: Unknown distribution -- not LinuxMint, nor Ubuntu, but: $DISTRIB_ID"
    echo
  fi

  # The VirtualBox bugs you to update whenever an update is available.
  # To make this process more seamless, we automate the setup process.
  wget \
    -O oracle_virtualbox_download_latest.txt \
    http://download.virtualbox.org/virtualbox/LATEST.TXT
  # Contains, e.g., "5.0.20".
  LATEST_VBOX_VERSION_BASE=$(cat oracle_virtualbox_download_latest.txt)
  # Figure out the package name.
  DOWNL_PATH=oracle_virtualbox_download_index_$LATEST_VBOX_VERSION_BASE.html
  wget -O $DOWNL_PATH http://download.virtualbox.org/virtualbox/$LATEST_VBOX_VERSION_BASE/
  LATEST_VBOX_DEB_PKG=$(\
    grep "${DISTRIB_CODENAME}_amd64" $DOWNL_PATH \
    | /bin/sed -r s/\<[^\>]*\>//g \
    | /bin/sed -r s/^[\ ]\+\(.*\.deb\).*$/\\1/ \
  )

  if [[ -z $LATEST_VBOX_DEB_PKG ]]; then
    echo
    echo "WARNING: Could not deduce download path from index.html:"
    echo
    echo "           $DOWNL_PATH"
    echo
    exit 2
  fi

  if [[ -e ${OPT_DLOADS}/${LATEST_VBOX_DEB_PKG} ]]; then
    echo
    echo "WARNING: Skipping VirtualBox install -- Already downloaded."
    echo "Remove download if you want to start over: ${OPT_DLOADS}/${LATEST_VBOX_DEB_PKG}"
    echo
    exit 1
  fi

  wget -N \
    http://download.virtualbox.org/virtualbox/${LATEST_VBOX_VERSION_BASE}/${LATEST_VBOX_DEB_PKG}

  #sudo apt-get remove virtualbox-4.3
  sudo dpkg -i ${LATEST_VBOX_DEB_PKG}
  #/bin/rm ${LATEST_VBOX_DEB_PKG}

# FIXME: Minor version bumps require uninstall.
#landonb@larry:.downloads ⚓ $   sudo dpkg -i ${LATEST_VBOX_DEB_PKG}
#dpkg: regarding virtualbox-5.1_5.1.0-108711~Ubuntu~trusty_amd64.deb containing virtualbox-5.1:
# virtualbox-5.1 conflicts with virtualbox
#  virtualbox-5.0 provides virtualbox and is present and installed.
#
#dpkg: error processing archive virtualbox-5.1_5.1.0-108711~Ubuntu~trusty_amd64.deb (--install):
# conflicting packages - not installing virtualbox-5.1
#Errors were encountered while processing:
# virtualbox-5.1_5.1.0-108711~Ubuntu~trusty_amd64.deb
###sudo apt remove virtualbox virtualbox-5.0 virtualbox-4.*
if false; then
sudo apt-get remove virtualbox-5.0
fi

  # Remove old files.
  #
  # E.g., ./oracle_virtualbox_download_index_5.1.6.html
  find . -maxdepth 1 -name "oracle_virtualbox_download_index_[0-9]*\\.[0-9]*\\.[0-9]*\\.html" \
    -exec echo {} + | \
    /bin/sed s/\\.\\/${DOWNL_PATH}// | \
    xargs /bin/rm
  #
  # E.g., ./virtualbox-5.1_5.1.6-110634~Ubuntu~trusty_amd64.deb
  find . -maxdepth 1 -name "virtualbox-[0-9]*\\.[0-9]*_[0-9]*\\.[0-9]*\\.[0-9]*-[0-9]*~Ubuntu~[a-zA-Z0-9]*_[a-zA-Z0-9]*\\.deb" \
    -exec echo {} + | \
    /bin/sed s/\\.\\/virtualbox-[0-9]*\\.[0-9]*_${LATEST_VBOX_VERSION_BASE}-[0-9]*~Ubuntu~[a-zA-Z0-9]*_[a-zA-Z0-9]*\\.deb// | \
    xargs /bin/rm

  popd &> /dev/null

}
virtualbox_dubs_update

