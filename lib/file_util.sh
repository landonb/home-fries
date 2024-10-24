#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

home_fries_default_umask () {
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

home_fries_wire_export_less () {
  # In Fedora (at least not in Ubuntu at work), if this isn't on, psql
  # paginates large output, but you can only hit space to go through it
  # (there's no going backwards) and the output is left in the command
  # window. Using less, you can use the keys you normally use with less,
  # and when you're done, the output isn't left as crud in the window.
  # 2014.11.20: Add -R so ANSI "color" escape sequences work, otherwise
  # commands like `git log` will show escape characters as, e.g., ESC[33mc.
  #
  #  export PAGER=less
  export PAGER=less\ -R

  # -i or --ignore-case
  # -M or --LONG-PROMPT
  # -xn,... or --tabs=n,... [x2: Sets 2 tab stops. Default: 8, so wide!]
  # NOTE -F or --quit-if-one-screen
  #      This is cool in that, for short files, it just dumps the file
  #      and quits. But for multiple pages, the output remains in the
  #      terminal, which is annoying; I don't like crud!
  #
  export LESS="-iMx2"

  # 2020-09-19: Whoa, this one's nifty!
  # - Enable `less` syntax highlighting,
  #   like you see in your normal editor!
  # - Thanks to:
  #   https://danyspin97.org/blog/colorize-your-cli/#highlight
  # - Uses `highlight` (`apt install highlight`):
  #   http://www.andre-simon.de/doku/highlight/highlight.php
  # - You can add line numbers, but they seem distracting, or at least
  #   line numbers only seem useful for an editor, not a viewer.
  #     --line-numbers
  # - You can change the theme easily.
  #     --style <style>
  #   Some theme examples (screenshots):
  #     http://www.andre-simon.de/doku/highlight/theme-samples.php
  #   Some themes I like:
  #     candy
  #     matrix
  #     vampire
  #     molokai
  #     moria
  #     night
  #     edit-vim-dark [what default theme looks like]
  #   Find themes under:
  #     /usr/share/highlight/themes/
  # - To see list of supported file types:
  #     highlight --list-scripts=langs
  #
  # FIXME/2020-09-19: Default color (when not a recognized file type) is
  #                   green. Is that better than default white foreground
  #                   color (i.e., `LESSOPEN='' less ...`).
  #
  # Aka ${HOMEBREW_PREFIX}
  local brew_home="/opt/homebrew"
  # Otherwise on Intel Macs it's under /usr/local.
  [ -d "${brew_home}" ] || brew_home="/usr/local"
  [ -d "${brew_home}" ] || brew_home="/usr"
  #
  if [ -x "${brew_home}/bin/highlight" ]; then
    export LESSOPEN="| ${brew_home}/bin/highlight %s --out-format xterm256 --force"
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
  ${HOMEFRIES_TRACE} && echo "Web dir.: $1"
  #chmod -R o+rX $1 &> /dev/null || sudo chmod -R o+rX $1
  chmod -R u+rwX,g+rwX,o+rX $1 &> /dev/null || sudo chmod -R u+rwX,g+rwX,o+rX $1
  # Also fix the ancestor permissions.
  local cur_dir=$1
  while [[ -n ${cur_dir} && $(dirname -- "${cur_dir}") != '/' ]]; do
    ${HOMEFRIES_TRACE} && echo "Ancestor: ${cur_dir}"
    # NOTE: Not giving read access, just execute.
      chmod -R o+X ${cur_dir} &> /dev/null || sudo chmod -R o+X ${cur_dir}
    local cur_dir=$(dirname -- "${cur_dir}")
  done
}

# Web-ify a single directory (does not recurse).
# - REFER: How you might web-ify directory contents:
#     find . -maxdepth 1 -type d -exec chmod 2775 {} +
#     find . -maxdepth 1 -type f -exec chmod u+rw,g+rw,o+r {} +
dirperms () {
  local one_dir="$1"

  if [ -z "${one_dir}" ]; then
    one_dir=".* *"
  fi

  # Because `chmod --silent`
  chmod_kludge () {
    command -v gchmod || command -v chmod
  }

  $(chmod_kludge) --silent u+rwX,g+rwX,o+rX ${one_dir}
}

# Reset file permissions on directory hierarchy.
# Caveat: Removes executable bits from executable files.
reperms () {
  # This doesn't work: it makes the current directory inaccesible:
  #   chmod --silent -R 664 ${one_dir}
  #   chmod --silent -R u+X,g+X,o+X ${one_dir}
  # Nor does this work: it doesn't un-executable-ify my files (weird):
  #   if [[ -z $1 ]]; then
  #     one_dir="."
  #   else
  #     one_dir=$1
  #   fi
  #   chmod --silent -R u-x,u+rwX,g-x,g+rwX,o-wx,o+rX ${one_dir}
  # Guess we'll stick with find:
  find $1 -type d -exec chmod 2775 {} +
  find $1 -type f -exec chmod 664 {} +
  echo "Done!"
  echo "But you'll want to chmod 775 executable files as appropriate."
  echo "To see a list of distinct file extensions, try:"
  echo " find . -type f | perl -ne 'print $1 if m/\.([^.\/]+)$/' | sort -u"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

if false; then
  iterate_files_with_spaces_example () {
    while IFS= read -d $'\0' -r file ; do
      printf 'File found: %s\n' "${file}"
    done < <(find . -iname 'foo*' -print0)
  }
fi

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

mv_based_on_name () {
  local src_path=$1
  [ -z "${src_path}" ] && echo 'USAGE: mv_based_on_name FILE-PATH [TARGET-BASE]' && return 1
  [ ! -f "${src_path}" ] && echo "ERROR: FILE is not: “${src_path}”" && return 2

  local dst_base
  dst_base="${2:-${HOMEFRIES_MEDIA_BASE}}"
  dst_base="${dst_base:-.}"

  local copy_safe_dont_skip
  copy_safe_dont_skip=${3:-false}

  # NOTE: sed supports extended regex, which does not support (?:) non capturing groups.
  local dst_subd
  dst_subd="$( \
    echo "${src_path}" | \
    /usr/bin/env sed -E 's#.*(^|/)(IMG_|VID_|PXL_)?([0-9]{4})([0-9]{2})([0-9]{2})_(.*)$#'${dst_base}'/\3/\4/\3_\4_\5#' \
  )"

  if [ "${src_path}" = "${dst_subd}" ]; then
    dst_subd="$( \
      echo "${src_path}" | \
      /usr/bin/env sed -E 's#.*(^|/)([0-9]{4})_([0-9]{2})_([0-9]{2})/(IMG_|VID_|PXL_)(.*)$#'${dst_base}'/\2/\3/\2_\3_\4#' \
    )"
  fi

  if [ "${src_path}" = "${dst_subd}" ]; then
    echo "ERROR: Could not parse date from filename: “${src_path}”"
    return 3
  fi

  local dst_file
  dst_file=$(basename -- "${src_path}")
  local dst_path
  dst_path="${dst_subd}/${dst_file}"

  if [ -e "${dst_path}" ] || [ -h "${dst_path}" ]; then
    # MEH/2019-04-25: We could add a `diff` here to skip/not copy if not changed.
    # - (lb): But all my use cases are to use fdupes beforehand, so... hrmmm.....
    if diff "${src_path}" "${dst_path}"; then
      echo "NOTICE: No differences: “${dst_path}”"
      return 0
    fi

    # Target either exists (or is a broken symlink); add date to avoid name clash.
    if ! ${copy_safe_dont_skip}; then
      echo "WARNING: Already exists: “${dst_path}”"
      return 0
    fi
    # NOTE: It is expected caller handles duplicate files first, e.g.,
    #       by running `fdupes`, so this function does not go out of its
    #       way to handle clashes other than to just not be destructive,
    #       but to still complete the mv.
    file_name="${dst_file%.*}"
    file_ext="${dst_file##*.}"
    # 2020-08-26: Note that `date +%N` is not an option on macOS, prints just 'N'.
    # We could call print_nanos_now for nanos, but we're adding the N to
    # generate a unique name -- so might as well replace with UUID fragment.
    dst_path="${dst_subd}/${file_name}-$(date +%Y_%m_%d_%Hh%Mm%Ss)-$(uuidgen | head -c8).${file_ext}"
    echo "NOTICE: Renamed on copy: “${dst_path}”"
  fi

  mkdir -p -- "${dst_subd}/"
  command mv -i -- "${src_path}" "${dst_path}"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main () {
  :
}

main "$@"
unset -f main

