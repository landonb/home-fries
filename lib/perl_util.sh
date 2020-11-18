#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Project: https://github.com/landonb/home-fries#🍟
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

check_deps () {
  check_dep 'path_prefix'
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

perl_set_path_and_environs () {
  # 2020-05-04: The optional GnuCash extension, Finance::Quote, installed
  # from CPAN (via gnc-fq-update), appends these environs to ~/.bashrc.
  # - See:
  #     tasks/app-gnucash.yml
  #   from
  #     github.com:landonb/zoidy_home-fries
  # - Ref:
  #     http://finance-quote.sourceforge.net/

  # PATH="${HOME}/perl5/bin${PATH:+:${PATH}}"
  path_prefix "${HOME}/perl5/bin"

  PERL5LIB="${HOME}/perl5/lib/perl5${PERL5LIB:+:${PERL5LIB}}"
  export PERL5LIB

  PERL_LOCAL_LIB_ROOT="${HOME}/perl5${PERL_LOCAL_LIB_ROOT:+:${PERL_LOCAL_LIB_ROOT}}"
  export PERL_LOCAL_LIB_ROOT

  PERL_MB_OPT="--install_base \"${HOME}/perl5\""
  export PERL_MB_OPT

  PERL_MM_OPT="INSTALL_BASE=${HOME}/perl5"
  export PERL_MM_OPT
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

alias perl-repl='rlwrap perl -d -e 1'

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main () {
  check_deps
  unset -f check_deps

  perl_set_path_and_environs
  unset -f perl_set_path_and_environs
}

main "$@"
unset -f main

