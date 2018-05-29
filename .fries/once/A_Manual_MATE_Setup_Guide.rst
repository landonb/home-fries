##########################################################
Manual Linux Distro Onboarding Instructions For Developers
##########################################################

========
Overview
========

There are a few Linux stand up tasks that cannot be automated.

So, after running ``setup_mint.sh``, follow these steps.

=====================
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

 - Window List Content: Right-click empty space in Window List panel.
   Choose "Show windows from current workspace" if you'd like to not
   see all Windows from any workspace.

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
Another VIM             (from Add to Panel > Application Launcher... > Accessories)
---------------------   -----------------------------------------------------------------------
Termdub Dbms            (from Add to Panel > Custom Application Launcher)
---------------------   -----------------------------------------------------------------------
Termdub Topper          (from Add to Panel > Custom Application Launcher)
---------------------   -----------------------------------------------------------------------
Termdub Bottom          (from Add to Panel > Custom Application Launcher)
---------------------   -----------------------------------------------------------------------
Another VIM             (from Add to Panel > Application Launcher... > Accessories)
---------------------   -----------------------------------------------------------------------
Another VIM             (from Add to Panel > Application Launcher... > Accessories)
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
Digikam5                (from Add to Panel > Custom Application Launcher)
                        /srv/opt/bin/digikam5
                        ~/.icons/hicolor/48x48/apps/appimagekit-digikam.png
---------------------   -----------------------------------------------------------------------
Arduino IDE             (from Add to Panel > Custom Application Launcher)
                        /srv/opt/.downloads/arduino-1.6.12/arduino
                        ~/.local/share/icons/hicolor/48x48/apps/arduino-arduinoide.png
---------------------   -----------------------------------------------------------------------
Opera                   (from Add to Panel > Application Launcher... > Internet)
---------------------   -----------------------------------------------------------------------
GIMP Image Editor       (from Add to Panel > Application Launcher... > Graphics)
                        gimp-2.8 %U
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

- Chrome

  - HINT: If Chrome windows open but don't have focus, use a custom launcher::

    /home/user/.fries/bin/chrome_shim.sh

- Notes file in GVim, e.g.,::

    gvim --servername SAMPI --remote-silent path/to/notes.rst

  - Change default icon (e.g., ``/usr/share/icons/Mint-X/apps/48/vim.png``)
    to whatever of your choosing.

- Basic Terminal::

    /bin/bash -c "/usr/bin/mate-terminal"

  - Or more simply::

    mate-terminal

- Example Termdub::

    /bin/bash -c "${HOME}/.fries/bin/termdub.py -t dbms -x 1486 -y 0"

  - ``termdub.py`` is a wrapper that sizes and positions the terminal window.

See also:

.. code-block:: text

    $ dconf dump /org/mate/panel/objects/ | grep launcher-location
    launcher-location='mate-terminal.desktop'
    ...

    $ /bin/ls -1 ~/.config/mate/panel2.d/default/launchers
    firefox.desktop
    ...

===================
Add Browser Plugins
===================

-------
Gesture
-------

Juice up your mouse control with a gesture plugin.

- Mouse gesture plugins:

   - `Gestures for Mozilla Firefox
     <https://addons.mozilla.org/en-US/firefox/addon/firegestures/>`__

   - `CrxMouse for Google Chrome
     <https://chrome.google.com/webstore/detail/crxmouse/jlgkpaicikihijadgifklkbpdajbkhjo>`__

-----
HTTPS
-----

Be assertive and demand HTTPS when available.
your browser requests try to use https.

- Force-HTTPS plugins:

   - `HTTPS Everywhere for Firefox
     <https://www.eff.org/files/https-everywhere-latest.xpi>`__

   - `HTTPS Everywhere for Chrome
     <https://www.eff.org/https-everywhere>`__

--------------------
Backspace to go Back
--------------------

Google nixed the Backspace key as the "back" feature starting in Chrome 52.

http://venturebeat.com/2016/08/14/restore-backspace-shortcut-chrome/

Restore it!

- Backspace to go Back

  https://chrome.google.com/webstore/detail/backspace-to-go-back/nlffgllnjjkheddehpolbanogdeaogbc/related

- Back to Backspace

  https://chrome.google.com/webstore/detail/back-to-backspace/cldokedgmomhbifmiiogjjkgffhcbaec

NOTE: I don't have a preference to either plugin.
Both popped up when I searched for a solution.
I installed "Backspace to go Back" and it worked.

------------
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

-------------------
The Great Suspender
-------------------

- Buy yourself some time on closing all them tabs.

  `The Great Suspender [for Chrome]

  <https://chrome.google.com/webstore/detail/the-great-suspender/klbibkeccnjlkjkiokjodocebajanakg?hl=en>`__

---------------
Reload All Tabs
---------------

Useful if you open lots of tabs to a service that uses cookies that
time out everyday, so you don't have to manually reload a bunch of
tabs to refresh their cookies.

- `Reload All Tabs [for Chrome]

  <https://chrome.google.com/webstore/detail/reload-all-tabs/midkcinmplflbiflboepnahkboeonkam/related?hl=en>`__

-----
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

------------
Center Image
------------

- Center image in window.

  - `Image in the center
    <https://chrome.google.com/webstore/detail/image-in-the-center/kcpejamelebpigblebnbabhndaaffjok?hl=en>`__

----------
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

---------------------
Switcheroo Redirector
---------------------

Redirect URLs within Chrome.

Specifically, there are some sites that don't work for me, or, they
seem to work, but don't. E.g., a certain financial website I use
sends my Chrome to their mobile browser, which is confusing at first
because it seems like it works, but it seems overly simple, and
then you realize you can't do certain things, like Autopay. But I ramble.

- https://chrome.google.com/webstore/detail/switcheroo-redirector/cnmciclhnghalnpfhhleggldniplelbg?hl=en

  https://github.com/ranjez/Switcheroo

After installing, you'll see an 'S' button to the right of the location bar.

Click it and add your rickrollredirect.

``https://www.stupidbank.com`` -> ``https://www.youtube.com/watch?v=dQw4w9WgXcQ``

--------------------
Scrum for Trello.com
--------------------

http://scrumfortrello.com/

- Chrome

  https://chrome.google.com/webstore/detail/scrum-for-trello/jdbcdblgjdpmfninkoogcfpnkjmndgje

--------------------------------------
Chrome tabbed landing page replacement
--------------------------------------

It doesn't seem like you have much control of the Chrome landing
page that shows 8 icons of the most visited web sites. You can
basically remove items from the list, but you cannot restore items
without restoring all hidden items. And you cannot promote your owns
sites to the list.

"Speed Dial" replaces the landing page and offers much more control.

https://chrome.google.com/webstore/detail/speed-dial-fvd-new-tab-pa/llaficoajjainaijghjlofdfmbjpebpa?brand=CHBD&gclid=EAIaIQobChMI993or42i1QIV1YKzCh2YUAPNEAAYASABEgJcHfD_BwE&dclid=CO7gqrGNotUCFU1YDAodJ5oFzw

======================
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

