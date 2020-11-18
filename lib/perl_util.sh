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

# Perl REPL.

# V. Basic REPL:
#
#   alias perl-repl='perl -de1'
#
# Ref: https://stackoverflow.com/a/73703/14159598

# Use readline wrapper to add history, completion, and line editing:
#
#   alias perl-repl='rlwrap perl -d -e 1'
#
# (though it appears history and line editing work for me in the
#  V. Basic REPL, and I do not see completion working via rlwrap,
#  so in practice this behaves same for me as previous).
#
# Ref: https://stackoverflow.com/questions/73667/
#   how-can-i-start-an-interactive-console-for-perl#comment41519549_73703

# Step it up a notch, cleanup the prompt, from this:
#
#   __DB<1>_print "hello, perld"
#
# to this:
#
#   perl> print "hello, perld"
#
# And add line evaluation, similar to Python and Node REPLs, e.g.,
#
#   $ perl-repl
#   perl> 123
#   123
#   perl> 123 + 345
#   468
#   perl> $q = "hello"
#   hello
#
# But note that a `print` itself is also evaluated, and it
# returns 1, which is printed after what `print` prints, e.g.,
#
#   perl> print "abc"
#   abc1
#   perl> print $q
#   hello1
#
# but given the evaluator itself, you won't need to call `print`.
#
# Ref: https://stackoverflow.com/a/22840242/14159598
perl-repl () {
  rlwrap -A -pgreen -S"perl> " perl -wnE'say eval()//$@'
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main () {
  check_deps
  unset -f check_deps

  perl_set_path_and_environs
  unset -f perl_set_path_and_environs
}

main "$@"
unset -f main

