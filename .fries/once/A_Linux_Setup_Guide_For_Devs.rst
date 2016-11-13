==========================================
A General Linux Setup Guide For Developers
==========================================

.. Author: Landon Bouma
.. Last Modified: 2016.11.12
.. Project Page: https://github.com/landonb/home_fries

Overview
--------

This is a tedious guide to setting up a Linux development
machine, either in a virtual machine or natively.

Much of the setup is automated, but not everything.

You can skip this guide if you've got your own
methods for installing and configuring Linux.

If you're just looking for the automated goodies,
check out ``setup_ubuntu.sh`` in the same directory
as this file.

Install Linux
-------------

VirtualBox vs. Native
^^^^^^^^^^^^^^^^^^^^^

First decide if you'd like to setup Linux natively or within
a virtual machine.

VirtualBox is great if you'd like to setup Linux quickly and not
have to mess around with hardware. And if your machine runs another
OS, like Windows or Mac OS, VirtualBox (or another virtualizer) is
pretty awesome, because you can easily jump between OSes.

But be aware, especially if you're on a laptop or a machine without
too many resources to spare. The VM can usually only use up to half
of the processors cores, which usually isn't a problem, except when
you're compiling lots of code. Nonetheless, it's easy to get a VM
running, and if you find a problem with performance in the future,
then you can decide if you want to go native.

Download Linux
^^^^^^^^^^^^^^

`Download the 64-bit Ubuntu 14.04 (Trusty Tahr) desktop installer
<http://releases.ubuntu.com/14.04/>`__
or your favorite binary-compatible distribution,
such as `Linux Mint 17.1 "Rebecca" - Mate (64-bit)
<http://www.linuxmint.com/edition.php?id=174>`__.

- Be sure to get the desktop install image and not the server installer.
  The latter doesn't include a modern desktop environment.

Setup VirtualBox or a Bootable USB
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Install VirtualBox
~~~~~~~~~~~~~~~~~~

.. note:: Follow these instructions if you'd like to use a
          virtual machine, otherwise skip this section.

Download `VirtualBox <https://www.virtualbox.org/wiki/Downloads>`__
and install it on your host machine.

Create a 64-bit Ubuntu machine.

.. todo:: Document VM setup and options

If your host OS does not natively support mounting ISO files
(ahem, Windows), download and install an ISO mounter.

- For Windows, try the wonderful
  `MagicISO Virtual CD/DVD-ROM
  <http://www.magiciso.com/tutorials/miso-magicdisc-overview.htm>`__
  tool.

Mount the Linux installer ISO and fire up the virtual machine.

.. note:: You may have to reboot into the BIOS and enable
          processor virtualization.

Install Linux.

.. todo:: Document Linux install and options.

Skip to the section `Configure Linux to Your Taste`_.

Make a Bootable USB
~~~~~~~~~~~~~~~~~~~

.. note:: Follow these instructions if you'd like to install
          Linux natively on your hardware. But if you've installed
          VirtualBox, skip this section.

Linux Mint includes a great tool, *USB Image Writer*, that'll
write the Linux ISO to a USB stick that you can use to boot
your machine and install Linux.

- Use the tool to write the Linux ISO you downloaded to a USB stick.

If you don't already have access to Linux Mint, ask someone
else to burn the stick for you, or just install Lint Mint in
VirtualBox and find the tool that way.

- If you're running Windows or Mac OS, you can install VirtualBox,
  boot up the Linux ISO, and use the tool from within the VM.

  - You'll have to eject the USB device from the host OS first,
    and then the VM will see it.

You can also try creating the USB from Windows or Mac OS, but
you may have a problem creating the stick from Windows: it might
only offer two format options for USB sticks: ``ntfs`` and ``exFAT``.
But the stick needs to be formatted in the classic ``FAT`` format,
and many machines won't boot unless the stick is formatted as such.
So if you try formatting the stick using an application on Windows
and it doesn't work, you'll want to try again using
*USB Image Writer*.

Create a Dual-Boot Laptop
^^^^^^^^^^^^^^^^^^^^^^^^^

.. note:: Follow these instructions if you'd like to setup a
          dual-boot machine. Skip this section if you're using
          VirtualBox or if you don't care to dual-boot.

If you'd like to install Linux directly on the hardware and skip
virtualization, you can obviously just wipe a drive and use that,
but if you've got a laptop that comes with Windows, you might want
to keep access to Windows applications. (Same for Mac OS but these
aren't instructions for setting up a dual-boot Mac machine.)

If you'd like to setup a dual boot laptop, follow these steps.

#. First backup all your files and copy them elsewhere.

#. Next, restart and boot into your recovery partition.

   - Assuming that your laptop has one.

   - E.g., on Lenovo Thinkpads, you'll find a ``Q:\``
     partition with recovery files on it.

#. Reset your laptop to factory settings.
   
   - I.e., blow away everything and start over.

#. Shrink your hard drive partition.

   - Boot into Windows, open Computer Management, and
     Shrink the size of your C:\\ volume.

     - Windows may not let you shrink past a certain point, depending
       on where certain files and other partitions are located.
       Hopefully you can shrink the size in half.

#. Create a Linux boot USB.

   - See above — download a Linux installation ISO
     and use *USB Image Writer*.

#. Power off, insert the boot stick, and reboot.

   - You may have to configure your BIOS so that USB boot devices
     are prioritized higher than your hard drive, otherwise you
     might just boot back into Windows.

   - Once the live image is booted, install Linux.

   - You'll probably need to make a swap partition. The old rule
     of thumb is to make a swap space that's twice the size of
     physical memory, but if you've got a lot of memory already,
     that's probably unnecessary. You could also choose not to
     configure a swap partition but then you'll probably have to
     do something special to setup a swap file later. So just
     make a swap partition that's the size of your RAM, or double
     it, whatever makes you comfortable.

#. When you're done, reboot; you should be prompted to remove
   the USB stick. After resetting, you should land at the Grub2 bootloader.

   - You'll probably see multiple partitions for Windows and Linux,
     but it shouldn't matter which one you choose. E.g., you might
     see two partitions for Linux — one for ``swap``, and one for
     ``/`` — but choosing either one boots into Linux.

Accessing your Windows Files
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. note:: If you setup a dual-boot machine and would like access
          to your Windows files from Linux, follow these steps.

While Windows doesn't know ``ext4``, Linux knows ``ntfs``.
So you can mount your Windows volume in Linux, but not vice versa.
At least not without installing a new file system driver in Windows.

Do something like this to mount your Windows partition in Linux:

.. code-block:: bash

   # List your Windows partitions.
   sudo fdisk -l | grep -e NTFS -e Blocks

   # Choose the device with the largest partition by block size:
   # this is probably the one you want.

   # Create a mount point.
   sudo mkdir /win

   # Mount the windows partition using the device name previously gathered.
   DEVICE_NAME=<DEVICE NAME e.g., /dev/sda2>
   sudo mount -t ntfs $DEVICE_NAME /win
   # `mount` shows how it mounts.
   # rw,nosuid,nodev,allow_other,blksize=4096

   # If you always want to mount this partition on boot,
   # first, get the drive's UUID.
   DEVICE_UUID=$(ls -l /dev/disk/by-uuid/ \
                 | grep `basename $DEVICE_NAME` \
                 | awk '{print $9}')
   echo $DEVICE_UUID # Just to make sure.

   # Update fstab.
   echo "UUID=${DEVICE_UUID}                     /win            ntfs    rw              0       2
 "  | sudo tee -a /etc/fstab

   # And then test.
   sudo mount -a

Configure Linux to Your Taste
-----------------------------

Configuring Linux is a personal process, obviously.

But it's also a tedious process and it's easy to forget every little
customization that you like. Thankfully, you can automate the process
with a shell script. Or you can just configure linux manually.

If you'd like to see an example of a Bash script that automates
setting up linux, see the `setup_ubuntu.sh <setup_ubuntu.sh>`__
script in the same directory as this document.

- The script installs a lot of software, and it's not tested
  very often, but it is updated frequently, so it's best to
  inspect it first before deciding to run it.

  - The script calls ``apt-get install`` on a long list of packages.

  - The script tweaks a lot of Mint and MATE options to customize
    the desktop environment, making it easier and more comfortable
    for development. (You can tweak the same options using the
    widgets in the Mint menu, but it's easier to just capture
    all your favorite settings in an easy-to-run script.)
    
    - Tweaks include disabling the 5-minute-idle screen lockout,
      hiding desktop icons, setting up user groups and memberships,
      updating sudoers to not bug you as often for your password,
      configuring Pidgin to start on boot, and much, much more.
      You'll want to look at the file to see everything it does.

Run Linux Configuration Script
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. note:: Skip this if you'll setup and configure Linux on your own.
          Otherwise, you may be interested in running a script to
          take care of everything for you.

Take a look at ``once/setup_ubuntu.sh``.

Run the script on a fresh distro install to ``apt-get``
a ton of packages and also to ``wget``, build, and install
a ton of other useful libraries and applications.

You'll have to logout or reboot at least once while running
the script (because ``groups``), and you'll be asked for your
root password at least once, but otherwise it'll chug along
for hours and hours and set everything up.

The setup script also customizes a lot of window manager
behavior via ``gsettings`` and ``dconf``. For wat it can't
setup (MATE panels, for one, and web browser plugins, for
another), refer to somewhere in one of these READMEs.

Here's a brief overview of what the script does:

   - Calls ``sudo apt-get install ...`` and installs a lot of packages.
     If you want to do this yourself to see what's installed,
     copy and paste from the list of packages in the function
     ``setup_mint_17_stage_1_apt_get_install``.

   - The script may setup
     `VirtualBox Guest Additions
     <https://www.virtualbox.org/manual/ch04.html>`__,
     unless you're running Linux natively.

   - The script adds the local user to some groups,
     including ``vboxsf`` (so the user can mount virtual box
     shared folders) if you're running VirtualBox, and to the
     ``postgres`` and ``www-data`` groups (so the user can read
     postgres and apache logs and can edit config files).

   - The script configures the window manager and some
     standard applications and installs additional applications
     that aren't available as aptitude packages.

     - You can skip this step if you want to setup your desktop manually.
       But if you just want to get it over with, take a look at the
       function, ``setup_mint_17_stage_4_extras``.

     - One of the window manager tweaks, for example, is to disable that
       pesky five-minute no-activity timeout. If you leave your machine,
       you should lock it if you care (use the Home-fries ``qq`` command),
       but if you're at home and just happen to take a short break, you
       shouldn't be bothered to unlock the screen when you return to work.

     - Some of the tweaks:

       - Disable five-minute no-activity timeout.

       - Hide desktop icons.

       - Configure terminal to be white on black (rather than white on grey,
         which isn't contrasty enough and causes squinting).

       - Configure ``.gitconfig`` (to use ``less`` for the pager
         and to translate ANSI escape codes, and to disable keepBackup
         so that intermediate files are removed).

       - Configure ``meld`` (to use Monospace 9 pt font
         and to show line numbers).

       - Configure ``sshd`` (to disable password authentication
         and require keys in order to combat hacker login attempts).

       - Configure Psql (by changing permissions so the user can
         read and edit configuration and log files).

       - Download and install Quicktile (a convenient window resizer and
         repositioner).

       - Configure Pidgin to start on boot.

         - Also open Preferences > Themes and choose "none" for "Smiley Theme",
           otherwise when you copy/paste code to Pidgin, you'll often end up
           with smilies.

       - Download and install Google Chrome.

       - Download and install Adobe Reader (alas, an old version, 9.5.5,
         since Adobe end-of-lifed the Linux build).

       - Remove "Menu" text from panel (it's the button in the lower-left
         part of the screen with the Mint logo, of course it's the "Menu").

       - And so much more!

Setup Bash and Vim (or Your Favorite Text Editor)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

If you're looking for a full-featured Vim IDE, check out
`Dubsacks Vim <https://github.com/landonb/dubsacks>`__.

Caveat: it's tailored to the tastes of a particular developer,
but the components are modular
`Pathogen <https://github.com/tpope/vim-pathogen>`__
plugins, so it's easy to install and test any features
that might interest you. Check out the docs for more.

There are also some
`bash scripts <https://github.com/landonb/home-fries/.fries/.bashrc>`__
that also live in the same project as this document.

The Bash scripts are tailored for a particular developer,
but you still might find a few copy-and-take-aways.

Superuser Bash Profile
^^^^^^^^^^^^^^^^^^^^^^

If you want your superuser account to have a similar shell
setup as your user account, make a link to your profile.

.. code-block:: bash

  sudo /bin/ln -s $HOME/.bashrc /root/.bashrc

You could also link you Vim scripts to your root account,
but this author worries that letting all your Vim plugins
run as root is dangerous. (Though so it probably more so
letting all your Bash config run, unless you've audited it
well.)

.. code-block:: bash

  # It seems dangerous to let vendor Vim code run as root...
  #  sudo /bin/ln -s $HOME/.vim /root/.vim
  #  sudo /bin/ln -s $HOME/.vimrc /root/.vimrc

Add Gmail Account to Pidgin
^^^^^^^^^^^^^^^^^^^^^^^^^^^

If you'd like to use Pidgin as your chat client with Gmail, follow these steps.

First visit your Google account settings page and
click on the *App password* Settings button.

- `<https://www.google.com/settings/security?hl=en>`_

Create a new app password and use it when configuring Pidgin.

Run Pidgin and add a new account.

   - *Protocol*: ``XMPP``

   - *Username*: ``your.email.user.name``

   - *Domain*: ``gmail.com``

   - *Password*: <16-character app password you just created>

   - *Remember password*: Enable

You'll probably also want to disable notification popups,
otherwise you'll be annoyed every time someone comes online.

- Find the menu item, ``Tools > Plugins``, and uncheck *Libnotify Popups*.

See also: Show system tray icon: Always.

Configure Gmail Notifier
~~~~~~~~~~~~~~~~~~~~~~~~

Run either ``/usr/bin/gnome-gmail-notifier`` or ``/usr/bin/gm-notifier``
and setup an email notifier.

Relay Postfix Email via smtp.gmail.com
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

If you'd like to configure Linux to use your gmail account
to send email from your machine, follow these instructions.

.. todo:: Verify these instructions.

Install postfix and a few addition packages.

Note that the postfix installer is interactive: it'll ask you a few questions.

   - Setup your server as *Internet Site*.

   - For the system mail name (*fully qualified domain name (FQDN)*),
     use whatever, like ``fake_machine.fake_domain.tld``.

.. code-block:: bash

   sudo apt-get -y install \
      postfix \
      mailutils \
      libsasl2-2 \
      ca-certificates \
      libsasl2-modules

Add some options to the postfix configuration file.

.. code-block:: bash

   echo "
 relayhost = [smtp.gmail.com]:587
 smtp_sasl_auth_enable = yes
 smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
 smtp_sasl_security_options = noanonymous
 smtp_tls_CAfile = /etc/postfix/cacert.pem
 smtp_use_tls = yes
 " >> /etc/postfix/main.cf

Set you gmail username and password in a new file.

.. code-block:: bash

   echo "[smtp.gmail.com]:587 USERNAME@gmail.com:PASSWORD" \
      > /etc/postfix/sasl_passwd
   sudo chmod 400 /etc/postfix/sasl_passwd

Create the Postfix lookup table.

.. code-block:: bash

   sudo postmap /etc/postfix/sasl_passwd

Add the Thawte certificate to the Postfix configuration directory.

.. code-block:: bash

   cat /etc/ssl/certs/Thawte_Premium_Server_CA.pem \
   | sudo tee -a /etc/postfix/cacert.pem

Reload the Postfix server.

.. code-block:: bash

   sudo /etc/init.d/postfix reload

Test that everything works.

.. code-block:: bash

   echo "Is this thing on?" | mail -s "Testing 123" your.email@domain.tld

Check both that you received the message in your Inbox,
and that a copy is saved in Sent Mail, which gmail does for all email,
even those relayed through SMTP.

You can send up to 500 emails per day via SMTP.

If you see the error, ``SASL authentication failed; server smtp.gmail.com``,
you'll need to confirm your humanity with Google.
Visit https://www.google.com/accounts/DisplayUnlockCaptcha

Thanks to: https://rtcamp.com/tutorials/linux/ubuntu-postfix-gmail-smtp/

Miscellaneous Notes
-------------------

Updates and Upgrades
^^^^^^^^^^^^^^^^^^^^

.. code-block:: bash

    # Update the cache.
    sudo apt-get -y update

    # Update all packages.
    sudo apt-get -y upgrade

    # Update distribution packages.
    sudo apt-get -y dist-upgrade

or just run Update Manager, which usually lives in the notifications panel.

Backups and Syncing
^^^^^^^^^^^^^^^^^^^

You'll probably want to setup a backup scheme and possibly a syncing
scheme so you don't lose personal data or data you haven't committed
to the remote repository, and so you can develop locally from
different machines, if you wish.

Here's the author's strategy:

On each of my Linux machines, I use a Bash script to
``tar`` and ``rsync`` files to backup directories on
other devices.

On each of my Windows machines, I use a DOS script to
``robocopy`` files to the backup locations.

I have multiple, redundant backup locations — one is always connected
so that I can automate the backup scripts (using ``anacron`` on Linux,
and *Scheduled Tasks* on Windows), and the other backups are kept offline.

- Keeping drives disconnected hopefully protects you against malicious
  malware that deletes files, against ransomware that encrypts your
  files and extorts you to buy the passcode with virtual currency,
  and — if you store any backups offsite — against physical disasters
  such as floods or fires.

I also often switch between two development machines:
a more-powerful and dual-monitored desktop machine when at home,
and a portable and (mostly) capable small-screened laptop when out and about.
Rather than using ``rsync``, ``git``, cloning virtual machine images,
or using a cloud storage solution to keep my machines in sync, I use a
cool tool called ``unison`` to sync files between the two machines.

- The ``unison`` tool is intelligent and copies files in either
  direction, depending on which file is newer. It'll ask you for
  guidance when both files have been edited. This is unlike
  ``rsync``, which only transfers files in one direction (though
  you can use the ``--update`` switch so you don't overwrite changed
  files on the receiver, ``rsync`` isn't useful when the file is
  changed on both the source and destination).

  - So even if you normally develop from one machine and then sync
    before developing from a different machine, if you accidentally
    forget to sync and change a file on both machines before syncing,
    ``unison`` will check for differences and ask you how to handle them.
    In the worst case, you'll have to ``scp`` one of the files and use
    ``meld`` to combine differences, but at least ``unison`` won't
    overwrite either file by default.

  - The easiest way to use unison is to
    `create profiles
    <http://www.cis.upenn.edu/~bcpierce/unison/download/releases/stable/unison-manual.html#profile>`__,
    or ``*.prf`` files that live in in the ``~/.unison`` directory.
    You can call them individually or from a script easily, e.g.,
    ``unison my_project`` will sync files according to the profile
    specified in ``~/.unison/my_project.prf``.

Grepping Code
^^^^^^^^^^^^^

The built-in ``grep`` commands are generally great except when they're
not, such as when you want to be able to ignore specific file paths.
Specifically, ``grep`` only lets you specify basenames of file and
directories to ignore, which means if you want to ignore ``/a/b/build``
but not ``/a/c/build``, then you're out of luck.

Fortunately, there's a "better ack/grep" tool called The Silver Searcher,
known by its executable name as ``ag``.

The Silver Searcher recognizes regular expressions, like ``grep``,
but it also recognizes ``.gitignore`` files (and its own ``.agignore``
files). As such, if your projects contain a lot of third-party
and compiled code, you're probably already using an ignore file,
and you'll probably want to ignore the same paths when searching
code. Otherwise your searches will take a long time and the
response will contain a lot of meaningless results.

Install the search tool:

.. code-block:: bash

   apt-get install -y silversearcher-ag

The tool is invoked from the command line by typing ``ag`` and works much
like grep — just specify a search term and a search location.

To use in Vim, you'll want to configure the output so it works
with the quickfix window. Add this to one of your ``~/.vim/plugin`` files,
if it's not there already:

.. code-block:: bash

   set grepprg=ag\ -A\ 0\ -B\ 0\ --smart-case

Differences: ``ag``'s regular expression syntax is similar to ``grep``
except that defining word boundaries uses the PCRE syntax.

   - E.g., Using ``\<ark\>`` to find ``ark`` and not ``bark`` doesn't work.
     You'll want to use ``\bark\b`` instead.

See more at: https://github.com/ervandew/ag

Lenovo Laptops...
^^^^^^^^^^^^^^^^^

Lenovo combines the function keys (Fn, or Fkeys)
and the hardware-specific keys (like volume up and down)
into the same row of keys, and it defaults to the hardware
keys, so to use the Fn keys, you have to press the Function key.

To reverse the mapping, hit ``Fcn-Esc``.

This solves the problem of quickly accessing F-keys
(which I use in Vim all the time!) but the keys on
my laptop are iconed with the hardware function, and
not the Fn marking (it's really very small!), so I'll
have to rely on my memory map and not the keyboard markings.

Passwordless, Unhibernateable, Encrypted Swap
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

If you setup an encrypted home directory, the installer
set up an encrypted swap to complement it. Verify this.
Try the following commands and look for ``cryptswap``.

.. code-block:: bash

    sudo dmsetup info
    cat /proc/swaps
    lsblk
    ll /dev/mapper
    cat /etc/fstab

Ref: http://hydra.geht.net/tino/howto/linux/cryptswap/

I have other, older notes that also indicate how to check the swap.

.. code-block:: bash

    ll ${HOME}/.ecryptfs
    cat /home/.ecryptfs/$USER/.ecryptfs/Private.mnt
    df ${HOME}

    # Most ideal check is probably the actual verification tool itself.
    ecryptfs-verify --home &> /dev/null
    echo $?

    sudo blkid | grep swap

    sudo cryptsetup status /dev/mapper/cryptswap1
    echo $?

    # This shows the swap name.
    swapon -s

