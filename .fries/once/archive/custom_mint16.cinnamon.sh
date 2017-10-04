# File: custom_mint16.cinnamon.sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Last Modified: 2017.10.03
# Project Page: https://github.com/landonb/home-fries
# Summary: Custom Mint16 Cinnamon Window Manage Customization.
# License: GPLv3

# 2016-10-10
echo "STALE/DEAD"
exit 1

stage_4_wm_terminal_white_on_black () {

  # Fix the Terminal colors: it's really hard to read against
  # the default Mint background!
  # - Make White text on Solid Black background.
  terminal_conf=.gconf/apps/gnome-terminal/profiles/Default/%gconf.xml
  /bin/cp -f \
    ${SCRIPT_DIR}/target/cinnamon/home/user/$terminal_conf \
    /home/$USER/$terminal_conf

} # end: stage_4_wm_terminal_white_on_black

stage_4_wm_desktop_icons_hide () {

  gsettings set org.nemo.desktop computer-icon-visible false
  gsettings set org.nemo.desktop home-icon-visible false
  gsettings set org.nemo.desktop volumes-visible false

} # end: stage_4_wm_desktop_icons_hide

stage_4_wm_customize_cinnamon_part_1 () {

  # Disable screensaver and lock screen.
  gconftool-2 --set \
    /apps/gnome-screensaver/lock_enabled \
    --type bool "0"
  gconftool-2 --set \
    /apps/gnome-screensaver/idle_activation_enabled \
    --type bool "0"

  # Disable alert sounds.
  #gsettings set org.cinnamon.sounds close-enabled false
  gsettings set org.cinnamon.sounds login-enabled false
  #gsettings set org.cinnamon.sounds map-enabled false
  #gsettings set org.cinnamon.sounds maximize-enabled false
  #gsettings set org.cinnamon.sounds minimize-enabled false
  gsettings set org.cinnamon.sounds plug-enabled false
  gsettings set org.cinnamon.sounds switch-enabled false
  gsettings set org.cinnamon.sounds tile-enabled false
  #gsettings set org.cinnamon.sounds unmaximize-enabled false
  gsettings set org.cinnamon.sounds unplug-enabled false

  # Disable the annoying HUD (heads-up display) message,
  # "Hold <CTRL> to enter snap mode
  #  Use the arrow keys to change workspaces"
  # which seems to appear when you're dragging a window and
  # then disappears quickly -- it's information I already know,
  # it's distracting when it pops up (and it doesn't always pop
  # up when dragging windows), and it hides itself so quickly it
  # seem useless.
  # NOTE: These instructions are wrong: [lb] thought I solved the
  #       problem, but it continued to happen.
  #gsettings set org.cinnamon hide-snap-osd true
  # Hrmpf, that setting didn't seem to work, or maybe it half worked:
  # I still see the popup notices, but it doesn't seem like as many.
  # Try another option, found on the Cinnamon panel at
  # System Settings > General > display notifications.
  #gsettings set org.cinnamon display-notifications false

  # Screensaver & Lock Settings > [o] Dim screen to save power
  gsettings set org.cinnamon.settings-daemon.plugins.power \
    idle-dim-battery false
  # MAYBE: Where's the setting for "Turn screen off when inactive for: "
  #        I want to set it to Never but neither gsettings nor gconftool-2
  #        reveal any differences...

  # Map Ctrl + Alt + Backspace to Immediate Logout
  gconftool-2 --type list --list-type string \
    --set /desktop/gnome/peripherals/keyboard/kbd/options \
    '[lv3 lv3:ralt_switch,terminate terminate:ctrl_alt_bksp]'
  # NOTE: MATE already implements this behavior.

  # *** Cinnamon applets

  # Calendar applet
  home_path=.cinnamon/configs/calendar@cinnamon.org
  /bin/cp \
    ${SCRIPT_DIR}/target/cinnamon/home/user/$home_path/calendar@cinnamon.org.json \
    ~/$home_path/

  # System monitor applet
  # Requires: gir1.2-gtop-2.0
  cd ${OPT_DLOADS}
  wget -N \
    http://cinnamon-spices.linuxmint.com/uploads/applets/YYRT-ZCAP-A2Y2.zip
  unzip YYRT-ZCAP-A2Y2.zip -d system_monitor_applet
  /bin/rm -rf ~/.local/share/cinnamon/applets/sysmonitor@orcus
  mv system_monitor_applet/sysmonitor@orcus \
     ~/.local/share/cinnamon/applets
  rmdir system_monitor_applet

  home_path=.local/share/cinnamon/applets/sysmonitor@orcus
  /bin/cp \
    ${SCRIPT_DIR}/target/cinnamon/home/user/$home_path/settings.json \
    ~/$home_path/

  # Weather applet
  cd ${OPT_DLOADS}
  wget -N \
    http://cinnamon-spices.linuxmint.com/uploads/applets/E51P-PRLJ-G0D8.zip
  unzip E51P-PRLJ-G0D8.zip -d weather_applet
  /bin/rm -rf ~/.local/share/cinnamon/applets/weather@mockturtl
  mv weather_applet/weather@mockturtl \
     ~/.local/share/cinnamon/applets
  rmdir weather_applet

  home_path=.local/share/cinnamon/applets/weather@mockturtl
  /bin/cp \
    ${SCRIPT_DIR}/target/cinnamon/home/user/$home_path/metadata.json \
    ~/$home_path/

  # Screenshot applet
  cd ${OPT_DLOADS}
  wget -N \
    http://cinnamon-spices.linuxmint.com/uploads/applets/10JS-URQD-PS1K.zip
  unzip 10JS-URQD-PS1K.zip -d capture_applet
  /bin/rm -rf ~/.local/share/cinnamon/applets/capture@rjanja
  /bin/mv capture_applet/capture@rjanja \
     ~/.local/share/cinnamon/applets/
  rmdir capture_applet

  home_path=.local/share/cinnamon/applets/capture@rjanja
  /bin/cp \
    ${SCRIPT_DIR}/target/cinnamon/home/user/$home_path/metadata.json \
    ~/$home_path/

  # Cinnamon Multi-Line Taskbar

  # http://cinnamon-spices.linuxmint.com/applets/view/123
  # UUID: cinnamon-multi-line-taskbar-applet

  # FIXME: This applet doesn't seem to work. It's completely AWOL once
  #        installed.
  #
  # See also: http://cinnamon-spices.linuxmint.com/extensions/view/9
  #  There's a Cinnamon Extension called 2 Bottom Panels 0.1 that should
  #  do something similar, but it, too, doesn't work.
  #  ... fingers crossed on Mint 17! Or maybe these authors or another
  #  dev will pickup and fix these applets/extensions: if you're going
  #  to stay true to the Gnome 2 ethos, how can you not support a multi-
  #  row panel? After all, not everyone likes to use workspaces! (I like
  #  one workspace, and a taskbar that can handle a dozen plus windows.)
  #
  # See also: "Window List With App Grouping 2.7"
  #  http://cinnamon-spices.linuxmint.com/applets/view/16
  # http://cinnamon-spices.linuxmint.com/uploads/applets/3IDA-0443-B57M.zip
  # WindowListGroup@jake.phy@gmail.com
  # 

  if false; then
    
    cd ${OPT_DLOADS}
    wget -N \
      http://cinnamon-spices.linuxmint.com/uploads/applets/R9H5-FHOY-QOGM.zip
    unzip R9H5-FHOY-QOGM.zip -d multi_line_taskbar_applet
    /bin/rm -rf \
      ~/.local/share/cinnamon/applets/cinnamon-multi-line-taskbar-applet-master
    /bin/mv \
       multi_line_taskbar_applet/cinnamon-multi-line-taskbar-applet-master \
       ~/.local/share/cinnamon/applets/
    rmdir multi_line_taskbar_applet
 
    home_path=.local/share/cinnamon/applets/capture@rjanja
    /bin/cp \
      ${SCRIPT_DIR}/target/cinnamon/home/user/$home_path/metadata.json \
      ~/$home_path/

  fi

  # Show hidden Startup Applications.
  # http://www.howtogeek.com/103640/
  #   how-to-make-programs-start-automatically-in-linux-mint-12/
  # sudo /bin/sed -i \
  #   's/NoDisplay=true/NoDisplay=false/g' /etc/xdg/autostart/*.desktop

} # end: stage_4_wm_customize_cinnamon_part_1

stage_4_wm_customize_cinnamon_part_2 () {

  # Rearrange all applets
  #
  # As noted above, the multi-line taskbar doesn't work, so don't exchange
  # the built-in window list:
  #   'panel1:left:3:window-list@cinnamon.org:37',
  # for the hopefully-fixed-soon-but-currently-broken-multi-line-window-list:
  #   'panel1:left:3:cinnamon-multi-line-taskbar-applet-master:18',
  #
  # The user applet seems worthless: it just accesses the panel settings,
  # lets you toggle panel edit mode, and lets you log off, same as options
  # you can find elsewhere in other panel applets.
  #   'panel1:right:7:user@cinnamon.org:5',
  #
  # The notifications applet also smells like a waste of space.
  #   'panel1:right:5:notifications@cinnamon.org:36',
  #
  # [lb] is still looking for a better window list applet. I choose not to
  # accept that people don't or shouldn't use the minimize action on a
  # window. I have lots of terminal windows for different things and I'm not
  # a workspace kinduv guy.
  #
  #  Cinnamon default:
  #    'panel1:left:5:window-list@cinnamon.org:37',
  #  Don't work:
  #    'panel1:left:5:cinnamon-multi-line-taskbar-applet-master:24',
  #    'panel1:left:3:windowPreviewWindowList@dalcde:25',
  #  Double-click icon to maximize window... weird. And, why?
  #    'panel1:left:3:window-list@zeripath.sdf-eu.org:26',
  #
  # [lb] is also annoyed that he can't stack his window list using multiple
  # rows. Not only does that save space, but then I can have, e.g., a
  # terminal that takes the top half of the screen and is logged onto the
  # production server and tailing all the logs be one icon in the window
  # list, and below that icon is another terminal that takes the bottom half
  # of the screen and is tailing the local client application logs. Duh!
  #
  #  Possible alternative window list applet that doesn't like look crap when
  #  you've got tons of windows open:
  #    'panel1:left:3:WindowListGroup@jake.phy@gmail.com:21',

  if false; then
    gsettings set org.cinnamon enabled-applets \
      "['panel1:left:0:menu@cinnamon.org:0',
        'panel1:left:1:panel-launchers@cinnamon.org:2',
        'panel1:left:2:show-desktop@cinnamon.org:1',
        'panel1:left:3:window-list@cinnamon.org:37',
        'panel1:right:0:systray@cinnamon.org:12',
        'panel1:right:1:sysmonitor@orcus:29',
        'panel1:right:2:capture@rjanja:18',
        'panel1:right:3:sound@cinnamon.org:10',
        'panel1:right:4:network@cinnamon.org:9',
        'panel1:right:5:weather@mockturtl:17',
        'panel1:right:6:calendar@cinnamon.org:13']"
  else
    # Try this if you want to experiment with the window list that groups
    # windows by application. It's kind of like how Windows 7 groups
    # windows, but clicking the icon in the window list is different: You
    # can keep clicking the icon to minimize each successive application
    # window until they're all minimized: which means, unlike Windows 7,
    # clicking the icon does not bring up a list of the application's
    # windows; rather, you have to hover over the icon to see a row of
    # icons, but if you have a lot of windows open, the row extends
    # beyond the edges of the screen (WTF, it makes the applet kind of
    # useless). So, clicking the icon is different. Also, once all windows
    # are closed, then clicking just shows/hides the last non-hidden
    # application window. Also, there's no way to show all windows of an
    # application or to close all windows of an application.
    #
    # I guess I can try pinning gVim to all workspaces and just have
    # terminals on different work spaces?
    #
    # Interesting note: the number at the end of each string (after the
    # fourth colon) is just a unique ID? I notice that if two numbers
    # match, then only one applet appears, and maybe not where you
    # expect....
    gsettings set org.cinnamon enabled-applets \
      "['panel1:left:0:menu@cinnamon.org:0',
        'panel1:left:1:panel-launchers@cinnamon.org:2',
        'panel1:left:2:show-desktop@cinnamon.org:1',
        'panel1:left:3:WindowListGroup@jake.phy@gmail.com:21',
        'panel1:left:4:window-list@cinnamon.org:37',
        'panel1:right:0:systray@cinnamon.org:12',
        'panel1:right:1:windows-quick-list@cinnamon.org:28',
        'panel1:right:3:sysmonitor@orcus:29',
        'panel1:right:4:capture@rjanja:18',
        'panel1:right:5:sound@cinnamon.org:10',
        'panel1:right:6:network@cinnamon.org:9',
        'panel1:right:7:weather@mockturtl:17',
        'panel1:right:8:calendar@cinnamon.org:13',
        'panel1:right:9:workspace-switcher@cinnamon.org:31'
        ]"
  fi

  # Copy .desktop entry files before making them panel launchers.
  home_path=.cinnamon/panel-launchers
  /bin/mkdir -p /home/$USER/.cinnamon/panel-launchers
  # It's not quite this simple:
  #  /bin/cp \
  #   ${SCRIPT_DIR}/target/cinnamon/home/user/$home_path/*.desktop \
  #   ~/$home_path/
  # We can't use environment variables, and since some of the
  #   executables (like .fries/bin/*) live in the user's directory,
  #   we have to set the path according to the user name.
  # See also: http://heath.hrsoftworks.net/archives/000198.html
  #   "Enable for loops over items with spaces in their name."
  #   We don't really need to change IFS, but it's good form.
  #   ... unless you never use spaces in your file names.
  OLD_IFS=$IFS
  IFS=$'\n'
  # Huh. I guess the wildcard doesn't work in the quotes.
  #  for dir in `ls "${SCRIPT_DIR}/target/cinnamon/home/$home_path/*.desktop"`
  for dtop_file in `ls ${SCRIPT_DIR}/target/cinnamon/home/user/$home_path/*.desktop`;
  do
    #echo $dtop_file
    m4 --define=TARGETUSER=$USER \
      $dtop_file \
      > ~/$home_path/$(basename -- "${dtop_file}")
  done
  # Similar to: IFS=$' \t\n'
  IFS=$OLD_IFS
  # You can view the IFS using: printf %q "$IFS".

  # Rearrange the Panel launchers
  gsettings set org.cinnamon panel-launchers \
    "['firefox.desktop',
      'google-chrome.desktop',
      'gvim-ccp.desktop',
      'meld-ccp.desktop',
      'gnome-terminal.desktop',
      'openterms-all.desktop',
      'openterms-dbms.desktop',
      'openterms-logs.desktop',
      'openterms-logc.desktop',
      'gnome-screenshot.desktop',
      'dia-ccp.desktop',
      'acroread-ccp.desktop',
      'wireshark.desktop']"

  # Customize the Mint Menu: Change icon and remove text label.

  # MAYBE: Use sed instead, since you're just changing two values.
  home_path=.cinnamon/configs/menu@cinnamon.org
  /bin/cp -f \
    ${SCRIPT_DIR}/target/cinnamon/home/user/$home_path/menu@cinnamon.org.json \
    ~/$home_path/

  fi # end: if $WM_IS_CINNAMON

} # end: stage_4_wm_customize_cinnamon_part_2

# ==============================================================
# Application Main()

setup_customize_cinnamon_go () {

  if $WM_IS_CINNAMON; then
    stage_4_wm_terminal_white_on_black
    stage_4_wm_desktop_icons_hide
    stage_4_wm_customize_cinnamon_part_1
    stage_4_wm_customize_cinnamon_part_2
  fi

} # end: setup_customize_cinnamon_go

setup_customize_cinnamon_go

