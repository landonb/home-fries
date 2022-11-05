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
#
#   rlwrap -A -pgreen -S"perl> " perl -wnE'say eval()//$@'
#
# Except arrays are not handled, e.g.,:
#
#   perl> @ocouple = qw( Felix Oscar );
#   2
#   perl> @ocouple
#   2
#   perl> scalar @ocouple
#   2

# Which brings us further down the SO discussion to a comment offering
# "a nice output when the expression evaluates to a list or a reference".
# Indeed, e.g.,:
#
#   perl> @ocouple = qw( Felix Oscar );
#   $VAR1 = [
#             'Felix',
#             'Oscar'
#           ];
#
#   perl> @ocouple
#   $VAR1 = [
#             'Felix',
#             'Oscar'
#           ];
#
#   perl> scalar @ocouple
#   $VAR1 = [
#             2
#           ];
#
# except now *everything* is printed as an array...
#
#   perl> 1234
#   $VAR1 = [
#             1234
#           ];
#
# nothing's ever perfect, is't.
perl-repl () {
  # Ref: michau 2019-07-14: https://stackoverflow.com/questions/73667/
  #   how-can-i-start-an-interactive-console-for-perl#comment100588494_22840242
  rlwrap -A -pgreen -S'perl> ' perl -MData::Dumper -wnE'say Dumper[eval()]//$@'
}

# MEH/2020-11-17 22:49: Here's one that maybe addresses previous issue?
# - Requires Data::Printer.
#     sudo cpan Data::Printer
# Ref: https://stackoverflow.com/a/31283257/14159598
#
# Hint: "Use `p @<arrayOrList>` or `p %<hashTable>` to print
#        arrays/lists/hashtables; e.g.: `p %ENV`"
#
#  claim_alias_or_warn "iperl" \
#   'rlwrap -A -S "iperl> " perl -MData::Printer -wnE '\'' BEGIN { say "HI"; } say eval()//$@'\'

# Other Perl REPL projects:
#
# - perlconsole (4+ years stale)
#   https://metacpan.org/pod/release/SUKRIA/perlconsole-0.4/perlconsole
#
# - Devel::REPL - A modern perl interactive shell (5+ years stale)
#   https://metacpan.org/pod/Devel::REPL
#   https://github.com/p5sagit/Devel-REPL
#   https://metacpan.org/release/Devel-REPL
#
# - Reply (4+ years stale)
#   https://metacpan.org/pod/Reply
#   https://github.com/doy/reply
#
# - perli (2 years stale)
#   https://github.com/mklement0/perli
#   https://github.com/mklement0/perli#examples
#
# - Perl Shell (psh) (8-21 years old)
#   https://gregorpurdy.com/psh/
#   https://github.com/gnp/psh

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

main () {
  check_deps
  unset -f check_deps

  perl_set_path_and_environs
  unset -f perl_set_path_and_environs
}

main "$@"
unset -f main

