#!/bin/bash

# Backs up and moves existing vim files and copies dubsacks

backup_dir="$HOME/.vim-backup-"`eval date +%Y%m%d`

# Case insensitve =~ regex matching
shopt -s nocasematch

read -a the_answer -p 'Install dubsacks vim files to '$backup_dir' ? [y/N] '
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

echo 'Backing up existing vim files'
#mv -f ~/.vim* $backup_dir
if [[ -d ~/.vim ]]; then
  echo "Moving $HOME/.vim"
  mv ~/.vim $backup_dir
fi
for f in "$HOME/.vimprojects" "$HOME/.vimrc"; do
  if [[ -f $f ]]; then
    echo "Moving $f"
    mv $f $backup_dir
  fi
done

echo 'Copying dubsacks vim files'
cp -R dubsacks/.vim* ~/

echo 'Enjoy!'

