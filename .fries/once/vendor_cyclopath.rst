Manual Cyclopath Configuration Steps and Gotchas
================================================

.. Author: Landon Bouma
.. Last Modified: 2017.10.03
.. Project Page: https://github.com/landonb/home-fries

After installing Cyclopath, perform manual configuration
tasks and learn about and be aware of post-install caveats.

Be Aware: RAM-specific Postgresql.conf
--------------------------------------

The setup script configured postgresql.conf according to the
specific amount of RAM available on the machine.

Look for the m4 variable ``PGSQL_SHBU``, set in
``once/vendor_cyclopath.sh`` and used in
``target/common/etc/postgresql/9.3/main/postgresql.conf``.

If your machine's RAM change (e.g., if you change the virtual
machine RAM -- especially if you lower it), you'll want to edit
``/etc/sysctl.conf`` and modify the settings,
``kernel.shmmax`` and ``kernel.shmall``. E.g.,

.. code-block:: conf

   # Use 50% of RAM for shared memory maximum segment size.
   #   Note that shmmax needs to be larger
   #   than Postgresql.conf's shared_buffers.
   # Also, set shmall to shmmax / page size. (Page size is almost always 4 Kb.)
   kernel.shmmax = 2601418752
   kernel.shmall = 635112

You might also need to edit
``/etc/postgresql/9.3/main/postgresql.conf``
for, e.g., ``shared_buffers``, ``work_mem``, etc.

- *Hint:* The file is marked where we changed values; search for "Cyclopath".

Configure Cyclopath
-------------------

We configured Cyclopath so that it works on your new machine.

But we didn't configure a geocoder for it, and we don't auto-start any daemons.

Cyclopath Geocoder
^^^^^^^^^^^^^^^^^^

If you want to use a Geocoder, Cyclopath works with
(or at least has worked with) Yahoo, MapPoint, and Bing.

* Since 2010, Cyclopath has only been tested using the Bing geocoder.

If you work at the U, just ask another user for the Bing Maps ID.

Otherwise, educational and non-profit users can get a free Basic Key
at the `Bing Maps Account Center <http://www.bingmapsportal.com/>`__.

* We don't have any instructions on obtaining a key; you're on your own.

Once you have a key, add it to the pyserver configuration file:

* Open ``/ccp/dev/cp/pyserver/CONFIG``

* Find and update the appropriate geocoder id key (you only need to setup one service):
  | ``yahoo_app_id:``
  | ``mappoint_user:``
  | ``mappoint_password:``
  | ``bing_maps_id:`` ``my_new_key_123``

Cyclopath Services
^^^^^^^^^^^^^^^^^^

For dev machines, we don't auto-start the route finder on boot.

* The route finder consumes memory proportional to the number of
  line segments in the database, and at a statewide level, that
  could be a number of GBs, so we let developers choose when they
  want to start the route finder.

To configure a machine so that the Cyclopath route finder(s) start
on boot, take a look at the template startup scripts and read the
instructions therein:

.. code-block:: bash

   $ ls /ccp/dev/cp/scripts/setupcp/ao_templates/mint16/target/etc/init.d/
   cyclopath-mr_do  cyclopath-routed

Setup Wireshark
^^^^^^^^^^^^^^^

Run Wireshark and set it up.

- Capture just Cyclopath developer traffic.

  - Find Capture > Options...

    - Choose "lo" as the capture interface.

    - For Capture Filter, type: ``host ccp``
      
    - Click Close
      
- Add Color Highlights for the GET and OK packets.
  
  - Find View > Coloring Rules...
    
    - Create two filters at the top:

      - Name: HTTP XML GET

        - Filter: ``xml && http.request``

      - Name: HTTP XML OK

        - Filter: ``xml && http.response.code == 200``
          
      - You could choose dark green for ``GET``
        and dark blue for ``OK`` to make it easier
        to find Cyclopath packets in the trace.

- Start a trace and open a browser to http://ccp to test.

Setup SSH Keys
^^^^^^^^^^^^^^

If you develop for the U, you'll want to setup SSH keys
so that you're not constantly asked for your password.

Start by generating a new key.

* The default key length is just 1K,
  but you can specify 4K for a stronger key.

* If you have multiple keys,
  you can add comments to distinguish them apart,
  and you can name them differently.

  * However, ssh only looks for ``~/.ssh/id_rsa`` by default.
    But if you're using the Bash profile scripts included in
    this project, they automatically look for and load all
    keys named ``~/.ssh/*_rsa``.

To generate a new key:

* Specify the type of key (what encryption method) to use.
  It's probably best to use RSA (``-t rsa``).

* Specify a byte size; use 2K at a minimum (``-b 2048``)
  or 4K if you're more paranoid (``-b 4096``, but note
  that not all systems will recognize or work with larger key sizes;
  try 4K first and use 2K if 4K doesn't work).

* Add a comment (which gets appended to the public key)
  if you'd like a hint about what key it is.

* Specify the destination key path, which is useful
  if you've already got a key at ``~/.ssh/id_rsa``.
  And if you don't specify a path, you'll be prompted.

For example::

   ssh-keygen -t rsa -b 2048 -C "ccp" -f $HOME/.ssh/id_ccp_rsa

You'll be prompted for a passphrase. Choose something.

* Note that the security of keys comes more from keeping
  your private key safe than from keeping your password
  secret. A hacker can't do much with your password without
  your private key, but with your private key and without
  your password, a hacker can launch a brute-force attack
  to find the password. So passwords on keys are good
  (you'll be safe if someone sits down at your laptop and
  can't guess your password, so they can't use your key),
  but passwords are pretty much useless once your private
  key is compromised (albeit it would take a dedicated
  hacker a little bit of time to crack it, which might
  give you time to launch a defensive attack and clear out
  all your ``authorized_keys`` files from accepting the
  compromised key).

If you're using the Cyclopath Bash scripts, your new key
should be loaded after you boot your machine, log on,
and open a terminal window -- you'll be prompted in the
terminal to enter the passphrase, and then your key will be
available to any application from then on.

But before you reboot, test the new key.

First, kill the agent, if it's running. (Each time you run ``ssh-agent``, it creates a new instance, so only run it once.)

.. code-block:: bash

   ssh-agent -k

Now, restart the agent.

.. code-block:: bash

   ssh-agent

Add your key (you'll be asked for the passphrase).

.. code-block:: bash

   ssh-add /path/to/my/new/key_rsa

List the loaded keys and make sure it worked.

.. code-block:: bash

   ssh-add -l

Setup Remote Machine SSH Keys
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

To be able to logon to a remote machine without
entering your password on that machine,
add your key to it and tell it to trust your key.

Use ``scp`` to copy your public key to the remote machine. E.g.,

.. code-block:: bash

   /bin/cp /path/to/my_key_rsa.pub my_name@remote:/home/my_name/.ssh/my_key_rsa.pub

Next, logon to the remote machine and authorize it.

.. code-block:: bash

   cd ~/.ssh
   cat my_key_rsa.pub >> authorized_keys

Check that it's permission are ``640``.

Note: If you login to your remote machine and want to logon
from there to other machines, you might want to also copy
your private key to your remote home directory. If you do this,
you'll want to sure sure the identity link exists:

.. code-block:: bash

   if [[ -e ~/.ssh/identity ]]; then
      ln -s ~/.ssh/my_key_rsa ~/.ssh/identity
   fi

Setup Bitbucket SSH Keys
^^^^^^^^^^^^^^^^^^^^^^^^

Cyclopath and GroupLens use Bitbucket to host source code.

So that you don't have to type a password when pushing
or pulling code from Bitbucket, you can create a new
key, add it to your ssh-agent, and upload the public
key to Bitbucket.

Rather than use the key you just generated for your remote machine(s),
generate a new key (following the same instructions) and then logon
to Bitbucket and upload the public key.

You can find more info on the Bitbucket wiki:

* https://confluence.atlassian.com/pages/viewpage.action?pageId=270827678

