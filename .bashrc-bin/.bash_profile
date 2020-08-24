# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# macOS sources ~/.bash_profile on new Terminal.app window,
# but then it sources ~/.bashrc on /bin/bash command.

# sw_vers is macOS's ProductName, ProductVersion, and BuildVersion reporter.
[ "$(sw_vers &> /dev/null)" ] && [ -r ~/.bashrc ] && . ~/.bashrc

