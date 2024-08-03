#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=bash
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# 2020-03-20: I don't normally care about Ctrl-s too much,
#             but I find that the more I run Vim in a terminal
#             (because I'm wicked into tmux panes recently),
#             the more I inadvertently type Ctrl-s,
#               thinking that I'm saving,
#             then freaking out for a split second thinking
#             my machine or Vim froze, to getting frustrated
#             that I typed Ctrl-s, then remembering I need to
#             Ctrl-q, then :w. Ug.
#
# - tl;dr Make Ctrl-s work in terminal vim.
#
# - AFAIK, XON/XOFF flow control is only used for serial connections
#   (RS-232), so nothing lost by disabling this.
#
# - Ref: Some interesting background information on these settings:
#     https://unix.stackexchange.com/questions/12107/
#       how-to-unfreeze-after-accidentally-pressing-ctrl-s-in-a-terminal#12146

# Disable XON/XOFF flow control, and sending of start/stop characters,
#   i.e., reclaim Ctrl-s and Ctrl-q.
#
# - (lb): For whatever reason, -ixoff is already default for me, even on
#           bash --noprofile --norc
unhook_stty_ixon_ctrl_s_xon_xoff_flow_control () {
  stty -ixon -ixoff
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# Run the function if being executed.
# Otherwise being sourced, so do not.
if [ "$0" = "${BASH_SOURCE[0]}" ]; then
  unhook_stty_ixon_ctrl_s_xon_xoff_flow_control
fi

