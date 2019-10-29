# vim:tw=0:ts=2:sw=2:et:norl:nospell:ft=sh

# USAGE: Useful for sorting and saving changes to your ~/.vim/spell/en.utf-8.add
#   There are probably additional uses, too.
# E.g.,
#
#   [${HOME}/.dotfiles]
#   autocommit =
#     # Sort the spell file, for easy diff'ing, or merging/meld'ing.
#     # - The .vimrc startup file will remake the .spl file when you restart Vim.
#     sort_file_then_commit '.mrinfuse/.vim/spell/en.utf-8.add'

source_deps () {
  # Load: warn, etc.
  . ${HOME}/.fries/lib/logger.sh
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

sort_file_then_commit () {
  local targetf="$1"

  # If `mr` run from a subdir, top-level .mrconfig found, but still run some subdir.
  local before_cd="$(pwd -L)"
  cd "${MR_REPO}"

  if [ -f "${targetf}" ]; then
    # NOTE: cat'ing and sort'ing to the cat'ed file results in a 0-size file!?
    #   So we use an intermediate file.
    local sortedf
    sortedf="$(mktemp --suffix='.myrepostravel')"

    /bin/cat "${targetf}" | /usr/bin/sort > "${sortedf}"
    /bin/mv -f "${sortedf}" "${targetf}"

    git_auto_commit_one "${targetf}"
  else
    warn
    warn 'WARNING: No file to sort and commit found at:'
    warn "  ${targetf}"
    warn
    return 1
  fi

  cd "${before_cd}"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main () {
  source_deps
}

main "$@"

