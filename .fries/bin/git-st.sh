#!/bin/bash
#  vim:tw=0:ts=2:sw=2:et:norl:

# File: git-st.sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Last Modified: 2017.10.03
# Project Page: https://github.com/landonb/home_fries
# Summary: Helpful `git st`, `git add -p`, and `git diff` wrapper
#          used to hide acceptably deviant repository changes.
# License: GPLv3

# USAGE: This script hides tracked files from a `git status` report that
#        normally differ from the upstream branch's file.
#
#        It can also start a `git diff ...` or `git add -p ...` on those files.
#
#        E.g., if you always enable a certain debug switch after cloning the
#        project, you can use this script to avoid seeing that file always
#        show up in a `git status` or `git diff` command.
#
#        ----   How to ignore files
#        ----    that you need edited
#        ----     in your working directory
#        ----      that you should not commit to you branch
#        ----       because these difference must not be merged to other branches
#        ----        -- especially not production branches! --
#        ----
#        ----   and still be able to have a clean `git status`
#        ----    and be able to `git diff`
#        ----     without always seeing these stupid files
#        ----      and wondering if their diff is your dev change
#        ----       or if it's really something you gotta commit.
#        ----
#
#        Instructions for managing working changes in
#        files that cannot be ignored via .gitignore:
#
#           1. Make a copy of the edited file and assign it a .GTSTOK extension.
#              E.g., /bin/cp -a path/to/orig.file path/to/orig.file.GTSTOK
#
#              Think of the file extension, .GTSTOK, meaning,
#              "GiT STatus, you're OKay ignoring this file if it matches its master"
#
#              - This script will diff the two files -- the original, git-tracked file,
#                and the GTSTOK file -- and this script will exclude the file from the
#                `git status` report if the tracked file matches the approved deviation.
#
#                Otherwise, if the tracked file is dirty but doesn't match the GTSTOK file,
#                this script will add the file to the list of files sent to the git command.
#
#           2. By default, this script spits out a `git status` without GTSTOK distractions.
#              It also echoes a `git diff` command that you can copy and paste to do a diff.
#
#              You can also have it start a `git diff` or `git add -p` on the identified
#              files by setting either the GIT_ST_DIFF or GIT_ST_ADDP environment variable,
#              respectively.
#
#              Example USAGEs:
#
#                 alias git-st='git-st.sh'
#                 alias git-diff='GIT_ST_DIFF=true git-st.sh'
#                 alias git-add='GIT_ST_ADDP=true git-st.sh'
#
#                 # assuming the location of git-st.sh is also part of PATH.

# FIXME: git-st not working on files under a subpath (uncles okay, though).
#        E.g., consider a file at repo/subdir/some_file.GTSTOK, then
#                cd subdir ; git-st
#              doesn't work (because our file path is ../subdir/some_file.GTSTOK,
#                            but the `git status` path is just some_file.GTSTOK.
#              (This works from a cousin subdir, though, e.g.,
#                cd different_dir ; git st
#              works because ../subdir/some_file.GTSTOK is what `git st` says, too.)

SPECIAL_EXT="GTSTOK"

if [[ -z ${GIT_ST_DIFF} ]]; then
  GIT_ST_DIFF=false;
fi
if [[ -z ${GIT_ST_ADDP} ]]; then
  GIT_ST_ADDP=false;
fi

if [[ -f ${HOME}/.fries/lib/git_util.sh ]]; then
  source ${HOME}/.fries/lib/git_util.sh
else
  echo "FATAL: Missing: ${HOME}/.fries/lib/git_util.sh"
fi

# Enable a little more echo, if you want.
DEBUG=false
#DEBUG=true
echod () {
  ${DEBUG} && echo $*
}

GREP_EXCLUDE=''
DIVERGENTS=()
prepare_grep_exclude () {

  # Get the prefix to the parent directory so we can match the
  # relative path backing-up, so that these fcns. can run from
  # a repo subdirectory.
  find_git_parent
  # sets: REL_PREFIX

  # In lieu of fiddling if IFS=$'\n' or IFS=$'\0' or whatever,
  # we could do a find-pipe-read.
  if false; then
    find . -name "*.${SPECIAL_EXT}" -exec echo "{}" \; | while read file_path; do
        ref_file=${file_path%%.${SPECIAL_EXT}}
        echo "file_path: ${file_path} / ref_file: $ref_file"
    done
  fi

  # But maybe using Bash's globstar is a more-better method.
  shopt -s globstar
  for file_path in ${REL_PREFIX}**/*.${SPECIAL_EXT}; do
    echod "GTSTOK file_path: ${file_path}"

    if [[ ${file_path} == "**/*.${SPECIAL_EXT}" ]]; then
      # Nothing found.
      echo "Nothing GTSTOK found."
      break
    fi

    ref_file=${file_path%%.${SPECIAL_EXT}}
    echod "file_path: ${file_path}"
    echod "ref_file: ${ref_file}"

    echod "diff ${ref_file} ${file_path}"

    diff ${ref_file} ${file_path} &> /dev/null
    if [[ $? -eq 0 ]]; then
      # The tracked file matches an approved divergent file.
      # 2016-10-24: Because of color, line ends: .[m | 1B 5B 6D 0A
      #             Also need grep -P to use line termination match$.
      curr_dir=$(readlink -f .)
      abs_path=$(readlink -f -- "${ref_file}")
      ref_path=${abs_path#${curr_dir}/}
      echod "curr_dir: ${curr_dir}"
      echod "abs_path: ${abs_path}"
      echod "ref_path: ${ref_path}"
      # Check if the path starts with a path delimiter, i.e., is absolute.
      if [[ ${ref_path} == /* ]]; then
        # An absolute path means git-st being run from a cousin
        # directory of the GTSTOK file.
        GREP_EXCLUDE="${GREP_EXCLUDE} |
          grep -P -v \"${ref_file}$\" |
          grep -P -v \"${ref_file}\x1B\x5B\x6D$\""
      else
        # A relative path means git-st being run from the directory
        # containing .GTSTOK or a parent directory.
        GREP_EXCLUDE="${GREP_EXCLUDE} |
          grep -P -v \"${ref_path}$\" |
          grep -P -v \"${ref_path}\x1B\x5B\x6D$\""
      fi
    else
      # The tracked file doesn't match, so make sure it's dirty
      # and that `git status` shows it, otherwise gripe about it.
      if [[ -z `git diff ${ref_file}` ]]; then
        # Empty diff; which means wrong copy might have accidentally
        # been committed.
        #DIVERGENTS+=("WARNING: Possibly accidentally committed divergent file: ${ref_file}")
        DIVERGENTS+=(\
          "\t${LAVENDER}${font_bold_bash}DIVERGENT:  ${font_underline_bash}${ref_file}${font_normal_bash}"\
        )
      else
        : # git status will show that it diffs.
      fi
    fi
  done

  # Let's also exlude a silly line printed if nothing's staged, e.g.,
  #   "no changes added to commit (use "git add" and/or "git commit -a")"
  GREP_EXCLUDE="${GREP_EXCLUDE} | grep -v \"no changes added to commit\""

  # We can remove newlines here, with grep, or later with sed.
  GREP_EXCLUDE="${GREP_EXCLUDE} | grep -v \"^$\""

  echod "GREP_EXCLUDE: ${GREP_EXCLUDE}"
}
prepare_grep_exclude

DIFFABLES=''
prepare_diffables () {
  # Get a list of dirty files excluding those we just checked.
  # NOTE: git version 1.7.9.5 prefaces its `git status` lines
  #       with pound signs; git version 1.9.1 does not; so we
  #       use `sed` to remove the prefix.
  #       Here was [lb]'s first go:
  #          git status ${GREP_EXCLUDE} \
  #          | /bin/grep 'modified:' \
  #          | sed s/^\#// \
  #          | awk '{print \$2}' \
  #          | tr '\n' ' '"
  #       but for the `git diff` copy-paste to work from any
  #       arbitrary subdir, we need to prepend the complete path
  #       (or a relative path, but that seems too hard to figure
  #       out... using $CURRENT_DIR and doing dir math, ew).
  GIT_ST_CMD="\
    git status ${GREP_EXCLUDE} \
      | /bin/grep 'modified:' \
      | /bin/sed -r "s/\#//" \
      | /bin/sed -r 's/.*modified:\\s*//' \
      | tr '\n' ' ' \
      | /bin/sed -r 's/[\x01-\x1F\x7F]\[m//g' \
  "
  echod "${GIT_ST_CMD}"
  DIFFABLES=$(eval "${GIT_ST_CMD}")
  # Make an array by splitting on the spaces we made from the newlines.
  # CAVEAT: There's probably a way to allow spaces in paths (ew! I know)
  #         but I tried IFS=$'\n' and IFS='\n' but nothing I tried worked.
  #         So we use `tr` to make spaces and then Internal field separator
  #         to split the string into an array of strings.
  IFS=' ' read -ra DIFFABLES <<< "$DIFFABLES"
  echod "No. of \$DIFFABLES: ${#DIFFABLES[@]}"
  # 2016-05-27: I fixed a difficult problem, finally!
  #
  #   - I spent, what, this past hour tonight on this? Or maybe even 90 minutes.
  #     But I didn't want to give up!
  #
  #   - First, a taste of my earlier frustration:
  #
  #      "Well this is frustrating!
  #       2016-02-20: [lb] was hoping to run a custom `git diff` command but all hope is lost:
  #
  #       This works:
  #
  #         DIFFABLES=("path/to/some/file.rst" "path/to/some/module.py")
  #         git diff "${DIFFABLES[@]}"
  #
  #       but this doesn't:
  #
  #         eval "git diff" ${diffables}
  #
  #       because git says:
  #
  #         fatal: ambiguous argument 'path/to/some/file.rst':
  #          unknown revision or path not in the working tree.
  #         Use '--' to separate paths from revisions, like this:
  #         'git <command> [<revision>...] -- [<file>...]'
  #
  #       but if you add the '--' separator then the diff shows up blank, which is the
  #       same thing that happens if you specify a nonfile, e.g., `git diff -- blahshdh`.
  #
  #       So [lb] wonders if maybe the $diffables string has some gunk in it... but I
  #       tried `RUNME=$(echo "git diff ${DIFFABLES[0]}") ; eval $RUNME` and got the
  #       same failure."
  #
  #   - 2016-05-27: On 2/20, I was right about "some gunk in it", but I didn't triage it right!'
  #     If only I'd known about the `od` command!!
  #
  #         TESTING="git diff ${DIFFABLES[0]}"
  #         echo $TESTING | od -c
  #         # 0000000   g   i   t       d   i   f   f       /   s   r   v   /   p   a
  #         # 0000020   t   h   /   t   o   /   s   o   m   e   _   r   e   a   l   l
  #         # 0000040   y   _   f   a   r   o   f   f   f   i   l   e   .   p   y 033
  #         # 0000060   [   m  \n
  #         # 0000063
  #
  #     The "033" is ESC, and ESC[m or \033[00m is a color code!
  #     Because I like to prettify my git output.
  #
  #         $ git config --get-regexp color.status
  #         color.status.added green bold
  #         color.status.changed yellow bold
  #         color.status.untracked red
  #
  #     Adding the `sed` on [\x01-\x1F\x7F] strips the control characters.
}
prepare_diffables

exclude_git_usage_message () {
  # E.g.,
  #   On branch redacted
  #   Your branch is ahead of 'origin/redacted' by 1 commit.
  #     (use "git push" to publish your local commits)
  #   Changes to be committed:
  #     (use "git reset HEAD <file>..." to unstage)
  #   	deleted:    redacted
  #   Changes not staged for commit:
  #     (use "git add <file>..." to update what will be committed)
  #     (use "git checkout -- <file>..." to discard changes in working directory)
  #   	modified:   redacted

  # Nix the "on-branch".
  GREP_EXCLUDE="${GREP_EXCLUDE} | grep -v \"^On branch \""

  # Nix the "Changes ..." messages.
  GREP_EXCLUDE="${GREP_EXCLUDE} | grep -v \"^Changes \""

  # Nix the '(use "git ..." blah blah blah)' messages.
  GREP_EXCLUDE="${GREP_EXCLUDE} | grep -v \"^  (use \\\"git\""
}
exclude_git_usage_message

print_divergents () {
  #if [[ -n "${DIVERGENTS[0]}" ]]; then
  #  echo
  #fi
  # Set IFS so spaces in the messages we added are not interpreted as separate
  # array members.
  OLD_IFS=$IFS
  IFS=$'\n'
  for warning in "${DIVERGENTS[@]}"; do
    # Use -e so ${COLOR} and **bold** and __underline__ works.
    echo -e ${warning}
  done
  IFS=$OLD_IFS
}

show_extended_git_st () {
  # Given git-diff, printing out the diffables doesn't seem necessary;
  # 2016-08-15: and [lb] has copy-pasted this information in a very,
  # very log time.
  if ${DEBUG}; then
    echo "git diff \${DIFFABLES[@]}"
    echo
    echo "git diff ${DIFFABLES[@]}"
    echo
    echo "git status \${GREP_EXCLUDE}"
    echo
    echo "git status ${GREP_EXCLUDE}"
    echo
  fi
  #   On branch feature/blah
  #   Your branch is ahead of 'origin/master' by 25 commits.
  #     (use "git push" to publish your local commits)
  #   Changes not staged for commit:
  #     (use "git add <file>..." to update what will be committed)
  #     (use "git checkout -- <file>..." to discard changes in working directory)
  #
  #   	modified:   some/file
  #
  #   Untracked files:
  #     (use "git add <file>..." to include in what will be committed)
  #
  #   	another/file
  #
  #   no changes added to commit (use "git add" and/or "git commit -a")

  eval "git status ${GREP_EXCLUDE}"

  # We can remove newlines with GREP_EXCLUDE or with sed.
  #eval "git status ${GREP_EXCLUDE}" | /bin/sed '/^\s*$/d'

  # 2016-10-24: Text colors make word and line boundaries harder to detect.
  #stripcolors='/bin/sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g"'
  #eval "git status | ${stripcolors} ${GREP_EXCLUDE}"

  echod

  print_divergents
}

if [[ ${#DIFFABLES[@]} -eq 0 ]]; then
  # Return code is 0 if nothing diffs, but there could be added
  # (but not committed) and untracked files lurking about.
  RET_CODE=0
  echo -n "DUDE: Nothing dirty. "
  if ${GIT_ST_DIFF}; then
    echo "Nothing to diff."
    # MAYBE: Is this okay? What if added-but-not-committed? Untracked?
  elif ${GIT_ST_ADDP}; then
    echo "Nothing to add."
    # MAYBE: Is this okay? What if added-but-not-committed? Untracked?
  else
    echo "Nothing to stat."
    show_extended_git_st
  fi
else
  RET_CODE=1
  if ${GIT_ST_DIFF}; then
    git diff ${DIFFABLES[@]}
  elif ${GIT_ST_ADDP}; then
    git add -p ${DIFFABLES[@]}
  else
    show_extended_git_st
  fi
fi

exit ${RET_CODE}

