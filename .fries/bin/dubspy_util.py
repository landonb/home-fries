!/usr/bin/python3
# -*- coding: utf-8 -*-
# vim: ts=4:sw=4:et

# File: termdub.py
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Last Modified: 2016.11.19
# Project Page: https://github.com/landonb/home_fries
# License: GPLv3

import os
import sys

import re
import subprocess

class Term_Util(object):

    def __init__(self):
        assert(False)

    @staticmethod
    def get_emulator_app_name():
        # The MATE window manager renames its GNOMEy derivatives.
        # 2015.08.07: There used to be a try-except where we'd try
        #  without universal_newlines and catch TypeError if it
        #  failed, and then we'd try universal_newlines=True. But it
        #  should always be True because we want a string, not bytes.
        wind_mgr = subprocess.check_output(
            ['/usr/bin/wmctrl', '-m',],
            stderr=subprocess.STDOUT,
            universal_newlines=True
        )
        if re.match(r"^Name: Mutter (Muffin)\n", wind_mgr):
            # Cinnamon
            the_terminal = 'gnome-terminal'
        #elif re.match(r"^Name: Xfwm4\n", wind_mgr):
        #    # Xfce
        #    [lb] is not sure this is right...
        #    the_terminal = 'gnome-terminal'
        elif (True
            or re.match(r"^Name: Marco\n", wind_mgr)
            or re.match(r"^Name: Metacity \(Marco\)\n", wind_mgr)
        ):
            # MATE
            the_terminal = 'mate-terminal'
        else:
            print('WARNING: Unknown OS: Is this GNOME or MATE?')
            #sys.exit(1)
            #the_terminal = 'gnome-terminal'
            the_terminal = None
        return the_terminal

