##########################################################
Manual Linux Distro Onboarding Instructions For Developers
##########################################################

.. Author: Landon Bouma
.. Last Modified: 2016.10.19
.. Project Page: https://github.com/landonb/home_fries

Overview
========

There are a few Linux stand up tasks that cannot be automated.

So, after running ``setup_mint.sh``, follow these steps.

Configure MATE Panels
=====================

Configure MATE panel(s).

- You might like a two-panel setup to make the best use of space:

   - One panel on the bottom with panel launchers on the left,
     and the notification, system monitor, weather and time
     applets on the right.

   - And a second panel atop the first with just the Window List
     applet. Make the panel 54 pixels tall to make two rows of
     window buttons.

 - Or do whatever you want — group windows, use workspaces,
   whatever makes you happiest.

Landon's Preferred Panel Layout
-------------------------------

This is the author's layout, from left to right in the bottom-most panel.

=====================   =======================================================================
**Left-justified**
-----------------------------------------------------------------------------------------------
mintMenu                (from Add to Panel)
---------------------   -----------------------------------------------------------------------
Show Desktop            (from Add to Panel)
---------------------   -----------------------------------------------------------------------
Firefox Web Browser     (from Add to Panel > Application Launcher... > Internet)
---------------------   -----------------------------------------------------------------------
Google Chrome           (from Add to Panel > Application Launcher... > Internet)
---------------------   -----------------------------------------------------------------------
Dubsacks VIM            (from Add to Panel > Application Launcher... > Accessories)
---------------------   -----------------------------------------------------------------------
Terminal                (from Add to Panel > Application Launcher... > System Tools)
---------------------   -----------------------------------------------------------------------
OpenTerms               (from Add to Panel > Custom Application Launcher)
---------------------   -----------------------------------------------------------------------
Termdub Dbms            (from Add to Panel > Custom Application Launcher)
---------------------   -----------------------------------------------------------------------
Termdub Logs            (from Add to Panel > Custom Application Launcher)
---------------------   -----------------------------------------------------------------------
Termdub Logc            (from Add to Panel > Custom Application Launcher)
---------------------   -----------------------------------------------------------------------
Meld                    (from Add to Panel > Application Launcher... > Programming)
---------------------   -----------------------------------------------------------------------
Wireshark               (from Add to Panel > Application Launcher... > Internet)
---------------------   -----------------------------------------------------------------------
Adobe Reader 9          (from Add to Panel > Application Launcher... > Office)
---------------------   -----------------------------------------------------------------------
Oracle VM VirtualBox    (from Add to Panel > Application Launcher... > System Tools)
---------------------   -----------------------------------------------------------------------
Spotify                 (from Add to Panel > Application Launcher... > Sound & Music)
---------------------   -----------------------------------------------------------------------
Dia                     (from Add to Panel > Application Launcher... > Graphics)
---------------------   -----------------------------------------------------------------------
Take Screenshot         (from Add to Panel > Application Launcher... > Accessories)
---------------------   -----------------------------------------------------------------------
Chromium                (from Add to Panel > Application Launcher... > Internet)
---------------------   -----------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
**Right-justified**
-----------------------------------------------------------------------------------------------
Notification Area       (from Add to Panel)
---------------------   -----------------------------------------------------------------------
System Monitor          (from Add to Panel)
---------------------   -----------------------------------------------------------------------
Weather Report          (from Add to Panel)
---------------------   -----------------------------------------------------------------------
Clock                   (from Add to Panel)
=====================   =======================================================================

All launchers:

- Clear Comments.

Custom launchers:

- Dubsacks gVim/GVim:
  - ``gvim --servername SAMPI --remote-silent path/to/notes.rst``
  - Icon: Was default for a while: ``/usr/share/icons/Mint-X/apps/48/vim.png``
    Now: Personalized. I store icons I've used under ``/home/landonb/.fries/once/assets/``.
.. 2016-04-20: I tried a waffle, then a penis, then cheese.
..   http://www.flaticon.com/free-icon/waffle_93098#term=waffle&page=1&position=2
..   http://www.flaticon.com/free-icon/round-waffle_78774#term=waffle&page=1&position=3
..   http://www.flaticon.com/free-icon/penis_105392#term=penis&page=1&position=1
..   http://www.flaticon.com/free-icon/penis_105428#term=penis&page=1&position=2
..   http://www.flaticon.com/free-icon/cheese_89418#term=cheese&page=1&position=32
.. cheese-outline-stylized-NARROWER-000000-Hand.Drawn.Goods-food.svg

- Terminal:
  - ``/bin/bash -c "FORCE_JAILED=false /usr/bin/mate-terminal"``

- OpenTerms:
  - 2016.04.20: See install_openterms_mate_menu in ``.fries/once/*.private.*.sh``
    To prevent accidentally pressing it and having to ``exit`` a dozen terminals,
    we add it to the 'Programming' section of the MATE Menu instead.
    - In lieu of this applet, I've added a second gvim launcher for work notes,
      so I can have better separation between the two (and not obsess about
      a Very Dirty notes file as much if it's, say, just my personal notes and
      not my work notes that are dirty).
      - Icon: Like the other GVim launcher, personalize it.
.. 2016-04-20: I tried a brick wall (48/firestarter.png), then dog poo, then rats to cheese it.
..   http://www.flaticon.com/free-icon/dog-poop_103727#term=poop&page=1&position=2
..   http://www.flaticon.com/free-icon/dog-poo_91529#term=poo&page=1&position=1
..   http://www.flaticon.com/free-icon/pile-of-dung_64552#term=poop&page=1&position=1
..   http://www.flaticon.com/free-icon/dog-shitting_53131#term=poop&page=1&position=3
..   http://www.flaticon.com/free-icon/mouse-frontal-animal-head-outline_58428#term=mouse&page=4&position=33
..   http://www.flaticon.com/free-icon/rat-head-outline_29703#term=mouse&page=4&position=65
..   USING: http://www.flaticon.com/free-icon/rat-silhouette_47240#term=rat&page=1&position=3
..   http://www.flaticon.com/free-icon/rat-looking-right_84446#term=rat&page=1&position=4
.. - The old instructions:
..   - ``/home/<USERNAME>/.waffle/bin/openterms.sh 1024 0``
..   - Icon: ``/usr/share/icons/Mint-X/apps/48/abrt.png``
..           ``/usr/share/icons/matefaenza/apps/48/abrt.png``
.. mouse-rat-solid-000000-Freepik-animals-Rat.looking.right-animal.svg
.. mouse-rat-solid-000000-Freepik-animals-Rat.silhouette-shape.svg

- Termdub Dbms:
  - ``/bin/bash -c "FORCE_JAILED=false /home/<USERNAME>/.fries/bin/termdub.py -t dbms"``
  - Icon: ``/usr/share/icons/Humanity/apps/48/utilities-terminal.svg``

- Termdub Logs:
  - ``/bin/bash -c "FORCE_JAILED=false /home/<USERNAME>/.fries/bin/termdub.py -t logs"``

- Termdub Logc:
  - ``/bin/bash -c "FORCE_JAILED=false /home/<USERNAME>/.fries/bin/termdub.py -t logc"``

.. 2016-10-19: New links.

- Termdub Dbms:
  - ``/bin/bash -c "FORCE_JAILED=false ${HOME}/.fries/bin/termdub.py -t dbms -x 1486"``

- Termbud Toppers:
  - ``/bin/bash -c "FORCE_JAILED=false DUBS_STARTIN=$(readlink ~/.waffle/work/user-current-project) ${HOME}/.fries/bin/termdub.py -t dbms -x 1486"``

- Termdub Bottoms:
  - ``/bin/bash -c "FORCE_JAILED=false DUBS_STARTIN=$(readlink ~/.waffle/work/user-current-project) ${HOME}/.fries/bin/termdub.py -t dbms -x 0 -y 1080"``

See also:

.. code-block:: text

    $ dconf dump /org/mate/panel/objects/ | grep launcher-location
    launcher-location='mate-terminal.desktop'
    ...

    $ /bin/ls -1 ~/.config/mate/panel2.d/default/launchers
    firefox.desktop
    ...

Add Browser Plugins
===================

Gesture
-------

Juice up your mouse control with a gesture plugin.

- Mouse gesture plugins:

   - `Gestures for Mozilla Firefox
     <https://addons.mozilla.org/en-US/firefox/addon/firegestures/>`__

   - `CrxMouse for Google Chrome
     <https://chrome.google.com/webstore/detail/crxmouse/jlgkpaicikihijadgifklkbpdajbkhjo>`__

HTTPS
-----

Be assertive and demand HTTPS when available.
your browser requests try to use https.

- Force-HTTPS plugins:

   - `HTTPS Everywhere for Firefox
     <https://www.eff.org/files/https-everywhere-latest.xpi>`__

   - `HTTPS Everywhere for Chrome
     <https://www.eff.org/https-everywhere>`__

Center Image
------------

- Center image in window.

  - `Image in the center
    <https://chrome.google.com/webstore/detail/image-in-the-center/kcpejamelebpigblebnbabhndaaffjok?hl=en>`__

Regex
-----

Regular Expression Browser Search plugins.

Note: The Firefox plugin froze my browser for a few seconds while searching
`the nightly HTML spec
<http://www.w3.org/html/wg/drafts/html/master/single-page.html>`__.
The Chrome plugin works well, though.

- `Regex Find for Firefox
  <https://addons.mozilla.org/en-us/firefox/addon/regex-find/>`__

  - ``Ctrl-F`` like you normally would, and
    click the *Regex* button in the find bar.

- `Regex Search for Chrome
  <https://chrome.google.com/webstore/detail/regex-search/bcdabfmndggphffkchfdcekcokmbnkjl/related?hl=en>`__

  - Type ``Alt+Shift+F`` to open the finder, and
    ``Enter`` and ``Shift-Enter`` to navigate.

Ctrl+Shift+C
------------

[lb] often accidentally types Shift+Ctrl+C in the browser because that's
the copy command in the terminal. But in both Chrome and Firefox, that
key command is mapped to opening developer tools. To avoid accidentally
opening or switching to developer tools when you meant to copy the selected
text, remap the key command.

- `Keyboard Remapper for Chrome
  <https://chrome.google.com/webstore/detail/shortkeys-custom-keyboard/logpjaacgmcbpdkdchjiaagddngobkck?hl=en-US>`__

  - NOTE: 2016.04.10: I don't think I found a plugin for Chrome the last
    time I checked, which was probably last summer, but I found one today.
    However, copying to clipboard isn't one of the possible commands (maybe
    because Chrome doesn't let plugins do that?), but at least you can run
    custom JavaScript.

  - Keyboard Shortcut: ``shift+ctrl+c``

  - Behavior: "Run JavaScript"

  - Javascript [sic] code to run (note that JS cannot copy to clipboard):

.. code-block:: javascript

    function get_selection_text() {
        var text = 'ERROR: ctrl+shift+c: could not determine selection';
        if (window.getSelection) {
            text = window.getSelection().toString();
        }
        else if (document.selection && document.selection.type != 'Control') {
            text = document.selection.createRange().text;
        }
        return text;
    }
    var text = get_selection_text();
    //alert(text);
    window.prompt('Copy to clipboard: Ctrl+C, Enter', text);

- `Customize (Keyboard) Shortcuts for Firefox
  <https://addons.mozilla.org/en-US/firefox/addon/customizable-shortcuts/>`__

- Remap ``Ctrl-Shift-C``.

  - By default, it brings up the Firefox Developer Tools Inspector,
    but you might find yourself typing it by accident, because
    that's how you copy selected text from the terminal.

  - You could, e.g.,
    change the Inspector shortcut
    from ``Ctrl+Shift+C`` to ``Ctrl+Shift+D``,
    and also remap Console
    from ``Ctrl+Shift+K`` to ``Ctrl+Shift+X``
   (obscuring Text Switch Directions, which is not a feature
   you'll probably use if you stick to Latin text).

Keep Alive
----------

For financial and other security-forward Web sites, it's annoying when
you're in a safe place and you're constantly logged out of what you're
working on because you haven't refreshed a window recently.

- `ReloadEvery for Firefox
  <https://addons.mozilla.org/en-us/firefox/addon/reloadevery/contribute/roadblock/?src=dp-btn-primary&version=45.0.0>`__

  - Right-click on page to choose a reload frequency for a page.

- `Staying Alive for Chrome
  <https://chrome.google.com/webstore/detail/staying-alive-for-google/lhobbakbeomfcgjallalccfhfcgleinm/related?hl=en-US>`__

  - Navigate to
    `chrome-extension://lhobbakbeomfcgjallalccfhfcgleinm/settings.html`
    and make rules as necessary.

Configure Web Browsers
======================

A few ideas for configuring Firefox and Chrome:

- Tell 'em both to start with tabs and windows from last time.

- Set the homepages however you like.

- Tell Firefox not to warn when closing multiple tabs, or that
  many tabs might slow down the machine (silly warnings).

- Hide the Firefox menu bar to gain a little vertical space.

- Linux Mint 16 gets revenue by using Yahoo as the default Firefox
  page and search engine. But you can always enable Google:

  - http://www.linuxmint.com/searchengines.php

  - Then click on the Google icon beneath "Commercial Engines"
    
  - (The page is
    http://www.linuxmint.com/searchengines/anse.php?sen=Google&c=y
    but it is blank unless loaded from the base page.)

In ``chrome://settings/``:

- On startup: [Select] Continue where you left off
  
- Appearance: [Deselect] Use system title bar and borders

Configure Meld Preferences
==========================

Note: The meld settings are written to ~/.gconf/apps/meld/%gconf.xml.

(And while we could maybe just copy/paste that file, since Meld
changes between distros, it's probably wiser/easier to just do
this manually.)

Run Meld. Choose Preferences from the Meld menu. Click File Filters tab.

#. Dubsacks Vim / Home Fries

    - Title:

      Dubsacks Vim / Home Fries

    - Paths:
      
    cmdt_paths dubs_cuts id_inner_a611_rsa* id_inner_bes_rsa* known_hosts fries-setup-mysql.pwd authorized_keys .trash .cache openterms.sh hamster-* hamster.bkups environment master_chef cron.daily cron.weekly cron.monthly Baby_Tubes_Files Backpacking_Files Bike_Files Bouma_Assets_II_FIXME Cooking_and_Consuming_Files Gaming_Files Health_Files Job_Hunting_Files Names_and_Faces_Files Packlists_Files Pending_Files Photography_Files

#. Python bytecode

    - Title:

      Python bytecode

    - Paths:

      __pycache__

#. Cyclopath

    - Title:

      Cyclopath

    - Paths:

      FW.build_main.mxml.pid

#. tags

    - Title:

      tags

    - Paths:

      tags

Other Steps
===========

I didn't move everything to this file, just the stuff
I figured I'd always want.

See: A_General_Linux_Setup_Guide_For_Devs.rst

- Gmail notifier plugin [maybe browser toast notifications are good enough?]

- Add Gmail account to Pidgin [I've been having Pidgin issues lately;
  I've heard that I always appear offline?]

- Relay Postfix Email via smtp.gmail.com [doesn't seem necessary
  unless I was to write an app or service to needs to email]

