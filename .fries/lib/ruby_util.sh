# File: ruby_util.sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Last Modified: 2016.12.11
# Project Page: https://github.com/landonb/home_fries
# Summary: Ruby Helpers.
# License: GPLv3
# vim:tw=0:ts=2:sw=2:et:norl:

# 2016-12-07: ``chruby`` sources.
# MAYBE: This bashrc.core.sh is getting bloated. Make a ruby_util.sh?
if [[ -f /usr/local/share/chruby/chruby.sh ]]; then
  source /usr/local/share/chruby/chruby.sh
fi
if [[ -f /usr/local/share/chruby/auto.sh ]]; then
  source /usr/local/share/chruby/auto.sh
fi

# tail -n +2 remove the original function declartion.
eval "$(echo "orig_chruby_use()"; declare -f chruby_use | tail -n +2)"
# MONKEY PATCH!
chruby_use () {
  orig_chruby_use $*
  # See chruby_use in
  #   /usr/local/share/chruby/chruby.sh
  # MAYBE: If you need to cleanup old paths, something like this:
  if false; then
    export GEM_PATH="$(\
      echo ${GEM_PATH} \
        | /bin/sed -r "s@:?${GEM_HOME}[^:]*:@:@g" \
        | /bin/sed -r s/^:// \
        | /bin/sed -r s/:$//
    )"
  fi
  # Check if patch version.
  PATCH_NUM=$(ruby -e "puts RUBY_VERSION.split('.')[2]")
  if [[ ${PATCH_NUM} -gt 0 ]]; then
    # FIXME/2016-12-11: `gogo utc utc-audit` then `date` hits this
    #where
    # # 18 chruby_use /home/landonb/.fries/.bashrc/bashrc.core.sh
    # # 36 chruby /usr/local/share/chruby/chruby.sh
    # # 10 chruby_auto /usr/local/share/chruby/auto.sh
    # REASON: auto.sh sets a trap on DEBUG which runs before every command!
    # 2016-12-11: Ug: Now the problem isn't repeating itself...
    #   well, it seems to only happen in a `ttyrec` session. Srsly?
    echo "Monkey patching!"
    RUBY_MINOR_ZERO=$(ruby -e "puts RUBY_VERSION.split('.')[0..1].join('.') + '.0'")
    GEM_PATH="${GEM_PATH}:${HOME}/.gem/ruby/${RUBY_MINOR_ZERO}"
    GEM_PATH="${GEM_PATH}:${HOME}/.rubies/ruby-${RUBY_MINOR_ZERO}/lib/ruby/gems/${RUBY_MINOR_ZERO}"
    export GEM_PATH
    # WRONG:
    #RUBY_ROOT_ZERO=$(echo ${RUBY_ROOT} | /bin/sed -r s/-${RUBY_VERSION}$/-${RUBY_MINOR_ZERO}/)
	  #export PATH="${PATH}:${RUBY_ROOT_ZERO}/bin"
    export PATH="${PATH}:${GEM_HOME/${RUBY_VERSION}/${RUBY_MINOR_ZERO}}/bin"
  fi
}

