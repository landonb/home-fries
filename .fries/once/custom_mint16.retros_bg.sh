# File: custom_mint16.retros.bg.sh
# Author: Landon Bouma (home-fries &#x40; retrosoft &#x2E; com)
# Last Modified: 2015.01.26
# Project Page: https://github.com/landonb/home_fries
# Summary: Custom Mint16 Login Screen and Desktop Background.
# License: GPLv3

# Note: These customizations are for Mint 16.
#       Mint 17 has a revamped login screen.
#       Which is nice.
#       Maybe someday I'll find more than one photo
#       and hook into their slideshow.

# -- MDM Display Manager Greeter theme (own it!)

# Note: MDM has nothing to do with Mint nor with MATE;
#       it's its own login GUI.

# -- Custom Greeter Theme and Desktop background

# The Retrosoft theme is [lb]'s background image that he likes and a
# different placement of the username and password box. Feel free to
# substitute any image of your own that makes you want to log into a
# heartless machine and spend a lot of time working.

USE_GREETER_THEME="${script_absbase}/target/mint16-mdm/usr/share/mdm/html-themes/Retrosoft"

# You can use any jpeg or png image as a background. Specify it here.
USE_GREETER_IMAGE="${script_absbase}/assets/ccp-mint16-greeter-by-landonb.jpg"

USE_DESKTOP_IMAGE="${script_absbase}/assets/ccp-mint16-desktop-by-landonb.jpg"

# -- Remote resources. Maybe.

# If the login and background image(s) are not already local,
# specify the HTTP address and username and password to get them.
REMOTE_RESOURCES_URI=""
REMOTE_RESOURCES_USER=""
REMOTE_RESOURCES_PASS=""

# -- Customization function.

stage_4_wm_customize_login_and_dtop_bg () {

  # *** Cinnamon/Xfce/MATE Customization

  # Change the background image.

  # Download the remote file, maybe.
  if [[ -n $USE_DESKTOP_IMAGE \
        && $(dirname $USE_DESKTOP_IMAGE) == "." ]]; then
    if [[ -z $REMOTE_RESOURCES_URI ]]; then
      echo
      echo "ERROR: Set REMOTE_RESOURCES_URI or abs path for USE_DESKTOP_IMAGE"
      exit 1
    fi
    /bin/mkdir -p /ccp/var/.install
    cd /ccp/var/.install
    wget -N \
      --user "$REMOTE_RESOURCES_USER" \
      --password "$REMOTE_RESOURCES_PASS" \
      $REMOTE_RESOURCES_URI/$USE_DESKTOP_IMAGE
    if [[ $? -ne 0 || ! -e /ccp/var/.install/$USE_DESKTOP_IMAGE ]]; then
      echo
      echo "ERROR: No desktop image: $REMOTE_RESOURCES_URI/$USE_DESKTOP_IMAGE"
      exit 1
    fi
    USE_DESKTOP_IMAGE=/ccp/var/.install/$USE_DESKTOP_IMAGE
  fi

  if [[ -n $USE_DESKTOP_IMAGE ]]; then
    USER_BGS=/home/$USER/Pictures/.backgrounds
    /bin/mkdir -p $USER_BGS
    /bin/cp $USE_DESKTOP_IMAGE $USER_BGS
    BG_FILE_PATH="$USER_BGS/`basename $USE_DESKTOP_IMAGE`"
  fi

  if $WM_IS_MATE; then
    gsettings set \
      org.mate.background picture-filename "$BG_FILE_PATH"
    # There's also a dconf setting but I didn't explicitly set it:
    #   [org/mate/desktop/background]
    #   color-shading-type='solid'
    #   primary-color='#000000000000'
    #   picture-options='zoom'
    #   picture-filename='/home/cyclopath/Pictures/.backgrounds/desktop_bg.jpg'
    #   secondary-color='#000000000000'
  elif $WM_IS_CINNAMON; then
    gsettings set \
      org.cinnamon.desktop.background picture-uri "file://$BG_FILE_PATH"
  fi

  # Keep the image, at least while we keep testing this script.
  if false; then
    if [[ -e $USE_DESKTOP_IMAGE ]]; then
      /bin/rm -f $USE_DESKTOP_IMAGE
    fi
  fi

  # Custom login screen.

  # Download the remote file, maybe.
  if [[ -n $USE_GREETER_IMAGE && $(dirname $USE_GREETER_IMAGE) == "." ]];
    then
    if [[ -z $REMOTE_RESOURCES_URI ]]; then
      echo
      echo "ERROR: Set REMOTE_RESOURCES_URI or abs path for USE_GREETER_IMAGE."
      exit 1
    fi
    /bin/mkdir -p /ccp/var/.install
    cd /ccp/var/.install
    # -O doesn't work with -N so just download as is and then rename.
    wget -N \
      --user "$REMOTE_RESOURCES_USER" \
      --password "$REMOTE_RESOURCES_PASS" \
      $REMOTE_RESOURCES_URI/$USE_GREETER_IMAGE
    if [[ $? -ne 0 || ! -e /ccp/var/.install/$USE_GREETER_IMAGE ]]; then
      echo
      echo "ERROR: No greeter image at $REMOTE_RESOURCES_URI/$USE_GREETER_IMAGE"
      exit 1
    fi
    USE_GREETER_IMAGE=/ccp/var/.install/$USE_GREETER_IMAGE
  fi

  if [[ -n $USE_GREETER_IMAGE && -n $USE_GREETER_THEME ]]; then

    THEME_NAME=$(basename $USE_GREETER_THEME)

    sudo /bin/cp -r \
      $USE_GREETER_THEME \
      /usr/share/mdm/html-themes/
    sudo /bin/cp \
      $USE_GREETER_IMAGE \
      /usr/share/mdm/html-themes/$THEME_NAME/bg.jpg
    sudo /bin/cp \
      $USE_GREETER_IMAGE \
      /usr/share/mdm/html-themes/$THEME_NAME/screenshot.jpg

    sudo chown -R root:root /usr/share/mdm/html-themes/$THEME_NAME
    sudo chmod 2755 /usr/share/mdm/html-themes/$THEME_NAME
    dest_dir=/usr/share/mdm/html-themes/$THEME_NAME
    sudo find $dest_dir -type d -exec chmod 2775 {} +
    sudo find $dest_dir -type f -exec chmod u+rw,g+rw,o+r {} +

    # Keep the image, at least while we keep testing this script.
    if false; then
      if [[ -e $USE_GREETER_IMAGE ]]; then
        /bin/rm -f $USE_GREETER_IMAGE
      fi
    fi

    # NOTE: You have to reboot to see changes. Logout is insufficient.

    if $WM_IS_CINNAMON; then
      gconftool-2 --set /desktop/cinnamon/windows/theme \
        --type string "$THEME_NAME"
      gconftool-2 --set /apps/metacity/general/theme \
        --type string "$THEME_NAME"
      gconftool-2 --set /desktop/gnome/interface/gtk_theme \
        --type string "$THEME_NAME"
      gconftool-2 --set /desktop/gnome/interface/icon_theme \
        --type string "$THEME_NAME"
    fi
    sudo ln -s /usr/share/icons/Mint-X \
      /usr/share/icons/$THEME_NAME
    sudo ln -s /usr/share/icons/Mint-X-Dark \
      /usr/share/icons/$THEME_NAME-Dark
    #sudo ln -s /usr/share/mdm/html-themes/Mint-X \
    #  /usr/share/mdm/html-themes/$THEME_NAME
    sudo ln -s /usr/share/pixmaps/pidgin/tray/Mint-X \
      /usr/share/pixmaps/pidgin/tray/$THEME_NAME
    sudo ln -s /usr/share/pixmaps/pidgin/tray/Mint-X-Dark \
      /usr/share/pixmaps/pidgin/tray/$THEME_NAME-Dark
    sudo ln -s /usr/share/themes/Mint-X \
      /usr/share/themes/$THEME_NAME
    gsettings set org.gnome.desktop.wm.preferences theme "$THEME_NAME"
    gsettings set org.gnome.desktop.interface gtk-theme "$THEME_NAME"
    gsettings set org.gnome.desktop.interface icon-theme "$THEME_NAME"
    # org.gnome.desktop.sound theme-name 'LinuxMint'
    if $WM_IS_MATE; then
      gsettings set org.mate.Marco.general theme "$THEME_NAME"
      gsettings set org.mate.interface gtk-theme "$THEME_NAME"
      gsettings set org.mate.interface icon-theme "$THEME_NAME"
      gsettings set org.mate.Marco.general theme "$THEME_NAME"
      # org.mate.sound theme-name 'LinuxMint'
    elif $WM_IS_CINNAMON; then
      gsettings set org.cinnamon.desktop.wm.preferences theme "$THEME_NAME"
      gsettings set org.cinnamon.desktop.interface gtk-theme "$THEME_NAME"
      gsettings set org.cinnamon.desktop.interface icon-theme "$THEME_NAME"
    fi

    sudo /bin/sed -i.bak \
      "s/^\[greeter\]$/[greeter]\nHTMLTheme=$THEME_NAME/" \
      /etc/mdm/mdm.conf
  fi

} # end: stage_4_wm_customize_login_and_dtop_bg

# ==============================================================
# Application Main()

setup_retros_bg_go () {

  stage_4_wm_customize_login_and_dtop_bg

} # end: setup_retros_bg_go

setup_retros_bg_go

