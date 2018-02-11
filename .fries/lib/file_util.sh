#!/bin/bash
# vim:tw=0:ts=2:sw=2:et:norl:

# File: file_util.sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project Page: https://github.com/landonb/home-fries
# Summary: Generic Bash function library.
# License: GPLv3

# Usage: Source this script. Call its functions. Use its exports.

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

source_deps() {
  :
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

home_fries_default_umask() {
  # Set umask to ensure group r-w-x permissions for new files and directories
  # (for collaborative development, e.g., so a co-worker can ssh to your machine
  # and poke around your files).
  #
  # This is more useful in a collaborative environment than on one's own machine.
  #
  #   As one example, if a naive user calls pg_restore from a remote
  #   machine but references a database dump on your machine, Psql will
  #   create intermediate files on your machine. If that user's umask is,
  #   e.g., 0077, then only that user will have read-write access to the
  #   files and you'll need to ask that user or use sudo to wipe the files.
  #
  # Remember: umask bits are removed from bits applied to the new file or dir.
  #   A 0000 umask won't mask anything
  #     and new files will be user-group-world read-writeable;
  #     new directories will be user-group-world read-writeable-executable
  #       and will have the sticky bit set.
  #   For 0006, files will be -rw-rw---- and dirs will be drwxrws--x.
  #
  # Circa 2009, Debian defaults to 0022 -- give group and world execute + read.
  # Ubuntu defaults to 0006, or r+w+x for owner and group, and just
  #                             execute for everyone else.
  # 2015.02.26: Linux Mint 17.1 defaults to 0022.

  #umask 0006
  # 2015.02.26: [lb] doesn't have anyone ssh'ing into my box anymore (or
  #             at least rarely ever) and since I'm developing web apps,
  #             I should probably default to no access for other, and
  #             then to deliberately use a fix-perms/web-perms macro to
  #             make htdocs/ directories accessible to the web user.
  #umask 0007
  # 2015.05.14: On second thought... After 'git pull' I have to fix permissions
  #             on the Excensus web application files, so might as well make life
  #             easier.
  umask 0002
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# Tell psql to use less for large output

home_fries_wire_export_less() {
  # In Fedora (at least not in Ubuntu at work), if this isn't on, psql
  # paginates large output, but you can only hit space to go through it
  # (there's no going backwards) and the output is left in the command
  # window. Using less, you can use the keys you normally use with less,
  # and when you're done, the output isn't left as crud in the window.
  # 2014.11.20: Add -R so ANSI "color" escape sequences work, otherwise
  # commands like `git log` will show escape characters as, e.g., ESC[33mc.
  #export PAGER=less
  export PAGER=less\ -R
  # -i or --ignore-case
  # -M or --LONG-PROMPT
  # -xn,... or --tabs=n,...
  # NOTE -F or --quit-if-one-screen
  #      This is cool in that, for short files, it just dumps the file
  #      and quits. But for multiple pages, the output remains in the
  #      terminal, which is annoying; I don't like crud!
  export LESS="-iMx2"

  # Hrmm. I cannot get this to work...
  if false; then
    # 2017-06-30: Make less and more more colorful.
    #   -R or --RAW-CONTROL-CHARS
    export LESS="-iMx2R"
    # 2017-06-30: Preprocess the input with pygmentize, for color.
    export LESSOPEN='|~/.lessfilter %s'
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# Helpers for fixing permissions (mostly for web-accessible files).

# Recursively web-ify a directory hierarchy.

webperms () {
  if [[ -z $1 || ! -d $1 ]]; then
    echo "ERROR: webperms: ‘$1’ is not a directory"
    return 1
  fi
  # Recurse through the web directory.
  # The naive `find` approach.
  #   find $1 -type d -exec chmod 2775 {} +
  #   find $1 -type f -exec chmod u+rw,g+rw,o+r {} +
  # A smarter approach: use chmod's 'X' flag to only add the
  # execute bit to directories or to files that already have
  # execute permission for some user.
  ##chmod -R o+rX $1
  #chmod -R u+rwX,g+rwX,o+rX $1
  ${DUBS_TRACE} && echo "Web dir.: $1"
  #chmod -R o+rX $1 &> /dev/null || sudo chmod -R o+rX $1
  chmod -R u+rwX,g+rwX,o+rX $1 &> /dev/null || sudo chmod -R u+rwX,g+rwX,o+rX $1
  # Also fix the ancestor permissions.
  local cur_dir=$1
  while [[ -n ${cur_dir} && $(dirname -- "${cur_dir}") != '/' ]]; do
    ${DUBS_TRACE} && echo "Ancestor: ${cur_dir}"
    # NOTE: Not giving read access, just execute.
      chmod -R o+X ${cur_dir} &> /dev/null || sudo chmod -R o+X ${cur_dir}
    local cur_dir=$(dirname -- "${cur_dir}")
  done
}

# Web-ify a single directory (does not recurse).
dirperms () {
  # find . -maxdepth 1 -type d -exec chmod 2775 {} +
  # find . -maxdepth 1 -type f -exec chmod u+rw,g+rw,o+r {} +
  local one_dir=""
  if [[ -z $1 ]]; then
    one_dir=".* *"
  else
    one_dir=$1
  fi
  chmod --silent u+rwX,g+rwX,o+rX $one_dir
}

# Reset file permissions on directory hierarchy.
# Caveat: Removes executable bits from executable files.
reperms () {
  # This doesn't work: it makes the current directory inaccesible:
  #   chmod --silent -R 664 $one_dir
  #   chmod --silent -R u+X,g+X,o+X $one_dir
  # Nor does this work: it doesn't un-executable-ify my files (weird):
  #   if [[ -z $1 ]]; then
  #     one_dir="."
  #   else
  #     one_dir=$1
  #   fi
  #   chmod --silent -R u-x,u+rwX,g-x,g+rwX,o-wx,o+rX $one_dir
  # Guess we'll stick with find:
  find $1 -type d -exec chmod 2775 {} +
  find $1 -type f -exec chmod 664 {} +
  echo "Done!"
  echo "But you'll want to chmod 775 executable files as appropriate."
  echo "To see a list of distinct file extensions, try:"
  echo " find . -type f | perl -ne 'print $1 if m/\.([^.\/]+)$/' | sort -u"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main() {
  : #source_deps
}

main "$@"
