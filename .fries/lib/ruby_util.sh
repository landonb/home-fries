# File: ruby_util.sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Last Modified: 2016.12.11
# Project Page: https://github.com/landonb/home_fries
# Summary: Ruby Helpers.
# License: GPLv3
# vim:tw=0:ts=2:sw=2:et:norl:

# See:
#   https://github.com/postmodern/ruby-install
#   https://github.com/postmodern/chruby

if [[ -f /usr/local/share/chruby/chruby.sh ]]; then
  source /usr/local/share/chruby/chruby.sh
fi

if [[ -f /usr/local/share/chruby/auto.sh ]]; then
  source /usr/local/share/chruby/auto.sh
fi

# Here we monkey patch the chruby function -- we replace
# the chruby fcn. with our own wrapper function.
# MAYBE: I should probably just submit a pull request.
#
# PROBLEM: If the ruby version is not the 0 patch level (e.g., 2.3.0),
#   chruby doesn't include all the gem paths. For example, should you
#   `chruby 2.3.3`, GEM_PATH include the 2.3.3/ directory, but gem install
#   stashed everything under the 2.3.0/ directory, so we have to add that
#   back in.

# Do a little Bash trickery: Spit out the original function and set it up
#   under a new name. We use `tail -n +2` to remove the original function
#   name but leave the function body, e.g., leave out ``chruby_use ()\n``.
eval "$(echo "orig_chruby_use()"; declare -f chruby_use | tail -n +2)"

# And here's our
#   MONKEY PATCH!
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
    # NOTE/2016-12-11: If there's a .ruby-version file in the current
    #   directory, running *any* command might invoke us, since auto.sh
    #   sets a trap on DEBUG which runs before every command. Just FYI.
    # MAYBE: Silence this echo. For now, curious when this fcn. is triggered.
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

