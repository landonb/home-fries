#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

home_fries_aliases_wire_fd() {
  # `fd` is `fdfind` on Debian 12, Ubuntu 20.04, etc.
  # REFER: https://github.com/sharkdp/fd/issues/1009
  #   https://stackoverflow.com/questions/1583219/how-can-i-do-a-recursive-find-replace-of-a-string-with-awk-or-sed/71931037#71931037
  if ! (
    unset -f fdfind
    unalias fdfind
    command -v fdfind
  ) >/dev/null 2>&1; then

    claim_alias_or_warn "fdfind" "fd"
  fi

  if _hf_fd_abs_path >/dev/null; then
    alias fd="_hf_fd -I"

    # Without the --no-ignore
    claim_alias_or_warn "fdi" "_hf_fd"

    # Without the output-stream-blocking final `ls` command:
    claim_alias_or_warn "fdx" "HOMEFRIES_FD_EXEC_BATCH=false _hf_fd"
  fi
}

# 2020-09-26: -H/--hidden: Include hidden files and directories
# 2024-05-07: -L/--follow: Descend into symlinked directories.
#                          - Override with --no-follow
#                          - How was this not added sooner?
# 2021-11-10: -I/--no-ignore: Ignore .gitignore, .ignore or .fdignore rules.
# 2023-01-25: - I want to use -H and -I because I use ignore rules to avoid
#               duplicate grep results caused by symlinks, but I don't want
#               `fd` to ignore those symlinks. (Another way to consider this:
#               my `fd` rules are different than my `rg` rules, but I do not
#               want to have to maintain two sets of rules.)
#               - Anyway, here's that basic command:
#                   alias fd="fd -H -I"
#               - However, you'll end up with some obvious noise, like any
#                 .git/ directory.
#               - Fortunately, a little `fd` noise is not a big deal (I don't
#                 run `fd` often), but seeing a bunch of .git/ hits (e.g., in
#                 .git/refs branch names) that are obviously uninteresting to
#                 any user is certainly beyond the pale (and users can just
#                 `cd` into .git/ dir if they really want to search it).
#               - So let's inject some hardcoded business logic here, but it's
#                 generally pretty universal business logic, so no worries,
#                 there is no coupling concern (by which I mean, for now it's
#                 just one rule to ignore .git/ dirs, but maybe we'll identify
#                 more rules later, and perhaps then we'll want to make this
#                 setting customizable; but for now `-E .git/` is too easy).
#             -E/--exclude pattern: I think this is the easiest approch
#               (note: "This overrides any other ignore logic." but we're
#                also using -I so doesn't matter).
#             --ignore-file path: Alternative approach
#               (e.g., `/usr/bin/env fd -H -I --ignore-file <(echo .git/) <term>`
#               2025-09-08: `man fd` (fdfind) v8.6.0 (from APT fd-find on Debian 12) says:
#                 --ignore-file path: Add a custom ignore-file in '.gitignore' format.
#                   These files have a low precedence.
#               - So not *alternative* to --ignore behavior, but *in addition* to.
#                 Per -I/--no-ignore help, fd will check --ignore files (.gitignore,
#                 .git/info/exclude, ~/.config/git/ignore, .ignore, .fdignore, and
#                 ~/.config/fd/ignore), and then check --ignore-file.

# SAVVY: `-E/--exclude` unaffected by later `-u`.
# - For instance, the following does not work as expected
#   (or at least how author originally expected):
#     fd -E node_modules/ -u {term}
#   - Despite --unrestricted following --exclude,
#     `fd` will still not search node_modules/.
# - Note that -u will override --no-hidden and --ignore.
#   - E.g., this command is unrestricted:
#       fd --no-hidden --ignore --unrestricted {term}
#     But this command is restricted:
#       fd --unrestricted --no-hidden --ignore {term}
# - As such, when user specifies -u/--unrestricted,
#   omit the -E/--exclude and --ignore-file args
#   (which configure a set of default args most users
#   should appreciate, such as skipping node_modeles/
#   and site-packages/ dirs, and using '.fdignore'
#   but ignoring '.gitignore'), and set no_hidden and
#   no_ignore accordingly.

_hf_fd() {
  local no_follow=false
  local no_hidden=false
  local no_ignore=false
  local unrestricted=false
  local exec_batch=""
  local format=""
  local format_pending=false

  local arg
  for arg in "$@"; do
    if ${format_pending}; then
      format="--format $1"
      format_pending=false
      continue
    fi

    case "${arg}" in
    -L | --follow) no_follow=false ;;
    --no-follow) no_follow=true ;;
    -H | --hidden) no_hidden=false ;;
    --no-hidden) no_hidden=true ;;
    --ignore) no_ignore=false ;;
    -I | --no-ignore) no_ignore=true ;;
    -u | --unrestricted)
      unrestricted=true
      no_hidden=false
      no_ignore=true
      ;;
    --format)
      format_pending=true
      ;;
    # See following comment — Cannot add non-fd options, e.g.:
    #   --exec-batch) exec_batch="..." ;;
    esac
  done

  # Currently, CLI args are passed-through to `fd` below, and we
  # don't rebuild $@ specially. So each arg must match a legit
  # `fd` option. As such, other options should be vars/environs,
  # possibly presented to user via separate command name (e.g.,
  # how `fdx` alias sets the HOMEFRIES_FD_EXEC_BATCH variable).
  #
  # HSTRY/2026-05-19: Adding `--exec-batch` to default `fd`
  # behavior, for deterministic, and ordered, search results.
  # - Note this probably mostly works well in practice (author
  #   cannot detect any more or less lag with or without
  #   `--exec-batch ls`, at least for simple searches).
  #  - But if you run a search that blocks `fd` and its output
  #    for longer than you appreciate, cancel the search and
  #    run `fdx` (see alias above) to run a "normal" fd command,
  #    which streams results, outputting each path as its found.
  #
  # SAVVY: Note the ls output is a single color, not separate colors
  #   for directories and basename, like default fd. On the other
  #   hand, both eza and lsd highlight similar to fd; though they
  #   both add "./" prefix to path matches.
  if [ "${HOMEFRIES_FD_EXEC_BATCH}" = "fd" ] ||
    [ "${HOMEFRIES_FD_EXEC_BATCH}" = "false" ]; then
    exec_batch=""
  elif [ "${HOMEFRIES_FD_EXEC_BATCH}" = "ls" ]; then
    exec_batch="--exec-batch ls -1d --color=always"
  elif [ "${HOMEFRIES_FD_EXEC_BATCH}" = "lsd" ]; then
    # --classify: Appends one of: */=>@|
    exec_batch="--exec-batch lsd -1d --classify --color always"
  elif [ "${HOMEFRIES_FD_EXEC_BATCH}" = "eza" ] ||
    # BONUS: In addition to ensuring results sorted consistently between
    # repeated queries, also indicates file type, and shows symlink targets.
    command -v eza >/dev/null; then

    exec_batch="--exec-batch eza --oneline -d"
  fi

  # ***

  local exclude="${HOMEFRIES_FD_EXCLUDE}"

  # Common ignore rules everyone should enjoy.
  if ${no_ignore} && ! ${unrestricted} && test -z "${HOMEFRIES_FD_EXCLUDE+x}"; then
    # USYNC: Similar ignore lists (in different DepoXy projects):
    #   ~/.depoxy/ambers/home/.kit/git/ohmyrepos/lib/infuse-personal-projlns.sh
    #   ~/.depoxy/ambers/home/.projlns/infuse-projlns-omr.sh
    #   ~/.homefries/lib/alias/alias_fd.sh
    #   ~/.kit/nvim/landonb/dubs_project_tray/plugin/dubs_project.vim
    for exclude_dir in \
      ".git/" \
      "htmlcov/" \
      "node_modules/" \
      ".nyc_output/" \
      "__pycache__/" \
      ".pytest_cache/" \
      "site-packages/" \
      ".tox/" \
      ".trash/" \
      ".venv/" \
      "'.venv-*/'" \
      ".vscode/"; do

      exclude="${exclude} -E ${exclude_dir}"
    done
  fi

  # ***

  # When --ignore (and not -I/--no-ignore), this arg. redundant
  # (unnecessary) when it's the default, '.fdignore', because
  # `fd --ignore` also uses '.fdignore'.
  # - We add this arg. because our `alias fd` (above) adds the
  #   -I/--no-ignore arg, so that our search uses '.fgignore'
  #   *but not '.gitignore'*.
  #   - This is because '.gitignore' often ignores files you might
  #     want to find (e.g., build files), so it's better (you have
  #     more control) if you use '.gitignore' just for git commands,
  #     and you use '.fdignore' for fd commands.
  local ignore_file_path="${HOMEFRIES_FD_IGNORE_FILE:-.fdignore}"

  local ignore_file_arg=""
  if ${no_ignore} && ! ${unrestricted} && test -f "${ignore_file_path}"; then
    ignore_file_arg="--ignore-file '${ignore_file_path}'"
  fi

  # ***

  local fd_cmd="$(_hf_fd_abs_path) $(
    ${no_hidden} || printf "%s" "-H"
  ) $(
    ${no_follow} || printf "%s" "-L"
  ) ${format} ${exclude} ${ignore_file_arg} $@ \\
    ${exec_batch}"

  ! ${HOMEFRIES_FD_TRACE:-false} || echo "${fd_cmd}"

  eval "${fd_cmd}"
}

# ***

# SAVVY: Don't `command -v fd` and return, e.g., `alias fd=...`, but
# unset and unalias first to avoid that. Note this subprocess approach
# works in Dash, too.
_hf_fd_abs_path() {
  for cmd in "fd" "fdfind"; do
    (
      unset -f ${cmd}
      unalias ${cmd}
      command -v ${cmd}
    ) 2>/dev/null &&
      break
  done
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

unset_f_alias_fd() {
  unset -f home_fries_aliases_wire_fd
  # So meta.
  unset -f unset_f_alias_fd
}

# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ #

if [ "$0" = "${BASH_SOURCE[0]}" ]; then
  >&2 echo "ERROR: Trying sourcing the file instead: . $0" && exit 1
fi
