# Retrosoft bash shell script

# Source global definitions
if [ -f /etc/bashrc ]; then
    # Fedora
    . /etc/bashrc
elif [ -f /etc/bash.bashrc ]; then
    # Debian/Ubuntu
    . /etc/bash.bashrc
fi

# Source user scripts, e.g., ./.bashrc-work, ./.bashrc-home, etc.
for f in $(find . -maxdepth 1 -type f -name ".bashrc-*")
  do
    source $f
  done

