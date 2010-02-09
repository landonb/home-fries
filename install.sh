#!/bin/bash

# Backs up and moves existing bash and vim files and copies new ones
# setup for Cyclopath development

#CYCLOPATH_PATH=/export/scratch/landonb/cp
CYCLOPATH_PATH=/home/pee/cp/cp
# TODO Prompt for this!

backup_dir="$HOME/.Cyclopath_rc-backup-"`eval date +%Y%m%d`

# Case insensitve =~ regex matching
shopt -s nocasematch

read -a the_answer -p 'Install Cyclopath_rc bash and vim files to '$HOME' ? [y/N] '
if [[ $the_answer =~ ^ye?s?$ ]]; then
  : # no-op
else
  echo 'Better luck next time!'
  exit
fi

# See if the backup directory already exists
# NOOB NOTE Bash is particular about spaces, e.g., 
#           None when defining=variables, and always 
#           when [ -t testing ] files and folders
if [ -d $backup_dir ]; then
  # See 'info read'
  read -a the_answer -p 'Backup directory already exists. Overwrite? [y/N] '
  if [[ $the_answer =~ ^ye?s?$ ]]; then
    rm -rf $backup_dir
  else
    echo 'Oopsydoodle!'
    exit
  fi
fi

echo 'Creating backup directory ' $backup_dir
mkdir $backup_dir

echo 'Backing up existing files'
for f in "$HOME/.bash_logout" \
         "$HOME/.bash_profile" \
         "$HOME/.bashrc" \
         "$HOME/.bashrc-cyclopath" \
         "$HOME/.bashrc-dub" \
         "$HOME/.bashrc-private" \
         "$HOME/mm.cfg" \
         "$HOME/.vim/plugin/Cyclopath.vim"; do
         # See below for "$HOME/.vimprojects"
  if [[ -f $f ]]; then
    echo "Moving $f"
    mv $f $backup_dir/
  fi
done

echo 'Copying Cyclopath_rc files'
cp HOME/.bash* ~/
cp HOME/mm.cfg ~/
cp HOME/.vim* ~/
cp -Rf HOME/.vim ~/

# Fix the Cyclopath Path
echo 'Fixing Cyclopath paths'
sed s,%CYCLOPATH_PATH%,$CYCLOPATH_PATH,g HOME/.vimprojects > $HOME/.vimprojects

echo 'Enjoy!'

