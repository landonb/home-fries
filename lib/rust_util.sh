#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=bash
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# Rust `cargo` lazy-loader.

# PREREQUISITES:
#
# Install Rust: https://www.rust-lang.org/tools/install
#
#   curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
#
# Or audit the script first and run it manually:
#
#   cd "${HF_DOWNLOADS_DIR:-${HOME}/.downloads}"
#   wget https://sh.rustup.rs -O install-rust.sh
#   # Review the file. Then, if you trust it:
#   chmod 775 install-rust.sh
#   ./install-rust.sh
#
# Installs to:
#
#   ~/.rustup
#   ~/.cargo/bin
#
# Cleanup (remove) the source command it appends to the shell files:
#
#   ~/.profile
#   ~/.bashrc
#   ~/.zshenv
#
# Each file is appended with the same line:
#
#   . "$HOME/.cargo/env"
#
# Homefries is pure Bash, so remove the Zsh file:
#
#   command rm -- ~/.zshenv
#
# And we'll lazy-load the Rust toolchain on-demand (JIT!) [this file],
# so revert the changes to ~/.profile and ~/.bashrc and take a look
# below at the lazy-load functionality.
#
# HINTS:
#
# To update Rust:
#
#   rustup update
#
# To uninstall Rust:
#
#   rustup self uninstall

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

_hf_jit_load_rust () {
  if [ -d "${HOME}/.cargo" ]; then
    . "${HOME}/.cargo/env"

    return 0
  fi

  >&2 echo "ERROR: Missing dir: ~/.cargo"

  return 1
}

cargo () {
  if ! _hf_jit_load_rust; then

    return 1
  fi

  unset -f cargo
  unset -f _hf_jit_load_rust

  cargo "$@"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main () {
  :
}

main "$@"
unset -f main

