# File: custom_mint17.mate.sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Last Modified: 2016.10.10
# Project Page: https://github.com/landonb/home_fries
# Summary: Custom Mint17 MATE Window Manage Customization.
# License: GPLv3

stage_4_wm_terminal_white_on_black () {

  # Fix the Terminal colors: make White text on Black background.
  
  # For MATE, go to Edit > Profile Preferences, click the Colors tab,
  # uncheck Use colors from system theme, and choose White on black.
  #
  # FIXME: There's gotta be a configuration bit or config file somewhere
  #        that we can edit to automate setting up Mate Terminal, but
  #        [lb] hasn't found it yet. Even gsettings, doesn't help, e.g.,
  #           gsettings list-schemas | grep mate | sort
  #           gsettings list-recursively org.mate.terminal
  #

  :

} # end: stage_4_wm_terminal_white_on_black

stage_4_wm_desktop_icons_hide () {

  gsettings set org.mate.caja.desktop computer-icon-visible false
  gsettings set org.mate.caja.desktop home-icon-visible false
  gsettings set org.mate.caja.desktop volumes-visible false

  # 2016.04.02: What's up with this? Ubuntu MATE 15.10.
  # https://wiki.archlinux.org/index.php/MATE#Show_or_hide_desktop_icons
  dconf write /org/mate/desktop/background/show-desktop-icons false
  #  Hide computer icon:
  #  $ dconf write /org/mate/caja/desktop/computer-icon-visible false
  #  Hide user directory icon:
  #  $ dconf write /org/mate/caja/desktop/home-icon-visible false
  #  Hide network icon:
  #  $ dconf write /org/mate/caja/desktop/network-icon-visible false
  #  Hide trash icon:
  #  $ dconf write /org/mate/caja/desktop/trash-icon-visible false
  #  Hide mounted volumes:
  #  $ dconf write /org/mate/caja/desktop/volumes-visible false
} # end: stage_4_wm_desktop_icons_hide

stage_4_wm_customize_mate_misc () {

  # [lb] likes to be able to open and close his laptop lid without
  # sleeping or awakening the machine.

# FIXME: On the desktop machine, what are these values?
#        Should we not write them if they first don't exist?
  dconf write /org/mate/power-manager/button-lid-ac "'nothing'"
  dconf write /org/mate/power-manager/button-lid-battery "'nothing'"

  # Disable lid wakeup: Change for just the current session.
  #
  # To prevent the laptop from waking when you open the lid (I
  # bike with my laptop in a backpack and want to be sure it'll
  # never wake on its own), look in acpi's wakeup file:
  #   $ cat /proc/acpi/wakeup
  #   Device	S-state	  Status   Sysfs node
  #   LID	  S3	*enabled 
  #   ...
  # and you should see a device called LID.
  # (I think the 3.2 kernel also broke USB wake, which explains
  #  why my mouse (thanksfully) doesn't wake my machine.
  #   http://forum.kodi.tv/showthread.php?tid=121158)
  #
  # You can change the setting by writing to the special file
  #
  #   echo " LID" | sudo tee /proc/acpi/wakeup
  #
  #   $ cat /proc/acpi/wakeup
  #   Device	S-state	  Status   Sysfs node
  #   LID	  S3	*disabled 
  #   ...
  #
  # But we need a permanent fix.
  #
  # There are a bunch of hooks that run when sleep is activated:
  #   /usr/lib/pm-utils/sleep.d/
  # See: https://wiki.archlinux.org/index.php/Pm-utils
  sudo /bin/cp -f \
    ${script_path}/recipe/usr/lib/pm-utils/sleep.d/33disablewakeups \
    /usr/lib/pm-utils/sleep.d
  sudo chown root:root /usr/lib/pm-utils/sleep.d/33disablewakeups
  sudo chmod 755 /usr/lib/pm-utils/sleep.d/33disablewakeups
  # TO-TEST:
  #  sudo pm-suspend
  # then close and reopen the lid a few times.

  # 2014.12.08: The no-wake-on-lid-open seems to *mostly* work,
  #             but every once in a while, when [lb] opens the
  #             lid, the machine wakes. This seems to only happen
  #             when the machine has been sleeping for a while,
  #             because I am unable to reproduce it -- it only
  #             happens when I'm not trying to make it happen....

  # FIXME/MAYBE: Maybe move this to a Vim install/setup script?
  #
  # Add a keyboard shortcut for bring gVim to the foreground.
  # Hint: Type Alt-` to bring gvim to the foreground.
  dconf write /org/mate/desktop/keybindings/custom0/action \
    "'xdotool search --name SAMPI windowactivate'"
  dconf write /org/mate/desktop/keybindings/custom0/binding \
    "'<Mod4>grave'"
  dconf write /org/mate/desktop/keybindings/custom0/name \
    "'gVim [fs]'"

  # The quicktile application helps us tile windows but
  # it's also nice to be able to do it by dragging a window
  # to the monitor edge.
  #
  # Snap a window
  #   Go to Menu > Control Center > Personal
  #   Click "Windows" to open up "Window Preferences".
  #   Tick "Enable side by side tiling" under the "Placement" tab.

  dconf write /org/mate/marco/general/side-by-side-tiling \
    "true"

  # 2016.04.04: Ubuntu MATE Menu > Preferences > Main Menu is `mozo`:
  #   $ mozo
  #   Traceback (most recent call last):
  #     File "/usr/lib/python2.7/dist-packages/Mozo/MenuEditor.py", line 67, in save
  #       fd = open(getattr(self, menu).path, 'w')
  #   IOError: [Errno 13] Permission denied: '/home/$USER/.config/menus/mate-applications.menu'
  sudo chown -R $USER:$USER /home/$USER/.config/menus

} # end: stage_4_wm_customize_mate_misc

# ==============================================================
# Application Main()

setup_customize_mate_go () {

  if $WM_IS_MATE; then
    stage_4_wm_terminal_white_on_black
    stage_4_wm_desktop_icons_hide
    stage_4_wm_customize_mate_misc
  fi

} # end: setup_customize_mate_go

setup_customize_mate_go

