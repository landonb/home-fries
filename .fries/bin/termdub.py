#!/usr/bin/python3
# -*- coding: utf-8 -*-

# File: termdub.py
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Last Modified: 2017.10.03
# Project Page: https://github.com/landonb/home-fries
# License: GPLv3

# FIXME/2016-11-19: Make this its own project.
#                   Installable with pip (from local sources, too).
#                   See: /kit/sturdy/chjson
#                   http://stackoverflow.com/questions/15031694/
#                    installing-python-packages-from-local-file-system-folder-with-pip
#                   This is one of the few (only?) py files in home-fries,
#                   so it feels a little out of place. And hacky, too,
#                   since it should just install itself like normal.

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

import os
import sys

import optparse
import re
import subprocess
import time

import dubspy_util

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
         choices=list(Termdub.geoms.keys()),
         help='target: lhs|rhs|logs|logc|dbms|mini|minil|minir|bigl|bigc|bigr|bign')

      # You can override the position to fine tune window placement.
      # Hint: `wmctrl -lG` will help you find the coordinates of a
      #       window on your desktop whose position you like.

      self.add_option('-x', '--x-position', dest='position_x',
         action='store', default=0, type=int,
         help='override the target placement and use this x instead')

      self.add_option('-y', '--y-position', dest='position_y',
         action='store', default=0, type=int,
         help='override the target placement and use this y instead')

      self.add_option('-W', '--width-offset', dest='offset_width',
         action='store', default=0, type=int,
         help='if main display is right of other displays, specify offset')

      self.add_option('-H', '--height-offset', dest='offset_height',
         action='store', default=0, type=int,
         help='if main display is below other displays, specify offset')

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

   # CAVEAT: This script fails if the monitor size is not programmed herein.
   geoms = {
      "lhs": {                         # A collection of [lb's] monitors...
         1280: {
            800: "77x38+0+100",        # Lenovo X201
            1024: "77x46+0+100",       # HP L1925
            },
         1366: {
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
            1080: "130x48+315+65",
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
      # NOTE: See the newerish -x and -y argparse args.
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
      # A largestish size window to be used with -x and -y.
      # 2015.08.07: So far just 1920x1080 is configured to taste.
      # Ug, whatever, dbms is just as big.
      "bign": {
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
            1080: "120x49+500+100",
            },
         },
      }

   def __init__(self):
      pass

   #
   def go(self, cli_opts):
      self.cli_opts = cli_opts
      (width, height) = self.get_monitor_resolution()
      # If the width and height don't match the known monitor sizes,
      # use the next lowest size.
      (width, height) = self.normalize_resolution(width, height, cli_opts.target)
      self.open_terminal_window(width, height, cli_opts.target)

   # Note that the xrandr-reported current screen size adds together all
   # the monitor resolutions.
   #
   # E.g., an abbreviated xrandr response.
   #   $ xrandr
   #   Screen 0: minimum 320 x 200, current 2720 x 1680, maximum 32767 x 32767
   #   VGA1 connected 800x600+0+1080 (normal left inverted ...) 0mm x 0mm
   #      1024x768       60.0
   #      800x600        60.3*    56.2
   #      848x480        60.0
   #      ...
   #   HDMI1 connected 1920x1080+800+0 (normal left inverted ...) 509mm x 286mm
   #      1920x1080      60.0*+
   #      1680x1050      59.9
   #      ...
   #
   # [lb] is quite sure what the + symbol means but I've seen it used twice, e.g.,
   #   Screen 0: minimum 320 x 200, current 3286 x 1080, maximum 32767 x 32767
   #   eDP1 connected 1366x768+1920+164 (normal left inverted right x axis y axis) 310mm x 174mm
   #      1366x768       60.0*+
   #      ...
   #   VGA1 connected 1920x1080+0+0 (normal left inverted right x axis y axis) 476mm x 268mm
   #      1920x1080      60.0*+
   #      ...

   XR_CURRENT_RE = re.compile(
      r", current (?P<res_w>[0-9]+) x (?P<res_h>[0-9]+), maximum ")

   XR_CONNECTED_RE = re.compile(
      r"^[a-zA-Z0-9]+ connected (primary )?(?P<res_w>[0-9]+)x(?P<res_h>[0-9]+)\+(?P<off_w>[0-9]+)\+(?P<off_h>[0-9]+)")

   #
   def get_monitor_resolution(self):
      curr_width = None
      curr_height = None
      use_width = None
      use_height = None
      displays = []
      the_cmd = "xrandr"
      n_lines_current = 0
      n_lines_connected = 0
      topmost_displays = []
      top_and_leftmost = []
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
         if not line:
            # End of file
            break

         matched = Termdub.XR_CURRENT_RE.search(line)
         if matched is not None:
            if n_lines_current:
               print("WARNING: too many currents: %s" % (n_lines_current,))
            n_lines_current += 1
            curr_width = int(matched.group("res_w"))
            curr_height = int(matched.group("res_h"))

         matched = Termdub.XR_CONNECTED_RE.search(line)
         if matched is not None:
            if not n_lines_current:
               print("WARNING: found 'connected' before 'current'?")
            n_lines_connected += 1
            if n_lines_connected > 2:
               print("INTERESTING: you have many monitors: %s" % (n_lines_connected,))
            new_display = (
              int(matched.group("res_w")),
              int(matched.group("res_h")),
              int(matched.group("off_w")),
              int(matched.group("off_h")),)
            displays.append(new_display)
            # In Mint, there really is no "main" monitor, since you can put
            # panels wherever.
            # MAYBE: Figure out from which display this script was launched
            #        and put the new display there?
            # MAYBE: Always use the left-most or left- and top-most display?
            # MEH:   In any case, when you launch a new terminal, it tries
            #        to place it relative to 0,0, but if 0,0 is offscreen
            #        because you have one monitor to the upper-right of another,
            #        then the new terminal moves left until it's displayed, so
            #        it goes on the left side of the upper monitor. Knowing
            #        this, we could use the top-most or top- and left-most
            #        display as the target and compute the display size and
            #        the offsets using this information....
            if not new_display[3]:
               # The y-offset is 0, so the display is topmost.
               topmost_displays.append(new_display)
               if not new_display[2]:
                  # The x-offset is also 0, so the display is also leftmost.
                  top_and_leftmost.append(new_display)

      # end: while True

      if len(topmost_displays) > 1:
         # Two or more displays, side-by-side; choose the lefter of them all.
         assert(len(top_and_leftmost) == 1)
         use_width = top_and_leftmost[0][0]
         use_height = top_and_leftmost[0][1]

      else:
         # One or more displays, but one is the upperest; choose it.
         assert(len(topmost_displays) == 1)
         use_width = topmost_displays[0][0]
         use_height = topmost_displays[0][1]

      if not curr_width or not curr_height:
         print("WARNING: current resolution not found!")
         #curr_width = 1280
         #curr_height = 1024
         curr_width = 64
         curr_height = 64
      else:
         total_width = sum([x[0] for x in displays])
         total_height = sum([x[1] for x in displays])
         # The width and height of the combined display won't necessarily
         # be the total possible width and height because, e.g., if you
         # put two monitors side by side, the total height is the larger
         # of the two monitors' heights.
         if (total_width < curr_width) or (total_height < curr_height):
            print(
               "WARNING: Dimensional Mismatch: current %sx%s > cummulative %sx%s"
               % (curr_width, curr_height, total_width, total_height,))

      if not use_width or not use_height:
         print("WARNING: main display resolution not found!")
         use_width = curr_width
         use_height = curr_height

      sin.close()
      sout_err.close()
      p.wait()

      return (use_width, use_height)

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

      # Get name of terminal app, e.g., "gnome-terminal", "mate-terminal", etc.
      the_terminal = dubspy_util.Term_Util.get_emulator_app_name()
      assert(the_terminal)

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

      # Get the --geometry option, e.g., "110x43+765+210".
      geom_opt = Termdub.geoms[target][width][height]
      # Parse it.
      comps_geom = geom_opt.split('+')
      comps_lines = comps_geom[0].split('x')
      lines_wide = int(comps_lines[0])
      lines_tall = int(comps_lines[1])
      offset_w = int(comps_geom[1])
      offset_h = int(comps_geom[2])
      # Account for multiple displays.
      if self.cli_opts.offset_width:
         offset_w += self.cli_opts.offset_width
      if self.cli_opts.offset_height:
         offset_h += self.cli_opts.offset_height
      # But override if the caller says so.
      if self.cli_opts.position_x:
         offset_w = self.cli_opts.position_x
      if self.cli_opts.position_y:
         offset_h = self.cli_opts.position_y
      # Reassemble the option.
      geom_opt = ("%dx%d+%d+%d" % (lines_wide, lines_tall, offset_w, offset_h,))

      print('Opening %s: %s: %dx%d+%d+%d.'
            % (the_terminal, target, lines_wide, lines_tall, offset_w, offset_h,))

      the_cmd = ('%s %s --geometry %s' 
                 % (the_terminal,
                    termname,
                    geom_opt,))
      #print('the_cmd: %s' % (the_cmd,))

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
   tdub.go(cli_opts)

# vim:tw=0:ts=3:sw=3:et:norl:

