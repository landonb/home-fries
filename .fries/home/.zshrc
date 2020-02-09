
# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
export PATH="$PATH:$HOME/.rvm/bin"

# 2020-02-06: Added by git@github.com:junegunn/fzf.git:install.
#
# - This is what's appeneded to .zshrc:
#
#     [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
#
# - Because I don't use Z shell, I just copied that file's contents here.
#   - If I did use Z shell, I'd consider instead keeping that file
#     (perhaps under ~/.fries/lib) and sourcing it instead.
#
# - This is what I'd found in ~/.fzf.zsh:

# Setup fzf
# ---------
if [[ ! "$PATH" == */kit/working/golang/fzf/bin* ]]; then
  export PATH="${PATH:+${PATH}:}/kit/working/golang/fzf/bin"
fi

# Auto-completion
# ---------------
[[ $- == *i* ]] && source "/kit/working/golang/fzf/shell/completion.zsh" 2> /dev/null

# Key bindings
# ------------
source "/kit/working/golang/fzf/shell/key-bindings.zsh"

