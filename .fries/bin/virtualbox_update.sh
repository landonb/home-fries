#!/bin/bash
# Last Modified: 2016-05-02
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
  if [[ $DISTRIB_CODENAME == 'rebecca' ]]; then
    # Mint 17.X is rebecca is trusty.
    DISTRIB_CODENAME=trusty
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

  popd &> /dev/null

}
virtualbox_dubs_update

