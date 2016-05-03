#!/bin/bash
# Last Modified: 2016-05-02

# For years I've dealt with a weird Chrome issue that I never figured out
# how to solve on my own -- until now! -
#
# When I click the Chrome launcher in the Gnome panel, Chrome opens a new
# tab and brings a window to the front, but -- frustratingly! -- the window
# does not receive focus. And usually what happens is that I start typing a
# query, don't see it in Chrome, and then realize it's going to whatever
# application was last on top -- and still has focus!
#
# Fortunately, there's the wonderful wnctrl utility we can use to do the
# bringing-to-focus automatically for us after opening a new Chrome tab.

# I looked for bug reports of the same but am not convinced I found the same exact:
#  https://productforums.google.com/forum/#!topic/chrome/qu-FdnjP-fs
#  https://productforums.google.com/forum/?hl=en#!topic/chrome/FA98j4se-Go;context-place=topicsearchin/chrome/new$20windows$20does$20not$20get$20focus

# See: https://standards.freedesktop.org/desktop-entry-spec/latest/index.html
#
#  %U: A list of URLs. Each URL is passed as a separate argument to the executable program.
#      Local files may either be passed as file: URLs or as file path.
#      - I don't think we need to worry about %U, do we?
#        - We're not sending any arguments to the launcher.
#
# Original launcher command:
#
#  /usr/bin/google-chrome-stable %U
#
/usr/bin/google-chrome-stable &

# 2016-05-02: I tried 0.1/didn't work and 1.0/worked, and 0.5/worked/compromise.
sleep 0.5

# This maximizes the new tab window:
#
#   wmctrl -a "New Tab - Google Chrome"
#
# but it only works if the topmost existing Chrome window is in the
# upper monitor, if the second monitor is bottom-left (because the
# new windows gets the same left/x value as the topmost Chrome window
# by a 0-value y. So, at home, if the topmost Chrome window is in the
# bottom-left monitor, the new Chrome window goes to the upper-left
# hidden area.e
#
# hp L1925 1280x1024 / ASUS VS228H-P 1920x1080
wmctrl -a "New Tab - Google Chrome" -e 0,1280,0,1920,1080
wmctrl -a "New Tab - Google Chrome" -b add,maximized_vert,maximized_horz

