#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# *** Directory listings.

home_fries_aliases_wire_ls() {
  local ls_cmd="$(ls-or-gls)"

  # 2015-01-20: Using --color=tty still works, but `man` says use --color=auto.
  local color_opt="--color=auto"

  # Human readable /bin/ls that classifies files, shows all-
  # most all entries (excludes ./ and ../), and uses colour.
  claim_alias_or_warn "ls" "$(print_file_url_friendly_ls_alias)" ${_force:-true}

  # Compact /bin/ls listing (same as -hFA, really), but list
  # directories first, which seems to make the output cleaner.
  # - See `l` function, below, so we can pipe to tail and get rid of "total" line.
  #  alias l="${ls_cmd} -lhFA ${color_opt} --group-directories-first"

  # ***

  # Long /bin/ls listing, which includes ./ and ../ (perhaps
  # so you can check permissions).
  # - See `ll` function below, which ensures @macOS sorts like @Linux.
  #   - This is the legacy alias which sorts differently on either OS,
  #     which might annoy you if you use both and want both to behave
  #     as similarly as possible, so author assumes you want the new
  #     `ll` function.
  # - But we'll keep this for posterity, suffixed with an 'X'.
  claim_alias_or_warn "llX" "${ls_cmd} -lhFa ${color_opt}"

  # 2017-07-10: Show ISO timestamps.
  # - E.g., "2024-04-14 14:57" instead of "Jun 12 13:52".
  claim_alias_or_warn "lllX" "llX --time-style=long-iso"

  # Reverse sort by time. [2022-11-04: I use this very often.]
  claim_alias_or_warn "lo" "${ls_cmd} -lhFa -rt ${color_opt}"

  # Reverse sort by time; show ISO dates.
  # - [2022-11-04: I (almost?) never use either ISO option.
  #    2024-06-12: Which is odd, because I love ISO format.]
  claim_alias_or_warn "llo" "lo --time-style=long-iso"

  # Sort by size, from largest (empties last). [2022-11-04: I use this sometimes.]
  # - Huh, this conflicts with /bin/lS on macOS, some alternative `ls`, not sure.
  #  claim_alias_or_warn "lS" "${ls_cmd} ${color_opt} -lhFaS"
  alias lS="${ls_cmd} ${color_opt} -lhFaS"

  # Sort by size, largest last. [2022-11-04: I'd forgotten about this one.]
  claim_alias_or_warn "lS-" "${ls_cmd} -lFaS --color=always | sort -n -k5"

  # ***

  # L* aliases do not list owner (replace -l with -g),
  # and do not list group name (add -G).

  # Long listing, which includes ./ and ../, without owner.
  claim_alias_or_warn "LL" "${ls_cmd} -gGhFa ${color_opt}"

  # Reverse sort by time, without owner.
  claim_alias_or_warn "LO" "LL -rt"

  # ***

  # THANX: https://github.com/lukas-reineke/dotfiles/blob/02064d6dccb2e/bash/aliases.sh
  claim_alias_or_warn "tree-eza" "eza -alT --icons=always"

  # ***

  # REFER/2025-11-11: Colorful aliases inspired by Debian 13 stock ~/.bashrc.

  claim_alias_or_warn "dir" "dir --color=auto" ${_force:-true}
  claim_alias_or_warn "vdir" "vdir --color=auto" ${_force:-true}

}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# `l` is like `ls -la`, but:
# - It omits the . and .. directories; and
# - It chops the "total" line.
# Basically, it omits the first three lines from a basic listing:
#   $ /usr/bin/env ls -la
#   total 20K
#   drwxrwxr-x  4 landonb landonb 4.0K Dec 17 02:32 ./
#   drwxr-xr-x  3 landonb landonb 4.0K Apr  9 17:08 ../
# (the --almost-all/-A will omit the current and parent directories,
#  and then pipe to tail to strip the "total", which `ls` includes
#  with the -l[ong] listing format).
#
# - SAVVY: The `l` command sorts differently on @Linux and @macOS:
#   - @Linux ignores punctuation and case.
#   - @macOS sorts dotfiles first, then UPPER, then lower.
#   - I tested various language options (LC_ALL) to no avail.
#   - INERT: Add OS-agnostic sorting like `function ll()`.
#     - (Author doesn't use `l` enough to care about its sort.)

function l() {
  function _hf_cattail() {
    if [ $# -eq 0 ]; then
      # E.g., `tail --lines=+2`
      tail +2
    else
      cat
    fi
  }

  $(ls-or-gls) -lhFA \
    --color=always \
    --hide-control-chars \
    --group-directories-first \
    "$@" |
    _hf_cattail "$@"

  unset -f _hf_cattail
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# ls with file:// support.
#
# MAYBE: Add similar support to `ll`.
# - I've added to `ls` because relatively trivial, and wanted to
#   see how it'd be implemented.

# DEVEL: Hrmm... ls in same line uses old alias, ha, so run *twice* <Up><CR><Up><CR>
#
#   unalias ls && . ~/.kit/sh/home-fries/lib/alias/alias_ls.sh && home_fries_aliases_wire_ls && echo && type -a ls && echo && ls file://.

# Note we don't `if ! ls ...; then`, because don't want to have to handle errors.
# - E.g., shouldn't just assume error is because this.
#   ls: cannot access 'file://.': No such file or directory

# Meh: Could we avoid using a string?
# - Maybe not because quoting and expansion needs.
# - E.g.,
#   cmd=$(declare -f file_url_friendly_ls | tail -n +3 | sed '$d')

# ALERT: This does not handle spaces in filenames.
# - E.g., consider:
#     $ command ls "README.rst file://README.rst"
#     ls: cannot access 'README.rst README.rst': No such file or directory
#
#     $ ls "README.rst file://README.rst"
#     README.rst  README.rst
#
# INERT: FTREQ: Support quotes.
# - E.g.,
#     $ ls -1 "file://foo bar"
# - SPIKE: The `echo "$@"` loses the meaning...
#   - Would we have to make the command using proper quote
#     and then call `ls` using `eval`?
#     - I'm not thinking of another way to do it....
# - One option would be to "manually" support up to
#   nine arguments, and then use `set --` or something...
#   - Seems somewhat tedious, though, would you need
#     nine different set calls? set -- "$1", set -- "$1" "$2",
#     etc.?
#
# MAYBE: What about being more like `ll`, and checking arg count?
#    if [ $# -gt 1 ]; then
#      ... (just call ls without processing)

print_file_url_friendly_ls_alias() {
  printf "%s" "\
  _ls() {
    if [ \\\$# -gt 1 ]; then
      ${ls_cmd} -hFA ${color_opt} \\\"\\\$@\\\";
    else
      echo \\\"'\\\${1:-.}'\\\" | command sed -e \\\"s#^'file://#'#g\\\" | xargs ${ls_cmd} -hFA --color=auto;
    fi;
  }; _ls" |
    sed -e 's/^ \+//g' |
    tr "\n" " "
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# Long /bin/ls listing, which includes ./ and ../ (perhaps
# so you can check permissions).

# On Linux, you can just run ls:
#
#   ls -lhFa --color=auto
#
# But @macOS doesn't ignore leading punctuation — and I like my
# dot (hidden) files intermingled with non-dots, and also upper-
# and lowercase intermingled (case-insensitive).
#
# - I couldn't find a simple fix with LC_COLLATE/LC_ALL/LANG,
#   so we'll do it the hard way, using a command pipeline and
#   a complicated `sed` call.
#
# - Note that `ls -lhFa | sort -d -f -k 9,9` *almost* works,
#   but it doesn't preserve color =(. (And using
#   --color=always breaks the sort).

# REFER: These are the sed options used below:
#
#   h                   Copy the line to the hold space: "(hold) Replace the
#                       contents of the hold space with the contents of the
#                       pattern space."
#
#   s/^\([^ ]\+\(...    Remove all but the 9th column (file path)
#
#   s/\x1b[[0-9;]*m//g  Remove all colour sequences
#
#   s/^$/\./;s/^\.\/$/\.\./;s/^\.\.\/$/\.\.\./
#                       Ensure first 3 `ls -la` lines keep their position
#
#   G                   Append a newline and the contents of the hold space:
#                       "Append a newline to the contents of the pattern space,
#                        and then append the contents of the hold space to
#                        that of the pattern space."
#
#                       - This works because the previous s/// commands
#                         altered the pattern space, which is now the new
#                         sort key, and we append the original output line.
#                         (As opposed to 'H' command, which does it in the
#                          reverse: H appends "a newline to the contents of
#                          the hold space, and then append[s] the contents
#                          of the pattern space to that of the hold space."
#
#   s/\n/\t/            Change the newline to a tab
#
# REFER
#
#   https://www.gnu.org/software/sed/manual/sed.html#sed-commands-list
#
# - And special thanks for the pro 'h' and 'G' tips from this question:
#
#   https://stackoverflow.com/questions/29399752/bash-sort-command-not-sorting-colored-output-correctly
#
# Also:
#
#   sort -d             --dictionary-order
#   sort -f             --ignore-case
#   sort -k1,1          Sort on the first column
#   LC_ALL=C            So the first column is recongized
#
#   cut -f2-            Remove the first column

# Too slow: sed has an inline execute command option ('s//e'), but
# there's too much subprocess overhead:
#   s/.../e             e: "Executes the command that is found in pattern
#                        space and replaces the pattern space with the
#                        output; a trailing newline is suppressed."
#
#     function ll-slow () {
#       # Too slow (but simpler 'sed' than the `ff` function below)
#       $(ls-or-gls) -lhFa --color=always \
#         | sed 'h;s/^\(.*\)$/echo "\1" | awk "{print \\$9}"/e;s/\x1b[[0-9;]*m//g;G;s/\n/\t/' \
#         | sort -d -f \
#         | cut -f2-
#     }
#
# The faster solution (next) uses a tediously repetitive sed pattern
# to remove the first optional 8 fields, split by whitespace(s).
# - Optional because the first `ls` line has fewer, e.g., "total 488K".
# - Also strip trailing '/' from './' and '../' or they sort in reverse.
#   - And convert empty "total 488K" key to "." (and "." to "..", and
#     ".." to "...") so that it's not sorted according to "total"
#     (and so the first 3 lines keep their order).
#
# - BWARE: The fast approach doesn't work with path spaces.
#           (*But neither should you*)
#
# - BWARE: You can pass-through `ls` options to `ll`, but it might
#          affect the column count and bork the output.

# FEATR: If only one `ll` argument specified, strip "file://" prefix.
# - UCASE: Copy path from browser location and paste to terminal
#          (at least for `ls` and `ll` commands).

# MPROV: Exclude macOS system files you *shouldn't* care about (or at
# least author cannot imagine a scenario where you would care):
#
# - .DS_Store —   Apple's Desktop Services Store, created and managed
#                 by Finder when you view a particular directory.
#
#                   https://en.wikipedia.org/wiki/.DS_Store
#
#                 You can also manage .DS_Store files programmatically:
#
#                 - *Reading Writing ".DS_Store" Files*
#                   https://www-old.cs.utah.edu/plt/popl16/doc/ds-store/index.html#
#
#                 - *DS_Store Format*
#                   https://metacpan.org/dist/Mac-Finder-DSStore/view/DSStoreFormat.pod
#
# - .localized —  macOS uses empty .localized files to indicate to Finder to
#                 show a localized name for a directory, e.g., ~/Documents
#                 vs. ~/Dokumente, based on the user's language setting.
#
#                 - *What are .localized files?*
#                   https://discussions.apple.com/thread/252040
#
#                 - *".localized" folders in MacOS*
#                   https://discussions.apple.com/thread/254061065
#
#                 You can also manage your own .localized files, i.e.,
#                 for an app that uses specific directory names.
#
#                 - *Localizing the Name of a Directory*
#                   https://developer.apple.com/library/archive/documentation/FileManagement/Conceptual/FileSystemAdvancedPT/LocalizingtheNameofaDirectory/LocalizingtheNameofaDirectory.html

# TL_DR: `ll` sorts like @Linux `ls -la` on @macOS, and excludes Finder files.

function ll() {
  if [ $# -gt 1 ]; then
    $(ls-or-gls) -lhFa --color=always "$@"
  else
    $(ls-or-gls) -lhFa --color=always "$(echo "${1:-.}" | command sed -e 's#^file://##g')" |
      $(gnu_sed) 'h;s/^\([^ ]\+\( \+[^ ]\+\( \+[^ ]\+\( \+[^ ]\+\( \+[^ ]\+\( \+[^ ]\+\( \+[^ ]\+\( \+[^ ]\+ \+\)\?\)\?\)\?\)\?\)\?\)\?\)\?\)\?//;s/\x1b[[0-9;]*m//g;s/^$/\./;s/^\.\/$/\.\./;s/^\.\.\/$/\.\.\./;G;s/\n/\t/' |
      _hf_filter_ll "$@" |
      LC_ALL=C sort -d -f -k1,1 |
      cut -f2-
  fi
}

function _hf_filter_ll() {
  if test "$(command ls -A "$@" 2>/dev/null)" = ".DS_Store" ||
    test "$(command ls -A "$@" 2>/dev/null)" = ".localized" \
    ; then

    cat
  else
    grep -v -e "^\.localized\t" -e "^\.DS_Store\t"
  fi
}

# Show ISO timestamps.
# - E.g., "2024-04-14 14:57" instead of "Jun 12 13:52".
# - USYNC: The `--time-style=long-iso` reduces columns by 1, so
#   the command is same as `ll` minus the last \(...\)\? group.
function lll() {
  if [ $# -gt 1 ]; then
    $(ls-or-gls) -lhFa --time-style=long-iso --color=always "$@"
  else
    $(ls-or-gls) -lhFa --time-style=long-iso --color=always "$@" |
      $(gnu_sed) 'h;s/^\([^ ]\+\( \+[^ ]\+\( \+[^ ]\+\( \+[^ ]\+\( \+[^ ]\+\( \+[^ ]\+\( \+[^ ]\+\)\?\)\?\)\?\)\?\)\?\)\?\)\?//;s/\x1b[[0-9;]*m//g;s/^$/\./;s/^\.\/$/\.\./;s/^\.\.\/$/\.\.\./;G;s/\n/\t/' |
      LC_ALL=C sort -d -f -k1,1 |
      cut -f2-
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# REFER: https://github.com/lsd-rs/lsd
#   brew install lsd
function lld() {
  lsd -lhFa --color=always "$@"
}

# REFER: https://github.com/eza-community/eza
#   brew install eza
function llz() {
  # 2024-09-16: I haven't read the `man`, this snip from:
  #   https://stackoverflow.com/questions/78298133/
  eza --icons --long --header
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# REFER: For macOS ACL features, use `/bin/ls`, e.g., `/bin/ls -led ~/.Trash`
# - See `man ls` and `man chmod` for more on ACL.
ls-or-gls() {
  if ! command -v gls; then
    echo "/usr/bin/env ls"
  fi
}

gnu_sed() {
  for cmd in "gsed" "sed"; do
    (
      unset -f ${cmd}
      unalias ${cmd}
      command -v ${cmd}
    ) 2>/dev/null &&
      break
  done
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

unset_f_alias_ls() {
  unset -f home_fries_aliases_wire_ls
  # So meta.
  unset -f unset_f_alias_ls
}

# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ #

if [ "$0" = "${BASH_SOURCE[0]}" ]; then
  >&2 echo "ERROR: Trying sourcing the file instead: . $0" && exit 1
fi
