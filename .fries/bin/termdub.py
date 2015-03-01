#!/usr/bin/python2
# -*- coding: utf-8 -*-

# File: termdub.py
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Last Modified: 2015.02.27
# Project Page: https://github.com/landonb/home_fries
# License: GPLv3

"""
Monitor-size-aware Dimensionally-adaptive Gnome-terminal Wrapper
================================================================

Overview
~~~~~~~~

This script wraps gnome-terminal so you can open specifically-sized
terminal windows that are fit for your monitor's screen size.

Setup
~~~~~

Update Termdub.geoms with your screen resolution,
if it's not already registered.

Options
~~~~~~~

------------------------   --------------------------------------
Terminal Window            Command
Location
or Dimensions
========================   ======================================
Left Half of Screen        path/to/this/script/termdub.py -t lhs
Right Half of Screen       path/to/this/script/termdub.py -t rhs
Top Half of Screen         path/to/this/script/termdub.py -t logs
Bottom Half of Screen      path/to/this/script/termdub.py -t logc
Large and Square Window    path/to/this/script/termdub.py -t dbms
Miniature Window           path/to/this/script/termdub.py -t mini 
------------------------   --------------------------------------

Example Usage: As Panel Launchers
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Make panel launchers for those sizes you find
useful, so you can easily open new terminals::

   Gnome [menubar] 
     < Applications 
     < System Tools 
     < Terminal [Right-click and choose] Add this launcher to Panel 

Add one new launcher for each window size you like,
and then right-click each new launcher and edit the
Properties, entering the appropriate Command from
the table above.

"""

import optparse
import os
import re
import subprocess
import sys
import time

# env DUBS_TERMNAME="" \
#  env DUBS_STARTIN="" \
#  env DUBS_STARTUP="" \
#  $HOME/.fries/bin/termdub.py -t lhs

class Termdub_Parser(optparse.OptionParser):

   def __init__(self):
      optparse.OptionParser.__init__(self)
      self.cli_opts = None
      self.cli_args = None

   def get_opts(self):
      self.prepare();
      self.parse();
      assert(self.cli_opts is not None)
      return self.cli_opts

   def prepare(self):
      self.add_option('-t', '--target', dest='target',
         action='store', default='lhs', type='choice',
         choices=Termdub.geoms.keys(),
         help='target: lhs|rhs|logs|logc|dbms|mini|minil|minir|bigl|bigc|bigr')

   # FIXME: Add
   # DUBS_TERMNAME="" DUBS_STARTIN="" DUBS_STARTUP="" 
   # to options, since the gnome shortcut keeps running 
   # DUBS_STARTUP for the first window (winpdb)...
   # and I can't pass an env var to termdub from the
   # gnome applet, for whatever reason.

   def parse(self):
      '''Parse the command line arguments.'''
      (opts, args) = self.parse_args()
      # parse_args halts execution if user specifies:
      #  (a) '-h', (b) '--help', or (c) unknown option.
      self.cli_opts = opts
      self.cli_args = args

class Termdub(object):

   XR_RE = re.compile(
      r", current (?P<res_w>[0-9]+) x (?P<res_h>[0-9]+), maximum ")

   # CAVEAT: This script fails if the monitor size is not programmed herein.
   geoms = {
      "lhs": {                         # A collection of [lb's] monitors...
         1280: {
            800: "77x38+0+100",        # Lenovo X201
            1024: "77x46+0+100",       # HP L1925
            },
         1366: {
            # FIXME: 2015.02.27: Not customized yet. I copied 1280x800's.
            768: "77x38+0+100",        # Lenovo T440p
            },
         1600: {
            1200: "97x56+0+100",       # Dell ...
            },
         1680: {
            1050: "97x52+30+20",       # SyncMaster 226BW
            },
         1920: {
            1080: "95x45+130+100",     # ASUS VS228H-P
            },
         },
      "rhs": {
         1280: {
            800: "77x38+1000+100",
            1024: "77x46+1000+100",
            },
         1366: {
            768: "77x38+1000+100",
            },
         1600: {
            1200: "97x56+1000+100",
            },
         1680: {
            1050: "97x52+850+20",
            },
         1920: {
            1080: "95x45+950+100",
            },
         },
      "logs": {
         1280: {
            800: "1000x17+0+20",
            1024: "1000x27+0+20",
            },
         1366: {
            768: "1000x17+0+20",
            },
         1600: {
            1200: "1000x32+0+20",
            },
         1680: {
            1050: "1000x27+0+20",
            },
         1920: {
            1080: "1000x27+0+7",
            },
         },
      "logc": {
         1280: {
            800: "1000x18+0+1000",
            1024: "1000x21+0+1000",
            },
         1366: {
            768: "1000x18+0+1000",
            },
         1600: {
            1200: "1000x26+0+1000",
            },
         1680: {
            1050: "1000x22+0+535",
            },
         1920: {
            1080: "1000x25+0+495",
            },
         },
      "dbms": {
         1280: {
            800: "100x38+150+100",
            1024: "110x43+315+115",
            },
         1366: {
            768: "100x38+150+100",
            },
         1600: {
            1200: "110x43+525+250",
            },
         1680: {
            1050: "110x43+515+115",
            },
         1920: {
            1080: "110x43+515+115",
            },
         },
      "mini": {
         1280: {
            800: "77x30+250+100",
            1024: "77x30+250+100",
            },
         1366: {
            768: "77x30+250+100",
            },
         1600: {
            1200: "77x30+725+425",
            },
         1680: {
            1050: "77x30+575+200",
            },
         1920: {
            1080: "77x30+575+200",
            },
         },
      # 2015.02.27: [lb] added these for 1920x1080 but did not modify others.
      # A mini on the left.
      "minil": {
         1280: {
            800: "77x30+250+100",
            1024: "77x30+250+100",
            },
         1366: {
            768: "77x30+250+100",
            },
         1600: {
            1200: "77x30+725+425",
            },
         1680: {
            1050: "77x30+575+200",
            },
         1920: {
            1080: "77x30+235+200",
            },
         },
      # A mini on the left mini's right.
      "minir": {
         1280: {
            800: "77x30+250+100",
            1024: "77x30+250+100",
            },
         1366: {
            768: "77x30+250+100",
            },
         1600: {
            1200: "77x30+725+425",
            },
         1680: {
            1050: "77x30+575+200",
            },
         1920: {
            1080: "77x30+890+200",
            },
         },
      # Three big windows, cascaded.
      # MAYBE: Add 'cycle' option and open bigl first time,
      #        then bigm, then bigr? Or use math?
      "bigl": {
         1280: {
            800: "100x38+150+100",
            1024: "110x43+315+115",
            },
         1366: {
            768: "100x38+150+100",
            },
         1600: {
            1200: "110x43+525+250",
            },
         1680: {
            1050: "110x43+515+115",
            },
         1920: {
            1080: "110x43+265+50",
            },
         },
      "bigc": {
         1280: {
            800: "100x38+150+100",
            1024: "110x43+315+115",
            },
         1366: {
            768: "100x38+150+100",
            },
         1600: {
            1200: "110x43+525+250",
            },
         1680: {
            1050: "110x43+515+115",
            },
         1920: {
            1080: "110x43+515+140",
            },
         },
      "bigr": {
         1280: {
            800: "100x38+150+100",
            1024: "110x43+315+115",
            },
         1366: {
            768: "100x38+150+100",
            },
         1600: {
            1200: "110x43+525+250",
            },
         1680: {
            1050: "110x43+515+115",
            },
         1920: {
            1080: "110x43+765+210",
            },
         },
      }

   def __init__(self):
      pass

   #
   def go(self, target):
      (width, height) = self.get_monitor_resolution()
      # If the width and height don't match the known monitor sizes,
      # use the next lowest size.
      (width, height) = self.normalize_resolution(width, height, target)
      self.open_terminal_window(width, height, target)

   #
   def get_monitor_resolution(self):
      #width = 1280
      #height = 1024
      width = 64
      height = 64
      re.compile(r"^WARNING:"),
      the_cmd = "xrandr"
      # Python3.3 adds universal_newlines, which defaults to False and causes
      # raw binary stream to be returned. But we want to read strings.
      try:
         p = subprocess.Popen([the_cmd], 
                              shell=True, 
                              # bufsize=bufsize,
                              stdin=subprocess.PIPE, 
                              stdout=subprocess.PIPE, 
                              stderr=subprocess.STDOUT, 
                              close_fds=True,
                              universal_newlines=True)

      except TypeError as e:
         p = subprocess.Popen([the_cmd], 
                              shell=True, 
                              # bufsize=bufsize,
                              stdin=subprocess.PIPE, 
                              stdout=subprocess.PIPE, 
                              stderr=subprocess.STDOUT, 
                              close_fds=True)
      (sin, sout_err) = (p.stdin, p.stdout)
      while True:
         line = sout_err.readline()
         matched = self.XR_RE.search(line)
         if not line:
            print("WARNING: resolution not found!")
            break
         if matched is not None:
            width = int(matched.group("res_w"))
            height = int(matched.group("res_h"))
            break
      sin.close()
      sout_err.close()
      p.wait()
      return (width, height)

   #
   def normalize_resolution(self, width, height, target):

      # Check the width first.
      widths = list(Termdub.geoms[target].keys())
      widths.sort(reverse=True)
      correct_width = 0
      for known in widths:
         if width == known:
            correct_width = width
            break
         elif width > known:
            correct_width = known
            break
      if not correct_width:
         # Use the smallest width defined above.
         correct_width = widths[-1]

      # Now check the height.
      heights = list(Termdub.geoms[target][correct_width].keys())
      heights.sort(reverse=True)
      correct_height = 0
      for known in heights:
         if height == known:
            correct_height = height
            break
         elif width > known:
            correct_height = known
            break
      if not correct_height:
         # Use the smallest height defined for this width.
         correct_height = heights[-1]

      return (correct_width, correct_height)

   #
   def open_terminal_window(self, width, height, target):

      # NOTE: We gotta be in the user's home directory for gnome-terminal to
      # source our bash startup scripts.
      os.chdir(os.getenv('HOME'))

      # The MATE window manager renames its GNOMEy derivatives.
      try:
         wind_mgr = subprocess.check_output(
                     ['/usr/bin/wmctrl', '-m',],
                     stderr=subprocess.STDOUT)
      except TypeError as e:
         wind_mgr = subprocess.check_output(
                     ['/usr/bin/wmctrl', '-m',],
                     stderr=subprocess.STDOUT,
                     universal_newlines=True)
      if re.match(r"^Name: Mutter (Muffin)\n", wind_mgr):
         # Cinnamon
         the_terminal = 'gnome-terminal'
      #elif re.match(r"^Name: Xfwm4\n", wind_mgr):
      #   # Xfce
      #   [lb] is not sure this is right...
      #   the_terminal = 'gnome-terminal'
      elif (re.match(r"^Name: Marco\n", wind_mgr)
            or re.match(r"^Name: Metacity \(Marco\)\n", wind_mgr)):
         # MATE
         the_terminal = 'mate-terminal'
      else:
         print('WARNING: Unknown OS: Is this GNOME or MATE?')
         #sys.exit(1)
         the_terminal = 'gnome-terminal'

      # NOTE: The -e/--command runs a command inside the new terminal, but it's
      #       before bashrc executes, and a Ctrl-C closes the window. So if you
      #       want to run a command inside the terminal window and then let the
      #       terminal window live independent of that process, don't use -e.
      # So we don't use -e/--command, but we can use -t/--title, which names
      # the window first before bashrc runs the command, since gnome-terminal
      # doesn't update its titlebar until after bashrc completes.

      termname = os.getenv('DUBS_TERMNAME')
      if termname is not None:
         termname = '--title "%s"' % (termname,)
      else:
         termname = ''

      #
      print('Opening %s: %s: %d x %d.'
            % (the_terminal, target, width, height,))
      #
      the_cmd = ('%s %s --geometry %s' 
                 % (the_terminal,
                    termname,
                    Termdub.geoms[target][width][height],))
      #
      try:
         p = subprocess.Popen(the_cmd, shell=True, universal_newlines=True)
      except TypeError as e:
         p = subprocess.Popen(the_cmd, shell=True)
      sts = os.waitpid(p.pid, 0)

# ***

if (__name__ == "__main__"):

   parser = Termdub_Parser()
   cli_opts = parser.get_opts()

   tdub = Termdub()
   tdub.go(cli_opts.target)

# vim:tw=0:ts=3:sw=3:et:norl:

