#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=bash
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# Use a special character we can grep to determine if the mate-terminal
# window is to be made sticky or not.
# - Use a One Dot Leader - Unicode Character “․” (U+2024), i.e., looks
#   like a normal period, but it's not.
DUBS_STICKY_INDICATOR="․"

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# Called iff DUBS_ALWAYS_ON_VISIBLE=true.
sleep_then_ensure_always_on_visible_desktop() {
  # Note this fcn called backgrounded (&), so the sleep doesn't delay shell startup.
  sleep 3 #  MAGIC_NUMBER: It takes a few seconds for Home Fries to load.
  local winids
  winids=($(wmctrl -l -p |
    /bin/grep -E "^0x[a-f0-9]{8} +-?[0-3] +[0-9]+ +$(hostname) +[0-9]+${DUBS_STICKY_INDICATOR}" |
    cut -d ' ' -f 1))
  printf "%s\n" "${winids[@]}" | xargs -I % wmctrl -b add,sticky -i -r %
}

home_fries_always_on_visible_desktop() {
  if ${DUBS_ALWAYS_ON_VISIBLE:-false}; then
    # (lb): Gah. If you open lots of windows at once (or just change
    # focus to another window as the terminal is loading [as Home Fries
    # loads], the script's terminal window may no longer be the active
    # window! Like, duh! So this is no good:
    #
    #   wmctrl -r :ACTIVE: -b add,sticky
    #
    # Because I am unable to figure out how to find the owning window ID...
    # (I tried `xdotool search --pid $PPID`, but it appears all shells have
    # the same parent process, the one and only `mate-terminal`. And the
    # windows are not attached to the child, i.e., ``xdotool search --pid $$`
    # shows nothing (and `wmctrl -l -p` confirms that all terminal windows
    # share the same process ID (of the mate-terminal parent)), it looks like
    # our best bet is to use that special title prefix we set just prior to
    # this code being called (in _hf_prompt_configure).
    #
    # Ug again. I thought the title would be set already, but it's not...
    #
    #  winids=($(wmctrl -l -p \
    #    | /bin/grep -E "^0x[a-f0-9]{8} +-?[0-3] +[0-9]+ +$(hostname) +[0-9]+${DUBS_STICKY_INDICATOR}" \
    #    | cut -d ' ' -f 1))
    #
    # So rely on special default title in use before ours applies... "Terminal".
    # ... Ug triple! Other windows also have that name while loading, duh!
    #
    #   winids=($(wmctrl -l -p \
    #     | /bin/grep -E "^0x[a-f0-9]{8} +-?[0-3] +[0-9]+ +$(hostname) +Terminal$" \
    #     | cut -d ' ' -f 1))
    #
    # So, like, really? A total kludge is in order?! Deal with this "later!"
    #
    # NOTE: Use (subshell) to suppress output (e.g., job number and 'Done').
    (sleep_then_ensure_always_on_visible_desktop &)
    # We'll unset DUBS_ALWAYS_ON_VISIBLE later in bashrc.core.sh, after calling
    # _hf_set_iterm2_window_number_environ and setting up _hf_hook_titlebar_update,
    # so that new windows opened as child of this one are not similarly stickified.
    #   export DUBS_ALWAYS_ON_VISIBLE=  # Happens later.
  fi

  unset -f sleep_then_ensure_always_on_visible_desktop
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
