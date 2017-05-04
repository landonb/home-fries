# File: ruby_util.sh
# Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
# Last Modified: 2017.05.04
# Project Page: https://github.com/landonb/home_fries
# Summary: Ruby Helpers.
# License: GPLv3
# vim:tw=0:ts=2:sw=2:et:norl:

if [[ -f ${HOME}/.fries/lib/bash_base.sh ]]; then
  DEBUG_TRACE=false \
    source ${HOME}/.fries/lib/bash_base.sh
fi

# See:
#   https://github.com/postmodern/ruby-install
#   https://github.com/postmodern/chruby

if [[ -f /usr/local/share/chruby/chruby.sh ]]; then
  source /usr/local/share/chruby/chruby.sh
fi

# The github.com/postmodern/chruby README lists Anti-Features, starting with:
#   - Does not hook cd.
#   - Does not install executable shims.
# However, it doesn't say what it does do instead!
#   chruby/auto.sh sets a trap on DEBUG,
#   and if $BASH_COMMAND != $PROMPT_COMMAND,
#   it walks up the directory tree looking
#   for a .ruby-version file on which to chruby.
# Cmd:
#   trap '[[ "$BASH_COMMAND" != "$PROMPT_COMMAND" ]] && chruby_auto' DEBUG
# Ref:
#   BASH_COMMAND
#     The  command  currently  being  executed or about to be executed,
#     unless the shell is executing a command as the result of a trap,
#     in which case it is the command executing at the time of the trap.
#   PROMPT_COMMAND
#     If set, the value is executed as a command prior to issuing each
#     primary prompt.
#   DEBUG
#     Refer to the description of the extdebug option to the shopt builtin
#     for details of its effect  on  the  DEBUG  trap.
#   extdebug
#     If set, behavior intended for use by debuggers is enabled:
#     1.     The  -F option to the declare builtin displays the source file name and line number corresponding
#            to each function name supplied as an argument.
#     2.     If the command run by the DEBUG trap returns a non-zero value, the next command  is  skipped  and
#            not executed.
#     3.     If  the  command run by the DEBUG trap returns a value of 2, and the shell is executing in a sub‐
#            routine (a shell function or a shell script executed by the . or  source  builtins),  a  call  to
#            return is simulated.
#     4.     BASH_ARGC and BASH_ARGV are updated as described in their descriptions above.
#     5.     Function tracing is enabled:  command substitution, shell functions, and subshells invoked with (
#            command ) inherit the DEBUG and RETURN traps.
#     6.     Error tracing is enabled:  command substitution, shell functions, and subshells  invoked  with  (
#            command ) inherit the ERR trap.
# So:
#   Every time you run *any* command, auto.sh
#   crawls the tree looking for .ruby-version.

# 2017-05-03: I'm disabling this. Seems redonkulous.
# You have ``gogo`` command et al to accomplish same.
# And then you're not spinning up dir every time you
# run a Bash command. And it's not not that's slow,
# it's just the principal of the thing, man.
if false; then
if [[ -f /usr/local/share/chruby/auto.sh ]]; then
  source /usr/local/share/chruby/auto.sh
fi
fi

if [[ -z ${HOMEFRIES_WARNINGS+x} ]]; then
  # Usage, e.g.:
  #   HOMEFRIES_WARNINGS=true bash
  HOMEFRIES_WARNINGS=false
fi

# Here we monkey patch the chruby function -- we replace
# the chruby fcn. with our own wrapper function.
# MAYBE: I should probably just submit a pull request.
#
# PROBLEM: If the ruby version is not the 0 patch level (e.g., 2.3.0),
#   chruby doesn't include all the gem paths. For example, should you
#   `chruby 2.3.3`, GEM_PATH includes the 2.3.3/ directory, but gem install
#   stashed everything under the 2.3.0/ directory, so we have to add that
#   back in.

# Do a little Bash trickery: Spit out the original function and set it up
#   under a new name. We use `tail -n +2` to remove the original function
#   name but leave the function body, e.g., leave out ``chruby_use ()\n``.

orig_chruby_use () {
  :
}
if declare -f chruby_use &> /dev/null; then
  eval "$(echo "orig_chruby_use()"; declare -f chruby_use | tail -n +2)"
else
  $HOMEFRIES_WARNINGS && echo "WARNING: chruby_use() not found"
fi

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
    ruby_set_gem_path
    # WRONG:
    #RUBY_ROOT_ZERO=$(echo ${RUBY_ROOT} | /bin/sed -r s/-${RUBY_VERSION}$/-${RUBY_MINOR_ZERO}/)
    #export PATH="${PATH}:${RUBY_ROOT_ZERO}/bin"
    #export PATH="${PATH}:${GEM_HOME/${RUBY_VERSION}/${RUBY_MINOR_ZERO}}/bin"
    local gem_ruby_bin="${GEM_HOME/${RUBY_VERSION}/${RUBY_MINOR_ZERO}}/bin"
    #if [[ ":${PATH}:" != *":${gem_ruby_bin}:"* ]]; then
    #  export PATH="${PATH}:${gem_ruby_bin}"
    #fi
    path_add_part ${gem_ruby_bin}
  fi
}

ruby_set_gem_path () {
  local GEM_PATHS=()

  local RUBY_MINOR_ZERO=$(ruby -e "puts RUBY_VERSION.split('.')[0..1].join('.') + '.0'")
  local RUBY_VERS=$(ruby -e "puts RUBY_VERSION")

  if false; then
    # 2017-05-03: I started having issues at work... I think this is all too much!

    if ``command -v ruby >/dev/null 2>&1``; then
      # E.g., ${HOME}/.gem/ruby/2.3.0
      GEM_PATHS+=(${HOME}/.gem/ruby/${RUBY_MINOR_ZERO})
      # 2017-05-03: MAYBE: Do we need this one, too? If anything, it's same as previous.
      GEM_PATHS+=($(ruby -rubygems -e 'puts Gem.user_dir'))
    fi
    GEM_PATHS+=(${HOME}/.rubies/ruby-${RUBY_MINOR_ZERO}/lib/ruby/gems/${RUBY_MINOR_ZERO})
    # 2017-05-03: I am so confused.
    # E.g., ${HOME}/.gem/ruby/2.3.0/ruby/2.3.0
    GEM_PATHS+=(${HOME}/.gem/ruby/${RUBY_MINOR_ZERO}/ruby/${RUBY_MINOR_ZERO})
    # E.g., ${HOME}/.gem/ruby-2.3.3/ruby/2.3.0
    GEM_PATHS+=(${HOME}/.gem/ruby/${RUBY_VERS}/ruby/${RUBY_MINOR_ZERO})
    # 2017-01-25: Haven't touched a project in one month, and now it's not working?
    #   Am I on a different machine, or what? Anyway, missing /var/lib/gems, I guess!
    # E.g., /var/lib/gems/2.3.0
    # 2017-05-03 14:38: ARGH: apt-get install binaries are in /var/lib/gems,
    #   not the ones controlled by chruby, rvm, etc.
    #GEM_PATHS+=(/var/lib/gems/${RUBY_MINOR_ZERO})
  fi

  # E.g., ${HOME}/.rubies/ruby-2.3.3/ruby/2.3.0
  GEM_PATHS+=(${HOME}/.rubies/ruby-${RUBY_VERS}/ruby/${RUBY_MINOR_ZERO})

  for ((i = 0; i < ${#GEM_PATHS[@]}; i++)); do
    local PATH_ELEM="${GEM_PATHS[$i]}"
    #echo "PATH_ELEM: $PATH_ELEM"
    if [[ -d "${PATH_ELEM}" ]]; then
      if [[ ":${GEM_PATH}:" != *":${PATH_ELEM}:"* ]]; then
        if [[ -n ${GEM_PATH} ]]; then
          GEM_PATH="${GEM_PATH}:"
        fi
        GEM_PATH="${GEM_PATH}${PATH_ELEM}"
        #echo "GEM_PATH: $GEM_PATH"
      else
        #echo "Already added: $PATH_ELEM"
        :
      fi
    else
      #echo "Not a directory: $PATH_ELEM"
      :
    fi
  done
  #echo "GEM_PATH: $GEM_PATH"

  export GEM_PATH

  if true; then
    # $ echo $GEM_PATH
    # ${HOME}/.gem/ruby/2.3.0:/var/lib/gems/2.3.0
    # $ gogo project
    # Skipping ~/.exoline symlink: no replacement found.
    # Entered /work/clients/project
    # $ ll
    # Ignoring byebug-9.0.6 because its extensions are not built.  Try: gem pristine byebug --version 9.0.6
    # Monkey patching!
    # total 188K
    # drwxrwxr-x 11 landonb landonb 4.0K May  1 18:41 ./
    # drwxrwxr-x  7 landonb landonb 4.0K May  1 14:08 ../
    # ...

    # E.g., ${HOME}/.rubies/ruby-2.3.3/ruby/2.3.0/bin
    path_add_part ${HOME}/.rubies/ruby-${RUBY_VERS}/ruby/${RUBY_MINOR_ZERO}/bin
  fi

  if false; then
    # Put this at first place in the PATH. If it exists.
    path_add_part ${HOME}/.gem/ruby/${RUBY_MINOR_ZERO}/bin
    path_add_part ${HOME}/.gem/ruby/${RUBY_VERS}/bin
  fi

}
ruby_set_gem_path

