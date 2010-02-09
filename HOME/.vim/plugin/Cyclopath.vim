" This script modifies Vim for use in a Cyclopath development environment

" Cyclopath Shiftwidth
" --------------------------------
" Cyclopath uses trips! 321 Polo? 321 Cyclopath!
set tabstop=3
set shiftwidth=3
" Cyclopath also enforces a 79 character line max
" NOTE Not sure why set doesn't work, but autocmd does...
"set textwidth=79
"set wrapmargin=79
autocmd BufRead * set tw=79

" Cyclopath Grep
" --------------------------------
" Exclude Cyclopath's build directory from grep.
" See dubsacks.vim for what all these options mean.
if filereadable(
    \ $HOME . "/.vim/grep-exclude")
  " *nix
  set grepprg=egrep\ -n\ -R\ -i\ --exclude-from=\"$HOME/.vim/grep-exclude\"\ --exclude-dir=\"build\"
elseif filereadable(
    \ $USERPROFILE . 
    \ "/vimfiles/grep-exclude")
  " Windows
  set grepprg=egrep\ -n\ -R\ -i\ --exclude-from=\"$USERPROFILE/vimfiles/grep-exclude\"\ --exclude-dir=\"build\"
else
  call confirm('dubsacks.vim: Cannot find grep-xclude file', 'OK')
endif

