#!/bin/bash

# See:
#  http://vim.wikia.com/wiki/A_better_Vimdiff_Git_mergetool

mkdir -p /srv/opt/.downloads/whiteinge
pushd /srv/opt/.downloads/whiteinge &> /dev/null
git clone https://github.com/whiteinge/dotfiles.git
popd &> /dev/null

pushd ${HOME}/.fries/bin &> /dev/null
/bin/ln /srv/opt/.downloads/whiteinge/dotfiles/bin/diffconflicts .
popd &> /dev/null

git config --global merge.tool diffconflicts
git config --global mergetool.diffconflicts.cmd 'diffconflicts vim $BASE $LOCAL $REMOTE $MERGED'
git config --global mergetool.diffconflicts.trustExitCode true
git config --global mergetool.keepBackup false

