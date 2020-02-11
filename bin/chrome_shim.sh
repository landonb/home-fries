#!/bin/bash
# Last Modified: 2016-05-04

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

# If we don't sleep, wmctrl -l won't see the new window.
sleep .5
# 2016.05.04: I thought I had timing issues between wmctrl
# commands, too, but I think that was something else; so
# sleep is disable for remaining command transitions.
SLEEP_TIME="0"

# Process ID? is shared:
#  wmctrl -p -l | grep "New Tab - Google Chrome" | awk '{print $3}'
# But whatever the first value is is unique:
#  wmctrl -p -l | grep "New Tab - Google Chrome" | awk '{print $1}'

WINDOW_IDS=$(wmctrl -p -l | grep "New Tab - Google Chrome" | awk '{print $1}')

for window_id in $WINDOW_IDS; do

  # FIXME: This should not be hardcoded in home-fries. Move to waffle.
  #if [[ $(hostname) == 'larry' ]]; then
  # @larry is dead! Long live @larry!
  if false; then
    # If you have multiple monitors, a new Chrome window will be positioned
    # with y=0 and x=same as the x of the topmost Chrome window. As such,
    # if you have two monitors positioned diagonally, if the topmost chrome
    # window is on the bottom monitor, new chrome windows will be placed in
    # the dead (offscreen) space above it.
    #
    # To fix this problem, we have to know the dimensions of both monitors.
    #
    # hp L1925 1280x1024 / ASUS VS228H-P 1920x1080
    sleep $SLEEP_TIME
    wmctrl -i -a $window_id -b remove,maximized_vert,maximized_horz
    sleep $SLEEP_TIME
    wmctrl -i -a $window_id -e 0,1280,0,1920,1080
    # It doesn't always catch the first time.
    sleep $SLEEP_TIME
    wmctrl -i -a $window_id -b add,maximized_vert,maximized_horz
    sleep $SLEEP_TIME
    wmctrl -i -a $window_id
  else
    # Maximize the new tab window.
    #wmctrl -a "New Tab - Google Chrome"
    sleep $SLEEP_TIME
    wmctrl -i -a $window_id
    sleep $SLEEP_TIME
    wmctrl -i -a $window_id -b add,maximized_vert,maximized_horz
    sleep $SLEEP_TIME
    wmctrl -i -a $window_id
  fi
done

