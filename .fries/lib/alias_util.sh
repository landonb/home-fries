#!/bin/bash
# vim:tw=0:ts=2:sw=2:et:norl:

# File: alias_util.sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project Page: https://github.com/landonb/home-fries
# Summary: Generic Bash function library.
# License: GPLv3

# Usage: Source this script. Call its functions. Use its exports.

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

source_deps () {
  local curdir=$(dirname -- "${BASH_SOURCE[0]}")
  source ${curdir}/logger.sh
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

home_fries_create_aliases_general () {
  # Hint: To run the native command and not the alias, use a \ prefix, e.g.,
  #       \rm will call the real /bin/rm not the alias.

  # *** File commands

  # NOTE: Sometimes the -i doesn't get overriden by -f so it's best to call
  #       `/bin/cp` or `\cp` and not `cp -f` if you want to overwrite files.
  alias cp='cp -i'
  alias mv='mv -i'

  # Move a glob of files and include .dotted (hidden) files.
  alias mv_all='mv_dotglob'
  # Problem illustration:
  #   $ ls project
  #   .agignore
  #   $ mv project/* .
  #   mv: cannot stat ‘project/*’: No such file or directory
  # This fcn. uses shopt to include dot files.
  # Note: We've aliased `mv` to `/bin/mv -i`, so you'll be asked to
  #       confirm any overwrites, unless you call `mv_all -f` instead.
  #
  # NOTE: You have to escape wildcards so that are not expanded too soon, e.g.,
  #
  #         mv. '*' some/place
  #
  mv_dotglob () {
    if [[ -z "$1" && -z "$2" ]]; then
      echo "mv_gotglob: missing args weirdo"
    fi
    shopt -s dotglob
    # or,
    #  set -f
    if [[ $1 == '-f' ]]; then
      /bin/mv $*
    else
      mv $*
    fi
    shopt -u dotglob
    # or,
    #  set +f
  }

  alias mv.='mv_dotglob'

  # *** Directory listings.

  # 2015.01.20: Used to use --color=tty (which still works), but man says =auto.
  alias ls='/bin/ls -hFA --color=auto'  # Human readable, classify files, shows
                                        #   almost all (excludes ./ and ../),
                                        #   and uses colour.
  alias l='/bin/ls -ChFA --color=auto --group-directories-first'
                                        # Compact listing (same as -hFA, really),
                                        #   but list directories first which
                                        #   seems to make the output cleaner.
  alias ll='/bin/ls -lhFa --color=auto' # Long listing; includes ./ and ../
                                        #   (so you can check permissions)
  alias lll='ll --time-style=long-iso'  # 2017-07-10: Show timestamps always.
  alias lo='ll -rt'                     # Reverse sort by time.
  alias llo='lo --time-style=long-iso'  # 2017-07-10: You get the ideaa.
  alias lS='/bin/ls --color=auto -lhFaS' # Sort by size, from largest (empties last).
  alias lS-='/bin/ls --color=auto -lFaS | sort -n -k5' # Sort by size, largest last.

  # *** Vim

  # gVim.
  alias ff='gvim --servername DIGAMMA --remote-silent' # For those special occassions
  alias fd='gvim --servername   DELTA --remote-silent' # when you want to get away
  alias fs='gvim --servername   SAMPI --remote-silent' # because relaxation is key
  alias fa='gvim --servername   ALPHA --remote-silent' # follow your spirit.

  # *** Miscellany

  # Misc. directory aliases.
  alias h='history'         # Nothing special, just convenient.
  # See also: `ss`, fresher than netstat.
  #   "Netstat and ifconfig are part of net-tools, while ss and ip are part of iproute2."
  #   https://utcc.utoronto.ca/~cks/space/blog/linux/ReplacingNetstatNotBad
  alias n='netstat -tulpn'  # --tcp --udp --listening --program (name) --numeric

  # 2018-06-26: `alias t` had been `=tree` since 2017-10-12. ["2017-10-12?"
  # was my comment.] Before that, it was `=todo.sh` for, like, a day. And
  # And way long before time ago, it was `=top`. Now I'm thinking, `=todolist`.
  # 2018-06-26 20:32: We'll see if these catch up. I generally
  #   tend to make new aliases and then promptly forget them.
  alias t='todolist'
  alias todo='todolist'

  # It was `=top` way long ago, and then `=todo.sh` for, like, a day.
  #alias t='top -c'          # Show full command.
  alias ht='htop'

  alias cmd='command -v $1' # Show executable path or alias definition.
  #alias less='less -r'     # Raw control characters.
  alias less='less -R'      # Better Raw control characters (aka color).
  alias whence='type -a'    # `where`, of a sort.

  # Show resource usage, and default to human readable figures.
  alias df='df -h -T'
  alias du='du -h'
  alias dum="du -m -d 1 . | sort -n"
  #alias duhome='du -ah /home | sort -n'
  # Use same units, else sort mingles different sizes.
  # cd ~ && du -BG -d 1 . | sort -n
  alias free="free -m"

  # Does this help?
  alias findi='find . -iname'

  # 2016-09-24: Why didn't I think of this 'til now?
  # [Note also that pass can just do it, too.]
  alias pwgen16="pwgen -n 16 -s -N 1 -y"

  # [lb] uses p frequently, just like h and ll.
  alias p='pwd'

  alias cls='clear' # If you're like me and poisoned by DOS memories.

  # *** Python

  # Alias python from py, but only if there's not already symlink.
  if [[ ! -e /usr/bin/py ]]; then
    alias py='/usr/bin/env python'
  fi
  if [[ ! -e /usr/bin/py2 ]]; then
    alias py2='/usr/bin/env python2'
  fi
  if [[ ! -e /usr/bin/py3 ]]; then
    # 2016-11-28: hamster-briefs uses py3.5's subprocess.run.
    #alias py3='/usr/bin/env python3'
    # Argh...
    alias py3='/usr/bin/env python3.5'
  fi

  # *** Ruby

  # 2016-12-06: Not sure I need this... probably not.
  #if [[ ! -e "/usr/bin/ruby1" ]]; then
  #  alias ruby1='/usr/bin/env ruby1.9.1'
  #fi
  #if [[ ! -e "/usr/bin/ruby2" ]]; then
  #  #alias ruby2='/usr/bin/env ruby2.0'
  #  #alias ruby2='/usr/bin/env ruby2.2'
  #  alias ruby2='/usr/bin/env ruby2.3'
  #fi

  # *** ``*ami``s

  # The `whoami` is just `id -un` in disguise.
  # Here are its lesser known sibling commands.
  #
  # 2018-03-28: There's a package for that!
  #   ## alias whereami=is an actual package you can install.
  #   # alias whereami="echo 'How should I know?' ; \
  #   #   /usr/bin/python /usr/lib/command-not-found whereami"
  #   npm install -g @rafaelrinaldi/whereami
  #
  alias howami="echo 'Doing well. Thanks for asking.' ; \
                /usr/bin/python /usr/lib/command-not-found howami"
  alias whatami="echo 'Neither plant nor animal.' ; \
                /usr/bin/python /usr/lib/command-not-found whatami"
  alias whenami="echo 'You are in the here and now.' ; \
                /usr/bin/python /usr/lib/command-not-found whenami"
  alias whyami="echo 'Because you gotta be somebody.' ; \
                /usr/bin/python /usr/lib/command-not-found whyami"

  # *** Git

  # Do it to it git it st'ok it.
  # MAYBE: Make these git aliases? Or just stick in ~/.local/bin?
  alias git-st='git-st.sh'
  alias git-diff='GIT_ST_DIFF=true git-st.sh'
  alias git-add='GIT_ST_ADDP=true git-st.sh'

  # *** Home Fries

  # 2016-06-28: Stay in same dir when launching bash.
  # FIXME: Should I make sure just to do this if a gnome/mate terminal?
  # 2018-04-03: Is it really kosher to alias bash??
  alias bash='DUBS_STARTIN=$(dir_resolve $(pwd -P)) /bin/bash'

  # *** Stream editing

  alias sed='sed -r'        # Use extended regex.

  # 2016-11-18: If ack -v works (unlike ag -v) I might use this.
  alias ack="ack-grep"

  # *** Vi(m)

  # Vi vs. Vim: When logged on as root, vi is a dumbed-down vim. Root rarely
  # needs vanilla `vi` -- only when the home directories aren't mounted -- so
  # we can alias vi to vim.
  if [[ $EUID -eq 0 ]]; then
    alias vi="vim"
  fi

  # 2018-03-28: From MarkM. Except it doesn't quite work for me....
  #alias v='${EDITOR} $(fc -s) ' # edit results of last command
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

home_fries_create_aliases_grep_and_egrep () {
  alias grep='grep --color' # Show differences in colour.

  # Preferred grep switches and excludes.
  #   -n, --line-number
  #   -R, --dereference-recursive
  #   -i, --ignore-case
  if [[ -e $HOME/.grepignore ]]; then
    alias eg='egrep -n -R -i --color --exclude-from="$HOME/.grepignore"'
    alias egi='egrep -n -R --color --exclude-from="$HOME/.grepignore"'
  fi
}

home_fries_create_aliases_ag_options () {
  # The Silver Search.
  # Always allow lowercase, and, more broadly, all smartcase.
  alias ag='ag --smart-case --hidden'
  # When you use the -m/--max-count option, you'll see a bunch of
  #   ERR: Too many matches in somefile. Skipping the rest of this file.
  # which come on stderr from each process thread and ends up interleaving
  # with the results, making the output messy and unpredicatable.
  # So that Vim can predictably parse the output, use this shim of a fcn.,
  # i.e., from Vim as `set grepprg=ag_peek`. (2018-01-12: Deprecated;
  # favor just inlining in the .vim file.)
  # 2018-01-29: Obsolete. In Vim, idea to `set grepprg=ag_peek`, but didn't work.
  function ag_peek () {
    ag -A 0 -B 0 --hidden --follow --max-count 1 $* 2> /dev/null
  }
}

home_fries_create_aliases_rg_options () {
  # 2017-09-13: ripgrep!
  # https://github.com/BurntSushi/ripgrep
  # I'm only doing this because The Silver Searcher is identifying
  # one of my reST files as binary, and I don't care to figure out
  # why.
  #alias rg='rg --smart-case --hidden'
  # 2017-10-16: Output is difficult to read. Emulate The Silver Searcher.
  #  Colors: red, blue, green, cyan, magenta, yellow, white, black.
  #  Styles: nobold, bold, nointense, intense.
  #  Format is {type}:{attribute}:{value}.
  #    {type}: path, line, column, match.
  #    {attribute}: fg, bg style.
  #    {value} is either a color (for fg and bg) or a text style.
  alias rgn="\
    rg \
      --smart-case \
      --hidden \
      --colors 'path:fg:yellow' \
      --colors 'path:style:bold' \
      --colors 'line:fg:green' \
      --colors 'line:style:bold' \
      --colors 'match:bg:white' \
    "

  # DELETE/2018-01-29: This fcn., rg_peek, is not called.
  # 2018-01-29: Obsolete. In Vim, idea to `set grepprg=rg_peek`, but didn't work.
  function rg_peek () {
    rg -A 0 -B 0 --hidden --follow --max-count 1 $* 2> /dev/null
  }
}

home_fries_create_aliases_rg_tag_wrap () {
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

  local engine='rg'

  if ! hash ${engine} 2>/dev/null; then
    warn "No Silver Search or Rip Grep found [${engine}]"
    return 1
  fi

  # Choices: ag, rg
  export TAG_SEARCH_PROG=${engine}

  tag () {
    command tag "$@"
    source ${TAG_ALIAS_FILE:-/tmp/tag_aliases} 2>/dev/null
  }

  local rg_wrap_with_options=" \
    tag \
      --smart-case \
      --hidden \
      --colors 'path:fg:yellow' \
      --colors 'path:style:bold' \
      --colors 'line:fg:green' \
      --colors 'line:style:bold' \
      --colors 'match:bg:white' \
  "

  # rgt -- Open search result in Vim in current terminal.
  alias rgt="\
    TAG_CMD_FMT_STRING=\"
      vim -c 'call cursor({{.LineNumber}}, {{.ColumnNumber}})' '{{.Filename}}'
    \" \
    ${rg_wrap_with_options} \
  "

  # rgg -- Open search result in specific Gvim window, and switch to it.
  # FIXME/2018-03-26: The servername, SAMPI, is hardcoded: Make Home Fries $var.
  # NOTE: (lb): I could not get "-c 'call cursor()" to work in same call as
  #       --remote-silent, so split into two calls, latter using --remote-send.
  alias rgg="\
    TAG_CMD_FMT_STRING=' \
      true \
      && gvim --servername SAMPI --remote-silent \"{{.Filename}}\" \
      && gvim --servername SAMPI --remote-send \
        \"<ESC>:call cursor({{.LineNumber}}, {{.ColumnNumber}})<CR>\" \
      && xdotool search --name SAMPI windowactivate \
    ' \
    ${rg_wrap_with_options} \
  "
  alias rg="rgg"
}

home_fries_create_aliases_greppers () {
  home_fries_create_aliases_grep_and_egrep
  home_fries_create_aliases_ag_options
  home_fries_create_aliases_rg_options
  home_fries_create_aliases_rg_tag_wrap
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# Changing Directories like Hänsel und Gretel

# 2015.04.04: Tray Cray.
# FIXME: completions... limit to just directories, eh.
cdd_ () {
  if [[ -n $2 ]]; then
    echo 'You wish!' $*
    return 1
  fi
  if [[ -n $1 ]]; then
    pushd "$1" &> /dev/null
    # Same as:
    #  pushd -n "$1" &> /dev/null
    #  cd "$1"
    if [[ $? -ne 0 ]]; then
      # Maybe the stupid user provided a path to a file.
      pushd $(dirname -- "$1") &> /dev/null
      if [[ $? -ne 0 ]]; then
        echo "You're dumb."
      else
        # alias errcho='>&2 echo'
        # echo blah >&2
        >&2 echo "FYI: We popped you to a file's homedir, home skillet."
      fi
    fi
  else
    pushd ${HOME} &> /dev/null
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

home_fries_create_aliases_chdir () {
  # FIXME: 2015.04.04: Still testing what makes the most sense:
  #        2016-10-07: I just use `cdd`. What's the problem?
  alias cdd='cdd_'
  # HINT: `dirs -c` to clear pushd/popd directory stack.
  #alias ccd='cdd_'
  #alias cdc='cdd_'
  # MAYBE GOES FULL ON:
  ##alias cd='cdd_'
  # FIXME: Choose one of:
  #alias ppd='popd > /dev/null'
  #alias pod='popd > /dev/null'
  alias cdc='popd > /dev/null'
  # 2017-05-03: How is `cd -` doing a flip-between-last-dir news to me?!
  alias cddc='cd -'
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

home_fries_create_aliases_tab_completion () {
  # Helpful Bash Tab Completion aliases.

  # For those (silly) projects that use tabs (I know!) in Bash scripts,
  # you'll want to disable tab autocompletion if you want to copy-and-paste
  # from the script to the terminal, otherwise the autocomplete responses
  # are intertwined with the paste.

  #alias tabsoff="bind 'set disable-completion on'"
  #alias tabson="bind 'set disable-completion off'"

  alias toff="bind 'set disable-completion on'"
  alias ton="bind 'set disable-completion off'"

  # 2017-08-25: You need to disable tab completion to test copy-paste
  #             ``<<-`` here-documents.
  #
  #             E.g.,
  #
  #                 bind 'set disable-completion on'
  #
  #                 cat <<-EOF
  #                 	<Tabdented>
  #                 EOF
  #
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main () {
  source_deps
}

main "$@"

