#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

check_deps() {
  # Verify sh-logger/bin/logger.sh loaded.
  check_dep '_sh_logger_log_msg'
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

home_fries_aliases_wire_rg_tag() {
  home_fries_create_aliases_rg_tag_wrap
  home_fries_create_aliases_rg_options
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# 2018-03-26: Fancy ag/rg wrapper makes jumping to search result seamless!
#
#   https://github.com/aykamko/tag
#
#   OPTIONS             Default/Choices
#   ------------------  --------------------------------------------------------
#   TAG_SEARCH_PROG     ag | rg
#   TAG_ALIAS_FILE      /tmp/tag_aliases
#   TAG_ALIAS_PREFIX    e                 [e.g., ``e1`` opens first match]
#   TAG_CMD_FMT_STRING  vim \
#                         -c 'call cursor({{.LineNumber}}, {{.ColumnNumber}})' \
#                         '{{.Filename}}'

home_fries_create_aliases_rg_tag_wrap() {
  local rg_cmd='rg'

  if ! hash ${rg_cmd} 2>/dev/null; then
    warn "ERROR: Rip Grep not found"

    return 1
  fi

  # Choices: ag, rg
  export TAG_SEARCH_PROG=${rg_cmd}

  tag() {
    local aliases="${TAG_ALIAS_FILE:-/tmp/tag_aliases}"
    command rm -f "${aliases}"

    local tag_ecode
    # See: ${HOME}/.gopath/bin/tag
    command tag "$@"
    tag_ecode=$?
    # tag passes through rg exit: 0 if 1+ matches, 1 if none, or 2 if error.
    if [ ${tag_ecode} -eq 0 ]; then
      if ! [ -s "${aliases}" ] || ! . "${aliases}"; then
        >&2 echo "GAFFE: Missing or broken tag aliases file"
        tag_ecode=3
      fi
    fi

    return ${tag_ecode}
  }

  # [lb] 2019-01-06: BEWARE: --no-ignore-parent can be used to ignore .ignore's
  #   up the path. I mention it because the feature is easily forgotton when one
  #   is tracking down which .ignore file is resposible for a file being ignored.
  # - ODDLY/2024-10-18: macOS `man rg` does not show '--no-ignore-parent'
  #   or '--no-ignore-vcs', but `rg --help` does.
  # SAVVY: Testing shows `rg` skip graphics formats: *.jpg, *.png, *.xcf
  # USYNC: Similar rg --glob's (found locally at these paths within DepoXy environ):
  #   ~/.depoxy/ambers/core/fzf-setup.sh
  #   ~/.kit/sh/home-fries/lib/alias/alias_rg_tag.sh
  #   ~/.kit/nvim/landonb/dubs_grep_steady/bin/vim-grepprg-rg-sort
  #   ~/.kit/nvim/landonb/.whilom/dubs_file_finder/plugin/dubs_file_finder.vim
  # - Note ~/.[tT]rash0? per https://github.com/landonb/sh-rm_safe#🗑

  local dglobs=()
  local fglobs=()
  # Common dev tool directories
  dglobs+=(".git")
  dglobs+=(".tox")
  dglobs+=("node_modules")
  # Home directories
  # Vim's ~/.vim_backups/*.swp
  fglobs+=("*.swp")
  # Graphics, Document, and other files (you probably won't open in text)
  fglobs+=(".bash_history")
  fglobs+=("*.bin")
  fglobs+=("*.gif")
  fglobs+=("*.gpg")
  fglobs+=("*.jpg")
  fglobs+=("*.Jpg")
  fglobs+=("*.JPG")
  fglobs+=("*.nib")
  fglobs+=("*.odg")
  fglobs+=("*.odt")
  # SAVVY: `rg --ignore-case` doesn't seem to work on globs, so add permutations
  fglobs+=("*.pdf")
  fglobs+=("*.Pdf")
  fglobs+=("*.PDF")
  fglobs+=("*.png")
  fglobs+=("*.pyc")
  fglobs+=("*.svg")
  fglobs+=(".viminfo")
  fglobs+=("*.xpm")
  fglobs+=("*.zip")
  # DepoXy-specific directories
  dglobs+=(".crypt")
  # Vim :Helptags tags files
  fglobs+=("doc/tags")
  # Trash directories (that you'll probably ignore from ~/.ignore, anyway)
  #   dglobs+=(".trash")
  #   dglobs+=(".trash0")
  #   dglobs+=(".Trash")
  #   dglobs+=(".Trash0")

  local dir_globs=""
  local dglob
  for dglob in "${dglobs[@]}"; do
    [ -z "${dir_globs}" ] || dir_globs="${dir_globs},"
    dir_globs="${dir_globs}${dglob}"
  done

  local file_globs=""
  local fglob
  for fglob in "${fglobs[@]}"; do
    [ -z "${file_globs}" ] || file_globs="${file_globs},"
    file_globs="${file_globs}${fglob}"
  done

  # USYNC: #_rg_colors
  local rg_wrap_with_options="$(
    echo "
      tag
        --with-filename
        --smart-case
        --hidden
        --follow
        --no-ignore-vcs
        --no-ignore-parent
        --colors 'path:fg:yellow'
        --colors 'path:style:bold'
        --colors 'line:fg:green'
        --colors 'line:style:bold'
        --colors 'column:none'
        --colors 'match:bg:white'
        --glob '!**/{${dir_globs}}/**'
        --glob '!**/{${file_globs}}'
    " | tr -d $'\n' | sed 's/  \+/ /g' | sed 's/^ \+//' | sed 's/ \+$//'
  )"

  # `rgt` will search and wire the `e*` commands to open
  #       each search result in Vim in current *terminal*.
  #
  # NOTE: So that other scripts can source this script and call `rgt`,
  #       define as a function, and not as an alias. Note the eval,
  #       which is necessary to expand ${rg_wrap_with_options}.
  eval "rgt () {
    TAG_CMD_FMT_STRING='vim -c \"call cursor({{.LineNumber}}, {{.ColumnNumber}})\" \"{{.Filename}}\"' \
      ${rg_wrap_with_options} \"\${@}\"
  }"

  # `rg` (yes, this replaces, but still uses, ripgrep's rg!)
  #      will search and wire the `e*` result commands to open
  #      each search result in a GVim window, and switch to it.

  # CXREF: https://github.com/DepoXy/gvim-open-kindness#🐬
  # - If using DepoXy, it's at:
  #   ~/.kit/sh/gvim-open-kindness/bin/gvim-open-kindness
  #   - You can choose nvim w/ GVIM_OPEN_PREFER_NVIM=true:
  #     ~/.depoxy/running/home/.config/depoxy/depoxyrc
  #
  # REFER: The gvim-open-kindness script uses $GVIM_OPEN_SERVERNAME
  # to indicate which GVim instance to use, or NVIM_OPEN_SOCKETNAME
  # for Neovim if GVIM_OPEN_PREFER_NVIM is true. If you do not
  # set or change this value, each file will be opened in the same
  # instance of GVim/nvim. Or, change the environ to use different
  # instances, e.g.,
  #   $ rg `some term`
  #   foo/bar.bat
  #   [1] 1:1 some term
  #   [2] 2:1 some term
  #   $ GVIM_OPEN_SERVERNAME=gvim1 e1
  #   $ GVIM_OPEN_SERVERNAME=gvim2 e2
  #   $ NVIM_OPEN_SOCKETNAME=nvim3 GVIM_OPEN_PREFER_NVIM=true e2

  # TRICK: Add this as the first line to the environ
  #        to view the command when tag is invoked:
  #   echo \"TAG_CMD_FMT_STRING=\${TAG_CMD_FMT_STRING}\" && \

  TAG_CMD_FMT_STRING=" \
    gvim-open-kindness \
      \"''\" \
      \"{{.LineNumber}}\" \
      \"{{.ColumnNumber}}\" \
      \"{{.Filename}}\" \
  "
  export TAG_CMD_FMT_STRING

  alias rg="${rg_wrap_with_options}"

  eval "_hf_rg() { ${rg_wrap_with_options} \"\$@\"; }"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

home_fries_create_aliases_rg_options() {
  # REFER/2017-09-13: ripgrep!
  # https://github.com/BurntSushi/ripgrep
  # - HSTRY: I found rg after The Silver Searcher identified one of
  #   my reST files as binary, and I didn't care to figure out why.
  # - SAVVY/2017-10-16: The default output is difficult to read.
  #   - So let's emulate The Silver Searcher, whose colors I like.
  # - REFER:
  #   - Colors: red, blue, green, cyan, magenta, yellow, white, black
  #   - Styles: nobold, bold, nointense, intense
  #   - Format is {type}:{attribute}:{value} —
  #       {type}: path, line, column, match
  #       {attribute}: fg, bg style
  #       {value} is either a color (for fg and bg) or a text style
  # USYNC: #_rg_colors
  claim_alias_or_warn "rgn" "\
    rg \
      --smart-case \
      --hidden \
      --colors 'path:fg:yellow' \
      --colors 'path:style:bold' \
      --colors 'line:fg:green' \
      --colors 'line:style:bold' \
      --colors 'column:none' \
      --colors 'match:bg:white'"

  claim_alias_or_warn "rgg" "rg --ignore-parent"

  # USAGE: Search for lines containing two distinct terms,
  # in either order, and highlight the matches differently,
  # e.g.:
  #   gr foo | gr bar
  # MNEMO: Mnemonic: `gr` is `rg` transposed.
  # - It's also a common alias some devs use for `grep`.
  claim_alias_or_warn "gr" "rg_producer_consumer"

  # USAGE: If you'd like to show all results for the first
  # term, and to also show results for lines that contain
  # the first term AND the second term (but not lines that
  # contain only the second term), use --passthru, e.g.,
  #   gr foo | gr bar --passthru
  # Or more simply:
  #   gr foo | grpt bar
  # - Aside: There's a regex pattern you could use instead,
  #   ORing with nothing, which prints non-matching, too, e.g.:
  #     rg "(|foo)"
  #     gr foo | gr ("|bar")
  claim_alias_or_warn "grpt" "rg_producer_consumer --passthru"

  # USAGE: Because pipeline stages each run in a subprocesses,
  # the /tmp/tag_aliases `e1` commands et al. cannot be wired
  # from `gr` (rg_producer_consumer) pipeline.
  # - So either call `gr` and then call `ee` to load aliases;
  #   or call `grgr` and pass both search terms to it; e.g.:
  #     $ gr foo | gr bar ; ee
  #   Or:
  #     $ grgr foo bar
  # - NAMIN: First alias is `e1`, so `ee` feels like a good spot.
  claim_alias_or_warn "ee" "_hf_tag_aliases_load"
  claim_alias_or_warn "grgr" "_hf_rg_two_terms"
}

# ***

# WORDS: The following comments use some terms which we'll
# define here, just for clarity, even though these terms
# are possibly already widely known. But just to be safe:
# - Each command block in a process pipeline is technically
#   called a "stage" or "segment", as in "pipeline stages".
#             ‾‾‾‾‾      ‾‾‾‾‾‾‾
#   - E.g., there are 2 stages/segments in `echo foo | cat`.
# - The commands themselves are often called "filters",
#                                             ‾‾‾‾‾‾‾
#   because they transform data from stdin to stdout.
# - The first command is called the "source" or "producer".
#                                    ‾‾‾‾‾‾      ‾‾‾‾‾‾‾‾
# - The final command is called the "sink", or "consumer".
#                                    ‾‾‾‾       ‾‾‾‾‾‾‾‾

# FEATR/2026-06-27: Pipe-friendly rg, for matching *two terms*.
# - Previously, if you wanted to search for two terms, you were
#   pretty much limited to combining them in a single call, e.g.:
#     rg -e "foo.*bar" -e "bar.*foo"
#   - This will find lines that contain "foo" and "bar", in
#     either order; it'll show results in color, with file path
#     headers (--heading), line and column numbers, and the "[1]"
#     ordinal, etc., that corresponds to the `e1` aliases et al.
#   - But note the highlight on each line includes *everything*
#     in between "foo" and "bar" (or between "bar" and "foo").
#   - And if you wanted to highlight *only* "foo" and "bar",
#     piping between two grep commands doesn't work the same.
#     - E.g.,:
#         rg foo | rg bar
#       Or:
#         rg foo | grep bar
#     Because, when piped, "rg" doesn't enable `--heading`,
#     `--line-number`, or `--column`.
#     - More importantly, `tag` itself falls back to
#       passthrough mode if either stdin or stdout is
#       not connected to a terminal.
#   - One might also consider ORing the two terms, e.g.,
#       rg "(foo|bar)"
#     but (obviously) that prints lines that contain either.
# - So here we define a pipe-friendly function.
#   - You'll also need the author's tag fork, which
#     adds `--tag` option, so you can pipe from `tag`
#     (orig. tag acts as passthrough otherwise).
#   - Features: Aka differences from default `rg | rg` behavior:
#     - Keeps color (rg/grep inhibits color by default when piping).
#     - The second `rg` — the consumer being piped-to — does not
#       also prepend its line numbers and columns to the output.
#     - Keeps the path lines and blank lines printed between results
#       from different files (the --heading output from the first `rg`).
#     - Bonus: Uses separate color for the second search term,
#       so it's easier to spot which term is used where.
# - Words: Per the dictionary lesson above, the rg_producer_consumer
#   command below is both the *source* and the *sink*, albeit it
#   plays those roles in separate stages.
#   - As the source, it enables `tag`, despite stdout being piped.
#   - As the sink, it preserves --heading's, and it highlights
#     the second search term differently than the source does.
# - Inert: Note there are no plans to reorder ordinals from 1.
#   - I.e., the consumer filters the results from the producer,
#     but it leaves the "[1]" et al. ordinals. So if there are
#     fewer results from the consumer, there will be gaps in
#     the outpt.
#   - Consider the following example. You'll see that `gr foo` matches 3
#     items and shows "[1]", "[2]", and "[3]", but `gr foo | gr bar` does
#     not match the everything, so you see "[2]" and "[3]", but not "[1]":
#
#       $ echo -e "foo\nbar after foo\nbar\nfoo before bar\n" > test
#       $ gr foo
#       test
#       [1] 1:1:foo
#       [2] 2:11:bar after foo
#       [3] 4:1:foo before bar
#
#       $ gr foo | gr bar
#       test
#       [2] 2:11:bar after foo
#       [3] 4:1:foo before bar
#
#     - Note you can add `--passthru` if you'd like to see all ordinals,
#       though the results are not as filtered and include everything that
#       matches the first term, but not necessarily everything that matches
#       the second, e.g.:
#
#       $ gr foo | gr bar --passthru
#       test
#       [1] 1:1:foo
#       [2] 2:11:bar after foo
#       [3] 4:1:foo before bar
# - Altly: Historically, we just had the `rg` alias (see above,
#   home_fries_create_aliases_rg_tag_wrap). But we cannot call
#   aliases from a function, so a dynamic function, _hf_rg, is
#   now created alongside the alias.
#   - By default, calling `rg` from a func. is akin to calling
#     `command rg`, i.e., it'll call ripgrep, and not our wrapper.
#   - Note there are a few (kludgy) ways to call an alias:
#     - Enable expand aliases, e.g.:
#         shopt -s expand_aliases
#         rg ...
#     - Or use the shell's aliases lookup, e.g.:
#         eval "${BASH_ALIASES[rg]} ..."
# - Savvy: We can call `rg` directly for the sink.
#   - Here's why we don't need to call the `_hf_rg` wrapper:
#     - Many of the options control how input files are selected:
#         --hidden --follow
#         --no-ignore-vcs --no-ignore-parent
#         --glob '!**/{.git,.tox,node_modules,.crypt}/**'
#         --glob '!**/{*.swp,...,*.zip,doc/tags}' "$@"
#       - But these would be ignored, because input is being streamed.
#     - Half of the options set colors:
#         --colors 'path:fg:yellow' --colors 'path:style:bold'
#         --colors 'line:fg:green' --colors 'line:style:bold'
#         --colors 'column:none' --colors 'match:bg:white'
#       - But only the 'match' color matters, because the others
#         are input-file related (coloring path, line, column),
#         which are only used by the first stage (the source).
#     - That leaves only one option we need to specify:
#         --smart-case
#       - Which is part of shared_args/shared_args_raw/shared_args_too.

rg_producer_consumer() {
  local shared_args="--smart-case --hidden --color=always"
  if ! test -t 1; then
    # Stdout not terminal, so acting as producer.
    # - --tag enables `tag` (which creates /tmp/tag_aliases) — and
    #   it adds these arguments: --color=always --heading --column
    _hf_rg --tag ${shared_args} "$@"
  elif ! test -t 0; then
    # Stdin not terminal, so acting as consumer.
    # - Don't add lines and columns (keep producer's).
    # - Don't filter --heading (let it --passthrough).
    # - Don't renumber ordinals [Inert: Possibly tedious to fix].
    # SAVVY: The magic regex pattern below matches ANSI escape sequences,
    # i.e., it represents color and font styling bytes.
    # - REFER: The middle chunk — \x1b\[[0-9;]* — matches control bytes.
    #   - The '^' prefix ensures that it matches from the start of line (SOL).
    #   - And the character class — [^\[] — does *not* match lines that
    #     (effectively) start with an opening square bracket '[' (color
    #     bytes aside), i.e., it matches the file path header lines, and
    #     not the "[1]", "[2]", etc. lines.
    #     - It also matches empty lines, so we technically don't need the '^$'.
    local arg
    local curr=0
    local found_index=-1
    local after_index=0
    local pattern_opt_a=""
    local pattern_opt_b=""
    for arg in "$@"; do
      case "${arg}" in
      --)
        # Note: `command rg -- foo bar baz` searches
        # for "foo" in files "bar" and "baz".
        break
        ;;
      -e | --regexp | --regexp*)
        break
        ;;
      -* | --*)
        # Savvy: Note you cannot use long options with separate values.
        # - E.g., `... | gr -m 2 foo` won't work; you'd need to instead
        #   call `... | gr --max-count=2 foo`, or `... | gr -m 2 -e foo`.
        #   - Except this is a poor example; --max-count won't work on
        #     the consumer, because the file context is missing (same
        #     with -A|--after-context, etc.).
        # - Usefulness of the available two-argument long options aside,
        #   all rg options that accept a follow-up arg. can instead be
        #   specifed using single arg format, e.g., `--option=value`.
        # Altly: ((curr++))
        let 'curr += 1'
        continue
        ;;
      *)
        found_index=${curr}
        if [ ${found_index} -eq 0 ]; then
          pattern_opt_a="-e"
        fi
        break
        ;;
      esac
    done
    if [ ${found_index} -gt 0 ]; then
      pattern_opt_b="-e"
    elif [ ${found_index} -eq -1 ]; then
      found_index=$#
    fi
    let 'after_index = found_index + 1'

    # ***

    local shared_args_raw="${shared_args} --no-line-number --no-column"
    # USYNC: #_rg_colors
    local shared_args_too="${shared_args_raw} --colors match:bg:green"
    # See comment above re: We call rg directly for the sink (not _hf_rg).
    command rg ${shared_args_raw} -e '^$' -e '^\x1b\[[0-9;]*m[^\[]' \
      --colors 'path:none' --colors 'line:none' --colors 'column:none' --colors 'match:none' \
      ${pattern_opt_a} "${@:1:${found_index}}" ${pattern_opt_b} "${@:${after_index}}" |
      command rg ${shared_args_too} --passthru \
        ${pattern_opt_a} "${@:1:${found_index}}" ${pattern_opt_b} "${@:${after_index}}" |
      (
        if ${HOMEFRIES_RG_GR_INHIBIT_PRUNE:-false}; then
          cat
        else
          # Remove --heading and blank lines with no results following.
          awk '
            /^$/ { if (heading) { heading = ""; next; } }
            /^\x1b\[[0-9;]*m[^\[]/ { heading = $0; next; }
            { if (heading) { print heading; heading = ""; } }
            1
            '
        fi
      )
  else
    # Both stdin and stdout connected to terminal;
    # acting as passthrough.
    # - Note --tag is implied, b/c terminal stdio.
    _hf_rg --tag ${shared_args} "$@"
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

_hf_rg_two_terms() {
  local patt_a="$1"
  local patt_b="$2"

  if [ -z "${patt_a}" ] || [ -z "${patt_b}" ]; then
    >&2 echo "USAGE: Please specify two search terms"

    return 1
  fi

  rg_producer_consumer "${patt_a}" | rg_producer_consumer "${patt_b}"

  # This is why we need this function (otherwise user has
  # to call this next step manually):
  _hf_tag_aliases_load
}

# ***

_hf_tag_aliases_load() {
  local aliases="${TAG_ALIAS_FILE:-/tmp/tag_aliases}"
  if [ -s "${aliases}" ]; then
    . "${aliases}" 2>/dev/null
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

unset_f_alias_rg_tag() {
  unset -f check_deps
  unset -f home_fries_aliases_wire_rg_tag
  unset -f home_fries_create_aliases_rg_tag_wrap
  unset -f home_fries_create_aliases_rg_options
  # So meta.
  unset -f unset_f_alias_rg_tag
}

# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ #

_homefries_warn_on_execute() {
  >&2 echo "ERROR: Trying sourcing the file instead: . $0" && exit 1
}

main() {
  check_deps
  unset -f check_deps
}

if [ "$0" = "${BASH_SOURCE[0]}" ]; then
  _homefries_warn_on_execute
else
  main "$@"
fi
unset -f _homefries_warn_on_execute
unset -f main
