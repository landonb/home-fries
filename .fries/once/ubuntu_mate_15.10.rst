#######################
#!/bin/bash
#######################
Or is this a reST file?

.. 2016-03-13: For a private password keeper trapper machine,
               I did the following.

VirtualBox New Machine
======================

 - The Wizard setup is simple.
  
   - Give the machine a proper name and the
     OS and 32- or 64-bitness is detected.

       E.g., My Linux Mint x64

       E.g., My Ubuntu MATE 17.10

   - For RAM, I chose 3840 (768 was suggested so I just timesed 5).

   - Make a dynamic virtual drive.

   - Increase the disk size or you'll cap out.

     The default is 8.00 GB, which is tiny. Go big: 1.00 TB.

   - Double check that the image is being saved to the location
     and you want.

 - After finishing the Wizard, adjust the new machine's settings.

   - Shared Clipboard: Bidirectional
  
   - Base Memory: 4096 MB or what you will, maybe just 3840

   - Processor(s): I'm generally happy sharing 2 of the 4

   - Execution Cap: Live on the edge. Full throttle. 100%

   - Video Memory: Max it out. 128 MB

   - Network Adapter 1: Normally I'd set this to Bridged, but
                        for now we'll use NAT (the default)
                        and then once our OS is updated
                        we'll *disable* networking
                        and use just shared folders
                        and the shared clipboard
                        to let the sacred machine
                        communicate with the outside
                        world.

   - Shared Folders: Make paths to all your favorites;
                      use Auto-mount
                      and Full Access.

       E.g., /home/$USER

       E.g., /au_jus

       (Later, you'll find these at, e.g., /media/sf_$USER and /media/sf_au_jus)

   - User Interface: Mini Toolbar: NO: Show in Full-screen/Seamless

 - A note about Encryption:

   - Before Oracle VirtualBox, I just used Ubuntu's full disk
     encryption when setting up the machine.

     But now you can also choose to encrypt the whole machine.

     For the purposes of setting up a machine for securewords,
     it wouldn't seem to matter whether the disk was encrypted,
     or whether the virtual machine was encrypted... except if
     the machine is encrypted you could potentially hide what
     OS is installed, or maybe you have a secret BIOS no one
     has, but really there shouldn't really be a difference.

     - Choose one of the other, or both.

     - I chose the AES-XTS256-PLAIN64 cipher.

     - 2016-03-23: I had to try again because of an error and didn't
       use VM encryption but still used LVM encryption, and then I
       added home folder encryption (so still twice encrypted), but
       I think the problem was that I didn't resize the dynamic disk
       from the default 8 GB maximum to something larger, like 1.00 TB.

       So I think VM encryption works if you want to try it next time.

Live Installer
==============

 - "Download updates while installing"

     Usually I wait and do it manually later, in case
     the installation fails or I want to start over.

 - "Install this third-party software"

     For a development machine, sure,
     but for a keypasskeep, don't do it.

 - "Encrypt the new Ubuntu MATE installation for security"

     For a keepasskeep, always.
     For a laptop host, generally always.
     For a desktop host, it's up to you.
     - I've never noticed a performance hit.

     2016-03-23: I'm trying VirtualBox's new VM encryption.
     Should I also do OS encryption? It can't hurt to try!

 - "Use LVM with the new Ubuntu MATE installation"

     Logical Volume Management lets you take snapshots.

     The downside is that it might impact performance.

     Since it's easy for me to setup this VM and OS,
     and since I backup outside the VM often, I'm not
     going to want LVM.

     Except that LVM is mandatory is you encrypt....

     Oh, whatever, LVM probably doesn't impact performance
     unless you have tons of snapshots or something.

     Ref: "Detailed study on Linux Logical Volume Manager"
           https://www.flux.utah.edu/download?uid=176
           Prashanth Nayak, Robert Ricci
           Flux Research Group Universitiy [sic] of Utah
           August 1, 2013

 - "Who are you?"

     Log in automatically: Is there a point not to use this unless
     you're encrypting your home folder? If people got past the VM
     and the disk encryption you're probably already boned. So make
     your life easier and bypass the OS log in prompt.

Reboot.
-------

- The reboot hangs on an error.

.. code-block:: bash

                    Ubuntu MATE
                     .  .  .  .   26.873142 piix4_smbus 0000:00:07.0:
      SMBus base address unitialized - upgrade BIOS or use force_addr=0xaddr
   [   27.088790] intel_rapl: no valid rapl domains found in package 0
   [   27.300745] intel_rapl: no valid rapl domains found in package 0

Resetting the VM machine works.

Notice a few things.
--------------------

A few things.

 - The Live CD should have automatically unmounted.

 - Wait to hide the VM menu bar until after installing Guest Additions.

 - Shared Clipboard won't work until VBox Additions is installed.

Setup Linux
===========

Terminal
--------

Open a MATE Terminal (via Applications > System Tools,
           or right-click desktop and use context menu)

 - Turn off Show Menu Bar, if you want.

 - Set Profile Preferences:
  
   x Allow bold text

   o Show menubar by default in new terminals

   o Terminal bell

   Built-in schemes: White on black

   Scrollback: Unlimited

Pre-Scripted Setup
------------------

Update and Upgrade the OS
^^^^^^^^^^^^^^^^^^^^^^^^^

.. code-block:: bash

    # Type these. Manually. You can't paste. Ha!
    # At least tab-completion works for gsettings, cool!

    # First, so you don't get prompted when you disengage during upgrade.
    gsettings set org.mate.screensaver idle-activation-enabled false
    gsettings set org.mate.screensaver lock-enabled false

    # Second, update and upgrade.
    
    # 2016-03-23: `sudo apt-get update` terminates early with an error.
    #               "E: dpkg was interrupted, you must manually run
    #                'sudo dpkg --configure -a' to correct the problem."
    sudo dpkg --configure -a
    sudo apt-get update
    sudo apt-get upgrade
    sudo apt-get install dkms build-essential

(I rebooted now, but I think you can wait to reboot.)

Install Guest Additions
^^^^^^^^^^^^^^^^^^^^^^^

Insert the Guest Additions CD by selecting its menu item.

 - Devices > Insert Guest Additions CD Image...

Install Guest Additions and add the `vboxsf` user.

.. code-block:: bash

    pushd /media/$USER/VBOXADDITIONS*
    sudo sh ./VBoxLinuxAdditions.run

    # Do this now so we don't have to logout/reboot again later.
    sudo usermod -aG vboxsf $USER

Reboot the machine.

We're almost there
^^^^^^^^^^^^^^^^^^

Yeah, now the bidirectional clipboard works!

Setup home-fries and Dubsacks Vim.

.. code-block:: bash

    # Grab the goodies!

    #/bin/cp -ar /media/$USER/
    pushd ~/Downloads

    # You could clone from a local source if you prefer.
    #git clone /media/sf_$USER/ home-fries
    # But if the github repo is up to date, just use that.
    git clone https://github.com/landonb/home-fries home-fries

    /bin/cp -ari ~/Downloads/home-fries/ /home/
    # /home/$USER/.bashrc should be the only conflict.


Install Dubsacks Vim immediately, if you want, or don't
and let the setup script install it.

.. code-block:: bash

    sudo apt-get install -y vim-gtk git git-core
    # 2016.03.23: I was copying locally at first, but really what's on
    #             github is golden, so don't specify a local git path.
    #export URI_DUBSACKS_VIM_GIT=/media/sf_$USER/.vim
    source ~/.fries/once/vendor_dubsacks.sh
    stage_4_dubsacks_install

    # Note that home-fries uses the developer Dubsacks link
    # (points to bundle_/). Fix that.
    pushd ~
    /bin/ln -sf .vim/bundle/dubs_all/.vimrc.bundle .vimrc

If you're replicating your dev machine, copy its privates.

.. code-block:: bash

    /bin/cp -rn ~/.waffle/home/.gitconfig ~/

    pushd ~/.fries/.bashrc
    /bin/cp -L ~/.waffle/home/.fries/.bashrc/bashrx.private.$USER.sh .

Setup Home-Fries
================

.. code-block:: bash

  pushd ~/.fries/once/
  export INCLUDE_ADOBE_READER=false
  ./setup_mint17.sh

Dev Hints
=========

When setting up a VirtualBox image, it's easy to update
the setup scripts on the host and just copy over changes.

However, you'll need to go through git. Trying to avoid
git would be a pain, since the repo is overlayed atop the
user's home directory.

.. code-block:: bash

    dubspdate () {
        pushd ~/Downloads/home-fries/
        git pull
        /bin/rm -rf ~/.git
        /bin/cp -ar ~/Downloads/home-fries/ /home/
        popd
    }
    dubspdate

Post sec ops
============

Ubuntu gives you an out if you forget your account password
and cannot otherwise decrypt your home directory.

.. code-block:: bash

    mkdir ~/.fries/.crunch
    # I tried to get around passphrase always asking for your password
    # by using expect, but if a passphrase has $ in it, I couldn't get
    # bash not to interpolate it, even trying single instead of double
    # quotes and also trying to escape the dolla dolla sign, yo.
    ecryptfs-unwrap-passphrase
    # Copy and paste your blah and add the recovery code to your special
    # export.
    echo 'blah' > ~/.fries/.crunch/islandmine.ecryptfs-unwrap-passphrase.txt

Post dev clone
==============

If you want a real dev machine clone, clone appropriate development directories.

For instance, the Dubsacks Vim instance installed by default is
the official all-in-one distribution -- where the modules are all
submodules. Copy the real deal if you expect to edit Vim files and
want to push them to their appropriate projects and not the master
project.

.. code-block:: bash

    pushd ~
    /bin/rm -rf ~/.vim
    /bin/cp -ar /media/sf_$USER/.vim ~/
    /bin/ln -sf .vim/bundle_/dubs_all/.vimrc.bundle_ .vimrc

Caveats
=======

- On boot, I see error messages after entering my password.

  E.g., "cryptsetup: unknown fstype, bad password or options?"

  So far I don't know that this causes any issues
  and can probably be (safely) ignored.

  https://bugs.launchpad.net/ubuntu/+source/cryptsetup/+bug/1481536

Laptop Install
==============

Follow most of the instructions above, with the following modifications:

- Obviously, skip the initial VirtualBox step.

- The easiest way to run the Live CD is to find a big enough USB
  stick and use that.

  See: A_General_Linux_Setup_Guide_For_Devs.rst
  Find: "Make a Bootable USB"

- Choose to encrypt the user home directory, and then verify
  that an encrypted swap space was also setup.

  Caveat: Make sure all of your sensitive files live under your
  home directory.

- Otherwise everything's pretty similar....

References
==========

https://en.wikipedia.org/wiki/MATE_(software)#Software_components

OS Diatribe
===========

Anecdotally: Ubuntu MATE is slower to boot than Linux Mint MATE.
I've read the Ubuntu is in general a little slower than Mint, but
I've only noticed this with Ubuntu on my laptop (which is both the
only placed I've installed Ubuntu MATE so far and also a machine that's
six years old at this point) -- Mint would literally boot in tens or twenty
seconds; Ubuntu takes a minute or two. I can't vouch for development
performance because Ubuntu MATE on my laptop is the first time I've used
an encrypted home directory.

Funnily enough, I moved from early Mac OS (7x) to middle Mac OS (9x),
skipped the OS X revolution, jumped to Windows when it was finally
somewhat tolerable (XP SP2 came out soon after I got a job writing
Windows device drivers, albeit I still had to support older consumer
versions, like Windows 98 (actually a decent OS, but only with SPAK2,
which seemed to be a Microsoft theme -- the first release sucks, wait
for the right service pack) and Windows ME (a shitshow), and I also had
to support enterprise versions like Windows NT and Windows 2000 (don't
get me started; these were horrible beasts), and then I jumped from Windows
to Linux once Linux had matured and Windows was shooting itself in the foot
by trying to be "innovative" (Windows XP SP2 was followed by the disastrous
Windows Vista rollout, but, again, a later service pack (SP1? I think) corrected
that, and then Windows 7 was a true beauty! But then Windows 8 (a stepping
stone?) was released, and then Windows 10, and everything went to shit;
fortunately I had found Linux Mint MATE (around the time of Ubuntu fucking
itself with GNOME 3/Unity) and later found Ubuntu MATE. Now here's to hoping
they stop innovating OSes, at least drastically, because all my stand up scripts
run great and I hate having to figure out how to customize new OSes every time
they're released and I find myself without other options (such as sticking with
what works and what I like!).

Also note that with Windows 7, I'm given a year to upgrade for free to Windows 10.
I did so on my laptop but never run Windows 10. I repartitioned the drive to
give half to Windows and the other half to Linux (and would have given more to
Linux if the partition tool let me), and then I upgrade from Windows 7 to Windows 10,
though now I wish I just overwrote the recovery partition and the ``ntfs`` partition
and just went all-out-balls-to-the-chassis linux. Anyway, I never run Windows, and
I choose not to upgrade the other Windows installation on my desktop machine (so I'll
lost my Windows license there) but I rarely run Windows. Recently, it's just to run
the Webex application, and I can do that through VirtualBox with one of the free
Internet Explorer/MS Edge developer images. But even then, VBox runs soooo slow --
I can run my host OS and two Linux VBoxes at once, but when I run a Windows virtual
machine, I gotta kill all other virtual machines, and I even have to quit Firefox
or Chrome in the host to reclaim enough memory to run Windows without grinding to
a halt, and even then the host CPU usage is so stressed when running Windows;
seriously, fuck that OS. And fuck Mac OS, too, for locking so many people into
the "Windows alternative" -- yes, Windows sucks, but Mac OS isn't your only
retreat. Linux has a steep learning curve, for sure, but once you're there,
you're there -- in a sense, schools could teach Linux and kids would *quickly*
get it and then in a generation or two Mac and Windows would lost their monopoly
(or is it monopolies? they're pretty much in collusion).

