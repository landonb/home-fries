#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# Most of my Git magic is elsewhere:
#
#   github.com:landonb/git-smart#💡
#   github.com:landonb/git-veggie-patch#🥦
#   github.com:landonb/git-my-merge-status#🌵
#   and more to come!

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

check_deps () {
  check_dep 'first_char_capped'
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# *** Interrogate user on clobbery git command.

# 2017-06-06: Like the home-fries /bin/rm monkey patch (rm_safe), why not
# preempt "unsafe" git commands with a similarly pesky are-you-sure? prompt.
# - Specifically added because sometimes when I mean to type
#     `git reset HEAD blurgh`  I type instead
#     `git co -- blurgh`       -- oh no! --
#   but I will note that since this command (comment) was added I've stopped.
# NOTE: The name of this function appears in the terminal window title, e.g.,
#       on `git log`, the tmux window title might be, `_git_safe log | abc`.
_git_safe () {
  local disallowed=false
  local skip_hooks=${HUSKY_SKIP_HOOKS}

  _git_prompt_user_where_reflog_wont_save_them () {
    local prompt_yourself=false

    _git_prompt_determine_if_destructive () {

      # Verify `git co -- ...` command.
      # NOTE: `co` is a home-🍟 alias, `co = checkout`.
      # NOTE: (lb): I'm not concerned with the long-form counterpart, `checkout`,
      #       a command I almost never type, and for which can remain unchecked,
      #       as a sort of "force-checkout" option to avoid being prompted.
      if [ "$1" = "co" ] && [ "$2" = "--" ]; then
        prompt_yourself=true
      fi
      # Also catch `git co .`.
      if [ "$1" = "co" ] && [ "$2" = "." ]; then
        prompt_yourself=true
      fi

      # Verify `git reset --hard ...` command.
      if [ "$1" = "reset" ] && [ "$2" = "--hard" ]; then
        prompt_yourself=true
      fi
    }

    _git_prompt_ask_user_to_continue () {
      printf "Are you sure this is absolutely what you want? [Y/n] "
      read -e YES_OR_NO
      # As writ for Bash 4.x+ only:
      #   if [[ ${YES_OR_NO^^} =~ ^Y.* ]] || [ -z "${YES_OR_NO}" ]; then
      # Or as writ for POSIX-compliance:
      if [ -z "${YES_OR_NO}" ] || [ "$(first_char_capped ${YES_OR_NO})" = 'Y' ]; then
        # FIXME/2017-06-06: Someday soon I'll remove this sillinessmessage.
        # - 2020-01-08: lb: I'll see it when I believe it.
        echo "YASSSSSSSSSSSSS"
      else
        echo "I see"
        disallowed=true
      fi
    }

    if [ $# -lt 2 ]; then
      return
    fi

    _git_prompt_determine_if_destructive "$@"

    if ${prompt_yourself}; then
      _git_prompt_ask_user_to_continue
    fi
  }

  _git_husky_hooks_cherry_pick_skip_hooks () {
    # MAYBE/2021-01-04 14:31: Also check aliases? || [ "$1" = "pr" ] and "pp", etc.
    #                         Or maybe in the alias itself probably-instead.
    if [ "$1" != "cherry-pick" ]; then
      # Command is not `git cherry-pick [...]`.
      return
    fi

    # Always skip hooks (pre-commit) on cherry-pick.
    skip_hooks=${HUSKY_SKIP_HOOKS:-1}
  }

  _git_husky_hooks_pre_push_touch_bypass () {
    # Straight to the point -- does this even matter?
    if [ ! -f "${HOME}/.huskyrc" ]; then
      return
    fi
    # Likewise: Check if called within Git working tree,
    # and that pre-push wired (a file husky place-creates).
    local working_dir
    working_dir="$(command git rev-parse --show-toplevel)"
    if [ $? -ne 0 ] || [ ! -f "${working_dir}/.git/hooks/pre-push" ]; then
      return
    fi

    # MAYBE/2021-01-04 14:31: Also check aliases? || [ "$1" = "pr" ] and "pp", etc.
    #                         Or maybe in the alias itself instead?
    if [ "$1" != "push" ]; then
      # Not `git push [...]`.
      #  >&2 printf "%s\n" "It's Git, but it's no Push."
      return
    fi

    for argument in "$@"; do
      if [ "${argument}" = "--help" ] || [ "${argument}" = "-h" ]; then
        # User is requesting Help.
        # - Zap! This is what we in the biz pan as a short-cirtuit return. ;)
        #   Aka, Flow Control Surprise!
        >&2 printf "%s\n" "Here, let me help you."
        return
      fi
    done

    # ***

    # If flow already returned, means pre-push is *not* going to be called.
    # For code flowing past this commit, pre-push -- and ~/.huskyrc -- are
    # on deck.
    #
    # We might want to tell ~/.huskyrc not to run checks,
    # specifically if the user is deleting remote branch.

    # Load USER_HUSKY_RC_SKIP_INDICATOR, a touch file used to control
    # ~/.huskyrc later when it's run by husky-run.
    . "${HOME}/.huskyrc" --source

    # There are 2 delete remote branch variants we can ignore on:
    #
    #   git push --delete/-d ...
    #   git push remote :branch
    #
    # First delete variant:
    for argument in "$@"; do
      if [ "${argument}" = "--delete" ] || [ "${argument}" = "-d" ]; then
        # Hopes deleted. Oh, expletive deleted.
        # Brannigan, get out here and surrender before I get my expletives deleted.
        # Fry, delete that. Delete that right now!
        # (Whispers) Send. (Coughing) Did you delete it? Uh...
        # And everybody knows, once you delete a photo, it's gone forever.
        # And delete 12 terabytes of outdated catchphrases. Sounds like fun on a bun!
        # [Sniffles] I'll always remember you, Fry. [Robotic Voice] Memory deleted.
        #  printf "%s\n" "Hopes deleted."
        #  printf "%s\n" "Get out here and surrender before I get my expletives deleted."
        >&2 printf "%s\n" "Oh, expletive deleted."
        touch "${USER_HUSKY_RC_SKIP_INDICATOR}"
      fi
    done
    #
    # Old school delete variant (using this shows you dev-age, can I get a
    # “DEV!”, What What!):
    # MAGIC_NUMBER: "$3", as in: git push remote :branch
    #                                 $1    $2      $3
    if [[ "$3" =~ ^:.* ]]; then
      >&2 printf "%s\n" "I'm going to allow this."
      touch "${USER_HUSKY_RC_SKIP_INDICATOR}"
    fi
  }

  # Prompt user if command consequences are undoable,
  # i.e., if previous file state would be *unrecoverable*.
  _git_prompt_user_where_reflog_wont_save_them "$@"

  if ! ${disallowed}; then
    # Because husky prefers config from package.json and does not merge
    # (additional) config from .husrkrc[.js[on]], do so here.
    _git_husky_hooks_cherry_pick_skip_hooks "$@"
  fi

  if ! ${disallowed}; then
    _git_husky_hooks_pre_push_touch_bypass "$@"
  fi

  if ! ${disallowed}; then
    HUSKY_SKIP_HOOKS=${skip_hooks} command git "$@"
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# *** git-bfg wrapper.

git-bfg () {
  # Note that the ZP Ansible git-bfg install task makes a symlink to the BFG JAR,
  # whose name includes the version, SHA, and branch, e.g., it might really be
  # called "bfg-1.13.1-SNAPSHOT-master-5158aa4.jar".
  local bfg_jar="${HOME}/.local/bin/bfg.jar"
  if [ ! -f "${bfg_jar}" ]; then
    local zphf_uroi="https://github.com/landonb/zoidy_home-fries"
    local help_hint="Run the Zoidy Pooh task ‘app-git-the-bfg’ from: ${zphf_uroi}"
    >&2 echo "ERROR: The BFG is not installed. ${help_hint}"
    return 1
  fi
  java -jar ${HOME}/.local/bin/bfg.jar "$@"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main () {
  check_deps
  unset -f check_deps

  # unalias git 2> /dev/null
  alias git='_git_safe'
}

main "$@"
unset -f main

